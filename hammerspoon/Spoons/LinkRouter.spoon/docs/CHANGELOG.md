# Changelog

## 0.1.0

First release. Rules `{ match, open, from }` checked top to bottom: a Lua pattern, a list of them or a function; a browser name, a bundle id or a function; optionally only for links from given apps. `localNetwork` and `slackRedirect` ready to use, `unwrap` for redirect wrappers, `route()` to check a rule without opening anything. Links open with `open -b`; settings are checked on `start()`.
