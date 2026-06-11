# Publishing — deploy, preview, failures

## Publish

Triggers: "publish", "update site", "can I see it", "show".

One shell call:
```
bash ~/projects/dotfiles/claude-code/skills/create-regular-website/scripts/deploy.sh "$PWD"
```

The script builds the site and pushes it to Surge.sh, prints the URL.

After a successful deploy:
1. Send the URL via `mcp__bot__send_message` if Telegram MCP is wired.
2. Reply in the user's language: "Done, site updated: <URL>. Should be
   live in a few seconds."

If a Playwright MCP is available, take a screenshot of the home page
and send via `mcp__bot__send_image` with a short caption.

**Preview**: if the user says "let me check first" or you want to show
a big change before going live:
```
bash ~/projects/dotfiles/claude-code/skills/create-regular-website/scripts/deploy.sh "$PWD" --preview
```
Deploys to `<slug>-preview.surge.sh` — separate URL, production untouched.

## When something breaks

Read the error, do not show stack traces to the user. Common cases:

- `SURGE_LOGIN / SURGE_TOKEN must be set` — credentials missing; escalate
  to the operator.
- `npm ERR! ...` — engine deps broken; run `update-engine.sh` (see
  [site-management.md](site-management.md)).
- `domain is already in use` / `not authorized to deploy to <slug>.surge.sh`
  — someone else already owns that subdomain on Surge. Ask the user to
  rename the site topic to something more unique, then redeploy.
- Cyrillic in topic name → transliterated to slug, expected.

If you cannot fix it in 1–2 attempts, say in the user's language:
"Something is off with my tools — please ping the operator, they will
fix it quickly."

## Surge gotchas

- Two rapid deploys of the same site: Surge handles it but the last one
  wins. Don't trigger back-to-back deploys for the same site.
- Surge subdomains are a global namespace — `<slug>.surge.sh` must not
  be taken by anyone else. If deploy errors with "already in use" /
  "not authorized", ask the user to rename the site topic to something
  more distinctive, then redeploy.
- Surge reserves slugs starting with `surge-` (e.g. `surge-test`,
  `surge-blog`). Attempting to deploy such a slug makes surge crash
  with `Cannot read properties of undefined (reading 'filename')` —
  this is a client bug masking a server-side rejection. If you see
  this error, ask the user to rename the topic to not start with
  "surge-", then redeploy.
