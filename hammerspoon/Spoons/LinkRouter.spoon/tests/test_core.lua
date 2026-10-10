local core = require "core"

local CHROME, FIREFOX, VIVALDI = "com.google.Chrome", "org.mozilla.firefox", "com.vivaldi.Vivaldi"
local TELEGRAM = "com.tdesktop.Telegram"

local function compiled(rules, extra)
    local settings = { default = "main", browsers = { main = VIVALDI, dev = CHROME, work = FIREFOX }, rules = rules }
    for key, value in pairs(extra or {}) do settings[key] = value end
    return core.compile(settings)
end

local routes = compiled({
    { core.localNetwork, "dev" },
    { { "workname", "workproject" }, "work" },
    { "xd%.adobe%.com", FIREFOX },
    { "^https://meet%.", "work", from = TELEGRAM },
})

local function to(url, sender)
    local _, destination, rule = core.route(routes, url, sender)
    return destination, rule
end

eq(to("http://localhost:3000/x"), CHROME, "local: localhost with a port")
eq(to("http://localhost"), CHROME, "local: bare localhost")
eq(to("http://127.0.0.1:8080"), CHROME, "local: loopback")
eq(to("https://192.168.0.14:3000/"), CHROME, "local: home network")
eq(to("http://10.1.2.3/"), CHROME, "local: 10/8")
eq(to("http://172.20.0.5/"), CHROME, "local: 172.16/12")
eq(to("http://172.32.0.5/"), VIVALDI, "local: 172.32 is public")
eq(to("http://i9.local:2283/"), CHROME, "local: mDNS name")
eq(to("https://localhost.example.com/"), VIVALDI, "local: a public host that starts with localhost")
eq(to("https://example.com/?next=http://localhost"), VIVALDI, "local: localhost inside the query does not count")

eq(to("https://app.workproject.com/"), FIREFOX, "list: any pattern matches")
eq(to("https://jira.workname.com/"), FIREFOX, "list: a pattern is a substring, not a word")
eq(to("https://xd.adobe.com/view/1"), FIREFOX, "bundle id written in place of a name")
eq(to("https://xdXadobe.com/"), VIVALDI, "escaped dot is a dot")

eq(to("https://meet.google.com/abc", TELEGRAM), FIREFOX, "from: applies to links from that app")
eq(to("https://meet.google.com/abc", "com.apple.Safari"), VIVALDI, "from: not from other apps")
eq(to("https://meet.google.com/abc", nil), VIVALDI, "from: not when the sender is unknown")

local destination, rule = to("https://example.com/")
eq(destination, VIVALDI, "default: nothing matched")
eq(rule, nil, "default: no rule number")
destination, rule = to("http://localhost:1/")
eq(rule, 1, "route reports the deciding rule")

local seen = nil
local handler = function(url) seen = url end
local custom = compiled({ { function(url, sender) return sender == TELEGRAM and url:find("t%.me/") ~= nil end, handler } })
local _, run = core.route(custom, "https://t.me/x", TELEGRAM)
eq(run, handler, "function match and function target")
_, run = core.route(custom, "https://t.me/x", nil)
eq(run, VIVALDI, "function match sees the sender")

local wrapped = compiled({ { "github%.com", "dev" } }, { unwrap = { core.slackRedirect } })
local url, target = core.route(wrapped, "https://slack.redir.net/link?url=https%3A%2F%2Fgithub.com%2Fx&v=3")
eq(url, "https://github.com/x", "unwrap: slack redirect decoded")
eq(target, CHROME, "unwrap: rules see the unwrapped url")
url = core.route(wrapped, "https://example.com/")
eq(url, "https://example.com/", "unwrap: nil keeps the url")

local function fails(settings, label)
    eq(pcall(core.compile, settings), false, label)
end
fails({ browsers = {} }, "default is required")
fails({ default = "nowhere" }, "default: unknown name")
fails({ default = VIVALDI, browsers = { x = "not a bundle" } }, "browsers: bundle ids only")
fails({ default = VIVALDI, rules = { { "a", "nowhere" } } }, "rule: unknown browser name")
fails({ default = VIVALDI, rules = { { "a" } } }, "rule: open is required")
fails({ default = VIVALDI, rules = { { nil, VIVALDI } } }, "rule: match is required")
fails({ default = VIVALDI, rules = { { {}, VIVALDI } } }, "rule: empty pattern list")
fails({ default = VIVALDI, rules = { { "[", VIVALDI } } }, "rule: broken Lua pattern")
fails({ default = VIVALDI, rules = { { "a", VIVALDI, form = TELEGRAM } } }, "rule: misspelt field")
fails({ default = VIVALDI, rules = { { "a", VIVALDI, from = "Telegram" } } }, "rule: from takes bundle ids")
fails({ default = VIVALDI, rules = { "a" } }, "rule: must be a table")
fails({ default = VIVALDI, unwrap = { "slack" } }, "unwrap: functions only")
eq(pcall(core.compile, { default = VIVALDI }), true, "no rules: everything goes to the default")
