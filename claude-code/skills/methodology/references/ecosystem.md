# Skills, Agents, and Commands Catalog

## Skills Ecosystem

<!-- Exclude from methodology catalogs: items for private repo management (public-repo skill, public-repo-scanner agent, sync-public command). They are tooling for maintaining this repository, not part of the development methodology. -->

### Planning Skills
| Skill | Purpose |
|-------|---------|
| `project-planning` | New project: interview → project knowledge docs (project.md, architecture.md, etc.) |
| `user-spec-planning` | Feature requirements: interview → user-spec.md |
| `tech-spec-planning` | Architecture: research → tech-spec.md |
| `task-decomposition` | Decompose tech-spec into atomic task files |

### Execution Skills
| Skill | Purpose |
|-------|---------|
| `code-writing` | TDD cycle: plan → tests → code → review |
| `prompt-master` | LLM prompt engineering: write, improve, verify prompts |
| `feature-execution` | Team lead dispatches agents by wave; teammates commit own code, lead commits statuses |
| `pre-deploy-qa` | Pre-deploy acceptance testing: tests + acceptance criteria |
| `post-deploy-qa` | Post-deploy verification on live environment via MCP tools |

### Quality & Review Skills
| Skill | Purpose |
|-------|---------|
| `code-reviewing` | 11-dimension code review methodology (incl. Resource Management) |
| `security-auditor` | OWASP Top 10 security analysis |
| `test-master` | Testing strategy: when to use which tests |

### Meta Skills
| Skill | Purpose |
|-------|---------|
| `methodology` | This skill — how the process works |
| `documentation-writing` | Manage Project Knowledge files |
| `skill-master` | Create and maintain quality skills |
| `infrastructure-setup` | Framework init, Docker, pre-commit hooks, testing setup |
| `deploy-pipeline` | CI/CD pipelines, deployment config, automated deploy |
| `prompt-master` | Effective prompts for LLMs (also an execution skill) |
| `skill-testing` | Design and run skill tests: quick smoke or full A/B with baseline |

## Agents

Agents are isolated subprocesses with fresh context. They receive input, do one job, return structured output.

### Validators (run during spec/task creation)
- `userspec-quality-validator` — document quality and completeness
- `userspec-adequacy-validator` — solution feasibility
- `interview-completeness-checker` — interview coverage gaps
- `tech-spec-validator` — template compliance
- `skeptic` — detects mirages (non-existent files/functions/APIs)
- `completeness-validator` — bidirectional requirements traceability, over/underengineering, solution depth
- `task-validator` — task template compliance
- `task-creator` — generates task files from tech-spec
- `reality-checker` — validates tasks against codebase

### Reviewers (run during/after code writing)
- `code-reviewer` — code quality across 10 dimensions
- `test-reviewer` — test quality analysis with concrete fixes
- `security-auditor` — OWASP Top 10, auth, input validation
- `prompt-reviewer` — prompt quality against prompt-master principles
- `documentation-reviewer` — project-knowledge quality against documentation-writing principles
- `deploy-reviewer` — CI/CD pipeline and deployment configuration quality
- `infrastructure-reviewer` — folder structure, Docker, pre-commit hooks, .gitignore

### Research
- `code-researcher` — codebase research for features (files, patterns, tests, integrations, risks)

### QA
- `pre-deploy-qa` — pre-deploy acceptance testing (tests + acceptance criteria)
- `post-deploy-qa` — post-deploy verification on live environment (MCP tools, AVP)

### Meta
- `skill-checker` — validates skills against skill-master standards

## Commands Reference

| Command | Purpose |
|---------|---------|
| `/new-user-spec` | Interview → user-spec.md |
| `/new-tech-spec` | Research → tech-spec.md |
| `/decompose-tech-spec` | Tech-spec → task files |
| `/do-task` | Execute single task with quality gates |
| `/do-feature` | Execute all tasks via agent teams |
| `/done` | Update PK, archive feature |
| `/write-code` | Ad-hoc coding with TDD and reviews |
| `/init-project` | Initialize new project with template, git, GitHub |
| `/init-project-knowledge` | Fill all project documentation via project-planning skill |
