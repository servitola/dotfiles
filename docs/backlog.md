# Backlog

Идеи и планы по развитию dotfiles. Не таск-трекер — сюда попадает то, что не делается прямо сейчас.

## Мечты

### Единое сгенерированное keyboard-приложение (вместо Karabiner + Hammerspoon + системных раскладок)

Один компилированный Swift-бинарник, сгенерированный из существующих конфигов
(`karabiner/hand/*.json`, `karabiner/layers.toml`, `HotKeys.spoon/layout/60%/*.lua`, BirmanLayer.spoon's
`typography_table.lua`, `docs/keyboard-setup.md`), который закрывает всё: Hyper, слои, лаунчеры, окна,
per-app логику и — главное — **фиктивные раскладки**: системная раскладка навсегда U.S.,
а ru/el/типографский слой Бирмана печатаются напрямую через
`CGEventKeyboardSetUnicodeString`. Переключение «раскладки» = смена таблицы в памяти:
мгновенно при любой нагрузке, приложения всегда видят английскую раскладку,
punto switcher вырождается во флип внутреннего режима.

Архитектура-кандидат: переиспользовать открытый Karabiner-DriverKit-VirtualHIDDevice
(как это делает kanata) для модификаторов/Hyper + event tap для фиктивных раскладок.
Конфиги остаются source of truth, бинарник — build-артефакт (как `karabiner.json` сегодня).

Известные риски: secure input (в полях паролей event tap отключается — фиктивная
раскладка падает в настоящий US), армия краёв (key repeat, dead keys, диктовка,
emoji-пикер, игры с raw input — нужен аналог профиля «Empty»), и главное —
самостоятельный мейнтенанс поломок каждого мажорного macOS, которые сейчас чинит
комьюнити Karabiner.

Прототип для де-риска: ~200–300 строк Swift — event tap, фиктивные Ru/El поверх US,
за тумблером. Две недели пожить (пароли, Rider, терминал, игры) — потом решать.

Пруф существования по частям: kanata/kmonad (движки поверх драйвера Karabiner,
у kanata есть unicode-вывод), Squirrel/Rime (надёжность IME-пути). Целиком —
«персональное приложение из своих конфигов» — никто не делает.

## Keyboard core → keylord (staged extraction, parked)

Target design: `~/projects/keylord/docs/superpowers/specs/2026-09-25-keylord-design.md` (parked 2026-09-27).
Shipped: step 1 HotKeys action registry (2026-09-25); step 2 roles in `constants.env`; steps 3–4 the
`[slots]` table in `karabiner/layers.toml` and Hyper layers `07`–`17` generated from it (there is no
`bridge.lock` file: the slots live in the same TOML); step 5a machine shortcuts (`macos_shortcuts/`).
Rolled back the same day they shipped (2026-09-26): 5b app-shortcut catalog and 6 `chords.toml` — see the
note at the end of this section. What a next consolidation step would add is one read-only resolver across
the four sources (`layers.toml`, layout `.lua`, `hand/*.json`, `shortcuts.toml`): "what is on chord X".

Deferred from the step-1 final review (none blocking):
- `focusAppWindow` in `actions/apps.lua`: both callers pass bundle ids now; drop the
  name path and the `hs.window` unwrap, use `hs.application.get` only.
- `test_bind.lua` has no fixture for the `app` branch.
- Lint A1 regexes: double quotes only, `list_re` hardcodes `register(name`. Both fail
  loud, never silently pass.
- Eight registered actions have no chord (`press_return`,
  `set_secondary_layout`, `set_primary_layout`, `show_youtrack`,
  `show_youtrack_tasks`, `translate_to_greek`, `audio.marshall`, `app_usage_stats`).
  An INFO rule A2 would surface them.
- `HotKeys.spoon/init.lua` requires the config-root `notify`; inject a reporter before
  extraction.
- `appSpecificHotkeys` table still lives inside `HotKeys.spoon/init.lua` as data.

Deferred from the step-3 (slots) review, none blocking:
- The bridge-key set is defined three times (`lint.py` `BRIDGE_CHORD`,
  `bridges._BRIDGE_KEY_CODE`, `bridges.BRIDGE_BASES`); B2 should build on `bridges`.
- `tools/bridge.py --json` drops `side` and `rule`.

Deferred from the step-4 (Hyper-layer generation) review, none blocking:
- `lint.py` `check_layer_raw` crashes on a malformed `hand/raw/*.json` instead of a finding.
- `lint.py` `check_layer_table` calls `key_code_of` without the guards `bridge_rows` has
  (two-key lock row or the `~` key would crash lint).
- `bridges.render_output` rebuilds its reverse dict per call; `_output_tokens.cache` is a
  hand-rolled `functools.cache`.
- B4 findings always anchor at line 1 of the raw file (index is given).

Deferred from step 5a (machine shortcuts), decisions or polish:
- Maccy preview toggle `⌃␣` sits on enabled system hotkey 60 (input-source switch; lint no longer
  reports it, the row is still `enabled = true`); Hammerspoon does the layout switching, so
  `id = 60 enabled = false` in `macos_shortcuts/shortcuts.toml` is the likely answer. Owner's call.
- Music menu duplicates (`⌥⌘a` All/Repeat All, `⌥⌘o` One/Repeat One) reported by S3.
- Menu-combo encodings for arrows/F-keys/PgUp/PgDn are unverified (no live example).
- `up` runs `shortcuts.py capture --write` and `install/check.sh` runs `check`; nothing runs `check`
  on a schedule, so a drift is noticed only when someone runs `check.sh`.
- 10 symbolic-hotkey ids captured as `name = "unknown"`: 16 18 20 22 24 175 179 233 235 260.

Steps 5b and 6 rolled back 2026-09-26, the same day they shipped: too much machinery
for one user. `keyboard/` (catalog, `chords.toml`, `keys.toml`, `build.sh`), `gen_layout.py`,
`catalog_import.py`, `explain.py` and their tests are gone; `lint.py`, `normalize.py` and the
`lint-keyboard-layout` hook are back at their step-5a state. Kept: the regenerated layout files,
the SVGs and the Greek-column fix in `parse_birman.py`. The per-app knowledge the catalog
collected lives only in the Lua comment tables again.

- boring-notch-sync (2026-09-26 12:38 run): the old `boringNotch` process (pid started
  11:29, bundle already deleted by the job) survived `stop_app` and ran next to the new
  `Boring Notch` until 12:59 (killed by hand: ignored SIGTERM, needed SIGKILL). Two
  instances with active event taps made every trackpad click stall (WindowServer
  "imbalanced gesture state" from 12:40). The cask-upgrade step also logged "Application
  did not quit … Enable Automation access" and "App source /Applications/boringNotch.app
  is not there". Harden `stop_app`: kill by executable path (`pkill -9 -f
  "/Applications/boringNotch.app/"` and `"$APPDEST/Contents/MacOS/"`) and, after `open`,
  fail if any process of the bundle id runs from a path outside `$APPDEST`. Not changed
  here — another session owns that script today.

Deferred from the hotkey-adapters pass (2026-09-26), all need a live run:
- First real `shortcuts.py apply` for Services (`pbs -update` without logout?) and for
  Itsycal (picks up a script-written hotkey after relaunch?).
- Ice: set one hotkey in its Settings, verify decoding, then allow `apply`.
- `keycodes.ns_to_chord`: a masshortcut dict with `keyCode == 65535` decodes to `""`,
  not `"none"`; unreachable today, guard if another masshortcut app is added.
- Boring Notch registers three identical active event taps (`shortcuts.py taps`).
- `services` adapter: capture `enabled_services_menu`/`enabled_context_menu` as
  `enabled = false` and make S2/S3 ignore disabled services (all five on this Mac are off).
- `capture` keeps rows for uninstalled apps whose prefs domain survived (Ice, ChatGPT,
  Lunar, VMware Fusion); either delete the leftover domains or mark rows `installed = false`.
