---
name: security-scanner
description: Security scanning for vulnerabilities, secrets, dependencies, and code security. Use before commits or deployments.
---

# Security Scanner Skill

Comprehensive security scanning for ${project_name} to identify vulnerabilities before they reach production.

## Scan Categories

### 1. Secrets Detection
Scan for accidentally committed secrets:
- API keys
- Database credentials
- Private keys
- Access tokens
- Passwords

**Tools**: gitleaks, truffleHog, detect-secrets

```bash
# Run secrets scan
gitleaks detect --source . --verbose
trufflehog git file://. --only-verified
```

### 2. Dependency Vulnerabilities
Check for known vulnerabilities in dependencies:

**Tools**: npm audit, pip-audit, osv-scanner, dependabot

```bash
# Node.js
npm audit
npm audit fix

# Python
pip-audit
safety check

# Multi-language
osv-scanner -r .
```

### 3. Code Security
Static analysis for security issues:

**Tools**: semgrep, bandit (Python), eslint-plugin-security

```bash
# General
semgrep --config auto .

# Python
bandit -r .

# JavaScript
eslint --plugin security .
```

### 4. Container Security
Scan Docker images for vulnerabilities:

**Tools**: docker scout, trivy, grype

```bash
docker scout cve <image>
trivy image <image>
grype <image>
```

### 5. Infrastructure Security
Check IaC configurations:

**Tools**: checkov, tfsec, terrascan

```bash
checkov -d .
tfsec .
```

## Pre-Commit Checklist

```bash
# Run all security checks
make security-scan

# Or individual checks
npm audit --production
pip-audit
gitleaks detect
semgrep --config auto .
```

## GitHub Actions Integration

```yaml
name: Security Scan
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Dependency Audit
        run: npm audit --audit-level=high

      - name: Secrets Scan
        uses: gitleaks/gitleaks-action@v2

      - name: Code Scan
        uses: returntocorp/semgrep-action@v1
```

## Remediation Steps

1. **Secrets Found**: Rotate immediately, remove from history
2. **Vulnerable Dependencies**: Update to patched versions
3. **Code Issues**: Fix according to tool recommendations
4. **Container Issues**: Update base images, rebuild

## Reporting

Generate security report:
```markdown
## Security Scan Report

### Summary
- Secrets found: 0
- Vulnerable dependencies: 2
- Code issues: 5

### Critical Issues
[List critical issues requiring immediate attention]

### Recommendations
[Action items for security improvements]
```
