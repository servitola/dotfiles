# Paper Drafting (Phase 5)

Section-by-section guide for writing a complete, publication-ready paper. For sentence-level style, word choice, and the narrative principle, see [writing-guide.md](writing-guide.md). For LaTeX templates, packages, tables, figures, and diagrams, see [latex-toolkit.md](latex-toolkit.md).

---

## Contents

- [Context Management for Large Projects](#context-management-for-large-projects)
- [Writing Workflow](#writing-workflow)
- [Two-Pass Refinement Pattern](#two-pass-refinement-pattern)
- [Step 5.0: Title](#step-50-title)
- [Step 5.1: Abstract](#step-51-abstract-5-sentence-formula)
- [Step 5.2: Figure 1](#step-52-figure-1)
- [Step 5.3: Introduction](#step-53-introduction-1-15-pages-max)
- [Step 5.4: Methods](#step-54-methods)
- [Step 5.5: Experiments & Results](#step-55-experiments--results)
- [Step 5.6: Related Work](#step-56-related-work)
- [Step 5.7: Limitations](#step-57-limitations-required)
- [Step 5.8: Conclusion & Discussion](#step-58-conclusion--discussion)
- [Step 5.9: Appendix Strategy](#step-59-appendix-strategy)
- [Page Budget Management](#page-budget-management)
- [Step 5.10: Ethics & Broader Impact Statement](#step-510-ethics--broader-impact-statement)
- [Step 5.11: Datasheets & Model Cards](#step-511-datasheets--model-cards-if-applicable)

---

## Context Management for Large Projects

A paper project with 50+ experiment files, multiple result directories, and extensive literature notes can easily exceed the agent's context window. Manage this proactively:

**What to load into context per drafting task:**

| Drafting Task | Load Into Context | Do NOT Load |
|---------------|------------------|-------------|
| Writing Introduction | `experiment_log.md`, contribution statement, 5-10 most relevant paper abstracts | Raw result JSONs, full experiment scripts, all literature notes |
| Writing Methods | Experiment configs, pseudocode, architecture description | Raw logs, results from other experiments |
| Writing Results | `experiment_log.md`, result summary tables, figure list | Full analysis scripts, intermediate data |
| Writing Related Work | Organized citation notes, .bib file | Experiment files, raw PDFs |
| Revision pass | Full paper draft, specific reviewer concerns | Everything else |

**Principles:**
- **`experiment_log.md` is the primary context bridge** — it summarizes everything needed for writing without loading raw data files (see [experiment-patterns.md](experiment-patterns.md), "The Experiment Log")
- **Load one section's context at a time** when delegating. A sub-agent drafting Methods doesn't need the literature review notes.
- **Summarize, don't include raw files.** For a 200-line result JSON, load a 10-line summary table. For a 50-page related paper, load the 5-sentence abstract + your 2-line note about its relevance.
- **For very large projects**: Create a `context/` directory with pre-compressed summaries:
  ```
  context/
    contribution.md          # 1 sentence
    experiment_summary.md    # Key results table (from experiment_log.md)
    literature_map.md        # Organized citation notes
    figure_inventory.md      # List of figures with descriptions
  ```

## Writing Workflow

Spend approximately **equal time** on: the abstract, the introduction, the figures, and everything else combined. Most reviewers form judgments before reaching your methods — readers encounter the paper as title → abstract → introduction → figures → maybe the rest (see [writing-guide.md](writing-guide.md), "Time Allocation").

```
Paper Writing Checklist:
- [ ] Step 1: Define the one-sentence contribution
- [ ] Step 2: Draft Figure 1 (core idea or most compelling result)
- [ ] Step 3: Draft abstract (5-sentence formula)
- [ ] Step 4: Draft introduction (1-1.5 pages max)
- [ ] Step 5: Draft methods
- [ ] Step 6: Draft experiments & results
- [ ] Step 7: Draft related work
- [ ] Step 8: Draft conclusion & discussion
- [ ] Step 9: Draft limitations (required by all venues)
- [ ] Step 10: Plan appendix (proofs, extra experiments, details)
- [ ] Step 11: Complete paper checklist
- [ ] Step 12: Final review
```

## Two-Pass Refinement Pattern

When drafting with an AI agent, use a **two-pass** approach (proven effective in SakanaAI's AI-Scientist pipeline):

**Pass 1 — Write + immediate refine per section:**
For each section, write a complete draft, then immediately refine it in the same context. This catches local issues (clarity, flow, completeness) while the section is fresh.

**Pass 2 — Global refinement with full-paper context:**
After all sections are drafted, revisit each section with awareness of the complete paper. This catches cross-section issues: redundancy, inconsistent terminology, narrative flow, and gaps where one section promises something another doesn't deliver.

```
Second-pass refinement prompt (per section):
"Review the [SECTION] in the context of the complete paper.
- Does it fit with the rest of the paper? Are there redundancies with other sections?
- Is terminology consistent with Introduction and Methods?
- Can anything be cut without weakening the message?
- Does the narrative flow from the previous section and into the next?
Make minimal, targeted edits. Do not rewrite from scratch."
```

Append the LaTeX error checklist from [latex-toolkit.md](latex-toolkit.md) to every refinement prompt.

## Step 5.0: Title

The title is the single most-read element of the paper. It determines whether anyone clicks through to the abstract.

**Good titles**:
- State the contribution or finding: "Autoreason: When Iterative LLM Refinement Works and Why It Fails"
- Highlight a surprising result: "Scaling Data-Constrained Language Models" (implies you can)
- Name the method + what it does: "DPO: Direct Preference Optimization of Language Models"

**Bad titles**:
- Too generic: "An Approach to Improving Language Model Outputs"
- Too long: anything over ~15 words
- Jargon-only: "Asymptotic Convergence of Iterative Stochastic Policy Refinement" (who is this for?)

**Rules**:
- Include your method name if you have one (for citability)
- Include 1-2 keywords reviewers will search for
- Avoid colons unless both halves carry meaning
- Test: would a reviewer know the domain and contribution from the title alone?

## Step 5.1: Abstract (5-Sentence Formula)

From Sebastian Farquhar (DeepMind):

```
1. What you achieved: "We introduce...", "We prove...", "We demonstrate..."
2. Why this is hard and important
3. How you do it (with specialist keywords for discoverability)
4. What evidence you have
5. Your most remarkable number/result
```

**Delete** generic openings like "Large language models have achieved remarkable success..." — see [writing-guide.md](writing-guide.md) for a worked example.

## Step 5.2: Figure 1

Figure 1 is the second thing most readers look at (after abstract). Draft it before writing the introduction — it forces you to clarify the core idea.

| Figure 1 Type | When to Use | Example |
|---------------|-------------|---------|
| **Method diagram** | New architecture or pipeline | TikZ flowchart showing your system |
| **Results teaser** | One compelling result tells the whole story | Bar chart: "Ours vs baselines" with clear gap |
| **Problem illustration** | The problem is unintuitive | Before/after showing failure mode you fix |
| **Conceptual diagram** | Abstract contribution needs visual grounding | 2x2 matrix of method properties |

**Rules**: Figure 1 should be understandable without reading any text. The caption alone should communicate the core idea. Use color purposefully — don't just decorate.

## Step 5.3: Introduction (1-1.5 pages max)

Must include:
- Clear problem statement
- Brief approach overview
- 2-4 bullet contribution list (max 1-2 lines each in two-column format)
- Methods should start by page 2-3

Full structure template and good/bad contribution bullets: [writing-guide.md](writing-guide.md), "Introduction Structure".

## Step 5.4: Methods

Enable reimplementation:
- Conceptual outline or pseudocode
- All hyperparameters listed
- Architectural details sufficient for reproduction
- Present final design decisions; ablations go in experiments

## Step 5.5: Experiments & Results

For each experiment, explicitly state:
- **What claim it supports**
- How it connects to main contribution
- What to observe: "the blue line shows X, which demonstrates Y"

Requirements:
- Error bars with methodology (std dev vs std error)
- Hyperparameter search ranges
- Compute infrastructure (GPU type, total hours)
- Seed-setting methods

## Step 5.6: Related Work

Organize methodologically, not paper-by-paper. Cite generously — reviewers likely authored relevant papers.

## Step 5.7: Limitations (REQUIRED)

All major conferences require this. Honesty helps:
- Reviewers are instructed not to penalize honest limitation acknowledgment
- Pre-empt criticisms by identifying weaknesses first
- Explain why limitations don't undermine core claims

## Step 5.8: Conclusion & Discussion

**Conclusion** (required, 0.5-1 page):
- Restate the contribution in one sentence (different wording from abstract)
- Summarize key findings (2-3 sentences, not a list)
- Implications: what does this mean for the field?
- Future work: 2-3 concrete next steps (not vague "we leave X for future work")

**Discussion** (optional, sometimes combined with conclusion):
- Broader implications beyond immediate results
- Connections to other subfields
- Honest assessment of when the method does and doesn't work
- Practical deployment considerations

**Do NOT** introduce new results or claims in the conclusion.

## Step 5.9: Appendix Strategy

Appendices are unlimited at all major venues and are essential for reproducibility. Structure:

| Appendix Section | What Goes Here |
|-----------------|---------------|
| **Proofs & Derivations** | Full proofs too long for main text. Main text can state theorems with "proof in Appendix A." |
| **Additional Experiments** | Ablations, scaling curves, per-dataset breakdowns, hyperparameter sensitivity |
| **Implementation Details** | Full hyperparameter tables, training details, hardware specs, random seeds |
| **Dataset Documentation** | Data collection process, annotation guidelines, licensing, preprocessing |
| **Prompts & Templates** | Exact prompts used (for LLM-based methods), evaluation templates |
| **Human Evaluation** | Annotation interface screenshots, instructions given to annotators, IRB details |
| **Additional Figures** | Per-task breakdowns, trajectory visualizations, failure case examples |

**Rules**:
- The main paper should be self-contained — reviewers are not required to read appendices
- Keep critical evidence in the main paper, not only in the appendix
- Cross-reference: "Full results in Table 5 (Appendix B)" not just "see appendix"
- Use `\appendix` command, then `\section{A: Proofs}` etc.

## Page Budget Management

When over the page limit:

| Cut Strategy | Saves | Risk |
|-------------|-------|------|
| Move proofs to appendix | 0.5-2 pages | Low — standard practice |
| Condense related work | 0.5-1 page | Medium — may miss key citations |
| Combine tables with subfigures | 0.25-0.5 page | Low — often improves readability |
| Use `\vspace{-Xpt}` sparingly | 0.1-0.3 page | Low if subtle, high if obvious |
| Remove qualitative examples | 0.5-1 page | Medium — reviewers like examples |
| Reduce figure sizes | 0.25-0.5 page | High — figures must remain readable |

**Do NOT**: reduce font size, change margins, remove required sections (limitations, broader impact), or use `\small`/`\footnotesize` for main text.

## Step 5.10: Ethics & Broader Impact Statement

Most venues now require or strongly encourage an ethics/broader impact statement. This is not boilerplate — reviewers read it and can flag ethics concerns that trigger desk rejection.

**What to include:**

| Component | Content | Required By |
|-----------|---------|-------------|
| **Positive societal impact** | How your work benefits society | NeurIPS, ICML |
| **Potential negative impact** | Misuse risks, dual-use concerns, failure modes | NeurIPS, ICML |
| **Fairness & bias** | Does your method/data have known biases? | All venues (implicitly) |
| **Environmental impact** | Compute carbon footprint for large-scale training | ICML, increasingly NeurIPS |
| **Privacy** | Does your work use or enable processing of personal data? | ACL, NeurIPS |
| **LLM disclosure** | Was AI used in writing or experiments? | ICLR (mandatory), ACL |

**Writing the statement:**

```latex
\section*{Broader Impact Statement}
% NeurIPS/ICML: after conclusion, does not count toward page limit

% 1. Positive applications (1-2 sentences)
This work enables [specific application] which may benefit [specific group].

% 2. Risks and mitigations (1-3 sentences, be specific)
[Method/model] could potentially be misused for [specific risk]. We mitigate
this by [specific mitigation, e.g., releasing only model weights above size X,
including safety filters, documenting failure modes].

% 3. Limitations of impact claims (1 sentence)
Our evaluation is limited to [specific domain]; broader deployment would
require [specific additional work].
```

**Common mistakes:**
- Writing "we foresee no negative impacts" (almost never true — reviewers distrust this)
- Being vague: "this could be misused" without specifying how
- Ignoring compute costs for large-scale work
- Forgetting to disclose LLM use at venues that require it

**Compute carbon footprint** (for training-heavy papers):
```python
# Estimate using ML CO2 Impact tool methodology
gpu_hours = 1000  # total GPU hours
gpu_tdp_watts = 400  # e.g., A100 = 400W
pue = 1.1  # Power Usage Effectiveness (data center overhead)
carbon_intensity = 0.429  # kg CO2/kWh (US average; varies by region)

energy_kwh = (gpu_hours * gpu_tdp_watts * pue) / 1000
carbon_kg = energy_kwh * carbon_intensity
print(f"Energy: {energy_kwh:.0f} kWh, Carbon: {carbon_kg:.0f} kg CO2eq")
```

## Step 5.11: Datasheets & Model Cards (If Applicable)

If your paper introduces a **new dataset** or **releases a model**, include structured documentation. Reviewers increasingly expect this, and NeurIPS Datasets & Benchmarks track requires it.

**Datasheets for Datasets** (Gebru et al., 2021) — include in appendix:

```
Dataset Documentation (Appendix):
- Motivation: Why was this dataset created? What task does it support?
- Composition: What are the instances? How many? What data types?
- Collection: How was data collected? What was the source?
- Preprocessing: What cleaning/filtering was applied?
- Distribution: How is the dataset distributed? Under what license?
- Maintenance: Who maintains it? How to report issues?
- Ethical considerations: Contains personal data? Consent obtained?
  Potential for harm? Known biases?
```

**Model Cards** (Mitchell et al., 2019) — include in appendix for model releases:

```
Model Card (Appendix):
- Model details: Architecture, training data, training procedure
- Intended use: Primary use cases, out-of-scope uses
- Metrics: Evaluation metrics and results on benchmarks
- Ethical considerations: Known biases, fairness evaluations
- Limitations: Known failure modes, domains where model underperforms
```

The full datasheet question list lives in [paper-types.md](paper-types.md), "Dataset Documentation".
