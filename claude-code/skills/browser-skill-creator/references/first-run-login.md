# First-run setup: profile, MCP config, login, cache scrape

How a generated skill gets its persistent logged-in browser and its initial
cache. Done once per skill; everything after rides the saved session.

## Contents

1. [Profile directory](#profile-directory)
2. [Project-scoped .mcp.json](#project-scoped-mcpjson)
3. [Login handover (2FA / SMS / SSO)](#login-handover-2fa--sms--sso)
4. [Session persistence rules](#session-persistence-rules)
5. [One-time cache scrape](#one-time-cache-scrape)

## Profile directory

One persistent Chromium profile per skill at
`~/.claude-playwright-profiles/<name>` — short noun chosen in the discovery
interview (`food`, `gov`, `doctor`, `bills`). The directory is created
automatically by Playwright on first launch; nothing to pre-seed.

One profile per skill, never shared. Reasons:

- Different cookies and 3DS state must not interleave (a food order should
  not ride a payment portal's bank-recognition cookie).
- A broken/corrupted profile can be deleted and re-logged-in without
  touching other skills' sessions.

## Project-scoped .mcp.json

The Playwright MCP is registered per project directory, not globally. Each
site skill names the directory it works from (a serho topic folder or a
dedicated project dir) and that directory's `.mcp.json` carries the profile:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "-y",
        "@playwright/mcp@latest",
        "--user-data-dir",
        "/Users/servitola/.claude-playwright-profiles/<name>",
        "--viewport-size",
        "1280,900"
      ]
    }
  }
}
```

(Shape taken from the working food project config.) Notes:

- Absolute path in `--user-data-dir` — `~` is not expanded by every runner.
- A fixed `--viewport-size` keeps snapshots and screenshots reproducible
  across runs; 1280×900 is the proven default for desktop sites.
- The generated skill's body states the absolute project directory and
  opens with "cd there so the project-scoped MCP loads".
- Never pass `--isolated` — it wipes the session every run and forces a new
  SMS OTP each time. Write this warning into every generated skill.

## Login handover (2FA / SMS / SSO)

The agent never performs authentication. The pattern every generated skill
copies verbatim:

1. Open the site. If it lands on a login screen (or the logged-in indicator
   — avatar, address chip, account menu — is missing), tell the user:
   «Залогинься в окне браузера (<SMS-код / Ariadni / email+пароль — что
   попросит сайт>), потом скажи 'продолжай'.»
2. Wait. Do not type passwords, SMS codes, or eID approvals — the agent
   cannot read the user's phone, and wrong attempts can rate-limit or lock
   the account (government SSO portals are aggressive about this).
3. After the user confirms, re-snapshot and verify the logged-in indicator
   before proceeding.

SSO nuances to capture during recon and write into the generated skill:

- Which login the site actually uses (own account vs national SSO vs
  Google) and whether one SSO session unlocks several portals.
- Session lifetime if observable (e.g. ~30 days), so the skill can warn the
  user that a re-login will be needed rather than treating it as breakage.
- First-login housekeeping: pin the interface language to English where the
  site allows, accept the cookie banner once — both live in the profile
  afterwards and keep future snapshots consistent.

3DS / bank OTP on payment screens needs no special handling: by the time it
appears, the skill has already stopped at the final button and the user is
driving.

## Session persistence rules

- The profile keeps cookies, local storage, saved-card recognition, and
  language choice. Treat it as the credential store — and the only one.
- If the session is unexpectedly gone every run, check for `--isolated` in
  the MCP args and for the project dir being wrong (a different `.mcp.json`
  with a different profile would silently open a clean browser).
- A profile that misbehaves (corrupt cache, stuck service worker) can be
  deleted wholesale; cost is one re-login.

## One-time cache scrape

If the site holds history worth reusing (past orders, saved billers,
referrals), the generated skill scrapes it once, right after first login:

1. Open the site's history/account page ("My orders", "Pending payments",
   "My referrals").
2. Read the last ~30 entries / ~6 months. Extract the fields the skill's
   cache schema needs, including sanity anchors (last amount, frequency).
3. Read back anything sensitive (account numbers, references) in chat and
   save only after the user's explicit "yes, save".
4. Write the cache JSON with a `scraped_at` date (location per the
   template's cache-file pattern).
5. From then on, user requests short-circuit against the cache before any
   site search.
