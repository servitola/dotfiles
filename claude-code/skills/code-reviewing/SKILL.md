---
name: code-reviewing
description: |
  Code review methodology and quality standards for comprehensive code analysis.
  Use to understand WHAT and HOW to review code: 11 review dimensions, process, quality standards.

  Use when: "проверь код", "code review", "ревью кода", "review this code", "check code quality"
---

# Code Review Methodology

Comprehensive code review methodology for ensuring production-ready quality and maintainable architecture.

## Review Dimensions

Systematic analysis spans 11 dimensions. Per-dimension criteria, good practices, and automatic severity mappings live in [dimensions.md](references/dimensions.md) — load only the sections matching the dimensions prioritized for the code under review.

| # | Dimension | Focus |
|---|-----------|-------|
| 1 | Architectural Patterns | pattern adherence, layer separation, anti-patterns |
| 2 | Separation of Concerns | SRP, module boundaries, nesting depth |
| 3 | Readability & Maintainability | naming, comments, DRY, magic numbers |
| 4 | Error Handling & Logging | try-catch usage, log structure, secrets in logs |
| 5 | Type Safety | `any` usage, generics, null/undefined handling |
| 6 | Testing Coverage | test quality, critical paths, mocking strategy |
| 7 | Dependencies Management | necessity, versions, vulnerabilities, licensing |
| 8 | Security Considerations | injection/XSS, secrets, input validation |
| 9 | Performance Implications | N+1, algorithmic complexity, memory leaks |
| 10 | Cross-File Consistency | call signatures, imports, method existence |
| 11 | Resource Management | singletons, lifecycle, resource leaks |

## Dimension Prioritization

Focus on dimensions based on code context:

| Context | Prioritize | Reason |
|---------|------------|--------|
| Auth/login code | Security (8), Error Handling (4) | Auth vulnerabilities are critical |
| User input handling | Security (8), Type Safety (5) | Input validation prevents attacks |
| Database queries | Security (8), Performance (9) | SQL injection, N+1 queries |
| New feature | Architecture (1), Testing (6) | Foundation for future changes |
| Refactoring | Cross-File (10), Testing (6) | Avoid breaking existing code |
| Performance fix | Performance (9), Dependencies (7) | Target the actual bottleneck |
| Typed codebase | Type Safety (5), Cross-File (10) | Type errors cause runtime crashes |
| ML/AI pipeline | Resource Mgmt (11), Performance (9) | Heavy models duplicated waste memory |
| Microservice init | Resource Mgmt (11), Architecture (1) | Connection pools and clients should be shared |

## Review Process

1. **Initial Scan**: Quick overview to understand scope and context
2. **Deep Analysis**: Apply the per-dimension criteria from [dimensions.md](references/dimensions.md) for each prioritized dimension (checklists, good practices, severity mappings)
3. **Cross-Reference**: Compare implementation against userspec, techspec, and project standards
4. **Issue Categorization**: Classify findings by severity:
   - **critical** → blocking issues that must be fixed
   - **major** → significant concerns that should be addressed
   - **minor** → improvements that are valuable but optional
5. **Recommendation Formulation**: Provide specific, actionable suggestions

## Comment Severity Prefixes

Internal severity (critical/major/minor) drives review verdict. The
**comment to the author** must additionally start with a prefix so the
author knows what's required vs optional. Without prefixes authors
treat every comment as mandatory and waste time on suggestions.

| Prefix | Meaning | Author action |
|---|---|---|
| *(no prefix)* | Required change | Address before merge |
| **Critical:** | Blocks merge | Security, data loss, broken functionality |
| **Nit:** | Minor, optional | May ignore — formatting, style preference |
| **Optional:** / **Consider:** | Suggestion worth thinking about | Not required |
| **FYI:** | Informational only | No action — context for future |

Mapping from internal severity:
- critical → `Critical:` prefix
- major → no prefix (required) or `Critical:` if blocking
- minor → `Nit:` or `Optional:`

## Change Sizing

Small focused changes review faster and ship safer. Target sizes:

| Diff size | Verdict |
|---|---|
| ~100 lines | Good. Reviewable in one sitting. |
| ~300 lines | Acceptable if single logical change. |
| ~1000 lines | Too large. Ask author to split. |

Exception: file deletions and automated refactors where reviewer only
verifies intent, not each line.

**Splitting strategies when a change is too large:**

| Strategy | How | When |
|---|---|---|
| **Stack** | Submit small change, start next based on it | Sequential dependencies |
| **By file group** | Separate changes for groups needing different reviewers | Cross-cutting concerns |
| **Horizontal** | Shared code/stubs first, then consumers | Layered architecture |
| **Vertical** | Smaller full-stack slices of the feature | Feature work |

**Separate refactoring from feature work.** A PR that refactors AND adds
new behavior = two PRs. Small renames may piggyback at reviewer
discretion.

## Dead Code Hygiene

After refactoring or implementation, look for orphaned code: now-unused
functions, components, constants, backwards-compat shims, `_unused`
no-op vars, `// removed` comments.

Process:
1. Identify what is now unreachable or unused.
2. List it explicitly in the review comment.
3. **Ask before deleting.** Don't silently nuke things — you may not see
   external callers.

```
DEAD CODE IDENTIFIED:
- formatLegacyDate() in src/utils/date.ts — replaced by formatDate()
- OldTaskCard in src/components/ — replaced by TaskCard
- LEGACY_API_URL in src/config.ts — no remaining references
→ Safe to remove these?
```

Don't accept "I'll clean it up later." Cleanup before merge or a filed
ticket with assignee — otherwise it never happens.

## Quality Standards

Be thorough but pragmatic:
- Focus on issues that materially impact code quality, security, or maintainability
- Distinguish between critical problems and stylistic preferences
- Provide constructive feedback with specific examples
- Acknowledge good practices when present
- Consider project context and constraints from project documentation (if available)
- Balance idealism with practical delivery needs

## Communication Style

- Be direct and specific - avoid vague feedback
- Use technical precision appropriate for senior developers
- Provide code examples in recommendations when helpful
- Explain the "why" behind each issue, not just the "what"
- Maintain professional, respectful tone
- Prioritize actionability over completeness

Goal: ensure production-ready code that is secure, maintainable, and aligned with project standards. Be thorough in analysis but efficient in communication.
