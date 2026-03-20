---
description: >
  Pre-production security gate that must pass before code reaches staging or production.
  Orchestrates static analysis, dependency scanning, and secret detection with clear 
  pass/fail criteria. Use when: (1) preparing code for deployment, (2) running final 
  security checks before release, (3) validating pull requests to protected branches,
  (4) setting up CI/CD security gates.
globs: ["**/*"]
alwaysApply: false
tags: [product]
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

## OWASP Top 10 for Agentic Applications (2026)

If your project uses AI agents (Cursor agents, LLM-powered features, or autonomous workflows), scan for these agentic-specific risks in addition to standard OWASP Top 10:

| Risk | Description | What to Check |
|------|-------------|---------------|
| **Prompt Injection** | Malicious input redirects agent behaviour | Inputs to LLM APIs validated and sanitised |
| **Excessive Agency** | Agent granted more permissions than needed | Principle of least privilege on all agent actions |
| **Insecure Output Handling** | Agent output used without validation | AI-generated code reviewed before execution |
| **Data Exfiltration** | Agent leaks data via tools or API calls | Egress controls on agent network access |
| **Memory Poisoning** | Malicious data stored in agent context/memory | Context sources trusted and validated |
| **Supply Chain Compromise** | Malicious plugins, MCP servers, or tools | Verify all installed plugins and MCP servers; pin MCP versions; see MCP Security skill |
| **Uncontrolled Resource Use** | Agent spawns expensive loops or subagents | Rate limits on agent tool calls and spawning |

## MCP Configuration Security (Feb 2026)

### CVE-2025-54136: MCPoison Trust Bypass

A critical vulnerability was disclosed (August 2025) in Cursor's MCP system. Once a user approves an MCP configuration, Cursor never re-checks it — allowing an attacker to silently modify the MCP after approval and gain persistent remote code execution.

**Add this to your security gate:**

```bash
# 1. Check for unpinned MCP versions (red flag)
grep -r '"args"' .cursor/mcp.json | grep -v '@[0-9]' && echo "WARNING: Unpinned MCP versions found"

# 2. Verify MCP configs haven't changed since last known-good state
if [ -f .cursor/mcp.json.checksum ]; then
  md5sum -c .cursor/mcp.json.checksum || echo "SECURITY: MCP config changed since last verification"
fi

# 3. Check for hardcoded credentials in MCP config
grep -E '(password|secret|key|token)\s*[:=]\s*["\x27][a-zA-Z0-9]{8,}' .cursor/mcp.json && echo "CRITICAL: Hardcoded credential in MCP config"
```

**Gate criteria:**
- ❌ Any unpinned MCP package version → Block and require pinning
- ❌ Hardcoded credentials in MCP config → Block immediately, rotate credentials
- ⚠️ MCP config changed since last review → Require human review before deployment

> See the **MCP Security** skill for full MCP governance guidance.

## Cursor Hooks (Enterprise Teams)

If your organisation uses Cursor for Teams or Enterprise, leverage **Cursor Hooks** to enforce the security gate at the IDE level:

Hooks run custom scripts before or after defined stages of the agent loop and can observe, block, or modify behaviour. Use them to:

```yaml
# Example hook configuration (cursor-hooks.json)
{
  "hooks": [
    {
      "event": "pre-tool-use",
      "script": "scripts/hooks/check-secret-patterns.sh",
      "description": "Block agent from using tools that would expose secrets"
    },
    {
      "event": "pre-deploy",
      "script": "scripts/hooks/run-security-gate.sh",
      "description": "Run full security gate before any deployment action"
    },
    {
      "event": "post-file-write",
      "script": "scripts/hooks/scan-written-file.sh",
      "description": "Scan files the agent writes for credentials or PII"
    }
  ]
}
```

**Hook capabilities:**
- Connect to your SIEM, secrets manager, or compliance system
- Block agent actions that violate policy before they execute
- Audit trail of every agent action for compliance reporting
- Enforce organisation-wide egress policies in the sandbox

> See Cursor docs for enterprise hooks setup: https://cursor.com/blog/hooks-partners

## Sandbox Network Controls (Feb 2026)

Cursor's sandbox now supports granular network access controls. Use them to restrict what the agent can reach during code execution:

```json
// .cursor/sandbox.json
{
  "network": {
    "mode": "allowlist",
    "allow": [
      "api.github.com",
      "registry.npmjs.org",
      "pypi.org"
    ],
    "deny": [
      "*.internal.company.com"  // Never expose internal services to agent
    ]
  },
  "filesystem": {
    "deny": ["~/.ssh", "~/.aws", "~/.config"]
  }
}
```

Enterprise admins can enforce these policies org-wide from the Cursor admin dashboard.

## When to Skip (Rarely)

The security gate can only be skipped with:
1. Documented business justification
2. Approval from security lead
3. Compensating controls in place
4. Time-limited exception with remediation plan

Never skip for convenience. Security debt compounds.