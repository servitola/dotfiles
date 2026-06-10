# Review Comments Deep Dive

How PR feedback is structured on GitHub and how to fetch / answer / resolve every piece of it. The fast path is the bundled script — this file covers what it does under the hood and the fallbacks.

## The Three Comment Types

| Type | Where it lives | REST endpoint | Caveat |
|------|----------------|---------------|--------|
| Conversation comments | PR "Conversation" tab | `/issues/N/comments` | Issue comments, not "review comments" |
| Review submissions | Approve / Request changes / Comment | `/pulls/N/reviews` | Body may be empty |
| Inline review threads | Specific file:line in the diff | `/pulls/N/comments` | REST returns a flat list — no thread grouping, no resolved state |

Only the GraphQL API exposes inline comments **grouped into threads** with `isResolved` / `isOutdated` flags, which is exactly what you need to know what still requires action. That's why the bundled script uses `gh api graphql`.

## Bundled Script: `scripts/fetch_comments.py`

```bash
python3 ~/projects/dotfiles/claude-code/skills/github-pr-workflow/scripts/fetch_comments.py > /tmp/pr_comments.json
```

- Resolves the PR for the current branch via `gh pr view` (handles cross-repo/fork PRs by reading the head repository owner/name).
- Runs one GraphQL query that fetches all three comment types at once, **cursor-paginated** (100 per page per connection) — it loops until `hasNextPage` is false on all three connections, so nothing is dropped on busy PRs.
- Output JSON shape:

```json
{
  "pull_request": { "number": 1, "url": "...", "title": "...", "state": "OPEN", "owner": "...", "repo": "..." },
  "conversation_comments": [ { "id", "body", "createdAt", "author": {"login"} } ],
  "reviews":               [ { "id", "state", "body", "submittedAt", "author": {"login"} } ],
  "review_threads":        [ { "id", "isResolved", "isOutdated", "path", "line", "resolvedBy",
                               "comments": { "nodes": [ { "id", "databaseId", "body", ... } ] } } ]
}
```

The `review_threads[].id` is the GraphQL node id you pass to `resolveReviewThread`. Each thread comment carries both `id` (GraphQL node id) and `databaseId` (numeric REST id) — the latter is what the REST `replies` endpoint needs. Filter to `isResolved == false` for the actionable list.

## Manual GraphQL (no script)

The core query the script runs — usable directly with `gh api graphql` (pass the query via `-F query=@-` on stdin to avoid quoting issues):

```graphql
query($owner: String!, $repo: String!, $number: Int!, $threadsCursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      comments(first: 100) { nodes { body author { login } } }
      reviews(first: 100)  { nodes { state body author { login } } }
      reviewThreads(first: 100, after: $threadsCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id isResolved isOutdated path line
          comments(first: 100) { nodes { id body author { login } } }
        }
      }
    }
  }
}
```

Re-run with `after:` cursors while any `hasNextPage` is true.

## curl Fallback (no gh)

GraphQL works with a plain token too:

```bash
curl -s -X POST https://api.github.com/graphql \
  -H "Authorization: bearer $GITHUB_TOKEN" \
  -d @- <<'EOF'
{"query": "query { repository(owner: \"OWNER\", name: \"REPO\") { pullRequest(number: N) { reviewThreads(first: 100) { nodes { id isResolved path line comments(first: 100) { nodes { body author { login } } } } } } } }"}
EOF
```

REST-only alternative (loses thread grouping and resolved state — last resort):

```bash
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments?per_page=100"
```

## Replying and Resolving

```bash
# Reply inside an inline thread. COMMENT_ID is the numeric REST id (databaseId)
# of any comment in the thread — usually the first one.
gh api "repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments/$COMMENT_ID/replies" \
  -f body="Fixed in $(git rev-parse --short HEAD)"

# Resolve / unresolve a thread (GraphQL node id from reviewThreads.nodes[].id)
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "<THREAD_ID>"}) { thread { isResolved } } }'
gh api graphql -f query='mutation { unresolveReviewThread(input: {threadId: "<THREAD_ID>"}) { thread { isResolved } } }'

# Reply on the conversation tab (general response, not tied to a line)
gh pr comment $PR_NUMBER --body "Addressed the review feedback in the latest commits."
```

Note: GraphQL node ids (`PRRC_...`) and numeric REST ids are different things. The bundled script's output already includes both per thread comment: use `comments.nodes[].databaseId` for the REST `replies` endpoint and `review_threads[].id` for the GraphQL resolve mutations. If you write your own query, request `databaseId` explicitly (or reply via GraphQL `addPullRequestReviewThreadReply` instead).

## Etiquette for Agents

- Address only the items the user selected; list the rest as "not addressed" in your summary.
- Reply with **what changed and where** (short SHA or path), not just "done".
- Resolve a thread only when the underlying request is actually fixed; if the comment is a question, answer it and leave the thread open for the reviewer.
- If a comment is outdated (`isOutdated: true`) because the code moved on, say so in the reply instead of force-fitting a change.
