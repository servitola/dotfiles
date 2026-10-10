-- Run: hs -c 'return dofile(os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/Displays.spoon/tests/test_topology.lua")'
local root = os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/Displays.spoon/"
local cfg = dofile(root .. "config.lua")
local T = dofile(root .. "topology.lua")

local failures, checks = {}, 0
local function eq(got, want, label)
    checks = checks + 1
    if got ~= want then
        table.insert(failures, string.format("%s: got %s, want %s", label, tostring(got), tostring(want)))
    end
end

-- Stub screen: only what topology needs.
local function screen(name, uuid)
    local s = { calls = {} }
    function s:name() return name end
    function s:getUUID() return uuid end
    function s:mirrorStop() table.insert(self.calls, "mirrorStop"); return true end
    function s:mirrorOf(other) table.insert(self.calls, "mirrorOf:" .. other:name()); return true end
    return s
end

local tv       = screen("LG TV", "uuid-tv")
local monitor  = screen("DELL U2720Q", "uuid-dell")
local retina   = screen("Built-in Retina Display", "uuid-int")
local xdr      = screen("Built-in Liquid Retina XDR Display", "uuid-xdr")
local colorlcd = screen("Color LCD", "uuid-lcd")
local imac     = screen("iMac", "uuid-imac")

-- is_internal: every known Apple built-in display name is recognized.
eq(T.is_internal(retina, cfg),   true,  "Built-in Retina внутренний")
eq(T.is_internal(xdr, cfg),      true,  "Built-in XDR внутренний")
eq(T.is_internal(colorlcd, cfg), true,  "Color LCD внутренний")
eq(T.is_internal(imac, cfg),     true,  "iMac внутренний")
eq(T.is_internal(tv, cfg),       false, "LG TV внешний")
eq(T.is_internal(monitor, cfg),  false, "монитор внешний")

-- classify returns two lists.
local int, ext = T.classify({ retina, tv }, cfg)
eq(#int, 1, "classify: один внутренний")
eq(#ext, 1, "classify: один внешний")
eq(int[1]:name(), "Built-in Retina Display", "classify: внутренний тот самый")
eq(ext[1]:name(), "LG TV", "classify: внешний тот самый")

-- state: laptop.
eq(T.state({ retina, tv }, cfg, true), "extend", "ноут+TV = extend")
eq(T.state({ tv }, cfg, true),         "mirror", "один внешний на ноуте = зеркало")
eq(T.state({ retina }, cfg, true),     "no_tv",  "только встроенный = no_tv")

-- state: desktop with no built-in display. One external screen here is NOT a mirror.
eq(T.state({ monitor }, cfg, false),          "no_tv", "десктоп, 1 монитор = no_tv")
eq(T.state({ monitor, tv }, cfg, false),      "no_tv", "десктоп, 2 монитора = no_tv")

-- external_screen: without an override, the first external screen is taken.
eq(T.external_screen({ retina, tv }, cfg):name(), "LG TV", "external по умолчанию")
eq(T.external_screen({ retina }, cfg), nil, "external нет, когда внешних нет")

-- external_screen: a UUID override wins regardless of order.
local cfg2 = {}
for k, v in pairs(cfg) do cfg2[k] = v end
cfg2.PREFERRED_EXTERNAL_UUIDS = { "uuid-tv" }
eq(T.external_screen({ retina, monitor, tv }, cfg2):name(), "LG TV", "оверрайд по UUID")

-- internal_screen.
eq(T.internal_screen({ retina, tv }, cfg):name(), "Built-in Retina Display", "internal найден")
eq(T.internal_screen({ tv }, cfg), nil, "internal нет в зеркале")

-- Topology actions. The stub screens record calls, so both the fact of
-- the call and the mirroring direction get checked.
local a_tv, a_int = screen("LG TV", "uuid-tv"), screen("Built-in Retina Display", "uuid-int")
local ok = T.set_extend({ a_int, a_tv }, cfg)
eq(ok, true, "set_extend успешен")
eq(#a_tv.calls, 1, "set_extend дёрнул ровно один вызов")
eq(a_tv.calls[1], "mirrorStop", "set_extend зовёт mirrorStop на внешнем")
eq(#a_int.calls, 0, "set_extend не трогает внутренний")

local b_tv, b_int = screen("LG TV", "uuid-tv"), screen("Built-in Retina Display", "uuid-int")
local ok2 = T.set_mirror({ b_int, b_tv }, cfg)
eq(ok2, true, "set_mirror успешен")
eq(b_int.calls[1], "mirrorOf:LG TV", "зеркалит внутренний НА внешний, не наоборот")
eq(#b_tv.calls, 0, "set_mirror не трогает внешний")

-- Degenerate cases return false instead of crashing.
local no_ext_ok, no_ext_err = T.set_extend({ screen("Color LCD", "u") }, cfg)
eq(no_ext_ok, false, "set_extend без внешнего = false")
eq(type(no_ext_err), "string", "set_extend без внешнего объясняет причину")

-- Key asymmetry: in mirror mode there IS NO internal screen — nothing to mirror.
local mirror_ok, mirror_err = T.set_mirror({ screen("LG TV", "uuid-tv") }, cfg)
eq(mirror_ok, false, "set_mirror из зеркала = false")
eq(type(mirror_err), "string", "set_mirror из зеркала объясняет причину")

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
