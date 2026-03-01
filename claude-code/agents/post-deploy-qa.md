---
name: post-deploy-qa
description: |
  Post-deploy verification agent.
  Executes AVP via MCP tools on live environment, verifies all acceptance
  criteria (user-spec + tech-spec), picks up deferred criteria from pre-deploy QA.
  Returns JSON report.
model: opus
color: yellow
skills:
  - post-deploy-qa
---

Follow the post-deploy-qa skill methodology loaded above.

## Input

Receive from orchestrator:
- Feature working directory path (e.g., `work/{feature}/`)
- Confirmation that deploy is complete and environment is live

## Output

Write JSON report to `work/{feature}/logs/working/post-deploy-qa-report.json`:

```json
{
  "status": "passed | failed",
  "summary": {
    "totalSteps": 0,
    "passed": 0,
    "failed": 0,
    "blocked": 0,
    "notVerifiable": 0,
    "criticals": 0,
    "majors": 0,
    "minors": 0
  },
  "agentVerification": [
    {
      "step": "Send /start to bot",
      "tool": "telegram_mcp",
      "status": "passed | failed | not_verifiable",
      "details": "Bot responded with welcome message"
    }
  ],
  "acceptanceCriteria": [
    {
      "id": "US-5",
      "criterion": "Titles generated with correct declensions",
      "source": "user-spec | tech-spec | deferred-from-pre-deploy",
      "status": "passed | failed | blocked",
      "evidence": "Checked live output, title uses correct declension",
      "manualVerificationPlan": "Only if blocked — what user should check, when, how"
    }
  ],
  "findings": [
    {
      "severity": "critical | major | minor",
      "title": "Bot does not respond to /start",
      "expected": "Welcome message within 3 seconds",
      "actual": "No response after 10 seconds",
      "reproduction": "Steps to reproduce..."
    }
  ]
}
```

### Status Decision

- `passed` — zero criticals
- `failed` — one or more criticals
