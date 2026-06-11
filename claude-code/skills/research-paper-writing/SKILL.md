---
name: research-paper-writing
description: |
  End-to-end pipeline for writing ML research papers for top venues (NeurIPS/ICML/ICLR/ACL): literature review with verified citations, experiment design, statistical analysis, LaTeX drafting, and submission prep.

  Use when: "напиши научную статью по ML", "помоги с paper для NeurIPS", "проверь цитирования в статье", "оформи эксперименты в paper", "write an ML paper", "draft a NeurIPS submission", "verify my paper's citations"
---

# Research Paper Writing Pipeline

End-to-end pipeline for producing publication-ready ML/AI research papers targeting **NeurIPS, ICML, ICLR, ACL, AAAI, and COLM**. Covers the full lifecycle: setup, literature review, experiment design, execution, analysis, drafting, review, submission, and post-acceptance.

This is not a linear pipeline — it is an iterative loop. Results trigger new experiments (analysis → design), reviews trigger new analysis or rewrites (review → design or drafting). Handle these feedback loops.

## Prerequisites

Citation verification and analysis use Python packages and a LaTeX toolchain:

```bash
pip install semanticscholar arxiv habanero requests scipy numpy matplotlib SciencePlots
# LaTeX (for compiling papers): install TeX Live / MacTeX, which provides latexmk
#   macOS:  brew install --cask mactex-no-gui
#   Debian: sudo apt-get install texlive-full latexmk
```

## Core Philosophy

1. **Be proactive.** Deliver complete drafts, not questions. Scientists are busy — produce something concrete they can react to, then iterate.
2. **Citations come from APIs, not memory.** AI-generated citations have ~40% error rate. Fetch programmatically; mark unverifiable citations as `[CITATION NEEDED]`.
3. **Paper is a story, not a collection of experiments.** Every paper needs one clear contribution stated in a single sentence. If you can't do that, the paper isn't ready.
4. **Experiments serve claims.** Every experiment explicitly states which claim it supports; cut experiments that don't connect to the narrative.
5. **Commit early, commit often.** Every completed experiment batch, every draft update — commit with descriptive messages. Git log is the experiment history.

## Pipeline Router

Load the smallest set of references that fits the task — each branch is self-contained.

**Phase 0 — Project Setup.** Starting from a codebase or idea? Set up the workspace, git, contribution statement, compute budget, and co-author workflow following [references/project-setup.md](references/project-setup.md). Before writing anything, articulate the contribution: the What (single thing the paper contributes), the Why (evidence), the So What (why readers care).

**Phase 1 — Literature Review.** Searching for related work and baselines? Run the breadth-then-depth search from [references/literature-review.md](references/literature-review.md). Verify every citation with the 5-step API workflow in [references/citation-workflow.md](references/citation-workflow.md) — search, verify in 2+ sources, retrieve BibTeX via DOI, validate the claim, add to .bib.

**Phase 2 — Experiment Design.** Designing experiments? Map every claim to an experiment, design baselines, and write crash-safe scripts following [references/experiment-patterns.md](references/experiment-patterns.md) (claims mapping, incremental saving, compute-matched comparison). Designing human evaluation? Read [references/human-evaluation.md](references/human-evaluation.md) first — it has longer lead times (IRB, recruitment) than automated runs.

**Phase 3 — Execution & Monitoring.** Running experiments? Launch with `nohup`, monitor via the cron pattern, recover from failures, and keep an experiment journal — all in [references/experiment-patterns.md](references/experiment-patterns.md) ("Launching Experiments", "Monitoring", "Failure Recovery", "The Experiment Journal").

**Phase 4 — Analysis.** Analyzing results? Apply the statistics, story-finding, and negative-results guidance from [references/experiment-patterns.md](references/experiment-patterns.md) ("Statistical Analysis", "From Results to Writing"). End the phase by writing `experiment_log.md` — the bridge between raw results and prose.

**Phase 5 — Drafting.** Writing any section (title, abstract, Figure 1, methods, results, limitations, ethics, appendix)? Follow the section-by-section guide in [references/paper-drafting.md](references/paper-drafting.md). For prose quality (narrative, abstract formula, sentence clarity, word choice), apply [references/writing-guide.md](references/writing-guide.md). For LaTeX work (templates, preamble, tables, TikZ, latexdiff, SciencePlots), use [references/latex-toolkit.md](references/latex-toolkit.md).

**Phase 6 — Self-Review & Revision.** Reviewing the draft or responding to reviews? Run the ensemble review simulation, visual pass, and claim verification from [references/reviewer-guidelines.md](references/reviewer-guidelines.md), which also covers evaluation criteria, scoring scales, feedback prioritization, and rebuttal writing.

**Phase 7 — Submission.** Preparing to submit? Work through anonymization, pre-compilation validation, format conversion, arXiv strategy, and code packaging in [references/submission.md](references/submission.md). Complete the venue's mandatory checklist from [references/checklists.md](references/checklists.md) — incomplete checklists cause desk rejection.

**Phase 8 — Post-Acceptance.** Accepted? Prepare poster, talk, and blog post per [references/post-acceptance.md](references/post-acceptance.md); camera-ready and code release are in [references/submission.md](references/submission.md).

## Cross-Cutting Branches

**Iteratively refining any output** (draft, script, analysis)? Choose the strategy (single pass / critique-and-revise / autoreason) with the decision table in [references/autoreason-methodology.md](references/autoreason-methodology.md) — strategy selection, loop configuration, prompts, scope constraints, failure modes.

**Writing a non-empirical paper** (theory, survey, benchmark, position, replication, workshop, or short paper)? Use the type-specific structures and venue tables in [references/paper-types.md](references/paper-types.md).

**Operating as an agent** (proactivity rules, tool mapping, parallel section drafting, state across sessions, when to notify the user)? Follow [references/agent-workflow.md](references/agent-workflow.md). Compose with the `arxiv` skill for Phase 1 paper discovery.

**Looking up original sources** (researcher writing guides, venue docs, APIs, attribution)? See [references/sources.md](references/sources.md).

Full routing table with reading orders for common scenarios: [references/_index.md](references/_index.md).

## LaTeX Templates

Conference templates ship with the skill in `templates/`: NeurIPS 2025, ICML 2026, ICLR 2026, ACL, AAAI 2026, COLM 2025. Copy the entire template directory before writing (see [references/latex-toolkit.md](references/latex-toolkit.md)); compilation setup is in [templates/README.md](templates/README.md).

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Abstract too generic | Delete first sentence if it could prepend any ML paper. Start with your specific contribution. |
| Introduction exceeds 1.5 pages | Split background into Related Work. Front-load contribution bullets. |
| Experiments lack explicit claims | Add: "This experiment tests whether [specific claim]..." before each one. |
| Reviewers find paper hard to follow | Add signposting, use consistent terminology, make figure captions self-contained. |
| Missing statistical significance | Add error bars, number of runs, statistical tests, confidence intervals. |
| Scope creep in experiments | Every experiment maps to a specific claim. Cut experiments that don't. |
| Paper rejected, need to resubmit | See format conversion in [references/submission.md](references/submission.md). Address concerns without referencing reviews. |
| Missing broader impact statement | See [references/paper-drafting.md](references/paper-drafting.md). "No negative impacts" is almost never credible. |
| Human eval criticized as weak | See [references/human-evaluation.md](references/human-evaluation.md). Report agreement metrics, annotator details, compensation. |
| Reviewers question reproducibility | Release code ([references/submission.md](references/submission.md)), document hyperparameters, seeds, compute. |
| Theory paper lacks intuition | Add proof sketches with plain-language explanations. See [references/paper-types.md](references/paper-types.md). |
| Results are negative/null | See "Handling Negative or Null Results" in [references/experiment-patterns.md](references/experiment-patterns.md). Consider workshops, TMLR, or reframing as analysis. |
