---
title: "Cursor Governance Skills"
date: 2026-03-20
tags: [product]
status: draft
---

# Cursor Governance Skills

[![MIT Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](LICENSE)
[![Cursor Compatible](https://img.shields.io/badge/Cursor-Compatible-purple.svg)](https://cursor.com)

[![43 Skills](https://img.shields.io/badge/skills-43-green.svg)](#whats-included)
[![Australian Made](https://img.shields.io/badge/made%20in-Australia%20🇦🇺-gold.svg)](https://www.skool.com/teachnology)

**Stop your AI from shipping insecure, undocumented rubbish.** Drop these governance skills into any Cursor project and your AI assistant will follow proper security, privacy, accessibility, and quality standards - automatically, every time.

**Last updated:** July 6, 2026 — Added Supply Chain Security skill covering June 2026 npm supply chain attacks (node-gyp worm, Red Hat Miasma campaign). Updated MCP Security and Cursor SDK with June 2026 threats and Team MCPs expansion.

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
| Feature flag created to bypass auth for "testing" — left enabled in production for 6 months | Feature Flag Governance enforces naming conventions, 90-day max lifespan, security red lines (never control auth/payments via flags), and mandatory cleanup tickets |
| Production goes down at 11pm — founder stares at logs for an hour not knowing where to start | Incident Response runbook: confirm, rollback, diagnose, fix — structured steps for the first 30 minutes |
| Founder forgets to set env vars on Vercel, deploys broken auth, users can't log in for 3 hours | Deployment Checklist catches missing env vars, wrong keys, and unrun migrations before the deploy button |
| AI builds a contact form — no server-side validation, user input passed straight to the DB | Input Validation skill requires parameterised queries, schema validation, and server-side checks on every endpoint |
| AI adds an OpenAI chat feature — no max_tokens, no spend limit, 10× traffic spike costs $800 overnight | AI Cost Management skill enforces spend caps, max_tokens on every call, per-user rate limits, and pre-launch cost estimation |
| App ships with no uptime monitoring — founder discovers site was down for 6 hours via a user email | Monitoring & Alerting skill installs Sentry + BetterStack, builds a `/api/health` endpoint, and sets alert rules before launch |
| AI processes user reviews, emails, and web content — hidden instructions in that content hijack AI behaviour to leak data or perform unauthorised actions | Prompt Injection Defense requires input sanitisation, output validation, and prompt boundary design for every external data pipeline |
| Founder pushes secret to git, removes it next commit, thinks it's fine — secret is still in git history forever | Git Security enforces branch protection, CODEOWNERS, pre-commit secret scanning, and teaches the critical "secrets in history are leaked" lesson |
| Team member writes vague prompt "make it better" — AI adds 5 unsolicited features, breaks existing UX | LLM Agent Governance requires scoped instructions, output verification, and a daily agent checklist before session end |
| Agent with shell access runs `rm -rf` on wrong directory, cascading failure corrupts 3 connected repos | Agentic AI Security enforces least-privilege tool access, circuit breakers on repeated failures, and explicit autonomy boundaries per agent |
| Founder runs `npm install` on a package with malicious `preinstall` hook — credentials stolen before code even runs | Supply Chain Security disables install scripts by default, requires package vetting, pins exact versions, and runs weekly audits |

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
    minimum_coverage: 80        # or 70, 90, whatever works
```

---

## What's Included

### Security (13 skills)
| Skill | What It Does |
|---|---|
| MCP Security | MCPoison CVE coverage, 30+ MCP CVEs, protocol-level risks, re-verification requirements |
| API Authentication Security | OAuth 2.0, JWT validation, token lifecycle, API key rotation |
| Prompt Injection Defense | Defence against indirect/direct injection attacks in AI-assisted development |
| Webhook Security | HMAC verification, replay prevention, payload injection mitigations |
| Security Gate | Pre-deploy gate: SAST, dependency scanning, secret detection, Security Review |
| Secrets Management | Environment variable discipline, .env hygiene, key rotation patterns |
| Env Variable Management | .env files, API key safety, environment hierarchy, platform-specific setup |
| Git Security | Branch protection, CODEOWNERS, signed commits, pre-commit hooks |
| Supply Chain Security | npm/pip dependency vetting, lockfile hygiene, install script controls, incident response |
| Privacy Guard | PII detection, data minimisation, encryption requirements, GDPR basics |
| Input Validation | Schema validation (Zod/Yup), sanitisation, parameterised queries |
| AI Output Validation | Detecting plausible-but-wrong AI code, logic verification patterns |
| AI Project Config Security | Securing `.cursorrules`, `AGENTS.md`, `CLAUDE.md`, agent config files |
| License Compliance | Dependency licence scanning, GPL detection, attribution requirements |

### AI Agent Governance (8 skills)
| Skill | What It Does |
|---|---|
| Cloud Agent Governance | Cloud Agents, Bugbot Autofix — human review requirements before merge |
| Self-Hosted Agent Governance | Self-hosted Cursor agents on your own infrastructure |
| Async Subagent Governance | `/multitask`, parallel agents, worktrees, multi-root workspaces |
| Cursor Automations Governance | Always-on triggered/scheduled agents, memory management, auto-approval limits |
| LLM Agent Governance | **NEW (May 2026)** — Prompting discipline, output verification, context management, onboarding |
| Agentic AI Security | **NEW (Jun 2026)** — OWASP Top 10 for Agentic Applications 2026: goal hijack, tool misuse, memory poisoning, cascading failures |
| Cursor SDK Governance | `@cursor/sdk` for programmatic agents outside the IDE |
| Human Approval | Structured escalation when AI decisions exceed documented requirements |
| LLM Observability | Production AI visibility: Langfuse, tracing, per-user cost tracking, feedback loops |

### Quality & Testing (5 skills)
| Skill | What It Does |
|---|---|
| Testing Standards | Naming conventions, structure, edge-case coverage requirements |
| Test Plan | Structured test planning aligned with PRD requirements |
| Test Automation | CI/CD test pipeline design, flaky test handling, coverage gates |
| Code Quality | Naming, complexity limits, SOLID principles, code review checklist |
| Documentation | ADRs, changelog standards, README structure, doc-as-code practices |

### Cost & Operations (8 skills)
| Skill | What It Does |
|---|---|
| Cost Governance | API costs, cloud spending, usage limits across providers |
| AI Cost Management | LLM-specific costs: token budgeting, spend alerts, caching, model selection |
| Deployment Checklist | Pre-deploy verification: env vars, migrations, feature flags, rollback plan |
| Environment Consistency | Dev/staging/production parity, config sync, drift detection |
| Database Migration Safety | Expand-contract pattern, rollback strategies, data loss prevention |
| Monitoring & Alerting | Error tracking, uptime monitoring, performance metrics, Core Web Vitals |
| Incident Response | Structured runbook for the first 30 minutes of an outage |
| Backup & Recovery | Automated backups, tested restores, RPO/RTO planning |

### Compliance & Safety (6 skills)
| Skill | What It Does |
|---|---|
| Accessibility | WCAG 2.2 AA compliance, ARIA, contrast, keyboard navigation, ADA/EAA deadlines |
| Error Handling | Structured error patterns, user-friendly messages, error boundaries |
| Browser Testing | Cross-browser testing requirements, responsive design gates |
| Pre-Release | Final release checklist, feature freeze coordination, release notes |
| Dependency Scanning | Vulnerability scanning, version pinning, update cadence |
| AI Project Config Security | Securing `.cursorrules`, agent config files, CODEOWNERS enforcement |

---

## How Skills Map to Real-World Disasters

These skills exist because real people hit real problems:

- **A teacher builds a simple tutoring AI tool with Cursor** → AI Cost Management + AI Output Validation prevent runaway API bills and plausible-but-wrong logic
- **A non-technical founder uses Cloud Agents to build their MVP** → Cloud Agent Governance ensures human review before every merge
- **A small team shares a repo with MCP configs** → MCP Security prevents silent credential theft via malicious plugin updates
- **An automation monitors support tickets and auto-fixes** → Cursor Automations Governance prevents compounding errors in always-on agents
- **Someone writes a vague prompt that generates 200 lines of code** → LLM Agent Governance teaches scoping, verification, and the daily agent checklist
- **An AI agent writes 50 async subagent tasks in parallel** → Async Subagent Governance prevents resource contention and cross-branch conflicts

---

## Version History

Full release notes are in the [CHANGELOG](CHANGELOG.md).

| Version | Date | Highlights |
|---|---|---|
| v1.15.0 | Jun 2026 | Agentic AI Security (OWASP ASI 2026) skill — 10 agentic risks mapped to governance |
| v1.14.0 | May 2026 | CVE-2026-26268 (git hook RCE) coverage; Cursor 3.6 Auto-review governance; Code Review for Founders skill |
| v1.11.0 | May 2026 | LLM Agent Governance skill, PR review / Build in Parallel / Spend Limits coverage |
| v1.10.0 | May 2026 | Security Gate: Cursor Security Review + OWASP GenAI Q1 2026; Async Subagent: worktrees + multi-root |
| v1.9.0 | Apr 2026 | Prompt Injection Defense, Git Security, MCP 30+ CVE update, EAA enforcement |
| v1.8.0 | Mar 2026 | Monitoring & Alerting, 5-CVE MCP cluster, WCAG 3.0 preview |
| v1.7.0 | Mar 2026 | LLM Observability, Webhook Security |
| v1.6.0 | Mar 2026 | Input Validation, AI Cost Management |
| v1.5.0 | Feb 2026 | AI Config Security, Deployment Checklist, Cost Governance, Incident Response |
