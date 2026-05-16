# Deploy Skill

## Standard deploy flow

1. Run all tests/linters for changed files
2. Sync changed scripts to server via scp/rsync
3. Restart affected services (systemd)
4. Verify service is running and responding
5. Commit with descriptive message if not already committed

## Staged rollout (when feature ships behind a flag)

For anything user-visible or risk-bearing, decouple deploy from
release: ship the code with the flag OFF, then enable it in stages.

```
1. Deploy with flag OFF                → code live, inactive
2. Enable for team / internal users    → 24h soak
3. Canary 5% of users                  → 24–48h soak
4. Gradual 25% → 50% → 100%            → roll back at any step
5. Full rollout, monitor 1 week
6. Clean up flag (within 2 weeks)
```

At each stage check the metrics against the thresholds below. Do not
advance on "looks fine" — advance only when numbers say green.

### Rollout decision thresholds

| Metric           | Advance (green)        | Hold (yellow)             | Roll back (red)         |
|------------------|------------------------|---------------------------|-------------------------|
| Error rate       | within 10% of baseline | 10–100% above baseline    | >2× baseline            |
| P95 latency      | within 20% of baseline | 20–50% above baseline     | >50% above baseline     |
| Client JS errors | no new error types     | new errors <0.1% sessions | new errors >0.1% sess   |
| Business metrics | neutral or positive    | decline <5% (may be noise)| decline >5%             |

Pick baselines from the 24h window before deploy. If a baseline is
unstable, hold and investigate before advancing.

### Rollback trigger conditions (any one triggers immediate rollback)

- Error rate > 2× baseline
- P95 latency increase > 50%
- Spike in user-reported issues
- Data-integrity issue detected
- Newly discovered security vulnerability
- Unauthorised "Ask first" change reached prod (see security-auditor)

### Rollback plan template (write before deploy, not during incident)

```
## Rollback Plan — {feature}

Trigger conditions:
- {numeric trigger 1}
- {numeric trigger 2}

Rollback steps:
1. Disable feature flag    (≈1 min)        OR
   Redeploy previous tag   (≈5 min)
2. Verify rollback: health check + error dashboard
3. Notify team in {channel}

Database considerations:
- Migration {X}: rollback path = {command} / no rollback needed
- Data written by new feature: {preserved | cleaned up by {script}}

Time-to-rollback target: {flag <1 min | redeploy <5 min | DB <15 min}
```

Without a written rollback plan, the deploy is not approved.
