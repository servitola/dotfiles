# firefox-vimium-addon — exported Vimium settings for the Firefox addon

- `vimium-options.json` is a backup of the Vimium Firefox addon's Options page (keyboard nav for the browser): link-hint characters (`sadfjklewcmpgh`), exclusion rules (Gmail, dwservice), search engines, scroll/smooth-scroll prefs, and hint CSS. `settingsVersion` records the Vimium schema it was exported under.
- Restore by opening Vimium's Options page and pasting this JSON into the backup/restore (raw settings) field; there is no symlink or Makefile install — it is a manual import, nothing reads it automatically.
- Sibling `chromium-vimium-extension/` holds the same-shaped export for the Chromium build; keep the two in sync conceptually but expect minor key/exclusion drift per browser (this Firefox export keeps `keyMappings` at the default placeholder, unlike the Chromium one's custom mappings).
- Edit the JSON only to mirror a change actually made in the addon UI — this file documents desired state, not a live config.
