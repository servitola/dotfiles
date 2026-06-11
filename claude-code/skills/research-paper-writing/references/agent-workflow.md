# Agent Workflow & Tooling

How an agent drives the full research lifecycle: proactivity rules, tool mapping, state management, monitoring, and communication patterns.

---

## Contents

- [Proactivity and Collaboration](#proactivity-and-collaboration)
- [Related Skills](#related-skills)
- [Tool Reference](#tool-reference)
- [Tool Usage Patterns](#tool-usage-patterns)
- [State Management](#state-management)
- [Periodic Monitoring](#periodic-monitoring)
- [Communication Patterns](#communication-patterns)
- [Decision Points Requiring Human Input](#decision-points-requiring-human-input)

---

## Proactivity and Collaboration

**Default: Be proactive. Draft first, ask with the draft.** Scientists are busy — produce something concrete they can react to, then iterate.

| Confidence Level | Action |
|-----------------|--------|
| **High** (clear repo, obvious contribution) | Write full draft, deliver, iterate on feedback |
| **Medium** (some ambiguity) | Write draft with flagged uncertainties, continue |
| **Low** (major unknowns) | Ask 1-2 targeted questions via `clarify`, then draft |

| Section | Draft Autonomously? | Flag With Draft |
|---------|-------------------|-----------------|
| Abstract | Yes | "Framed contribution as X — adjust if needed" |
| Introduction | Yes | "Emphasized problem Y — correct if wrong" |
| Methods | Yes | "Included details A, B, C — add missing pieces" |
| Experiments | Yes | "Highlighted results 1, 2, 3 — reorder if needed" |
| Related Work | Yes | "Cited papers X, Y, Z — add any I missed" |

**Block for input only when**: target venue unclear, multiple contradictory framings, results seem incomplete, explicit request to review first.

## Related Skills

Compose this skill with others for specific phases:

| Skill | When to Use |
|-------|-------------|
| **arxiv** | Phase 1 (Literature Review): searching arXiv, generating BibTeX, finding related papers via Semantic Scholar |

For Phase 5 (Drafting), use the Agent tool to draft sections in parallel with a two-stage review (spec compliance, then quality). For figures and architecture diagrams, use a diagramming skill if available. For interactive analysis, use a notebook/Jupyter workflow.

## Tool Reference

| Capability | Usage in This Pipeline |
|------------|------------------------|
| **Bash** | LaTeX compilation (`latexmk -pdf`), git operations, launching experiments (`nohup python run.py &`), process checks, running Python for citation verification / statistical analysis / data aggregation |
| **Read / Write / Edit** | Paper editing, experiment scripts, result files. Use Edit for targeted changes to large `.tex` files |
| **WebSearch** | Literature discovery: search for `"transformer attention mechanism 2024"` |
| **WebFetch** | Fetch paper content, verify citations: `https://arxiv.org/abs/2303.17651` |
| **the Agent tool** | Parallel section drafting — spawn isolated agents per section. Also for concurrent citation verification |
| **Task list** | Primary state tracker across sessions. Update after every phase transition |

## Tool Usage Patterns

**Experiment monitoring** (most common), via Bash:
```
ps aux | grep <pattern>
tail -30 <logfile>
ls results/
# then analyze results JSON / compute metrics with Python
git add <files> && git commit -m '<descriptive message>' && git push
```
Notify the user when the experiment completes.

**Parallel section drafting** — launch one Agent per section, e.g.:
```
Agent: "Draft the Methods section based on these experiment scripts and configs.
  Include: pseudocode, all hyperparameters, architectural details sufficient for
  reproduction. Write in LaTeX using the neurips2025 template conventions."

Agent: "Draft the Related Work section. Use web search/fetch to find papers.
  Verify every citation via Semantic Scholar. Group by methodology."

Agent: "Draft the Experiments section. Read all result files in results/.
  State which claim each experiment supports. Include error bars and significance."
```

Each agent runs with no shared context — provide all necessary information in the prompt. Collect outputs and integrate.

**Citation verification** — run Python via Bash:
```python
from semanticscholar import SemanticScholar
import requests

sch = SemanticScholar()
results = sch.search_paper("attention mechanism transformers", limit=5)
for paper in results:
    doi = paper.externalIds.get('DOI', 'N/A')
    if doi != 'N/A':
        bibtex = requests.get(f"https://doi.org/{doi}",
                              headers={"Accept": "application/x-bibtex"}).text
        print(bibtex)
```

## State Management

Track granular progress in your task list and persist key decisions (contribution framing, venue choice, key results, current phase) in a project notes file so they survive across sessions.

**Session startup protocol:**
```
1. Review the current task list
2. Recall key decisions from your notes file
3. git log --oneline -10        # recent commits
4. ps aux | grep python         # running experiments
5. ls results/ | tail -20       # new results
6. Report status to user, ask for direction
```

## Periodic Monitoring

For long-running experiments, periodically check status (process running? new results? complete?). When complete, read results, compute metrics, commit, and report a results table plus the key finding and next step. When nothing has changed, stay quiet rather than emitting noise. Track deadlines (e.g. NeurIPS submission date) against the task list and warn the user if fewer than 7 days remain with incomplete tasks.

The full cron monitoring prompt template and best practices live in [experiment-patterns.md](experiment-patterns.md), "Monitoring (Cron Pattern)".

## Communication Patterns

**When to notify the user:**
- Experiment batch completed (with results table)
- Unexpected finding or failure requiring decision
- Draft section ready for review
- Deadline approaching with incomplete tasks

**When NOT to notify:** experiment still running with no new results, routine monitoring with no changes, intermediate steps that don't need attention.

**Report format** — always include structured data:
```
## Experiment: <name>
Status: Complete / Running / Failed

| Task | Method A | Method B | Method C |
|------|---------|---------|---------|
| Task 1 | 85.2 | 82.1 | **89.4** |

Key finding: <one sentence>
Next step: <what happens next>
```

## Decision Points Requiring Human Input

Ask the user targeted questions when genuinely blocked:

| Decision | When to Ask |
|----------|-------------|
| Target venue | Before starting paper (affects page limits, framing) |
| Contribution framing | When multiple valid framings exist |
| Experiment priority | When the task list has more experiments than time allows |
| Submission readiness | Before final submission |

**Do NOT ask about** (be proactive, make a choice, flag it):
- Word choice, section ordering
- Which specific results to highlight
- Citation completeness (draft with what you find, note gaps)
