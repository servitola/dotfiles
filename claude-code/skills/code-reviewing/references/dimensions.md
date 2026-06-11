# Review Dimensions — Detailed Criteria

Detailed criteria, good practices, and automatic severity mappings for each of the 11 review dimensions. Load only the sections for the dimensions prioritized for the code under review (see Dimension Prioritization in SKILL.md).

## Table of Contents

1. [Architectural Patterns](#1-architectural-patterns)
2. [Separation of Concerns](#2-separation-of-concerns)
3. [Code Readability & Maintainability](#3-code-readability--maintainability)
4. [Error Handling & Logging](#4-error-handling--logging)
5. [Type Safety](#5-type-safety-typescripttyped-languages)
6. [Testing Coverage](#6-testing-coverage)
7. [Dependencies Management](#7-dependencies-management)
8. [Security Considerations](#8-security-considerations)
9. [Performance Implications](#9-performance-implications)
10. [Cross-File Consistency](#10-cross-file-consistency)
11. [Resource Management](#11-resource-management)

### 1. Architectural Patterns

- Evaluate adherence to established architectural patterns (MVC, MVVM, Clean Architecture, etc.)
- Assess design patterns usage (Factory, Strategy, Observer, etc.)
- Verify layer separation and dependency direction
- Check for architectural anti-patterns (circular dependencies, god objects, tight coupling)

### 2. Separation of Concerns

- Validate single responsibility principle compliance
- Examine module boundaries and cohesion
- Review business logic vs presentation logic separation
- Assess data layer abstraction and persistence logic isolation

**Good practices:**
- One file = one responsibility (UserService in one file, PaymentService in another)
- Functions < 50 lines; if larger, break into smaller functions
- Maximum 3 levels of nesting; use early returns to reduce nesting
- High-level modules should not depend on low-level details

### 3. Code Readability & Maintainability

- Evaluate naming conventions (variables, functions, classes)
- Assess code organization and file structure
- Check for appropriate use of comments and documentation
- Review complexity metrics (cyclomatic complexity, nesting depth)
- Verify consistent code style and formatting

**Good practices:**
- Meaningful comments focus on "why" rather than obvious "what"
- DRY principle: extract repeated code into functions/modules
- Readable > clever: clear code is better than short but cryptic code
- No magic numbers: extract to named constants (`MAX_UPLOAD_SIZE` not `5242880`)

### 4. Error Handling & Logging

- Examine error propagation strategy
- Verify appropriate use of try-catch blocks
- Check error messages clarity and actionability
- Assess graceful degradation and fallback mechanisms

**Good practices (error handling):**
- Always use try-catch for operations that can fail (API calls, DB operations, file I/O)
- Don't swallow errors: always re-throw after logging (unless explicitly handling)
- Fail fast: validate inputs early; throw errors immediately when invalid
- User-friendly errors: show generic message to users, log details internally

**Logging review checklist:**
- Key operations have logs (external calls, auth events, state transitions, business operations)
- Structured format used (JSON / logger library), not string concatenation or `console.log`
- Every log includes context: userId, action, resourceId (not just a bare message)
- Correlation/request ID propagated through call chain
- Log levels used correctly (info for success, warn for recoverable, error for failures)
- Error logs include stack traces
- No secrets or PII in logs (passwords, tokens, API keys, emails, phone numbers)
- No empty catch blocks (`catch (e) {}` — silent error swallowing)
- No logging inside tight loops (generates thousands of duplicate lines)

**Automatic severity mappings:**

| Pattern | Severity |
|---------|----------|
| Secrets or PII logged (tokens, passwords, emails in plaintext) | critical |
| Empty catch block — error swallowed without logging | major |
| External call (API, DB) without any logging | major |
| Missing correlation/request ID in service handling requests | minor |
| `console.log` / `print` used instead of structured logger | minor |

### 5. Type Safety (TypeScript/typed languages)

For TypeScript or other typed codebases:

- Validate type definitions completeness and accuracy
- Check for inappropriate use of `any` type (TypeScript) or equivalent loose typing
- Assess interface and type alias design
- Review generic type usage and constraints
- Verify null/undefined handling and optional chaining
- Check for type assertions and their justification

### 6. Testing Coverage

- Evaluate unit test presence and quality
- Assess test coverage for critical paths
- Review test organization and naming
- Check for integration and E2E test needs
- Verify mocking strategies and test isolation
- Assess edge case and error scenario coverage

**Good practices:**
- Tests needed for: business logic, validations, transforms, error handling
- Tests not needed for: simple getters/setters, one-line configs, trivial updates
- Rule: if mocking >3 dependencies → wrong test type, use integration test

### 7. Dependencies Management

- Review new dependencies necessity and appropriateness
- Check for dependency version conflicts
- Assess bundle size impact
- Verify security vulnerabilities (outdated packages)
- Evaluate licensing compatibility

**Good practices:**
- Verify imports exist before using: read source files to confirm exports match expected usage
- Check function signatures: ensure signatures match how you're calling them
- Prefer well-maintained packages: check npm/PyPI activity, security advisories
- Pin major versions: use `^` (caret) for npm to allow patch updates

### 8. Security Considerations

- Check for security vulnerabilities (injection, XSS, CSRF)
- Verify secrets management (no hardcoded credentials)
- Assess input validation and sanitization
- Review authentication and authorization logic
- Check for sensitive data exposure

**Good practices:**
- Never hardcode secrets: use environment variables (`.env`) for all sensitive data
- Always validate input: check types, formats, ranges before processing
- Sanitize user data: before database operations, API calls, or displaying
- Add to .gitignore: `.env`, `*.key`, `credentials.json`, `secrets/`

### 9. Performance Implications

- Identify potential performance bottlenecks
- Review algorithmic complexity
- Check for unnecessary re-renders (React) or recomputations
- Assess memory leak risks
- Evaluate database query efficiency

**Good practices:**
- Avoid N+1 queries: use batch operations, eager loading, or caching
- Cache expensive computations: use memoization for functions
- Prevent memory leaks: clean up event listeners, timers, subscriptions in cleanup functions
- Use pagination for large datasets: don't load all records at once
- Profile before optimizing: measure actual bottlenecks before making changes

### 10. Cross-File Consistency

For the code under review, verify correctness of function/class usage:

**Process:**
1. When code CALLS a function from another file → Read that file, verify signature matches
2. When code USES a class/method → Read class definition, verify method exists and signature matches
3. When code IMPORTS something → Verify import path is correct

**What to check:**
- Function called with correct arguments
- Method exists on the class
- Import paths are valid
- Types match (if TypeScript)

**Report as issue if:**
- Function called with wrong arguments (runtime crash)
- Method doesn't exist (runtime crash)
- Import path broken (load failure)

Read the source files where functions/classes are defined to verify signatures match.

### 11. Resource Management

- Identify heavy resources: ML models, database connection pools, browser instances, API clients, large caches
- Check if heavy resources are created as singletons (one instance shared) or duplicated across files/components
- When code creates a heavy resource (`new Model()`, `ModelClass(...)`, `create_pool()`): search the project for other instantiations of the same class
- Verify resource lifecycle: who creates, who consumes, when disposed
- Check for resource leaks: opened connections/files/handles that are never closed

**Automatic severity mappings:**

| Pattern | Severity |
|---------|----------|
| Same heavy resource class instantiated in multiple files without shared instance | major |
| Heavy resource created inside a loop or per-request handler | critical |
| Resource opened but never closed (connection, file handle, cursor) | major |
