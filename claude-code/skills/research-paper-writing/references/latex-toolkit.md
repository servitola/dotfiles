# LaTeX Toolkit

Templates, packages, tables, figures, diagrams, and revision tooling for conference papers. For section-by-section content guidance, see [paper-drafting.md](paper-drafting.md).

---

## Contents

- [Using LaTeX Templates](#using-latex-templates)
- [Template Pitfalls](#template-pitfalls)
- [Quick Template Reference](#quick-template-reference)
- [LaTeX Error Checklist](#latex-error-checklist)
- [Tables and Figures](#tables-and-figures)
- [Professional LaTeX Preamble](#professional-latex-preamble)
- [siunitx Table Alignment](#siunitx-table-alignment)
- [Subfigures](#subfigures)
- [Pseudocode with algorithm2e](#pseudocode-with-algorithm2e)
- [TikZ Diagram Patterns](#tikz-diagram-patterns)
- [latexdiff for Revision Tracking](#latexdiff-for-revision-tracking)
- [SciencePlots for matplotlib](#scienceplots-for-matplotlib)

---

## Using LaTeX Templates

**Always copy the entire template directory first, then write within it.**

```
Template Setup Checklist:
- [ ] Step 1: Copy entire template directory to new project
- [ ] Step 2: Verify template compiles as-is (before any changes)
- [ ] Step 3: Read the template's example content to understand structure
- [ ] Step 4: Replace example content section by section
- [ ] Step 5: Use template macros (check preamble for \newcommand definitions)
- [ ] Step 6: Clean up template artifacts only at the end
```

**Step 1: Copy the Full Template**

```bash
cp -r templates/neurips2025/ ~/papers/my-paper/
cd ~/papers/my-paper/
ls -la  # Should see: main.tex, neurips.sty, Makefile, etc.
```

Copy the ENTIRE directory, not just the .tex file. Templates include style files (.sty), bibliography styles (.bst), example content, and Makefiles.

**Step 2: Verify Template Compiles First**

Before making ANY changes:
```bash
latexmk -pdf main.tex
# Or manual: pdflatex main.tex && bibtex main && pdflatex main.tex && pdflatex main.tex
```

If the unmodified template doesn't compile, fix that first (usually missing TeX packages — install via `tlmgr install <package>`).

**Step 3: Keep Template Content as Reference**

Don't immediately delete example content. Comment it out and use as formatting reference:
```latex
% Template example (keep for reference):
% \begin{figure}[t]
%   \centering
%   \includegraphics[width=0.8\linewidth]{example-image}
%   \caption{Template shows caption style}
% \end{figure}

% Your actual figure:
\begin{figure}[t]
  \centering
  \includegraphics[width=0.8\linewidth]{your-figure.pdf}
  \caption{Your caption following the same style.}
\end{figure}
```

**Step 4: Replace Content Section by Section**

Work through systematically: title/authors → abstract → introduction → methods → experiments → related work → conclusion → references → appendix. Compile after each section.

**Step 5: Use Template Macros**

```latex
\newcommand{\method}{YourMethodName}  % Consistent method naming
\newcommand{\eg}{e.g.,\xspace}        % Proper abbreviations
\newcommand{\ie}{i.e.,\xspace}
```

## Template Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Copying only `.tex` file | Missing `.sty`, won't compile | Copy entire directory |
| Modifying `.sty` files | Breaks conference formatting | Never edit style files |
| Adding random packages | Conflicts, breaks template | Only add if necessary |
| Deleting template content early | Lose formatting reference | Keep as comments until done |
| Not compiling frequently | Errors accumulate | Compile after each section |
| Raster PNGs for figures | Blurry in paper | Always use vector PDF via `savefig('fig.pdf')` |

## Quick Template Reference

| Conference | Main File | Style File | Page Limit |
|------------|-----------|------------|------------|
| NeurIPS 2025 | `main.tex` | `neurips.sty` | 9 pages |
| ICML 2026 | `example_paper.tex` | `icml2026.sty` | 8 pages |
| ICLR 2026 | `iclr2026_conference.tex` | `iclr2026_conference.sty` | 9 pages |
| ACL 2025 | `acl_latex.tex` | `acl.sty` | 8 pages (long) |
| AAAI 2026 | `aaai2026-unified-template.tex` | `aaai2026.sty` | 7 pages |
| COLM 2025 | `colm2025_conference.tex` | `colm2025_conference.sty` | 9 pages |

**Universal**: Double-blind, references don't count, appendices unlimited, LaTeX required.

Templates in the skill's `templates/` directory. See [templates/README.md](../templates/README.md) for compilation setup (VS Code, CLI, Overleaf, other IDEs).

## LaTeX Error Checklist

Append this checklist to every refinement prompt. These are the most common errors when LLMs write LaTeX:

```
LaTeX Quality Checklist (verify after every edit):
- [ ] No unenclosed math symbols ($ signs balanced)
- [ ] Only reference figures/tables that exist (\ref matches \label)
- [ ] No fabricated citations (\cite matches entries in .bib)
- [ ] Every \begin{env} has matching \end{env} (especially figure, table, algorithm)
- [ ] No HTML contamination (</end{figure}> instead of \end{figure})
- [ ] No unescaped underscores outside math mode (use \_ in text)
- [ ] No duplicate \label definitions
- [ ] No duplicate section headers
- [ ] Numbers in text match actual experimental results
- [ ] All figures have captions and labels
- [ ] No overly long lines that cause overfull hbox warnings
```

## Tables and Figures

**Tables** — use `booktabs` for professional formatting:

```latex
\usepackage{booktabs}
\begin{tabular}{lcc}
\toprule
Method & Accuracy $\uparrow$ & Latency $\downarrow$ \\
\midrule
Baseline & 85.2 & 45ms \\
\textbf{Ours} & \textbf{92.1} & 38ms \\
\bottomrule
\end{tabular}
```

Rules:
- Bold best value per metric
- Include direction symbols ($\uparrow$ higher better, $\downarrow$ lower better)
- Right-align numerical columns
- Consistent decimal precision

**Figures**:
- **Vector graphics** (PDF, EPS) for all plots and diagrams — `plt.savefig('fig.pdf')`
- **Raster** (PNG 600 DPI) only for photographs
- **Colorblind-safe palettes** (Okabe-Ito or Paul Tol)
- Verify **grayscale readability** (8% of men have color vision deficiency)
- **No title inside figure** — the caption serves this function
- **Self-contained captions** — reader should understand without main text

## Professional LaTeX Preamble

Add these packages to any paper for professional quality. They are compatible with all major conference style files:

```latex
% --- Professional Packages (add after conference style file) ---

% Typography
\usepackage{microtype}              % Microtypographic improvements (protrusion, expansion)
                                     % Makes text noticeably more polished — always include

% Tables
\usepackage{booktabs}               % Professional table rules (\toprule, \midrule, \bottomrule)
\usepackage{siunitx}                % Consistent number formatting, decimal alignment
                                     % Usage: \num{12345} → 12,345; \SI{3.5}{GHz} → 3.5 GHz
                                     % Table alignment: S column type for decimal-aligned numbers

% Figures
\usepackage{graphicx}               % Include graphics (\includegraphics)
\usepackage{subcaption}             % Subfigures with (a), (b), (c) labels
                                     % Usage: \begin{subfigure}{0.48\textwidth} ... \end{subfigure}

% Diagrams and Algorithms
\usepackage{tikz}                   % Programmable vector diagrams
\usetikzlibrary{arrows.meta, positioning, shapes.geometric, calc, fit, backgrounds}
\usepackage[ruled,vlined]{algorithm2e}  % Professional pseudocode
                                     % Alternative: \usepackage{algorithmicx} if template bundles it

% Cross-references
\usepackage{cleveref}               % Smart references: \cref{fig:x} → "Figure 1"
                                     % MUST be loaded AFTER hyperref
                                     % Handles: figures, tables, sections, equations, algorithms

% Math (usually included by conference .sty, but verify)
\usepackage{amsmath,amssymb}        % AMS math environments and symbols
\usepackage{mathtools}              % Extends amsmath (dcases, coloneqq, etc.)

% Colors (for figures and diagrams)
\usepackage{xcolor}                 % Color management
% Okabe-Ito colorblind-safe palette:
\definecolor{okblue}{HTML}{0072B2}
\definecolor{okorange}{HTML}{E69F00}
\definecolor{okgreen}{HTML}{009E73}
\definecolor{okred}{HTML}{D55E00}
\definecolor{okpurple}{HTML}{CC79A7}
\definecolor{okcyan}{HTML}{56B4E9}
\definecolor{okyellow}{HTML}{F0E442}
```

**Notes:**
- `microtype` is the single highest-impact package for visual quality. It adjusts character spacing at a sub-pixel level. Always include it.
- `siunitx` handles decimal alignment in tables via the `S` column type — eliminates manual spacing.
- `cleveref` must be loaded **after** `hyperref`. Most conference .sty files load hyperref, so put cleveref last.
- Check if the conference template already loads any of these (especially `algorithm`, `amsmath`, `graphicx`). Don't double-load.

## siunitx Table Alignment

`siunitx` makes number-heavy tables significantly more readable:

```latex
\begin{tabular}{l S[table-format=2.1] S[table-format=2.1] S[table-format=2.1]}
\toprule
Method & {Accuracy $\uparrow$} & {F1 $\uparrow$} & {Latency (ms) $\downarrow$} \\
\midrule
Baseline         & 85.2  & 83.7  & 45.3 \\
Ablation (no X)  & 87.1  & 85.4  & 42.1 \\
\textbf{Ours}    & \textbf{92.1} & \textbf{90.8} & \textbf{38.7} \\
\bottomrule
\end{tabular}
```

The `S` column type auto-aligns on the decimal point. Headers in `{}` escape the alignment.

## Subfigures

Standard pattern for side-by-side figures:

```latex
\begin{figure}[t]
  \centering
  \begin{subfigure}[b]{0.48\textwidth}
    \centering
    \includegraphics[width=\textwidth]{fig_results_a.pdf}
    \caption{Results on Dataset A.}
    \label{fig:results-a}
  \end{subfigure}
  \hfill
  \begin{subfigure}[b]{0.48\textwidth}
    \centering
    \includegraphics[width=\textwidth]{fig_results_b.pdf}
    \caption{Results on Dataset B.}
    \label{fig:results-b}
  \end{subfigure}
  \caption{Comparison of our method across two datasets. (a) shows the scaling
  behavior and (b) shows the ablation results. Both use 5 random seeds.}
  \label{fig:results}
\end{figure}
```

Use `\cref{fig:results}` → "Figure 1", `\cref{fig:results-a}` → "Figure 1a".

## Pseudocode with algorithm2e

```latex
\begin{algorithm}[t]
\caption{Iterative Refinement with Judge Panel}
\label{alg:method}
\KwIn{Task $T$, model $M$, judges $J_1 \ldots J_n$, convergence threshold $k$}
\KwOut{Final output $A^*$}
$A \gets M(T)$ \tcp*{Initial generation}
$\text{streak} \gets 0$\;
\While{$\text{streak} < k$}{
  $C \gets \text{Critic}(A, T)$ \tcp*{Identify weaknesses}
  $B \gets M(T, C)$ \tcp*{Revised version addressing critique}
  $AB \gets \text{Synthesize}(A, B)$ \tcp*{Merge best elements}
  \ForEach{judge $J_i$}{
    $\text{rank}_i \gets J_i(\text{shuffle}(A, B, AB))$ \tcp*{Blind ranking}
  }
  $\text{winner} \gets \text{BordaCount}(\text{ranks})$\;
  \eIf{$\text{winner} = A$}{
    $\text{streak} \gets \text{streak} + 1$\;
  }{
    $A \gets \text{winner}$; $\text{streak} \gets 0$\;
  }
}
\Return{$A$}\;
\end{algorithm}
```

## TikZ Diagram Patterns

TikZ is the standard for method diagrams in ML papers. Common patterns:

**Pipeline/Flow Diagram** (most common in ML papers):

```latex
\begin{figure}[t]
\centering
\begin{tikzpicture}[
  node distance=1.8cm,
  box/.style={rectangle, draw, rounded corners, minimum height=1cm,
              minimum width=2cm, align=center, font=\small},
  arrow/.style={-{Stealth[length=3mm]}, thick},
]
  \node[box, fill=okcyan!20] (input) {Input\\$x$};
  \node[box, fill=okblue!20, right of=input] (encoder) {Encoder\\$f_\theta$};
  \node[box, fill=okgreen!20, right of=encoder] (latent) {Latent\\$z$};
  \node[box, fill=okorange!20, right of=latent] (decoder) {Decoder\\$g_\phi$};
  \node[box, fill=okred!20, right of=decoder] (output) {Output\\$\hat{x}$};

  \draw[arrow] (input) -- (encoder);
  \draw[arrow] (encoder) -- (latent);
  \draw[arrow] (latent) -- (decoder);
  \draw[arrow] (decoder) -- (output);
\end{tikzpicture}
\caption{Architecture overview. The encoder maps input $x$ to latent
representation $z$, which the decoder reconstructs.}
\label{fig:architecture}
\end{figure}
```

**Comparison/Matrix Diagram** (for showing method variants):

```latex
\begin{tikzpicture}[
  cell/.style={rectangle, draw, minimum width=2.5cm, minimum height=1cm,
               align=center, font=\small},
  header/.style={cell, fill=gray!20, font=\small\bfseries},
]
  % Headers
  \node[header] at (0, 0) {Method};
  \node[header] at (3, 0) {Converges?};
  \node[header] at (6, 0) {Quality?};
  % Rows
  \node[cell] at (0, -1) {Single Pass};
  \node[cell, fill=okgreen!15] at (3, -1) {N/A};
  \node[cell, fill=okorange!15] at (6, -1) {Baseline};
  \node[cell] at (0, -2) {Critique+Revise};
  \node[cell, fill=okred!15] at (3, -2) {No};
  \node[cell, fill=okred!15] at (6, -2) {Degrades};
  \node[cell] at (0, -3) {Ours};
  \node[cell, fill=okgreen!15] at (3, -3) {Yes ($k$=2)};
  \node[cell, fill=okgreen!15] at (6, -3) {Improves};
\end{tikzpicture}
```

**Iterative Loop Diagram** (for methods with feedback):

```latex
\begin{tikzpicture}[
  node distance=2cm,
  box/.style={rectangle, draw, rounded corners, minimum height=0.8cm,
              minimum width=1.8cm, align=center, font=\small},
  arrow/.style={-{Stealth[length=3mm]}, thick},
  label/.style={font=\scriptsize, midway, above},
]
  \node[box, fill=okblue!20] (gen) {Generator};
  \node[box, fill=okred!20, right=2.5cm of gen] (critic) {Critic};
  \node[box, fill=okgreen!20, below=1.5cm of $(gen)!0.5!(critic)$] (judge) {Judge Panel};

  \draw[arrow] (gen) -- node[label] {output $A$} (critic);
  \draw[arrow] (critic) -- node[label, right] {critique $C$} (judge);
  \draw[arrow] (judge) -| node[label, left, pos=0.3] {winner} (gen);
\end{tikzpicture}
```

## latexdiff for Revision Tracking

Essential for rebuttals — generates a marked-up PDF showing changes between versions:

```bash
# Install
# macOS: brew install latexdiff (or comes with TeX Live)
# Linux: sudo apt install latexdiff

# Generate diff
latexdiff paper_v1.tex paper_v2.tex > paper_diff.tex
pdflatex paper_diff.tex

# For multi-file projects (with \input{} or \include{})
latexdiff --flatten paper_v1.tex paper_v2.tex > paper_diff.tex
```

This produces a PDF with deletions in red strikethrough and additions in blue — standard format for rebuttal supplements.

## SciencePlots for matplotlib

Install and use for publication-quality plots:

```bash
pip install SciencePlots
```

```python
import matplotlib.pyplot as plt
import scienceplots  # registers styles

# Use science style (IEEE-like, clean)
with plt.style.context(['science', 'no-latex']):
    fig, ax = plt.subplots(figsize=(3.5, 2.5))  # Single-column width
    ax.plot(x, y, label='Ours', color='#0072B2')
    ax.plot(x, y2, label='Baseline', color='#D55E00', linestyle='--')
    ax.set_xlabel('Training Steps')
    ax.set_ylabel('Accuracy')
    ax.legend()
    fig.savefig('paper/fig_results.pdf', bbox_inches='tight')

# Available styles: 'science', 'ieee', 'nature', 'science+ieee'
# Add 'no-latex' if LaTeX is not installed on the machine generating plots
```

**Standard figure sizes** (two-column format):
- Single column: `figsize=(3.5, 2.5)` — fits in one column
- Double column: `figsize=(7.0, 3.0)` — spans both columns
- Square: `figsize=(3.5, 3.5)` — for heatmaps, confusion matrices

More chart examples (bar charts, convergence curves, rcParams) in [experiment-patterns.md](experiment-patterns.md), "Visualization Best Practices".
