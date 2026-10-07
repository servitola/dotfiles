**English** · [Русский](CHANGELOG.ru.md)

# Changelog

Versions follow Birman's: `3.9.N` is his Mac layout 3.9, read as he published it; `N` counts our own
releases on top of it. When he publishes 4.0, the next release here is `4.0.0`.

- **3.9.1** — `excludedLayouts`: input sources in which the layer stays out and ⌥ types the layout's own
  characters (for example Apple's Greek tonos letters).
- **3.9.0** — first release. Ilya Birman's layout exactly as his official 3.9 build defines it (English and
  Russian), on the right ⌥ or on both ⌥ keys (`rightOptionOnly`). It works on any layout: the ⌥ layers are
  positional and dead keys compose by the character typed. Your own changes go in `overrides`;
  `baseFixups` is an opt-in for ISO keyboards. Verified against every press his layouts define.
