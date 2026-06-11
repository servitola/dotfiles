# Project Setup (Phase 0)

Establish the workspace, understand existing work, identify the contribution. Complete this phase before designing experiments or writing.

---

## Contents

- [Step 0.1: Explore the Repository](#step-01-explore-the-repository)
- [Step 0.2: Organize the Workspace](#step-02-organize-the-workspace)
- [Step 0.3: Set Up Version Control](#step-03-set-up-version-control)
- [Step 0.4: Identify the Contribution](#step-04-identify-the-contribution)
- [Step 0.5: Create a TODO List](#step-05-create-a-todo-list)
- [Step 0.6: Estimate Compute Budget](#step-06-estimate-compute-budget)
- [Step 0.7: Multi-Author Coordination](#step-07-multi-author-coordination)

---

## Step 0.1: Explore the Repository

```bash
# Understand project structure
ls -la
find . -name "*.py" | head -30
find . -name "*.md" -o -name "*.txt" | xargs grep -l -i "result\|conclusion\|finding"
```

Look for:
- `README.md` — project overview and claims
- `results/`, `outputs/`, `experiments/` — existing findings
- `configs/` — experimental settings
- `.bib` files — existing citations
- Draft documents or notes

## Step 0.2: Organize the Workspace

Establish a consistent workspace structure:

```
workspace/
  paper/               # LaTeX source, figures, compiled PDFs
  experiments/         # Experiment runner scripts
  code/                # Core method implementation
  results/             # Raw experiment results (auto-generated)
  tasks/               # Task/benchmark definitions
  human_eval/          # Human evaluation materials (if needed)
```

## Step 0.3: Set Up Version Control

```bash
git init  # if not already
git remote add origin <repo-url>
git checkout -b paper-draft  # or main
```

**Git discipline**: Every completed experiment batch gets committed with a descriptive message. Example:
```
Add Monte Carlo constrained results (5 runs, Sonnet 4.6, policy memo task)
Add Haiku baseline comparison: autoreason vs refinement baselines at cheap model tier
```

## Step 0.4: Identify the Contribution

Before writing anything, articulate:
- **The What**: What is the single thing this paper contributes?
- **The Why**: What evidence supports it?
- **The So What**: Why should readers care?

> Propose to the scientist: "Based on my understanding, the main contribution is: [one sentence]. The key results show [Y]. Is this the framing you want?"

## Step 0.5: Create a TODO List

Use the `todo` tool to create a structured project plan:

```
Research Paper TODO:
- [ ] Define one-sentence contribution
- [ ] Literature review (related work + baselines)
- [ ] Design core experiments
- [ ] Run experiments
- [ ] Analyze results
- [ ] Write first draft
- [ ] Self-review (simulate reviewers)
- [ ] Revise based on review
- [ ] Submission prep
```

Update this throughout the project. It serves as the persistent state across sessions.

## Step 0.6: Estimate Compute Budget

Before running experiments, estimate total cost and time:

```
Compute Budget Checklist:
- [ ] API costs: (model price per token) × (estimated tokens per run) × (number of runs)
- [ ] GPU hours: (time per experiment) × (number of experiments) × (number of seeds)
- [ ] Human evaluation costs: (annotators) × (hours) × (hourly rate)
- [ ] Total budget ceiling and contingency (add 30-50% for reruns)
```

Track actual spend as experiments run:
```python
# Simple cost tracker pattern
import json, os
from datetime import datetime

COST_LOG = "results/cost_log.jsonl"

def log_cost(experiment: str, model: str, input_tokens: int, output_tokens: int, cost_usd: float):
    entry = {
        "timestamp": datetime.now().isoformat(),
        "experiment": experiment,
        "model": model,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "cost_usd": cost_usd,
    }
    with open(COST_LOG, "a") as f:
        f.write(json.dumps(entry) + "\n")
```

**When budget is tight**: Run pilot experiments (1-2 seeds, subset of tasks) before committing to full sweeps. Use cheaper models for debugging pipelines, then switch to target models for final runs.

## Step 0.7: Multi-Author Coordination

Most papers have 3-10 authors. Establish workflows early:

| Workflow | Tool | When to Use |
|----------|------|-------------|
| **Overleaf** | Browser-based | Multiple authors editing simultaneously, no git experience |
| **Git + LaTeX** | `git` with `.gitignore` for aux files | Technical teams, need branch-based review |
| **Overleaf + Git sync** | Overleaf premium | Best of both — live collab with version history |

**Section ownership**: Assign each section to one primary author. Others comment but don't edit directly. Prevents merge conflicts and style inconsistency.

```
Author Coordination Checklist:
- [ ] Agree on section ownership (who writes what)
- [ ] Set up shared workspace (Overleaf or git repo)
- [ ] Establish notation conventions (before anyone writes)
- [ ] Schedule internal review rounds (not just at the end)
- [ ] Designate one person for final formatting pass
- [ ] Agree on figure style (colors, fonts, sizes) before creating figures
```

**LaTeX conventions to agree on early**:
- `\method{}` macro for consistent method naming
- Citation style: `\citet{}` vs `\citep{}` usage
- Math notation: lowercase bold for vectors, uppercase bold for matrices, etc.
- British vs American spelling
