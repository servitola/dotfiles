# uv — global config for Astral's uv Python package/tool manager

- Its only setting is `exclude-newer = "7 days"`: uv ignores package releases fresher than 7 days, mirroring npm's `min-release-age` — a supply-chain safety pin against just-published malicious versions.
