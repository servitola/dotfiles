# Mobile scaffold (Kotlin / Swift)

Reference stack: **Android** ktlint + detekt via Gradle; **iOS** SwiftLint `--strict`
+ SwiftFormat. Git hooks use the **raw `.githooks/` + `core.hooksPath` pattern wired
through a Makefile** (the user's mobile repos avoid the pre-commit framework here).
Modelled on `serho_topics/сфера` and `Fradd`. Resolve latest-stable plugin versions.

## Contents
- Layout
- Android: ktlint + detekt
- iOS: SwiftLint + SwiftFormat
- Git hooks (.githooks + Makefile)
- Tests
- CI

## Layout

```
app-android/ app/build.gradle.kts   config/detekt/detekt.yml
app-ios/     .swiftlint.yml  .swiftformat
.githooks/pre-commit  .githooks/pre-push
scripts/check_file_length.py
Makefile   .gitleaks.toml  .gitignore  .github/workflows/ci.yml
```

## Android: ktlint + detekt

In the app `build.gradle.kts`:

```kotlin
plugins {
    id("org.jlleitschuh.gradle.ktlint") version "12.1.1"
    id("io.gitlab.arturbosch.detekt") version "1.23.7"
}
ktlint { version.set("1.3.1") }
detekt {
    buildUponDefaultConfig = true
    config.setFrom("$rootDir/config/detekt/detekt.yml")
    jvmTarget = "17"
}
```

`config/detekt/detekt.yml` — `buildUponDefaultConfig: true`, `MaxLineLength: 120`,
`ReturnCount: max 4`, and Compose-aware `ignoreAnnotated: ['Composable','Preview']`
(from the user's Fradd config).

## iOS: SwiftLint + SwiftFormat

`.swiftlint.yml`: `strict: true`, `line_length` warn 100 / err 120,
`cyclomatic_complexity` 6/10, `force_unwrapping` opt-in, plus the wide opt-in rule
set the user runs. Note: `file_length` in SwiftLint counts physical lines — leave it
generous and let the shared 100-logic-line gate do the real capping.

`.swiftformat`: `--swiftversion 6.0`, `--maxwidth 100`, `--indent 4`, `--self remove`.

## Git hooks (.githooks + Makefile)

Wire `core.hooksPath` so the checked-in hooks are used, via the Makefile:

```make
install-hooks:
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-commit .githooks/pre-push

verify:  ## heavy gate, mirrors CI
	./gradlew ktlintCheck detektMain testDebugUnitTest
	swiftlint --strict --config app-ios/.swiftlint.yml
	python3 scripts/check_file_length.py --walk app-android/src --walk app-ios/Sources
	gitleaks detect --no-banner --redact
```

`.githooks/pre-commit` — fast, staged-only: the file-length gate on `.kt/.kts/.swift`,
`ktlintFormat` check, and `gitleaks protect --staged --redact`.

```sh
#!/usr/bin/env bash
set -euo pipefail
staged=$(git diff --cached --name-only --diff-filter=ACM -- '*.kt' '*.kts' '*.swift')
[ -n "$staged" ] && python3 scripts/check_file_length.py $staged
gitleaks protect --staged --no-banner --redact
```

`.githooks/pre-push` runs `make verify` (the full gate). Team policy in these repos:
`--no-verify` is forbidden — state that in the repo README.

## Tests

- Android — JVM unit tests (`testDebugUnitTest`) fast; instrumentation / UI tests
  (`connectedAndroidTest`) are the integration tier, CI-only.
- iOS — XCTest unit target fast; UI-test target is the integration tier, CI-only.

## CI (.github/workflows/ci.yml)

```yaml
name: ci
on: { push: { branches: ["**"] }, pull_request: {} }
jobs:
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: "17" }
      - run: ./gradlew ktlintCheck detektMain testDebugUnitTest assembleDebug
      - run: python3 scripts/check_file_length.py --walk app-android/src
  ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: brew install swiftlint swiftformat
      - run: swiftlint --strict --config app-ios/.swiftlint.yml
      - run: xcodebuild test -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'
```
