-- Displays — modes for working with the external display (TV):
-- mirror ↔ extend, and parking a single window on the external display.
--
-- All state-reading and geometry logic lives in topology.lua and
-- window_parking.lua as pure functions, covered by tests. Here — only
-- side effects: real screens, timers, banners, subscriptions.
local obj = {}

local log = hs.logger.new('Displays', 'info')
local notify = require("notify")
local spoonPath = debug.getinfo(1, "S").source:match("@(.*/)")

local cfg      = dofile(spoonPath .. "config.lua")
local topology = dofile(spoonPath .. "topology.lua")
local parking  = dofile(spoonPath .. "window_parking.lua")

obj.config   = cfg
obj.topology = topology
obj.registry = parking.new_registry()

-- Whether the machine has an internal display at all. A hardware property,
-- computed once. Without it, "laptop in mirror mode" and "desktop with a
-- single monitor" are indistinguishable: in both cases the screen list is
-- exactly one external screen.
--
-- hw.model does NOT work for this: Apple moved to a scheme like "Mac15,7",
-- where the substring "MacBook" doesn't appear at all. The authoritative
-- source is system_profiler ("Connection Type: Internal"): it sees the
-- internal display even when it's hidden behind hardware mirroring. Takes
-- about a second, so it's computed asynchronously and exactly once.
local has_internal = nil
local _profiler_task = nil

local function probe_internal_display()
    if _profiler_task or has_internal ~= nil then return end
    _profiler_task = hs.task.new("/usr/sbin/system_profiler",
        function(_, stdout, _)
            _profiler_task = nil
            has_internal = (stdout or ""):find("Connection Type: Internal") ~= nil
            log.i("has_internal=" .. tostring(has_internal) .. " (system_profiler)")
        end,
        { "SPDisplaysDataType" })
    _profiler_task:start()
end

local function machine_has_internal_display()
    if has_internal ~= nil then return has_internal end
    -- Before system_profiler answers: only laptops have a battery, and every
    -- Apple laptop has an internal display. On an iMac this gives false, but
    -- there the real answer arrives a second later and overrides the guess.
    return hs.battery.percentage() ~= nil
end

obj.machine_has_internal_display = machine_has_internal_display

local function screens() return hs.screen.allScreens() end
local function state()   return topology.state(screens(), cfg, machine_has_internal_display()) end
local function tv()      return topology.external_screen(screens(), cfg) end

-- All banners of this feature share one id, so fast toggling redraws
-- one banner instead of stacking up a pile.
local BANNER_ID = "displays-state"
local function banner(title, message, tint, symbol)
    notify.show({
        id       = BANNER_ID,
        title    = title,
        message  = message,
        tint     = tint,
        symbol   = symbol,
        duration = 2,
    })
end

-- Parking -----------------------------------------------------------------

local function park(win)
    local target = tv()
    if not (win and target) then return end

    local entry        = obj.registry:record(win)
    local target_frame = target:fullFrame()
    win:setFrame(target_frame, 0)

    -- Verify what actually happened: setFrame can apply the position and
    -- silently ignore the size (Finder copy dialogs are fixed-size).
    obj._verify_timer = hs.timer.doAfter(cfg.PARK_VERIFY_DELAY, function()
        local result = parking.classify_park_result(
            win:frame(), target_frame, cfg.GEOMETRY_TOLERANCE)

        if result == "ok" then
            banner("На телевизоре", "", "green", "tv")
        elseif result == "size_rejected" then
            win:setFrame(parking.centered_frame(win:frame(), target_frame), 0)
            banner("Окно не резайзится", "отцентрировал на телевизоре", "orange", "tv")
        else
            win:setFrame(entry.frame, 0)
            obj.registry:forget(win)
            banner("Не удалось перенести окно", "вернул на место", "red",
                   "exclamationmark.triangle.fill")
        end
    end)
end

local function find_screen_by_uuid(uuid)
    for _, s in ipairs(screens()) do
        if s:getUUID() == uuid then return s end
    end
    return nil
end

local function unpark(win)
    if not win then return end
    local entry  = obj.registry:take(win)
    local origin = entry and find_screen_by_uuid(entry.screen_uuid) or nil

    -- Restore to the saved position only if the saved screen still exists
    -- AND it's internal. Otherwise fall back: the window ended up on the
    -- external screen without going through us (dragged by mouse), or the
    -- screen disappeared.
    if entry and origin and topology.is_internal(origin, cfg) then
        win:setFrame(entry.frame, 0)
        banner("На ноутбуке", "", "green", "laptopcomputer")
        return
    end

    local internal = topology.internal_screen(screens(), cfg)
    if not internal then
        banner("Некуда вернуть окно", "внутренний экран недоступен", "orange")
        return
    end

    win:moveToScreen(internal, false, true, 0)
    -- Second pass: when moving between screens the size doesn't always
    -- apply on the first try.
    obj._unpark_timer = hs.timer.doAfter(0.2, function()
        spoon.PowerWindows:moveLeft(win)
        banner("На ноутбуке", "вернул в позицию по умолчанию", "green", "laptopcomputer")
    end)
end

function obj:unpark_all()
    for _, id in ipairs(self.registry:ids()) do
        local win = hs.window.get(id)
        if win then
            unpark(win)
        else
            self.registry.entries[id] = nil
        end
    end
end

-- Waiting for the second screen to appear ---------------------------------

local function await_extend(onReady)
    local deadline = os.time() + cfg.EXTEND_TIMEOUT
    local poll
    poll = function()
        if state() == "extend" then
            onReady()
            return
        end
        if os.time() >= deadline then
            banner("Extend не поднялся", "второй экран не появился", "red",
                   "exclamationmark.triangle.fill")
            return
        end
        obj._poll_timer = hs.timer.doAfter(0.3, poll)
    end
    obj._poll_timer = hs.timer.doAfter(0.3, poll)
end

-- Toggles -------------------------------------------------------------------

function obj:toggle_window_to_tv()
    self.registry:prune()

    local st = state()
    if st == "no_tv" then
        banner("Внешний экран не подключён", "", "orange", "tv.slash")
        return
    end

    local win = hs.window.focusedWindow()
    if not win then
        banner("Нет активного окна", "", "orange")
        return
    end

    if st == "extend" then
        if self.registry:is_parked(win) then unpark(win) else park(win) end
        return
    end

    -- Mirror: we bring up extend ourselves, then park. The topology change
    -- takes seconds; hs.screen objects are stale until then.
    local ok, err = topology.set_extend(screens(), cfg)
    if not ok then
        banner("Не удалось включить extend", err or "", "red",
               "exclamationmark.triangle.fill")
        return
    end
    await_extend(function() park(win) end)
end

function obj:toggle_mirror()
    self.registry:prune()

    local st = state()
    if st == "no_tv" then
        banner("Внешний экран не подключён", "", "orange", "tv.slash")
        return
    end

    if st == "mirror" then
        local ok, err = topology.set_extend(screens(), cfg)
        if ok then
            banner("Extend", "внешний экран — второй", "green", "rectangle.on.rectangle")
        else
            banner("Не удалось включить extend", err or "", "red",
                   "exclamationmark.triangle.fill")
        end
        return
    end

    -- extend → mirror. With multiple external screens, "mirror" has no
    -- unambiguous meaning.
    local _, external = topology.classify(screens(), cfg)
    if #external > 1 then
        banner("Несколько внешних экранов", "зеркало неоднозначно", "orange")
        return
    end

    -- Order is critical: rescue windows WHILE both screens still exist.
    -- Otherwise macOS scatters windows from the vanishing screen itself,
    -- mangling their sizes.
    self:unpark_all()
    obj._mirror_timer = hs.timer.doAfter(cfg.UNPARK_SETTLE_DELAY, function()
        local ok, err = topology.set_mirror(screens(), cfg)
        if ok then
            banner("Зеркало", "Mac на разрешении внешнего экрана", "green",
                   "rectangle.on.rectangle")
        else
            banner("Не удалось включить зеркало", err or "", "red",
                   "exclamationmark.triangle.fill")
        end
    end)
end

-- Lifecycle -----------------------------------------------------------------

function obj:init()
    -- PowerWindows shouldn't know about the TV — it learns this from us.
    spoon.PowerWindows:addSkipPredicate(function(win)
        return obj.registry:is_parked(win)
    end)
    return self
end

-- Called AFTER require "reactive_state" — the subscription targets its state.
function obj:start()
    probe_internal_display()
    obj._display_watcher = hs.watchable.watch("hammerspoon.displayCount", function()
        if state() == "no_tv" then
            log.i("внешний экран пропал, спасаем припаркованные окна")
            obj:unpark_all()
        end
    end)

    -- The layout in PowerWindows is defined in screen fractions, and macOS
    -- doesn't recompute them on a resolution change — windows stay roughly in
    -- place with wrong sizes. Rescuing parked windows runs off the screen
    -- count and gets there first: it has its own 0.2s timer against our
    -- debounce.
    obj._relayout_watcher = hs.watchable.watch("hammerspoon.displaySignature", function()
        if obj._relayout_timer then obj._relayout_timer:stop() end
        obj._relayout_timer = hs.timer.doAfter(cfg.RELAYOUT_SETTLE_DELAY, function()
            spoon.PowerWindows:arrangeAllNow()
            banner("Разложил окна", "под новое разрешение", "green",
                   "macwindow.on.rectangle")
        end)
    end)
    return self
end

return obj
