---
description: Answer a question using servitola's dotfiles RAG collection (Qdrant + LiteLLM)
argument-hint: <question>
---

The user's question: $ARGUMENTS

Use the Bash tool to retrieve relevant context from the `dotfiles` Qdrant collection. Invoke the `rag` shell function from `~/projects/dotfiles/rag/rag.sh` with the `context` subcommand:

```
zsh -ic 'source ~/projects/dotfiles/rag/rag.sh && rag context --collection dotfiles --top-k 8 "QUESTION_HERE"'
```

- Replace `QUESTION_HERE` with the exact user question. Escape double-quotes inside the question with `\"`.
- The command prints retrieved chunks as blocks like `[Source N] path=... score=... \n <text>`.
- If `rag` or the containers are unavailable, say so plainly — do not guess.

Then answer the user based strictly on the retrieved context. Cite the source paths (the `path=` values) inline like `[README.md](/Users/servitola/projects/dotfiles/README.md)` so they're clickable. If the context is empty or irrelevant to the question, tell the user directly rather than inventing an answer.

Keep the answer concise. The user prefers no trailing summaries.
