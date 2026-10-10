-- Screen classification and topology switching.
--
-- The read functions are pure: they take a list of screens and never call
-- hs.screen themselves. A screen for them is any object with :name() and
-- :getUUID(). That's what makes the module testable without a second
-- physical display.
local T = {}

function T.is_internal(screen, cfg)
    local name = screen:name() or ""
    for _, pattern in ipairs(cfg.INTERNAL_NAME_PATTERNS) do
        if name:find(pattern) then return true end
    end
    return false
end

function T.classify(screens, cfg)
    local internal, external = {}, {}
    for _, s in ipairs(screens) do
        if T.is_internal(s, cfg) then
            table.insert(internal, s)
        else
            table.insert(external, s)
        end
    end
    return internal, external
end

-- has_internal_display — does the machine have a built-in display AT ALL.
-- Without it, "MacBook in mirror mode" (the internal display hidden under
-- hardware mirroring) and "desktop with one monitor" are indistinguishable:
-- in both cases the screen list is exactly one external screen.
function T.state(screens, cfg, has_internal_display)
    local internal, external = T.classify(screens, cfg)
    if #external == 0 then return "no_tv" end
    if #internal > 0 then return "extend" end
    if has_internal_display then return "mirror" end
    return "no_tv"
end

function T.external_screen(screens, cfg)
    local _, external = T.classify(screens, cfg)
    if #external == 0 then return nil end
    for _, uuid in ipairs(cfg.PREFERRED_EXTERNAL_UUIDS) do
        for _, s in ipairs(external) do
            if s:getUUID() == uuid then return s end
        end
    end
    return external[1]
end

function T.internal_screen(screens, cfg)
    local internal = T.classify(screens, cfg)
    return internal[1]
end

-- Actions ------------------------------------------------------------------
-- The only place in the module with side effects. Both calls verified
-- live: mirrorStop() decouples the pair, mirrorOf() sets it back up.

function T.set_extend(screens, cfg)
    local external = T.external_screen(screens, cfg)
    if not external then return false, "нет внешнего экрана" end
    return external:mirrorStop() == true, nil
end

-- Direction matters: the internal display mirrors the external one, not the
-- other way round. That keeps the external screen as the master mirror and
-- the Mac takes on its resolution — exactly the behavior wanted for
-- "watching a movie" mode.
function T.set_mirror(screens, cfg)
    local internal = T.internal_screen(screens, cfg)
    local external = T.external_screen(screens, cfg)
    if not internal then return false, "внутренний экран недоступен (уже зеркало?)" end
    if not external then return false, "нет внешнего экрана" end
    return internal:mirrorOf(external) == true, nil
end

return T
