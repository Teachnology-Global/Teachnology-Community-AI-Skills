---
title: "Cursor Governance Skills"
date: 2026-03-20
tags: [product]
status: draft
---

# Cursor Governance Skills

[![MIT Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](LICENSE)
[![Cursor Compatible](https://img.shields.io/badge/Cursor-Compatible-purple.svg)](https://cursor.com)

[![40 Skills](https://img.shields.io/badge/skills-40-green.svg)](#whats-included)
[![Australian Made](https://img.shields.io/badge/made%20in-Australia%20🇦🇺-gold.svg)](https://www.skool.com/teachnology)

**Stop your AI from shipping insecure, undocumented rubbish.** Drop these governance skills into any Cursor project and your AI assistant will follow proper security, privacy, accessibility, and quality standards - automatically, every time.

No plugins. No config servers. Just copy the files and go.

Built for the [Teachnology Community](https://www.skool.com/teachnology) by Jason La Greca.

---

## Before and After

| Without Governance | With Governance |
|---|---|
| AI hardcodes API keys in source files | AI uses environment variables, flags any secrets |
| AI skips alt text, breaks keyboard navigation | AI follows WCAG 2.2 AA, checks contrast and ARIA |
| AI installs GPL packages in your MIT project | AI checks every licence before adding dependencies |
| AI logs user emails and phone numbers in plaintext | AI flags PII in logs, enforces encryption |
| AI makes architecture changes without asking | AI pauses, explains the tradeoff, waits for your call |
| AI ships without tests or documentation | AI enforces 80% coverage, generates changelogs and ADRs |
| AI writes a DROP COLUMN migration and runs it live | AI uses expand-contract, writes rollback, tests on staging |
| AI generates plausible auth code with a logic bug | AI output validation checklist catches the flaw before merge |
| Team pulls a repo — malicious MCP quietly hijacks the IDE | MCP Security skill requires version pinning, audit trails, and re-verification |
| Bugbot Autofix auto-merges a "fix" that breaks auth | Cloud Agent Governance skill requires human review before every agent merge |
| Automation triggered by a Slack message executes injected instructions | Cursor Automations Governance skill requires explicit prompt injection mitigations and event data sanitisation |
| Scheduled automation makes a bad decision in week 1 — compounds for weeks unnoticed | Automations Governance requires weekly output review, memory governance, and auto-approval kill switch |

| PR adds a `.claude/settings.json` with hooks that exfiltrate API keys — nobody reviews it | AI Project Config Security requires CODEOWNERS on all AI config paths and CI flags on changes |
| Solo founder deploys on Friday, Vercel function loops, $400 OpenAI bill by Monday | Cost Governance enforces spending limits, retry caps, and caching before any API integration ships |
| AI feature ships to production — no logs, no alerts, no idea it's hallucinating for 20% of users until support tickets arrive 3 days later | LLM Observability instruments every call with tracing, error rate alerts, and per-user cost tracking from day one |
| Stripe webhook endpoint has no signature verification — attacker sends a fake "payment complete" event and gets paid orders for free | Webhook Security requires HMAC signature verification on every webhook endpoint before any business logic runs |
| Production goes down at 11pm — founder stares at logs for an hour not knowing where to start | Incident Response runbook: confirm, rollback, diagnose, fix — structured steps for the first 30 minutes |
| Founder forgets to set env vars on Vercel, deploys broken auth, users can't log in for 3 hours | Deployment Checklist catches missing env vars, wrong keys, and unrun migrations before the deploy button |
| AI builds a contact form — no server-side validation, user input passed straight to the DB | Input Validation skill requires parameterised queries, schema validation, and server-side checks on every endpoint |
| AI adds an OpenAI chat feature — no max_tokens, no spend limit, 10× traffic spike costs $800 overnight | AI Cost Management skill enforces spend caps, max_tokens on every call, per-user rate limits, and pre-launch cost estimation |

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

You can also try: "Run pre-release checklist" and watch it walk through all 17 governance gates.

---

## What's Included


### 30 Skills

| Skill | What It Does | Always On? |
|-------|-------------|------------|
| **Security Gate** | Blocks deployments with vulnerabilities. Runs SAST, SCA, secret detection. OWASP Agentic Top 10, Cursor Hooks, and MCPoison CVE guidance. | No |
| **Human Approval** | Pauses AI when it deviates from your PRD or touches security/privacy code. | **Yes** |
| **Code Quality** | Enforces linting, complexity limits (cyclomatic <= 10), formatting. | **Yes** |
| **Privacy Guard** | Validates GDPR/CCPA compliance. Catches PII in logs, unencrypted data. | No |
| **Accessibility** | WCAG 2.2 Level AA. Semantic HTML, keyboard nav, contrast, ARIA. 2026 compliance ready. | No |
| **Documentation** | Generates ADRs, changelogs, API docs, migration guides. | No |
| **Testing Standards** | Enforces coverage (>= 80%), test quality, proper patterns. | No |
| **Licence Compliance** | Prevents GPL contamination. Validates every dependency licence. | No |
| **Pre-Release** | Orchestrates all skills into a single go/no-go release gate. | No |
| **Test Plan** | Generates test plans from PRDs with full requirements traceability. | No |
| **Browser Testing** | E2E testing with Cursor's @Browser tools. Screenshots at every step. | No |
| **Test Automation** | Generates Playwright/Cypress test suites from test plans. | No |
| **Dependency Scanning** | Catches vulnerable, outdated, and risky packages. OWASP 2026 supply chain checks. | No |
| **Secrets Management** | Keeps credentials out of code, logs, and git. Rotation policies. | No |
| **API Rate Limiting** | Prevents quota exhaustion, service costs, 429 errors. Smart retry logic. | No |
| **Error Handling** | User-friendly errors, graceful degradation, proper logging. | No |
| **Environment Consistency** | Dev/staging/prod parity. Eliminates "works on my machine" issues. | No |
| **Database Migration Safety** | Zero-downtime migrations, expand-contract pattern, rollback scripts. Neon-specific guidance. | No |
| **AI Output Validation** | Validates AI-generated code before shipping. Catches hallucinated APIs, auth bugs, prompt injection. Updated for Bugbot and Cloud Agent PR review. | No |
| **MCP Security** ⭐ NEW | Governs Model Context Protocol configs. MCPoison CVE-2025-54136 guidance, version pinning, team approval workflows, quarterly audit. | No |
| **Cloud Agent Governance** | Safe delegation to Cursor Cloud Agents and Bugbot Autofix. PR review checklists, repo safeguards, rollback planning for autonomous agent workflows. | No |

| **Cursor Automations Governance** | Governs always-on scheduled and event-triggered agents. Covers event source security, prompt injection via Slack/PR/webhook data, memory governance, auto-approval safeguards, webhook authentication, and incident response. | No |
| **AI Project Config Security** ⭐ NEW | Governs all AI tool config files in repos (.cursor/, .claude/, copilot-instructions). CVE-2025-59536 and CVE-2026-21852 guidance. CODEOWNERS templates, CI integration, review protocol. | No |
| **Deployment Checklist** ⭐ NEW | Focused go/no-go checklist for the "I'm about to press deploy" moment. Platform-specific notes for Vercel, Railway, Fly.io. Rollback protocol. | No |
| **Cost Governance** ⭐ NEW | Prevents surprise bills from OpenAI, Anthropic, Vercel, and database providers. Spending limits, caching patterns, rate limiting, model routing, monthly review process. | No |
| **Incident Response** ⭐ NEW | Structured runbook for when production breaks. First 30 minutes protocol, common incident patterns, communication templates, post-mortem process. | No |
| **Input Validation** ⭐ NEW | Prevents XSS, SQL injection, path traversal, and data corruption. Validation patterns for forms, APIs, file uploads, and URL parameters. Covers AI-generated code red flags. | No |
| **AI Cost Management** | Prevents LLM API bill shock. Token budgeting, per-user rate limits, model selection, prompt caching, spend limits, and production cost estimation. | No |
| **LLM Observability** ⭐ NEW | Instruments AI features for production visibility. Tracing calls, quality monitoring, error alerting, per-user cost tracking. Langfuse integration and DIY logging patterns. | No |
| **Webhook Security** ⭐ NEW | Secures webhook endpoints against forged requests and replay attacks. HMAC verification for Stripe, GitHub, Slack, Clerk. Payload injection prevention for AI automations. | No |

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
- "Audit MCP configurations in this project"
- "Review this agent PR"
- "Set up a Cursor Automation safely"
- "Review my automations for prompt injection risk"

The AI knows what to do.

---

## Marketing Skills (NEW)

10 marketing skills built specifically for education entrepreneurs. Drop them into any project where you're writing copy, planning content, or building your education business.

| Skill | What It Does |
|-------|-------------|
| **brand-context** | Create a positioning document that all other marketing skills reference |
| **content-strategy** | Plan content across newsletter, YouTube, LinkedIn, blog, and community |
| **copy-polish** | Seven-sweep editing framework with the "3pm tired teacher" test |
| **email-nurture** | Email sequence templates: welcome, lead magnet, launch, re-engagement |
| **education-pricing** | Price courses, coaching, and communities without undercharging |
| **education-copywriting** | Write sales pages and landing pages for education businesses |
| **course-page-optimisation** | CRO analysis framework with education-specific benchmarks |
| **education-comparison** | Career path and competitor comparison pages for SEO |
| **education-lead-magnets** | Free tools, quizzes, and templates for lead generation |
| **education-psychology** | 10 behavioural science models adapted for teacher marketing |

**Quick start:** Copy the `skills/` folder into your project, then ask your AI:
- "Create my brand context document"
- "Plan my content strategy for next month"
- "Edit this sales page copy"
- "Design a welcome email sequence"
- "What should I charge for my course?"

---

## Project Structure

```
.cursor/skills/          <- 30 governance skills
skills/                  <- 10 marketing skills for education entrepreneurs
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
