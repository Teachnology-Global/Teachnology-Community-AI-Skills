---
title: "Changelog"
date: 2026-03-20
tags: [product]
status: draft
---

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0] - 2026-03-22

### Added
- **LLM Observability** skill — instruments AI-powered features for production visibility. Covers Langfuse integration (free tier, open source), DIY database logging for teams not ready for a dedicated tool, error rate alerting, per-user token budget enforcement, user feedback signals (👍/👎), deterministic output validation with Zod schemas, and a pre-launch observability checklist. Targets the exact failure pattern for non-technical founders: AI feature ships, works in dev, silently fails or hallucinate in production with no visibility. Cross-references AI Cost Management (controls) and AI Output Validation (prevention).
- **Webhook Security** skill — prevents forged requests, replay attacks, and payload injection via untrusted webhook data. Covers provider-specific HMAC verification for Stripe, GitHub, Slack, and Clerk; generic HMAC-SHA256 pattern for custom services; timestamp validation and event ID idempotency for replay prevention; payload injection mitigations specifically for AI automation pipelines; and a complete webhook security checklist. Includes test examples for each verification pattern.

### Changed
- README updated: Before/After table (2 new rows), skill count badge (38→40), skills table (28→30).

### Security
- Webhook Security closes a critical gap: non-technical founders frequently build Stripe/GitHub/Slack webhook receivers without any signature verification, making them trivially spoofable.
- LLM Observability adds a security-adjacent layer: per-user rate limits and token caps prevent resource exhaustion attacks and abuse of AI endpoints.
- Webhook payload injection guidance cross-references Cursor Automations Governance for teams using webhooks as automation triggers.

## [1.6.0] - 2026-03-15

### Added
- **Input Validation** skill — prevents XSS, SQL injection, path traversal, and data corruption from unvalidated user input. Includes validation patterns for forms, API endpoints, file uploads, and URL parameters. Zod/Pydantic schema examples, parameterised query patterns, DOMPurify XSS prevention, and a "red flags in AI-generated code" section for non-technical reviewers. Addresses a genuine gap: Cursor frequently generates code without server-side validation.
- **AI Cost Management** skill — prevents LLM API bill shock for non-technical founders building AI features. Covers token budgeting, `max_tokens` enforcement, per-user rate limiting, conversation history trimming, prompt caching (OpenAI and Anthropic native caching), model selection strategy (don't use Opus for everything), usage logging per call, and a pre-production cost estimation template. Targets the exact failure pattern: a feature that works fine in dev generating hundreds of dollars in production overnight.

### Changed
- **MCP Security** skill updated with March 2026 Marketplace expansion — 30+ new partner plugins added (Atlassian, Datadog, GitLab, Glean, Hugging Face, monday.com, PlanetScale). New risk profile table documents write-access capabilities of each partner (GitLab → repo writes, PlanetScale → production DB, Datadog → logs/PII). Elevated guidance for write-capable plugins: require technical sign-off before enabling. Added Team Marketplaces section (Teams/Enterprise plan central governance).
- README updated: Before/After table (2 new rows), skill count badge (36→38), governance skills table (26→28).

### Security
- Input Validation closes a gap in AI-generated code: Cursor frequently ships parameterisation-missing DB queries and missing server-side validation. This skill makes the patterns explicit and reviewable.
- AI Cost Management adds a security angle: leaked AI API keys without spend limits are a financial risk, not just a security one. Skill cross-references secrets rotation with financial urgency.
- MCP Security updated to reflect elevated risk from high-privilege Marketplace partners (GitLab, PlanetScale, Datadog) added in March 2026 expansion.

## [1.5.0] - 2026-03-08
## [1.4.0] - 2026-03-08

### Added
- **Cursor Automations Governance** skill — governs always-on, scheduled, and event-triggered agents (Cursor Automations, launched March 5, 2026). Covers: event source security and prompt injection via PR/Slack/webhook data, memory governance (memory poisoning risk), auto-approval safeguards, webhook authentication (HMAC-SHA256 validation), weekly automation review checklist, and incident response for runaway automations. Designed for non-technical founders who can't catch compounding agent errors.

### Changed
- **Cloud Agent Governance** skill updated to reference the new Cursor Automations Governance skill and clarify scope: this skill covers one-off Cloud Agents and Bugbot Autofix; Automations are a separate skill.
- **MCP Security** skill updated with "Related: AI Tool Project Config Files as Attack Surface" section — covers CVE-2025-59536 (Claude Code Hooks RCE) and CVE-2026-21852 (API key exfiltration), disclosed by Check Point Research March 2026. Documents the pattern: any AI tool config file in a shared repo is a potential RCE vector. Includes comparison table of `.cursor/mcp.json`, `.claude/settings.json`, and `.cursor/automations/` as attack surfaces.
- README updated: Before/After table, skill count badge (31→32), governance skills table.

### Security
- Added Cursor Automations governance — prompt injection via event data (PR titles, Slack messages, webhook payloads) is a new and underappreciated attack surface for automation-heavy teams
- Added CVE-2025-59536 / CVE-2026-21852 awareness: Claude Code Hooks RCE and API key exfiltration via `.claude/settings.json` — same trust model vulnerability class as MCPoison
- Added webhook authentication requirements for custom Automation triggers

## [1.3.0] - 2026-03-01

### Added
- **MCP Security** skill — Model Context Protocol governance: vetting, version pinning, team approval registry, quarterly audit workflow, and incident response. Covers CVE-2025-54136 (MCPoison trust bypass attack) discovered by Check Point Research (August 2025). Also covers Cursor Marketplace plugin governance (Feb 2026).
- **Cloud Agent Governance** skill — Safe use of Cursor Cloud Agents (launched Feb 24, 2026) and Bugbot Autofix (launched Feb 26, 2026). Includes repository safeguards required before enabling agents, PR review checklist, Bugbot evaluation workflow, safe agent task patterns, artifact review guidance, and rollback planning. Designed for non-technical founders who can't spot subtle AI-generated bugs by eye.

### Changed
- **Security Gate** skill updated with MCPoison (CVE-2025-54136) detection checks: unpinned MCP version detection, hardcoded credential scan in mcp.json, MCP config change verification. Added reference to MCP Security skill. Updated Supply Chain row in OWASP Agentic Top 10 table.
- **AI Output Validation** skill updated with Cloud Agent and Bugbot Autofix PR validation section: artifact review process, validation checklist for agent PRs, Bugbot fix evaluation workflow, and table of how AI failure modes manifest differently in autonomous agent output.
- README Before/After table updated with MCP and Cloud Agent governance examples.
- Skill count badge updated from 29 to 31 (21 governance + 10 marketing).
- README governance skills table updated from 19 to 21 skills.

### Security
- Added MCPoison (CVE-2025-54136) awareness and mitigations — critical for any team using Cursor in shared repositories
- Added guidance on MCP version pinning to prevent silent malicious updates after approval
- Added Cloud Agent scope controls — preventing agents from touching auth, payments, or database migrations autonomously
- Added Bugbot Autofix governance — human review required before merging any autonomous fix (including "obvious" ones)

## [1.2.0] - 2026-02-22

### Added
- **Database Migration Safety** skill - zero-downtime migrations, expand-contract pattern, rollback scripts, and Neon-specific branching guidance
- **AI Output Validation** skill - validates AI-generated code before shipping; covers hallucinated APIs, auth logic bugs, over-permissive access, missing input validation, and prompt injection; OWASP LLM Top 10 reference

### Changed
- **Security Gate** skill updated with OWASP Top 10 for Agentic Applications (2026) risk table; added Cursor Hooks enterprise governance section; added Cursor Sandbox Network Controls (Feb 2026)
- **Dependency Scanning** skill updated to reflect OWASP 2026 adding supply chain to Top 10; added Cursor Plugin/MCP server security guidance; added lock file integrity checks
- **Pre-Release** checklist updated from WCAG 2.1 to WCAG 2.2 references (2 occurrences fixed)
- README Before/After table updated with migration safety and AI validation examples
- Skill count badge updated from 27 to 29

### Security
- Added OWASP Top 10 for Agentic Applications awareness (prompt injection, excessive agency, insecure output handling, memory poisoning, supply chain compromise)
- Added Cursor Hooks guidance for enterprise policy enforcement at the IDE level
- Added sandbox network access control patterns (domain allowlists, filesystem restrictions)

## [1.1.0] - 2026-02-15

### Added
- **API Rate Limiting** skill - prevents quota exhaustion, service costs, and 429 errors with smart retry logic
- **Error Handling** skill - ensures user-friendly errors, graceful degradation, and proper logging standards  
- **Environment Consistency** skill - eliminates "works on my machine" by ensuring dev/staging/prod parity

### Changed
- **Accessibility** skill updated from WCAG 2.1 to WCAG 2.2 Level AA compliance
- Added WCAG 2.2 new success criteria (focus visibility, drag alternatives, target size, consistent help, redundant entry, accessible authentication)
- Added 2026 federal compliance deadline awareness (April 24, 2026 for ADA Title II)
- Updated skill count from 14 to 17 throughout documentation

### Security
- Enhanced security considerations for Cursor IDE's new browser/terminal access features
- Updated secrets management best practices with 2026 standards
- Added prompt injection attack awareness for autonomous agents

## [1.0.0] - 2026-02-14

### Added

- 14 governance skills for Cursor IDE
  - Security Gate - pre-deployment vulnerability scanning
  - Human Approval - pauses AI for significant decisions
  - Code Quality - enforces linting, complexity limits, formatting
  - Privacy Guard - GDPR/CCPA compliance checking
  - Accessibility - WCAG 2.1 Level AA enforcement
  - Documentation - ADR, changelog, and API doc generation
  - Testing Standards - coverage requirements and test quality
  - Licence Compliance - dependency licence validation
  - Pre-Release - unified go/no-go release gate
  - Test Plan - PRD-to-test-plan generation with traceability
  - Browser Testing - E2E testing with Cursor @Browser tools
  - Test Automation - Playwright/Cypress test suite generation
  - Dependency Scanning - vulnerability and supply chain checks
  - Secrets Management - credential leak prevention and rotation
- `.cursorrules` configuration for automatic governance activation
- `governance.yaml` project configuration template
- 7 scanning and setup scripts (Bash, PowerShell, Python, Node.js)
- 7 document templates (ADR, changelog, HITL decision, PRD, PIA, security exception, test plan)
- Next.js + Vercel + Neon setup guide
- Testing workflow guide
- GitHub Actions workflow template
