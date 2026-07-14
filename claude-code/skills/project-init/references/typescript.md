# TypeScript / JS scaffold

Reference stack: **flat `eslint.config.ts` (airbnb + typescript-eslint + @stylistic)
+ Jest (jsdom) + Playwright + granular-strict tsconfig**, git hooks via the
**pre-commit framework** (the user's TS repos deliberately avoid husky/lint-staged,
prettier and biome). Modelled on `Spotware/ctradermobileweb`. Resolve latest-stable
versions when installing — the user runs bleeding edge.

## Contents
- Layout
- package.json (scripts + latest deps)
- eslint.config.ts (flat)
- tsconfig.json (granular strict)
- Tests: unit vs e2e
- Hooks (.pre-commit-config.yaml)
- CI

## Layout

```
src/
tests/unit/            # Jest
tests/e2e/             # Playwright
scripts/check_file_length.py
package.json  tsconfig.json  eslint.config.ts
jest.config.js  playwright.config.ts
.pre-commit-config.yaml  .gitleaks.toml
.gitignore  .env.example  .github/workflows/ci.yml
```

## package.json

Install latest with `npm i -D eslint typescript typescript-eslint @stylistic/eslint-plugin
eslint-config-airbnb @eslint/compat @eslint/eslintrc jest ts-jest @types/jest jsdom
@playwright/test`. Scripts:

```json
{
  "type": "module",
  "scripts": {
    "lint": "eslint . --max-warnings 0",
    "typecheck": "tsc --noEmit",
    "test": "jest",
    "test:e2e": "playwright test",
    "check": "npm run lint && npm run typecheck && npm test"
  }
}
```

## eslint.config.ts (flat)

Airbnb is legacy-config, so bridge it through `FlatCompat`, then layer
typescript-eslint + stylistic and a small house-rules block.

```ts
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import stylistic from '@stylistic/eslint-plugin';
import { FlatCompat } from '@eslint/eslintrc';
import { fixupConfigRules } from '@eslint/compat';

const compat = new FlatCompat({ recommendedConfig: js.configs.recommended, allConfig: js.configs.all });

export default tseslint.config(
  ...fixupConfigRules(compat.extends('airbnb')),
  ...tseslint.configs.recommended,
  ...tseslint.configs.stylistic,
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: { parserOptions: { project: './tsconfig.json' } },
    plugins: { '@stylistic': stylistic },
    rules: {
      'no-console': 'error',
      eqeqeq: 'error',
      curly: ['error', 'all'],
      '@stylistic/max-len': ['error', { code: 140 }],
    },
  },
  { ignores: ['dist', 'coverage', '**/*.svg'] },
);
```

The 100-line-of-logic cap is enforced by the shared Python hook, not by eslint
`max-lines` (which counts physical lines and is off in the user's repos).

## tsconfig.json — granular strict

The user's convention: `strict: false` but the individual strict flags on. Reason:
keeps `noImplicitAny` relaxed for fast PoC iteration while still catching real bugs.

```json
{
  "compilerOptions": {
    "target": "ES2023", "module": "ESNext", "moduleResolution": "bundler",
    "jsx": "preserve", "strict": false,
    "strictFunctionTypes": true, "strictBindCallApply": true, "noImplicitThis": true,
    "noUnusedLocals": true, "noUnusedParameters": true, "noImplicitReturns": true,
    "noUncheckedIndexedAccess": true, "forceConsistentCasingInFileNames": true,
    "esModuleInterop": true, "skipLibCheck": true
  }
}
```

For a stricter product (not a throwaway PoC) flip `strict: true` and drop the
redundant individual flags.

## Tests: unit vs e2e

- `tests/unit/` — Jest + Testing Library, jsdom env, `*.test.ts(x)`. Fast loop + CI.
- `tests/e2e/` — Playwright (`*.spec.ts`), real browser. Separate CI job; not on the
  commit loop. Add a Storybook test-runner target later if the repo grows UI.

## .pre-commit-config.yaml

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks: [{ id: gitleaks }]
  - repo: local
    hooks:
      - id: eslint
        name: eslint
        entry: npx eslint --max-warnings 0
        language: system
        types_or: [ts, tsx, javascript, jsx]
      - id: file-length
        name: code files ≤ 100 lines of logic
        entry: python3 scripts/check_file_length.py
        language: system
        types_or: [ts, tsx, javascript, jsx]
      - id: typecheck
        name: tsc --noEmit
        entry: npx tsc --noEmit
        language: system
        pass_filenames: false
        stages: [pre-push]
      - id: jest
        name: jest (unit)
        entry: npx jest --passWithNoTests
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
      - uses: actions/setup-node@v4
        with: { node-version: "22", cache: "npm" }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test -- --coverage
      - run: npx playwright install --with-deps && npm run test:e2e
```
