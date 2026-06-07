---
description: >
  Pre-production security gate that must pass before code reaches staging or production.
  Orchestrates static analysis, dependency scanning, secret detection, and Cursor Security Review (beta April 2026).
  Use when: (1) preparing code for deployment, (2) running final
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

## OWASP GenAI Exploit Round-up Q1 2026

OWASP published its Q1 2026 GenAI Exploit Round-up Report (April 2026). Key findings that affect governance:

| Finding | Impact | Mitigation |
|---------|--------|------------|
| **LLM05: Improper Output Handling** | Debug artifacts leaked into production release paths | Strip debug/trace output before production builds |
| **ASI04: Agentic Supply Chain Vulnerabilities** | Agent tooling artifacts became a supply-chain weakness (malicious npm packages targeting AI agent ecosystems) | Pin ALL tool versions; scan agent dependencies separately from app dependencies |
| **Memory Poisoning via AI Chat Logs** | Conversation history containing injected payloads persisted across sessions | Sanitise chat logs before persistence; limit memory scope per session |
| **Denial of Wallet via Token Inflation** | Attackers craft inputs that cause exponential token output | Set hard `max_tokens` limits; implement output size validation |

Reference: [OWASP GenAI Exploit Round-up Q1 2026](https://genai.owasp.org/2026/04/14/owasp-genai-exploit-round-up-report-q1-2026/)

## OWASP Top 10:2025 Reference

The OWASP Top 10 was updated in 2025 with two significant changes from 2021:

| A#:2025 | Category | New In 2025? | Relevance to Cursor Projects |
|---------|----------|-------------|------------------------------|
| **A01** | Broken Access Control | No (still #1) | AI agents must follow least-privilege on repo/secret access |
| **A02** | Security Misconfiguration | ↑ from #5 | AI-generated config (CORS, middleware, CSP) must be reviewed |
| **A03** | Software Supply Chain Failures | NEW (#3) | See dependency-scanning.md — transitive deps, install scripts, lock files |
| **A04** | Cryptographic Failures | No | AI should never implement custom crypto; use established libraries |
| **A05** | Injection | ↓ from #1 | Prompt injection adds an AI-specific injection dimension |
| **A06** | Insecure Design | ↓ from #4 | Architecture review before AI scaffolds a system |
| **A07** | Authentication Failures | No | See api-authentication-security.md |
| **A08** | Software or Data Integrity Failures | No | AI-generated binaries, serialized data, unsigned deps |
| **A09** | Security Logging and Alerting Failures | No | See monitoring-alerting.md |
| **A10** | Mishandling of Exceptional Conditions | NEW (#10) | AI tends to skip error handling; see error-handling.md |

**A10:2025 — Mishandling of Exceptional Conditions** is a brand-new category in the 2025 revision. This directly impacts AI-assisted development because AI models frequently produce code that handles the happy path but omits error cases. The Security Gate should verify:
- Every API call has try/catch or equivalent error handling
- Every database query handles null/not-found cases
- Every async operation has timeout and retry logic
- Unhandled Promise exceptions are not left in code

See **Error Handling** skill for comprehensive patterns.

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

A critical vulnerability was disclosed (August 2025) in Cursor's MCP system. Once a user approves an MCP configuration, Cursor never re-checks it - allowing an attacker to silently modify the MCP after approval and gain persistent remote code execution.

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

## Cursor Security Review (Beta — April 2026)

**Cursor Security Review** launched April 30, 2026 (beta for Teams/Enterprise). This feature runs two types of always-on security agents directly in your workflow:

**Security Reviewer** — checks every PR for:
- Security vulnerabilities
- Auth regressions
- Privacy and data-handling risks
- Agent tool auto-approval issues
- Prompt injection attacks

Leaves inline comments at exact diff locations with severity and remediation.

**Vulnerability Scanner** — scheduled scans of your codebase for:
- Known vulnerabilities
- Outdated dependencies
- Configuration issues
- Slack notifications for findings

**Governance Requirements:**
1. **Enable on all team repos** — Admins should enable in Cursor dashboard
2. **Customise with your own instructions** — Add organisation-specific rules
3. **Integrate MCP scanners** — Plug in your existing SAST/SCA/secrets scanners via MCP servers
4. **Don't disable inline comments** — These are the first line of defence
5. **Review findings as part of PR review** — Treat Security Reviewer inline comments like linter errors — fix before merge

For Teams/Enterprise users: this supplements (not replaces) this Security Gate skill. Security Review catches things at PR time; Security Gate catches things pre-deploy. Use both.

See: [Cursor Security Review docs](https://cursor.com/docs/security-review)

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