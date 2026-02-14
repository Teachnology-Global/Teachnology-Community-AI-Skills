---
description: >
  Pre-production security gate that must pass before code reaches staging or production.
  Orchestrates static analysis, dependency scanning, and secret detection with clear 
  pass/fail criteria. Use when: (1) preparing code for deployment, (2) running final 
  security checks before release, (3) validating pull requests to protected branches,
  (4) setting up CI/CD security gates.
globs: ["**/*"]
alwaysApply: false
---

# Security Gate

## Purpose

Block deployments that contain security vulnerabilities. Every code change must pass this gate before reaching production.

## Activation

This skill activates when you mention:
- "deploy", "deployment", "release"
- "production", "staging", "pre-production"
- "security scan", "security check", "security gate"
- "ready for release", "ship it"

## Gate Criteria

### Pass (✅ Deploy Allowed)
- Zero critical findings
- Zero high findings  
- No secrets detected
- All scans completed successfully

### Conditional Pass (⚠️ Requires Approval)
- Only medium/low findings exist
- Documented security exceptions
- Human approval obtained

### Fail (❌ Deploy Blocked)
- Any critical finding
- Any high finding
- Any secret detected
- Scan failure

## Scanning Workflow

Execute these checks in order:

### 1. Static Analysis (SAST)

Scan source code for vulnerabilities:

```bash
# Using Semgrep
semgrep --config=auto --severity=ERROR --severity=WARNING --json /path/to/code

# Or using CodeQL (if configured)
codeql database analyze /path/to/db --format=sarif
```

**What to check:**
- SQL injection patterns
- Cross-site scripting (XSS)
- Insecure deserialization
- Hardcoded credentials
- Path traversal
- Command injection

### 2. Dependency Analysis (SCA)

Scan dependencies for known vulnerabilities:

```bash
# Using Trivy
trivy fs --severity CRITICAL,HIGH /path/to/code

# Or using npm/pip native
npm audit --audit-level=high
pip-audit
```

**What to check:**
- Known CVEs in dependencies
- Outdated packages with patches available
- License compliance issues

### 3. Secret Detection

Scan for leaked credentials:

```bash
# Using Gitleaks
gitleaks detect --source=/path/to/code --report-format=json

# Or using TruffleHog
trufflehog filesystem /path/to/code
```

**What to check:**
- API keys
- Database credentials
- Private keys
- OAuth tokens
- AWS/GCP/Azure credentials

### 4. Container Security (If Applicable)

If Dockerfile exists:

```bash
# Scan image
grype dir:/path/to/code -o json

# Lint Dockerfile
hadolint Dockerfile
```

### 5. Infrastructure as Code (If Applicable)

If Terraform/CloudFormation exists:

```bash
# Using Checkov
checkov -d /path/to/code --framework terraform,cloudformation
```

## Severity Classification

| Severity | Examples | Action |
|----------|----------|--------|
| **Critical** | RCE, SQL injection, auth bypass, leaked secrets | Block deployment |
| **High** | XSS, CSRF, sensitive data exposure, critical CVE | Block deployment |
| **Medium** | Weak crypto, missing input validation, medium CVE | Log, review |
| **Low** | Info disclosure, deprecated functions | Log only |

## Report Format

After scanning, present results like this:

```markdown
## 🔒 Security Gate Results

**Status**: [✅ PASSED | ⚠️ CONDITIONAL | ❌ FAILED]
**Scan Date**: [timestamp]
**Commit**: [hash]

### Summary
| Check | Status | Findings |
|-------|--------|----------|
| Static Analysis | ✅ | 0 critical, 0 high, 3 medium |
| Dependencies | ✅ | 0 critical, 0 high |
| Secrets | ✅ | 0 detected |
| Container | ✅ | 0 critical |

### Critical/High Findings
[None - or list each finding with file, line, description, remediation]

### Deployment Decision
[APPROVED for deployment | BLOCKED - fix required | REQUIRES HUMAN APPROVAL]
```

## Human Approval Required

If findings exist but you need to proceed, document the exception:

```markdown
## Security Exception Request

**Finding**: [description]
**Severity**: [level]
**Justification**: [why proceeding despite finding]
**Mitigations**: [compensating controls]
**Approver**: [name]
**Expiration**: [when exception expires]
```

## CI/CD Integration

Add to your pipeline:

```yaml
security-gate:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    
    - name: SAST Scan
      run: semgrep --config=auto --severity=ERROR --severity=WARNING .
      
    - name: Dependency Scan  
      run: trivy fs --severity CRITICAL,HIGH .
      
    - name: Secret Scan
      run: gitleaks detect --source=.
```

## When to Skip (Rarely)

The security gate can only be skipped with:
1. Documented business justification
2. Approval from security lead
3. Compensating controls in place
4. Time-limited exception with remediation plan

Never skip for convenience. Security debt compounds.

