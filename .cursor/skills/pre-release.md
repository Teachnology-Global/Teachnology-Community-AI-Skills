---
description: >
  Orchestrates all governance checks before release. Runs security gate, privacy
  compliance, accessibility audit, license check, and documentation validation as
  a unified pre-release checklist. Use when: (1) preparing for deployment,
  (2) final release validation, (3) production readiness review, (4) go/no-go decision.
globs: ["**/*"]
alwaysApply: false
---

# Pre-Release Checklist

## Purpose

Ensure all governance requirements are met before code reaches production. This skill orchestrates all other skills into a unified release gate.

## Activation

This skill activates when you mention:
- "release", "deploy", "ship"
- "production", "go live"
- "pre-release", "release checklist"
- "ready for production", "production readiness"
- "go/no-go", "release approval"

## Release Gate Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    PRE-RELEASE GATE                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Security Gate ──────────────────────────► Pass/Fail     │
│     └── SAST, SCA, Secrets, Container, IaC                  │
│                                                             │
│  2. Privacy Compliance ─────────────────────► Pass/Fail     │
│     └── PII handling, consent, encryption                   │
│                                                             │
│  3. Accessibility Audit ────────────────────► Pass/Fail     │
│     └── WCAG 2.1 AA compliance                              │
│                                                             │
│  4. License Compliance ─────────────────────► Pass/Fail     │
│     └── Dependency license validation                       │
│                                                             │
│  5. Code Quality ───────────────────────────► Pass/Fail     │
│     └── Linting, complexity, coverage                       │
│                                                             │
│  6. Testing ────────────────────────────────► Pass/Fail     │
│     └── Unit, integration, e2e coverage                     │
│                                                             │
│  7. Documentation ──────────────────────────► Pass/Fail     │
│     └── Changelog, ADRs, API docs                           │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  ALL PASS ──► ✅ RELEASE APPROVED                           │
│  ANY FAIL ──► ❌ RELEASE BLOCKED                            │
└─────────────────────────────────────────────────────────────┘
```

## Checklist

### 1. Security Gate

| Check | Status | Notes |
|-------|--------|-------|
| SAST scan passed | [ ] | Zero critical/high |
| SCA scan passed | [ ] | No vulnerable dependencies |
| Secret scan passed | [ ] | No secrets detected |
| Container scan passed | [ ] | If applicable |
| IaC scan passed | [ ] | If applicable |
| Security exceptions documented | [ ] | If any |

**Commands:**
```bash
# Run security scans
./scripts/security-scan.sh         # Unix
./scripts/security-scan.ps1        # Windows

# Or individually
semgrep --config=auto --severity=ERROR .
trivy fs --severity CRITICAL,HIGH .
gitleaks detect --source=.
```

### 2. Privacy Compliance

| Check | Status | Notes |
|-------|--------|-------|
| PII fields identified | [ ] | |
| Encryption verified | [ ] | At rest and transit |
| Consent mechanisms working | [ ] | |
| Deletion capability tested | [ ] | Right to erasure |
| PIA completed | [ ] | If required |
| Privacy scan passed | [ ] | No critical findings |

**Commands:**
```bash
python scripts/privacy-scan.py --severity high
```

### 3. Accessibility Audit

| Check | Status | Notes |
|-------|--------|-------|
| Automated scan passed | [ ] | axe-core, WAVE |
| Keyboard navigation tested | [ ] | |
| Screen reader tested | [ ] | VoiceOver, NVDA |
| Color contrast verified | [ ] | 4.5:1 minimum |
| Focus management correct | [ ] | |
| No critical/serious issues | [ ] | |

**Commands:**
```bash
node scripts/a11y-audit.js --severity serious
npm run test:a11y
```

### 4. License Compliance

| Check | Status | Notes |
|-------|--------|-------|
| All licenses identified | [ ] | |
| No GPL/AGPL contamination | [ ] | |
| License exceptions documented | [ ] | |
| Third-party attributions complete | [ ] | |

**Commands:**
```bash
npx license-checker --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC"
npx license-checker --failOn "GPL-2.0;GPL-3.0;AGPL-3.0"
```

### 5. Code Quality

| Check | Status | Notes |
|-------|--------|-------|
| Linting passed | [ ] | Zero errors |
| Type checking passed | [ ] | Zero errors |
| Complexity within limits | [ ] | Cyclomatic ≤ 10 |
| No TODO/FIXME without tickets | [ ] | |

**Commands:**
```bash
npm run lint
npm run typecheck
```

### 6. Testing

| Check | Status | Notes |
|-------|--------|-------|
| All tests passing | [ ] | |
| Coverage ≥ 80% | [ ] | Lines, branches |
| No flaky tests | [ ] | |
| Critical paths covered | [ ] | |
| Regression tests for bugs | [ ] | |

**Commands:**
```bash
npm test -- --coverage
npm run test:e2e
```

### 7. Documentation

| Check | Status | Notes |
|-------|--------|-------|
| CHANGELOG.md updated | [ ] | For all changes |
| ADRs created | [ ] | For architecture decisions |
| API docs updated | [ ] | If endpoints changed |
| Migration guide written | [ ] | If breaking changes |
| README accurate | [ ] | |

### 8. Human Approvals

| Approval | Status | Approver | Date |
|----------|--------|----------|------|
| Engineering Lead | [ ] | | |
| Security Review | [ ] | | |
| Product Owner | [ ] | | |
| QA Sign-off | [ ] | | |

## Release Report Format

```markdown
# Release Report

## Release Information
- **Version**: [version]
- **Date**: [date]
- **Release Manager**: [name]

## Gate Results

| Gate | Status | Details |
|------|--------|---------|
| Security | ✅ PASS | 0 critical, 0 high, 2 medium |
| Privacy | ✅ PASS | All PII encrypted |
| Accessibility | ✅ PASS | WCAG 2.1 AA compliant |
| Licenses | ✅ PASS | All permissive |
| Code Quality | ✅ PASS | 0 lint errors |
| Testing | ✅ PASS | 87% coverage |
| Documentation | ✅ PASS | Changelog updated |

## Summary
**Overall Status**: ✅ APPROVED FOR RELEASE

## Risk Assessment
[Any known issues or risks going to production]

## Rollback Plan
[How to revert if issues occur]

## Monitoring Plan
[Key metrics to watch post-release]

## Approvals
- [ ] Engineering Lead: [name] [date]
- [ ] Security: [name] [date]
- [ ] Product: [name] [date]
```

## Failure Handling

### If Security Fails
1. Stop release process
2. Document all findings
3. Prioritize fixes (critical first)
4. Re-run scans after fixes
5. Require security sign-off

### If Privacy Fails
1. Stop release process
2. Conduct PIA if not done
3. Implement required controls
4. Get DPO approval

### If Accessibility Fails
1. Block for critical/serious issues
2. Document exceptions for moderate/minor
3. Create remediation tickets
4. Set deadline for fixes

### If Any Gate Fails
1. Do NOT proceed with release
2. Document the failure
3. Create action items
4. Set remediation timeline
5. Re-run full checklist after fixes

## Emergency Release

For critical production fixes:

1. **Document the emergency**
   - What's broken?
   - Impact assessment
   - Why can't it wait?

2. **Get expedited approval**
   - Engineering Lead: Required
   - Security: Required for security-related
   - Product: Informed

3. **Minimum gates for emergency**
   - [ ] Security scan (critical/high only)
   - [ ] Basic smoke test
   - [ ] Rollback tested

4. **Post-emergency**
   - Full checklist within 24 hours
   - Incident report
   - Process improvement

## Integration

This skill orchestrates:
- `security-gate.md`
- `privacy-guard.md`
- `accessibility.md`
- `license-compliance.md`
- `code-quality.md`
- `testing-standards.md`
- `documentation.md`

All sub-skills must pass for release approval.

## CI/CD Integration

```yaml
# .github/workflows/release-gate.yml
name: Release Gate

on:
  push:
    branches: [release/*, main]
  workflow_dispatch:

jobs:
  security:
    # ... security checks
  
  privacy:
    # ... privacy checks
    
  accessibility:
    # ... a11y checks
    
  licenses:
    # ... license checks
    
  quality:
    # ... quality checks
    
  tests:
    # ... test suite
    
  documentation:
    # ... doc checks

  release-decision:
    needs: [security, privacy, accessibility, licenses, quality, tests, documentation]
    runs-on: ubuntu-latest
    steps:
      - name: Check all gates
        run: |
          echo "All gates passed - release approved"
```

