# Literature Review (Phase 1)

Find related work, identify baselines, gather citations. For the citation verification APIs and the full `CitationManager` implementation, see [citation-workflow.md](citation-workflow.md).

---

## Contents

- [Step 1.1: Identify Seed Papers](#step-11-identify-seed-papers)
- [Step 1.2: Search for Related Work](#step-12-search-for-related-work)
- [Step 1.2b: Deepen the Search](#step-12b-deepen-the-search-breadth-first-then-depth)
- [Step 1.3: Verify Every Citation](#step-13-verify-every-citation)
- [Step 1.4: Organize Related Work](#step-14-organize-related-work)

---

## Step 1.1: Identify Seed Papers

Start from papers already referenced in the codebase:

```bash
# Via terminal:
grep -r "arxiv\|doi\|cite" --include="*.md" --include="*.bib" --include="*.py"
find . -name "*.bib"
```

## Step 1.2: Search for Related Work

**Use the `arxiv` skill** for structured paper discovery. It provides arXiv REST API search, Semantic Scholar citation graphs, author profiles, and BibTeX generation.

Use WebSearch for broad discovery, WebFetch for fetching specific papers:

```
# Via WebSearch:
"[main technique] + [application domain] site:arxiv.org"
"[baseline method] comparison ICML NeurIPS 2024"

# Via WebFetch (for specific papers):
https://arxiv.org/abs/2303.17651
```

Additional search queries to try:

```
Search queries:
- "[main technique] + [application domain]"
- "[baseline method] comparison"
- "[problem name] state-of-the-art"
- Author names from existing citations
```

**Recommended**: Install **Exa MCP** for real-time academic search:
```bash
claude mcp add exa -- npx -y mcp-remote "https://mcp.exa.ai/mcp"
```

## Step 1.2b: Deepen the Search (Breadth-First, Then Depth)

A flat search (one round of queries) typically misses important related work. Use an iterative **breadth-then-depth** pattern inspired by deep research pipelines:

```
Iterative Literature Search:

Round 1 (Breadth): 4-6 parallel queries covering different angles
  - "[method] + [domain]"
  - "[problem name] state-of-the-art 2024 2025"
  - "[baseline method] comparison"
  - "[alternative approach] vs [your approach]"
  → Collect papers, extract key concepts and terminology

Round 2 (Depth): Generate follow-up queries from Round 1 learnings
  - New terminology discovered in Round 1 papers
  - Papers cited by the most relevant Round 1 results
  - Contradictory findings that need investigation
  → Collect papers, identify remaining gaps

Round 3 (Targeted): Fill specific gaps
  - Missing baselines identified in Rounds 1-2
  - Concurrent work (last 6 months, same problem)
  - Key negative results or failed approaches
  → Stop when new queries return mostly papers you've already seen
```

**When to stop**: If a round returns >80% papers already in your collection, the search is saturated. Typically 2-3 rounds suffice. For survey papers, expect 4-5 rounds.

**For agent-based workflows**: Delegate each round's queries in parallel using the Agent tool. Collect results, deduplicate, then generate the next round's queries from the combined learnings.

## Step 1.3: Verify Every Citation

Citations come from APIs, not from memory — AI-generated citations have ~40% error rate. For each citation, follow the 5-step process:

```
Citation Verification (per citation):
1. SEARCH → Query Semantic Scholar or Exa MCP with specific keywords
2. VERIFY → Confirm paper exists in 2+ sources (Semantic Scholar + arXiv/CrossRef)
3. RETRIEVE → Get BibTeX via DOI content negotiation (programmatically, not from memory)
4. VALIDATE → Confirm the claim you're citing actually appears in the paper
5. ADD → Add verified BibTeX to bibliography
If ANY step fails → mark as [CITATION NEEDED], inform scientist
```

Apply the API workflow from [citation-workflow.md](citation-workflow.md) — DOI content negotiation, the `CitationManager` class, the placeholder convention for unverifiable citations, and BibTeX key formats.

## Step 1.4: Organize Related Work

Group papers by methodology, not paper-by-paper:

**Good**: "One line of work uses X's assumption [refs] whereas we use Y's assumption because..."
**Bad**: "Smith et al. introduced X. Jones et al. introduced Y. We combine both."
