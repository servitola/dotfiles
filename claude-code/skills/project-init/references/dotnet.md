# .NET / C# scaffold

Reference stack: **`Directory.Build.props` (Nullable enable + wide WarningsAsErrors)
+ `.editorconfig` analyzer severities + xUnit**, using Roslyn CA analyzers +
IDisposableAnalyzers rather than StyleCop. Modelled on `Spotware/cTraderDev`. Git
hooks via the pre-commit framework (same as Python/TS). Resolve the latest SDK /
package versions when installing.

## Contents
- Layout
- Directory.Build.props (solution-wide gate)
- .editorconfig (severity dials)
- Tests: unit vs integration
- Hooks + CI

## Layout

```
src/<Proj>/<Proj>.csproj
tests/<Proj>.UnitTests/
tests/<Proj>.IntegrationTests/
Directory.Build.props
.editorconfig
scripts/check_file_length.py
.pre-commit-config.yaml  .gitleaks.toml
.gitignore  .github/workflows/ci.yml
```

Create with `dotnet new gitignore`, `dotnet new sln`, `dotnet new classlib -o
src/<Proj>`, `dotnet new xunit -o tests/<Proj>.UnitTests`, and add each to the sln.

## Directory.Build.props (applies to every project)

Nullable on, implicit usings off, overflow checks on, and a broad WarningsAsErrors
so nullable + analyzer diagnostics fail the build instead of scrolling past. Start
with the compact set below and widen toward the user's full CA/CS/IDISP list as the
code matures.

```xml
<Project>
  <PropertyGroup>
    <LangVersion>latest</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>false</ImplicitUsings>
    <CheckForOverflowUnderflow>true</CheckForOverflowUnderflow>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <AnalysisLevel>latest-recommended</AnalysisLevel>
    <WarningsAsErrors>
      CS8600;CS8601;CS8602;CS8603;CS8604;CS8618;CS8625;CS8619;CS8620;
      CA2007;CA1816;CA2000;NU1605
    </WarningsAsErrors>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>
</Project>
```

Test projects get their own `tests/Directory.Build.props` that relaxes analyzers not
relevant to tests (the user keeps a separate props under each test dir).

## .editorconfig

Sets formatting and dials specific analyzer rules — silence the noisy-in-a-PoC ones,
keep the load-bearing nullable/dispose rules as errors. Mark generated files.

```ini
root = true
[*.cs]
indent_style = space
indent_size = 4
dotnet_sort_system_directives_first = true
csharp_style_namespace_declarations = file_scoped:warning
dotnet_diagnostic.CA1816.severity = none
dotnet_diagnostic.IDISP001.severity = suggestion
[*.g.cs]
generated_code = true
```

## Tests: unit vs integration

- `tests/<Proj>.UnitTests/` — xUnit, pure. Fast loop + CI.
- `tests/<Proj>.IntegrationTests/` — xUnit with a `[Trait("Category","Integration")]`
  on each class (DB / HTTP / containers). Filter them out of the fast run with
  `dotnet test --filter Category!=Integration`; CI runs them in a separate step.

Add one trivial passing unit test so the scaffold is proven immediately.

## Hooks (.pre-commit-config.yaml)

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks: [{ id: gitleaks }]
  - repo: local
    hooks:
      - id: dotnet-format
        name: dotnet format (verify)
        entry: dotnet format --verify-no-changes
        language: system
        pass_filenames: false
      - id: file-length
        name: code files ≤ 100 lines of logic
        entry: python3 scripts/check_file_length.py
        language: system
        types_or: [c#]
      - id: dotnet-test
        name: dotnet test (unit)
        entry: dotnet test --filter Category!=Integration --nologo
        language: system
        pass_filenames: false
        stages: [pre-push]
```

## CI (.github/workflows/ci.yml)

```yaml
name: ci
on: { push: { branches: ["**"] }, pull_request: {} }
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: "9.0.x" }
      - run: dotnet restore
      - run: dotnet format --verify-no-changes
      - run: dotnet build -warnaserror --no-restore
      - run: dotnet test --filter Category!=Integration --no-build
      - run: dotnet test --filter Category=Integration --no-build
```
