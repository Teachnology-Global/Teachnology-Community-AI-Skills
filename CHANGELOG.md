---
title: "Changelog"
date: 2026-03-20
tags: [product]
status: draft
---

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Feature Flag Governance** skill (40) — governs safe use of feature flags for gradual rollouts, A/B testing, and kill switches. Covers flag lifecycle, naming conventions (exp-/ops-/perm-/roll- prefix scheme), cleanup discipline (90-day max lifespan), audit trails, and security red lines (never use flags for auth bypass, payment logic, or rate-limit disable). Critical for non-technical founders who need to ship safely without full confidence in every change.

### Changed
- **Cursor Automations Governance** — updated for three Cursor 3.5 features (May 2026):
  - **Automations in the Agents Window** (May 20, 2026): Added governance for managing automations alongside one-off agents in the same window. Risk of accidental cross-triggering; verify which automation config you're editing.
  - **Multi-repo Automations**: New safeguard section — branch protection required on ALL attached repos, per-repo CODEOWNERS, cross-repo contamination checks, unified DO NOT TOUCH list. The blast radius of one automation now spans every repo it's attached to.
  - **No-repo Automations**: New safeguard section — mandatory output logging (no Git trail), explicit per-tool write boundaries, higher review frequency, aggressive rate limiting. Five Marketplace templates launched (Slack digest, Product analytics, Product FAQ, Product finance, Customer health) — validate each before production enablement.
  - Added activation globs and Jira mention to the prompt injection section.
- **Security Gate** — added full OWASP Top 10:2025 reference table with mapping to existing skills. New A10:2025 (Mishandling of Exceptional Conditions) directly cross-references the Error Handling skill — AI models frequently skip error handling and the Gate should verify.
- **Dependency Scanning** — updated OWASP reference from "OWASP 2026: Supply Chain Now Top 10" to "OWASP Top 10:2025 — A03 Software Supply Chain Failures" reflecting the finalised 2025 list where supply chain formally ranks #3.

### Security
- **Cursor 3.5 Automations**: Multi-repo automations significantly expand blast radius — a single misconfigured automation can now affect multiple codebases simultaneously. No-repo automations have no Git audit trail, making output logging mandatory for traceability.
- **Cursor Jira Integration (May 19, 2026)**: `@Cursor` mentions in Jira comments can trigger agents — external contributors can now influence agent behaviour via Jira tickets. This is a new prompt injection surface.
- **Composer 2.5 (May 18, 2026)**: Substantially more intelligent than Composer 2. Better at sustained work and complex instructions, which means more convincing-but-incorrect outputs. Do not relax review standards.
- **OWASP Top 10:2025 A10 Mishandling of Exceptional Conditions**: New category that AI agents are particularly prone to miss. Code must be gate-checked for error handling coverage.

## [1.12.0] - 2026-05-17

### Changed
- **Cloud Agent Governance** — major update covering four new Cursor features from May 2026:
  - **Bugbot Effort Levels** (May 11, 2026): Added governance for Default/High/Custom effort tiers, usage-based billing implications, and cost control guidance. High effort costs 3-5× more — needs explicit scoping rules.
  - **Cloud Agent Development Environments** (May 13, 2026): New section covering Dockerfile-based environments, multi-repo environments, build secrets, version history/audit logs, and egress scoping. Covers credential bleed, scope creep, and cross-repo injection risks.
  - **Cursor in Microsoft Teams**: New section covering Teams-specific risks — unrestricted channel invocation, context leakage from thread history, and auto-PR creation governance.
  - Added activation globs for `Dockerfile*` and `.teams/**` patterns.

### Security
- **Bugbot billing change**: Switch to usage-based billing (effective after June 8, 2026) means cost control is now the admin's responsibility. Default effort level still works but High effort can blow budgets if triggered carelessly.
- **Dev Environment build secrets**: While scoped to build step, Docker layer caching could leak values. New governance rule: always verify build secrets don't appear in final image layers.
- **Multi-repo credential bleed**: Agents with access to multiple repos can potentially access credentials from repo A while working on repo B. Scope secrets to specific repos.
- **Teams channel exposure**: Any team member (including external/guest users) can trigger an agent via @Cursor. Restrict to dedicated channels with no guest access.

## [1.11.0] - 2026-05-10

### Added
- **LLM Agent Governance** skill — the foundational governance layer for interacting with AI agents. Covers prompting discipline (scoped instructions vs vague prompts), output verification (trust but verify checklist), context window discipline (using Cursor's May 2026 Context Usage Breakdown), prompt injection hygiene for project files, onboarding non-technical team members to AI-assisted development, and a daily agent checklist. This skill is the human-AI interface that all other governance skills assume but don't explicitly teach. Activated by `.cursorrules`, `.cursor/rules/`, `AGENTS.md`, `CLAUDE.md`, and prompt-related keywords.

### Changed
- **README** updated: skill count badge (38→39), added LLM Agent Governance row to AI Agent Governance table, added new Before/After row for vague prompts scenario, updated "Last updated" to May 2026, added Cursor 3 feature coverage (PR review, Build in Parallel, Split Changes into PRs, Context Usage Breakdown, Soft Spend Limits).

### Security
- Cursor 3.1+ (May 2026) introduces three major features affecting governance: **PR Review** experience (all-in-one PR management), **Build in Parallel from Plans** (async subagent spawning), **Split Changes into PRs** (auto-slice into independent branches). Each introduces new governance requirements around scope control, output verification, and PR hygiene. LLM Agent Governance addresses these at the operator level.
- Cursor's **Soft Spend Limits** (May 4, 2026) give enterprise admins granular budget control with alerts at 50%, 80%, 100% — this complements Cost Governance and AI Cost Management but doesn't replace them (soft limits still allow exceeding thresholds).
- Cursor's **Model Access Controls** (May 4, 2026) let admins block providers/models by default, set context window limits, and require migration by June 1st. Governance implications for team environments.

### Notable External Findings
- **OWASP GenAI Exploit Round-up Q1 2026** (covered in v1.10.0 Security Gate update): LLM05 Improper Output Handling, ASI04 Agentic Supply Chain Vulnerabilities, Memory Poisoning via AI Chat Logs, Denial of Wallet via Token Inflation.
- **OWASP Top 10 for Agentic Applications 2026** — distinct from LLM Top 10; focuses on agentic failures: goal misalignment, tool misuse, delegated trust, inter-agent communication, persistent memory, and emergent autonomous behavior. Coverage exists across MCP Security, Prompt Injection Defense, and Cloud Agent Governance.
- **WCAG 3.0** remains in Working Draft status (March 2026) — not yet legally enforceable. Continue targeting WCAG 2.2 AA.

## [1.10.0] - 2026-05-10

### Added
- **Cursor Security Review** integration in Security Gate skill — beta coverage for Teams/Enterprise (launched April 30, 2026). Security Reviewer (per-PR security checks) and Vulnerability Scanner (scheduled codebase scans) now complement existing SAST/dependency/secret scanning.
- **OWASP GenAI Exploit Round-up Q1 2026** section in Security Gate — LLM05, ASI04, Memory Poisoning, Denial of Wallet findings with governance mitigations.

### Changed
- **Security Gate** — now includes Cursor Security Review (beta) as a recommended supplementary scanning layer for Teams/Enterprise users.
- **Async Subagent Governance** — updated for Cursor 3.2 worktrees in Agents Window and multi-root workspace governance (from `3.1 /@multitask` to `3.2` with worktrees, multi-root).

## [1.9.0] - 2026-04-12

### Added