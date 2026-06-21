---
description: >
  Governs the safe use of Cursor Cloud Agents, Bugbot Autofix, and Cloud Agent
  Development Environments — autonomous AI agents that write code, run tests, use
  software in VMs, and submit pull requests without a human at the keyboard. Covers
  Bugbot effort levels (Default/High/Custom, usage-based billing), multi-repo
  environments, Dockerfile-based dev environments with build secrets, environment
  version history and audit logs, and Microsoft Teams integration. Defines review
  requirements, approval gates, and safe delegation patterns for non-technical
  founders and teachers. Updated June 2026.
  Use when: (1) enabling Cloud Agents on a project, (2) reviewing an agent-generated
  PR, (3) using Bugbot Autofix, (4) configuring Cloud Agent Dev Environments,
  (5) setting up multi-repo agent workflows, (6) using Cursor in Microsoft Teams.
globs: ["**/.github/**", "**/vercel.json", "**/.cursor/**", "**/Dockerfile*", "**/.teams/**"]
alwaysApply: false
tags: [product]
---

# Cloud Agent Governance

## Purpose

Cursor Cloud Agents (launched Feb 2026) run autonomously in isolated VMs. They can write code, run tests, use software, take screenshots, record videos — and submit the result as a pull request. Bugbot Autofix extends this: it automatically detects issues in your PRs and proposes fixes.

**Cursor Automations (launched March 2026)** extend this further with always-on, event-triggered and scheduled agents. These are a different risk category and have their own dedicated skill — see **Cursor Automations Governance**. This skill covers one-off Cloud Agents and Bugbot Autofix.

This is powerful. It is also a fundamentally new risk model for non-technical founders and teachers who use Cursor. An AI agent autonomously pushing to your codebase, with no human watching in real time, needs governance.

## The Risk Model for Non-Technical Builders

### What Cloud Agents Can Do (Feb 2026, updated April 2026)

| Capability | Risk |
|-----------|------|
| Write and modify code files | Can introduce bugs, security holes, or breaking changes |
| Run terminal commands in a VM | Can install packages, run scripts, modify configs |
| Use software (browser, terminal) with computer use | Can interact with any UI including admin panels in the VM |
| Submit PRs directly to your repository | Changes land in your codebase without you writing them |
| Record videos and screenshots as artifacts | Creates evidence of what happened — but you must review it |
| Push changes directly to a branch (if configured) | Bypasses even PR review if auto-merge is enabled |
| Run up to 10 agents in parallel (Cursor 3.0+) | Parallel agents can produce conflicting changes; review burden multiplies |
| Async subagents via /multitask (Cursor 3.2) | Agents run simultaneously — scope segregation critical; see Async Subagent Governance |
| Self-hosted cloud agents (Cursor 3.0+) | Code stays in your infra — but so does the risk; see Self-Hosted Agent Governance |
| Multi-root workspaces (Cursor 3.2) | Single agent session targets multiple repos — cross-repo scope bleed risk |
| Multi-repo Dev Environments (May 2026) | Agents span multiple repos — cross-repo secret exposure, credential bleed, and scope creep |
| Dev Environment version history | Admin-only rollback restrictions create single-point-of-failure; ensure at least 2 admins have rollback access |
| Cursor in Microsoft Teams | Mentioning @Cursor in a channel delegates tasks — any channel member can trigger agent actions; restrict who can invoke |
| Async subagent fleet management (Cursor 3.2) | Unbounded parallel execution without budget limits; requires cost monitoring |
| Design Mode UI targeting (Cursor 3.0+) | Agents can target specific UI elements — can be used to scrape sensitive UIs |
| Cloud Subagents in Agents Window (June 2026) | Agents can spawn sub-agents on separate VMs for parallel work; each sub-agent has independent tool access — scope segregation is critical |
| Cloud Environment Snapshots (June 2026) | Reusable environment snapshots speed up agent startup but may bake in stale configs or secrets if not refreshed |

### What Could Go Wrong

**For non-technical founders:**
- Agent introduces a subtle security bug in auth code
- Agent installs a dependency with a known vulnerability
- Agent modifies database queries in a way that breaks data integrity
- Agent generates code that passes tests but violates business logic
- Bugbot Autofix "fixes" something that wasn't actually broken
- Bugbot High effort mode costs 3-5× more per review — easy to blow budget if left unchecked
- Dev Environment build secrets leak into running agent environment despite scoping guarantees
- Multi-repo environment exposes credentials from repo A to an agent working on repo B
- Cursor Teams channel member sends malicious prompt that triggers agent to push changes

**The core issue:** Cloud agents are confident and fast. They produce code that looks reasonable. Non-technical reviewers may not catch problems that a senior developer would spot immediately. Governance is your safety net.

## Activation

This skill activates when you mention:
- "Cloud Agent", "cloud agent", "Bugbot", "Autofix"
- "agent PR", "agent pull request", "AI-generated PR"
- "agent wrote", "agent completed", "agent built"
- "Cursor onboard", "cursor.com/onboard"
- "autonomous agent", "background agent"

Also activates when:
- Reviewing a PR tagged as AI-generated or from a Cursor agent
- Configuring `.github/` workflows that involve Cursor agents
- Enabling Bugbot on a repository

> For scheduled or event-triggered agents (Cursor Automations), see the **Cursor Automations Governance** skill.

## Before You Enable Cloud Agents

### Repository Safeguards (Required First)

Do not enable Cloud Agents on a repository that lacks these protections:

```markdown
## Pre-Agent Safety Checklist

Branch protection:
- [ ] main/production branch is protected
- [ ] Direct pushes to main are blocked
- [ ] PRs require at least 1 review approval
- [ ] Status checks must pass before merge

CI/CD safeguards:
- [ ] Automated tests run on every PR
- [ ] Deployment to production requires manual approval
- [ ] Secrets are not accessible to PR builds from forks

Agent-specific:
- [ ] Bugbot Autofix is set to "propose only" (not auto-merge)
- [ ] Agent PR notifications are routed to a human (Slack/email)
- [ ] You have a rollback plan if an agent-generated change breaks production
```

### GitHub Branch Protection Settings

```yaml
# Ensure these protections are active before enabling agents
# Settings > Branches > Branch protection rules > main

required_status_checks:
  strict: true  # Branch must be up to date before merging
  contexts:
    - "test / run-tests"
    - "security-gate"

enforce_admins: false  # Agents shouldn't bypass rules
required_pull_request_reviews:
  required_approving_review_count: 1
  dismiss_stale_reviews: true
  
restrictions: null  # Or restrict to specific teams if needed
```

## Reviewing Agent-Generated PRs

This is the most important part. Never merge an agent PR without review.

### The Agent PR Review Checklist

```markdown
## Agent PR Review: [PR Title]
**Agent type:** [ ] Bugbot Autofix  [ ] Cloud Agent task  [ ] Background agent
**Date:** 
**Reviewer:**

### Review the Artifacts First
- [ ] Watched the screen recording / reviewed screenshots (if provided)
- [ ] The agent appears to have done what was asked — nothing more
- [ ] No unexpected file modifications in the artifacts

### Code Review (every file changed)
- [ ] Understand WHAT the agent changed and WHY
- [ ] No new dependencies added without justification
- [ ] No changes to authentication, authorisation, or session logic without your explicit intent
- [ ] No changes to database queries or schema
- [ ] No new API calls or webhooks without your explicit intent
- [ ] No changes to environment variable handling or .env files
- [ ] No hardcoded credentials or sensitive values

### Security Spot Check
- [ ] Ran the security gate on the PR diff (semgrep, gitleaks)
- [ ] No new packages added with known vulnerabilities
- [ ] No secret patterns detected in changed files

### Functional Check
- [ ] CI tests pass
- [ ] Changes are tested (unit tests exist for new code)
- [ ] Manually tested the changed feature if it's user-facing

### Business Logic Check (Non-Technical Founders: Read This)
Even if the code "works", verify it does what YOU intended:
- [ ] The change solves the actual problem you described
- [ ] No edge cases were quietly removed (e.g., validation that seemed annoying)
- [ ] Any UI changes match your design intent
- [ ] Pricing, permissions, or billing logic is not affected unless that was the task
```

### Files That Always Need Extra Review

Even from trusted agents, flag these for careful review:

```
High-risk files (always review carefully):
├── auth/, middleware/, guards/        ← Authentication/authorisation logic
├── payments/, billing/, stripe/       ← Money handling
├── migrations/, db/                   ← Database changes
├── .env*, *.config.*                  ← Environment configuration
├── .github/workflows/                 ← CI/CD pipeline changes
├── package.json, requirements.txt     ← New dependencies
└── Any file the agent wasn't asked to change
```

**If an agent changed a file you didn't ask it to:** Read that change very carefully. Agents sometimes make "helpful" changes that have unintended consequences.

## Bugbot Autofix Governance

Bugbot Autofix (launched Feb 26, 2026) detects issues in PRs and proposes fixes via `@cursor` commands.

### Bugbot Effort Levels (Updated May 11, 2026)

Cursor switched Bugbot to **usage-based billing** for Teams and Individual plans (effective at renewal after June 8, 2026). This removes per-seat fees and introduces configurable effort levels:

| Effort Level | Cost | Speed | Best For |
|---|---|---|---|
| **Default** | Standard | Fast | Routine PRs, minor bugs, formatting |
| **High** | 3-5× more | Slower | Security-sensitive code, auth changes, payment logic |
| **Custom** | Variable | Variable | Natural-language rules: "Use High effort for anything touching auth or payments, Default otherwise" |

**For non-technical founders:** If you set Bugbot to "Custom", write specific rules. Don't leave it open-ended. Ambiguity means Bugbot will default to the cheapest (Default) effort — which may miss subtle bugs in critical code paths.

### Recommended Configuration

```markdown
For small teams and non-technical founders:

Mode: PROPOSE ONLY (not auto-merge)
- Bugbot posts a comment with the fix preview
- A human reviews and merges using @cursor merge
- Never enable auto-push to branch without review

Effort level strategy:
- Most PRs: Default (cost-efficient)
- PRs touching auth/payments/DB: High (deep analysis worth the cost)
- Use Custom effort rules if you have predictable patterns

Why not auto-merge?
Bugbot Autofix has a 70%+ resolution rate for bugs it identifies,
but the 35% merge rate means most fixes still need human review.
Even when Bugbot's fix is correct, auto-merging without review
means you lose the chance to understand what went wrong — a critical
learning moment for less technical team members.
```

### Evaluating a Bugbot Fix

Before merging a Bugbot Autofix suggestion:

1. **Understand the original issue** — Does Bugbot's description match your understanding?
2. **Read the diff** — Is the fix minimal and targeted, or does it touch unrelated code?
3. **Check for regressions** — Does the fix break anything the tests don't cover?
4. **Verify the logic** — For security or business logic fixes, verify the fix is actually correct and complete

```markdown
## Bugbot Fix Evaluation

Issue described: [what Bugbot said it found]
Fix described: [what Bugbot proposed to fix it]

- [ ] I understand what the bug was
- [ ] I understand what the fix does
- [ ] The fix is minimal (no unnecessary changes)
- [ ] Tests still pass with the fix
- [ ] The fix actually addresses the root cause, not just the symptom
- [ ] No security-sensitive code was changed unexpectedly

Decision: [ ] Merge  [ ] Request changes  [ ] Close (false positive)
```

## Agentic Task Design (For Non-Technical Founders)

How you instruct agents matters enormously for safety.

### Safe Task Patterns

```markdown
✅ SAFE - Narrow, testable, reversible tasks:
- "Add a loading spinner to the submit button in /components/ContactForm.tsx"
- "Write unit tests for the calculateDiscount function in lib/pricing.ts"
- "Update the README with the new deployment steps"
- "Fix the TypeScript error on line 42 of api/users.ts"

✅ SAFE - With explicit boundaries:
- "Refactor the authentication middleware but do NOT change the session token logic"
- "Update the Stripe integration to use the latest SDK — only change the API calls, not the pricing logic"
```

```markdown
⚠️ REQUIRES EXTRA REVIEW - Broad or high-stakes tasks:
- "Improve the checkout flow"
- "Fix all the bugs in the payment system"
- "Optimise the database queries"

Why: These give the agent latitude to change more than you intended.
Always read the full diff before merging.
```

```markdown
❌ DO NOT DELEGATE TO AUTONOMOUS AGENTS:
- Anything involving database migrations (use Database Migration Safety skill instead)
- Changes to authentication or authorisation logic
- Changes to how secrets or API keys are handled
- Changes to billing or payment flows
- Anything that directly affects what users can access
```

### Writing Good Agent Prompts

```markdown
Template for safe agent tasks:

"Please [specific action] in [specific file(s)].

Scope: Only modify [specific files]. Do not touch [list of protected files].

Definition of done: [testable criterion — e.g., "the form submits without errors and the success message appears"]

Please provide a test that verifies this works."
```

## Audit Trail Review

Cursor Cloud Agents produce artifacts — videos, screenshots, and logs. Use them:

```markdown
When reviewing an agent PR, check the artifacts:

VIDEO/SCREENSHOTS:
- Does the agent's recorded session match what it was asked to do?
- Are there any unexpected actions (visiting URLs, opening files not in scope)?
- Does the final state of the UI/app look correct?

LOGS:
- What commands did the agent run?
- Were any commands unexpected (e.g., npm install of packages you didn't ask for)?
- Any errors that were silently ignored?

If the artifacts are missing or the agent didn't record:
- Be more cautious — you have less visibility
- Do a more thorough code review
- Run the feature manually before merging
```

## Rollback Planning

Before any agent-generated code reaches production:

```markdown
## Agent Deployment Rollback Plan

For each agent-generated feature:
- [ ] Know which commit to revert to if things go wrong
- [ ] Database changes? Know the rollback migration
- [ ] Feature flags? Can you disable this feature without a deploy?
- [ ] Monitoring? Alerts set for errors in the affected code path

Quick rollback command:
git revert [agent-commit-hash]
```

## Integration

### With Human Approval
- All agent-generated PRs require human approval before merging
- Any agent task that touches auth, payments, or database requires explicit prior approval
- "Bugbot says to fix this" is not sufficient approval to bypass human review

### With Security Gate
- Security gate runs on every agent PR as part of CI
- Any security finding from the agent's code blocks merge
- Agent PRs get the same security scrutiny as human-written code

### With AI Output Validation
- Apply all AI Output Validation checks to agent-generated code
- Hallucinated APIs, auth bugs, and over-permissive logic are common agent failure modes
- Treat every agent PR as AI-generated code that needs human validation

### With Database Migration Safety
- Agents must NEVER run database migrations autonomously
- If an agent suggests a migration, review it against the Migration Safety skill before running anything
- Even Bugbot Autofix should not touch migration files

### With Testing Standards
- Agent-generated code must meet the same test coverage requirements as human code
- If the agent didn't write tests, ask it to before merging
- Run the full test suite — not just the tests the agent wrote

## Cloud Agent Development Environments (May 2026)

Cursor released **Cloud Agent Development Environments** on May 13, 2026. This lets teams configure Dockerfile-based development environments for agents, with multi-repo support, build secrets, version history, and audit logs.

**For non-technical founders:** Think of a Dev Environment as a virtual computer that your AI agent uses to work. You configure it once (or Cursor auto-generates it), and every agent runs in that same reproducible setup. The agent gets the right tools, dependencies, and credentials before it starts working.

### Risk Model

| Capability | Risk | Mitigation |
|---|---|---|
| **Dockerfile-based config** | Misconfigured image can expose tools or libs to agents unnecessarily | Pin base images, remove unnecessary packages, use minimal base (alpine/slim) |
| **Build secrets** | Build secrets are scoped to build step BUT Docker layer caching can leak values; never use them with multi-stage build mistakes | Verify build secrets never appear in final image layers; use docker scan after build |
| **Multi-repo environments** | Credentials from repo A accessible to agent working on repo B — scope bleed | Only combine repos that need cross-repo access; separate environments otherwise |
| **Version history** | Rollback restricted to admins creates single-point-of-failure | Ensure at least 2 admins have rollback access |
| **Audit logs** | Audit log shows who changed environment — but not whether they *should* have changed it | Review audit logs weekly; alert on unexpected environment modifications |
| **Egress scoping** | Agent can reach any network the dev environment has access to | Restrict egress in Dockerfile; use egress proxy for outbound traffic |
| **Auto-generated Dockerfiles** | Cursor-generated Dockerfiles in private beta may include unnecessary dependencies | Review every auto-generated Dockerfile before committing |

### Dev Environment Governance Rules

```markdown
## Dev Environment Security Checklist

- [ ] Dockerfile pinned to specific base image tag (not `latest`)
- [ ] Only necessary packages installed
- [ ] Build secrets verified to not leak into final image
- [ ] Multi-repo environments only combine repos with genuine cross-repo access needs
- [ ] Egress restricted to required external services
- [ ] At least 2 admins have rollback permissions
- [ ] Audit log review scheduled (weekly minimum)
- [ ] Environment falls back to base image only — never silently succeeds with wrong config
```

### Multi-Repo Environment Risks

When an agent has access to multiple repos:

**Credential bleed:** If repo A has `DATABASE_URL` and the agent opens repo B's PR, the credential is technically available to any tool the agent runs in that environment. Scope secrets to specific repos when possible.

**Scope creep:** An agent tasked with "fix the API endpoint" in repo A might "helpfully" update the corresponding frontend in repo B without you asking. Set explicit scope boundaries in agent prompts.

**Cross-repo injection:** If repo B is a public repo and someone submits a PR with malicious code in a file the agent reads, the agent could be compromised via indirect prompt injection across repos.

## Cursor in Microsoft Teams (May 2026)

Cursor is now available in Microsoft Teams. Mention `@Cursor` in any Teams channel to delegate a task to a cloud agent.

### Teams-Specific Risks

**Unrestricted invocation:** Any member of the Teams channel can trigger an agent — including external users if the channel has guest access. This means your codebase can be accessed by anyone with channel membership.

**Context leakage:** Cursor reads the entire thread for context. Previous messages, files, and discussions become part of the prompt. Sensitive information in earlier thread messages is exposed to the agent.

**Auto-PR creation:** A casual request in a Teams chat creates a real PR. Without channel-level governance, this could lead to a flood of unreviewed agent work.

### Teams Governance Rules

```markdown
## Cursor in Teams — Required Safeguards

- [ ] Restrict @Cursor invocation to specific channels (not org-wide)
- [ ] Remove external/guest access from channels where Cursor is active
- [ ] Establish naming conventions for agent-generated PRs (e.g., "[Cursor] ...")
- [ ] Require human review for all Cursor-generated PRs (no auto-merge)
- [ ] Do not discuss secrets, credentials, or sensitive data in channels where Cursor is active
- [ ] Pin a governance message explaining how to use Cursor safely in the channel
```

**For non-technical founders:** The easiest way to misuse Cursor in Teams is to ask it to do something in a public channel where the wrong people can see the agent's work and the agent can see sensitive conversation history. Use a dedicated channel for agent tasks.