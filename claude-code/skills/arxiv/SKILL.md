---
name: arxiv
description: |
  Search and retrieve academic papers from arXiv (and citations via Semantic Scholar) using only curl + Python stdlib.

  Use when: "найди статью на arxiv", "поищи научные работы", "найди цитирования статьи", "search arxiv", "find papers on", "get citation count"
---

# arXiv Research

Search and retrieve academic papers from arXiv via their free REST API. No API key, no dependencies — just curl.

## What do you need?

Find papers?
├─ By topic / author / category → use the helper script (happy path below)
├─ Complex queries (field prefixes, boolean, sort, pagination) → follow syntax from [arxiv-api.md](references/arxiv-api.md)
└─ Results with citation counts (JSON) → use search endpoint from [semantic-scholar.md](references/semantic-scholar.md)

Work with a known paper (have its arXiv ID)?
├─ Read it → WebFetch (happy path below)
├─ BibTeX entry, version pinning, withdrawn check → follow recipes from [arxiv-api.md](references/arxiv-api.md)
└─ Citations / references / recommendations → use endpoints from [semantic-scholar.md](references/semantic-scholar.md)

Author profile (h-index, paper count)? → use author endpoint from [semantic-scholar.md](references/semantic-scholar.md)

Load the smallest set of references that fits the task — the happy paths below cover most requests without any.

## Quick Reference

| Action | Command |
|--------|---------|
| Search papers | `python scripts/search_arxiv.py "QUERY"` |
| Search (raw API) | `curl "https://export.arxiv.org/api/query?search_query=all:QUERY&max_results=5"` |
| Get specific paper | `curl "https://export.arxiv.org/api/query?id_list=2402.03300"` |
| Read abstract (web) | WebFetch on `https://arxiv.org/abs/2402.03300` |
| Read full paper (PDF) | WebFetch on `https://arxiv.org/pdf/2402.03300` |
| Citation count | `curl "https://api.semanticscholar.org/graph/v1/paper/arXiv:2402.03300?fields=citationCount"` |

## Searching Papers (happy path)

The arXiv API returns Atom XML; the `scripts/search_arxiv.py` helper handles parsing and prints clean output. Python stdlib only.

```bash
python scripts/search_arxiv.py "GRPO reinforcement learning"
python scripts/search_arxiv.py "transformer attention" --max 10 --sort date
python scripts/search_arxiv.py --author "Yann LeCun" --max 5
python scripts/search_arxiv.py --category cs.AI --sort date
python scripts/search_arxiv.py --id 2402.03300
python scripts/search_arxiv.py --id 2402.03300,2401.12345
```

For raw curl queries, build `search_query` using the prefix table (`ti:`, `au:`, `cat:`, …), boolean operators, and sort/pagination parameters from [arxiv-api.md](references/arxiv-api.md). Category codes (`cs.AI`, `cs.LG`, …) are listed there too.

## Reading Paper Content (happy path)

After finding a paper, read it with WebFetch:

```
# Abstract page (fast, metadata + abstract)
WebFetch on https://arxiv.org/abs/2402.03300

# Full paper (PDF)
WebFetch on https://arxiv.org/pdf/2402.03300

# HTML (when available)
WebFetch on https://arxiv.org/html/2402.03300
```

When citing what you read, preserve the version suffix (`v1`, `v7`) — versioning rules and the withdrawn-paper check are in [arxiv-api.md](references/arxiv-api.md).

## Complete Research Workflow

1. **Discover**: `python scripts/search_arxiv.py "your topic" --sort date --max 10`
2. **Assess impact**: `curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:ID?fields=citationCount,influentialCitationCount"`
3. **Read abstract**: WebFetch on `https://arxiv.org/abs/ID`
4. **Read full paper**: WebFetch on `https://arxiv.org/pdf/ID`
5. **Find related work**: citations/references endpoints from [semantic-scholar.md](references/semantic-scholar.md)
6. **Get recommendations**: POST to the recommendations endpoint, same reference
7. **Track authors**: author search endpoint, same reference

## Rate Limits

| API | Rate | Auth |
|-----|------|------|
| arXiv | ~1 req / 3 seconds | None needed |
| Semantic Scholar | 1 req / second | None (100/sec with API key) |

## Notes

- arXiv returns Atom XML — use the helper script for clean output; Semantic Scholar returns JSON — pipe through `python3 -m json.tool`
- PDF: `https://arxiv.org/pdf/{id}` — Abstract: `https://arxiv.org/abs/{id}`
- For local PDF processing, see the `ocr-and-documents` skill
