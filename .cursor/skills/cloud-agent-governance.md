---
description: >
  Governs the safe use of Cursor Cloud Agents and Bugbot Autofix — autonomous AI
  agents that write code, run tests, use software in VMs, and submit pull requests
  without a human at the keyboard. Defines review requirements, approval gates,
  and safe delegation patterns for non-technical founders and teachers.
  Use when: (1) enabling Cloud Agents on a project, (2) reviewing an agent-generated
  PR, (3) using Bugbot Autofix, (4) setting up autonomous coding workflows.
globs: ["**/.github/**", "**/vercel.json", "**/.cursor/**"]
alwaysApply: false
tags: [product]
---

# Cloud Agent Governance

## Purpose

Cursor Cloud Agents (launched Feb 2026) run autonomously in isolated VMs. They can write code, run tests, use software, take screenshots, record videos — and submit the result as a pull request. Bugbot Autofix extends this: it automatically detects issues in your PRs and proposes fixes.

**Cursor Automations (launched March 2026)** extend this further with always-on, event-triggered and scheduled agents. These are a different risk category and have their own dedicated skill — see **Cursor Automations Governance**. This skill covers one-off Cloud Agents and Bugbot Autofix.

This is powerful. It is also a fundamentally new risk model for non-technical founders and teachers who use Cursor. An AI agent autonomously pushing to your codebase, with no human watching in real time, needs governance.

## The Risk Model for Non-Technical Builders

### What Cloud Agents Can Do (Feb 2026)

| Capability | Risk |
|-----------|------|
| Write and modify code files | Can introduce bugs, security holes, or breaking changes |
| Run terminal commands in a VM | Can install packages, run scripts, modify configs |
| Use software (browser, terminal) with computer use | Can interact with any UI including admin panels in the VM |
| Submit PRs directly to your repository | Changes land in your codebase without you writing them |
| Record videos and screenshots as artifacts | Creates evidence of what happened — but you must review it |
| Push changes directly to a branch (if configured) | Bypasses even PR review if auto-merge is enabled |

### What Could Go Wrong

**For non-technical founders:**
- Agent introduces a subtle security bug in auth code
- Agent installs a dependency with a known vulnerability
- Agent modifies database queries in a way that breaks data integrity
- Agent generates code that passes tests but violates business logic
- Bugbot Autofix "fixes" something that wasn't actually broken

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

### Recommended Configuration

```markdown
For small teams and non-technical founders:

Mode: PROPOSE ONLY (not auto-merge)
- Bugbot posts a comment with the fix preview
- A human reviews and merges using @cursor merge
- Never enable auto-push to branch without review

Why not auto-merge?
Bugbot Autofix has a 35% merge rate — meaning 65% of its fixes require
human review. Even for the 35% that get merged, those were presumably
reviewed. Auto-merging without review is dangerous.
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