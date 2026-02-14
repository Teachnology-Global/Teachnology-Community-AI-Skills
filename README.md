# Cursor Governance Skills

[![MIT Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](LICENSE)
[![Cursor Compatible](https://img.shields.io/badge/Cursor-Compatible-purple.svg)](https://cursor.com)
[![14 Skills](https://img.shields.io/badge/skills-14-green.svg)](#whats-included)
[![Australian Made](https://img.shields.io/badge/made%20in-Australia%20🇦🇺-gold.svg)](https://www.skool.com/teachnology)

**Stop your AI from shipping insecure, undocumented rubbish.** Drop these governance skills into any Cursor project and your AI assistant will follow proper security, privacy, accessibility, and quality standards - automatically, every time.

No plugins. No config servers. Just copy the files and go.

Built for the [Teachnology Community](https://www.skool.com/teachnology) by Jason La Greca.

---

## Before and After

| Without Governance | With Governance |
|---|---|
| AI hardcodes API keys in source files | AI uses environment variables, flags any secrets |
| AI skips alt text, breaks keyboard navigation | AI follows WCAG 2.1 AA, checks contrast and ARIA |
| AI installs GPL packages in your MIT project | AI checks every licence before adding dependencies |
| AI logs user emails and phone numbers in plaintext | AI flags PII in logs, enforces encryption |
| AI makes architecture changes without asking | AI pauses, explains the tradeoff, waits for your call |
| AI ships without tests or documentation | AI enforces 80% coverage, generates changelogs and ADRs |

---

## Quick Start (5 minutes)

### 1. Copy to your project

```bash
git clone https://github.com/Teachnology-Global/cursor-governance-skills.git
cp -r cursor-governance-skills/.cursor /path/to/your/project/
cp cursor-governance-skills/.cursorrules /path/to/your/project/
cp cursor-governance-skills/governance.yaml /path/to/your/project/
```

### 2. Open your project in Cursor

The skills activate automatically. That's it. Open Cursor, start coding, and your AI now follows governance rules.

### 3. Customise (optional)

Edit `governance.yaml` to adjust thresholds for your project:

```yaml
skills:
  security:
    severity_threshold: high    # or medium, low, critical
  testing:
    coverage:
      minimum: 80               # your coverage target
  accessibility:
    level: "AA"                 # A, AA, or AAA
```

---

## Verify It Works

After installation, paste this into a file in Cursor and ask the AI to review it:

```python
password = "admin123"
api_key = "sk_live_abc123456789"
print(f"User logged in: {user.email}")
```

Your AI should flag all three lines - hardcoded password, exposed API key, and PII in logs. If it does, governance is working.

You can also try: "Run pre-release checklist" and watch it walk through all 14 governance gates.

---

## What's Included

### 14 Skills

| Skill | What It Does | Always On? |
|-------|-------------|------------|
| **Security Gate** | Blocks deployments with vulnerabilities. Runs SAST, SCA, secret detection. | No |
| **Human Approval** | Pauses AI when it deviates from your PRD or touches security/privacy code. | **Yes** |
| **Code Quality** | Enforces linting, complexity limits (cyclomatic <= 10), formatting. | **Yes** |
| **Privacy Guard** | Validates GDPR/CCPA compliance. Catches PII in logs, unencrypted data. | No |
| **Accessibility** | WCAG 2.1 Level AA. Semantic HTML, keyboard nav, contrast, ARIA. | No |
| **Documentation** | Generates ADRs, changelogs, API docs, migration guides. | No |
| **Testing Standards** | Enforces coverage (>= 80%), test quality, proper patterns. | No |
| **Licence Compliance** | Prevents GPL contamination. Validates every dependency licence. | No |
| **Pre-Release** | Orchestrates all skills into a single go/no-go release gate. | No |
| **Test Plan** | Generates test plans from PRDs with full requirements traceability. | No |
| **Browser Testing** | E2E testing with Cursor's @Browser tools. Screenshots at every step. | No |
| **Test Automation** | Generates Playwright/Cypress test suites from test plans. | No |
| **Dependency Scanning** | Catches vulnerable, outdated, and risky packages. Supply chain checks. | No |
| **Secrets Management** | Keeps credentials out of code, logs, and git. Rotation policies. | No |

### Scripts

| Script | Platform | Purpose |
|--------|----------|---------|
| `security-scan.sh` | macOS/Linux | Run SAST, SCA, and secret detection |
| `security-scan.ps1` | Windows | Same scans, PowerShell |
| `privacy-scan.py` | All (Python 3.8+) | Scan for PII handling issues |
| `a11y-audit.js` | All (Node 18+) | Accessibility audit |
| `init-project.sh` | macOS/Linux | One-command project setup |
| `init-project.ps1` | Windows | One-command project setup |
| `github-workflow.yml` | GitHub Actions | CI/CD governance pipeline |

### Templates

Ready-to-use templates for: Architecture Decision Records, changelogs, human approval logs, PRDs, privacy impact assessments, security exceptions, and test plans.

### Guides

- **Next.js + Vercel + Neon setup** - step-by-step for that specific stack
- **Testing workflow** - how the three testing skills work together

---

## How It Works

```
You write code in Cursor
        |
        v
+----------------------------+
|  .cursorrules loaded       | <- AI reads governance rules
|  Skills activate on        |
|  context (file type,       |
|  keywords, always-on)      |
+-------------+--------------+
              |
              v
+----------------------------+
|  AI follows governance:    |
|  - Checks security         |
|  - Pauses for approval     |
|  - Validates privacy       |
|  - Enforces quality        |
|  - Documents decisions     |
+-------------+--------------+
              |
              v
+----------------------------+
|  Pre-Release Gate          |
|  All checks must pass      |
|  before shipping           |
+----------------------------+
```

---

## Try It

Once installed, say any of these to your AI in Cursor:

- "Run security gate before deployment"
- "Check privacy compliance on this feature"
- "Generate a test plan from the PRD"
- "Is this accessible?"
- "Run pre-release checklist"
- "What licences are in my dependencies?"

The AI knows what to do.

---

## Project Structure

```
.cursor/skills/          <- 14 governance skills
.cursorrules             <- Cursor AI rules (auto-loaded)
governance.yaml          <- Project configuration
scripts/                 <- Security, privacy, a11y scanning
templates/               <- ADR, changelog, PIA, PRD, test plan
guides/                  <- Setup and workflow guides
```

---

## Requirements

**Required:**
- Cursor IDE

**Optional (for automated scanning):**
- [Semgrep](https://semgrep.dev/) for SAST
- [Trivy](https://trivy.dev/) for dependency scanning
- [Gitleaks](https://gitleaks.io/) for secret detection
- Python 3.8+ for privacy scanning
- Node.js 18+ for accessibility auditing

---

## Contributing

1. Fork it
2. Create a feature branch
3. Follow the governance standards (obviously)
4. Submit a PR

---

## Licence

MIT. Use it, modify it, share it.

---

Built with love and mild paranoia about shipping insecure code. 🇦🇺
