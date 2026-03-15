---
description: >
  A structured incident response runbook for when something breaks in production.
  Covers the first 30 minutes, communication, diagnosis, fix, and post-mortem.
  Designed for solo founders and small teams without dedicated ops staff.
  Use when: (1) production is down, (2) users are reporting errors, (3) data is
  corrupted, (4) a security incident is suspected, (5) a deployment went wrong.
globs: ["**/*"]
alwaysApply: false
---

# Incident Response

## Purpose

When production breaks, you need a clear sequence of actions — not a comprehensive guide to read. This skill is a runbook: follow the steps in order. Think later, act now.

## Activation

This skill activates when you mention:
- "production is down", "site is broken", "app is crashing"
- "users are seeing errors", "500 errors", "white screen"
- "incident", "outage", "downtime"
- "something broke", "deployment broke", "it's not working"
- "security breach", "data leak", "compromised"

## Severity Levels

Before you start, classify the incident:

| Level | Description | Response Time |
|---|---|---|
| **SEV 1 — Down** | Core functionality is broken for all users. No workaround. | Drop everything. Fix now. |
| **SEV 2 — Degraded** | Core functionality is impaired but partially working. Or broken for some users. | Fix within 1 hour. |
| **SEV 3 — Minor** | Non-critical feature is broken. Workaround exists. | Fix within 24 hours. |
| **SEV 4 — Cosmetic** | Visual glitch, typo, or minor UX issue. No functional impact. | Fix in next deploy. |

## The First 30 Minutes (SEV 1 & SEV 2)

Follow these steps in order. Don't skip ahead.

### Minute 0-5: Confirm and Contain

```
□ CONFIRM the problem is real
  └── Visit the production URL yourself
  └── Check from a different device/network (could be your local issue)
  └── Check your hosting platform's status page

□ Can you ROLLBACK immediately?
  └── If the problem started after a recent deploy: ROLLBACK NOW
  └── Vercel: npx vercel promote <previous-deployment-url>
  └── Railway: use dashboard to rollback
  └── Git: git revert HEAD && git push origin main
  └── Rolling back first, investigating second saves user-facing minutes

□ If rollback isn't possible or didn't fix it: move to diagnosis
```

### Minute 5-15: Diagnose

```
□ Check ERROR LOGS
  └── Vercel: Dashboard → Project → Logs (filter by "error")
  └── Railway: Dashboard → Project → Logs
  └── Browser: open DevTools → Console tab on the production URL
  └── Sentry/error tracker: check latest events

□ Identify the SCOPE
  └── All users or some users?
  └── All pages or specific pages?
  └── All API routes or specific routes?
  └── Started when? (correlate with deploys, config changes, provider outages)

□ Check EXTERNAL DEPENDENCIES
  └── Database: can you connect? run a simple query?
  └── Auth provider: is their status page green?
  └── API providers (OpenAI, Stripe, etc.): are they up?
  └── DNS: is your domain resolving correctly?
  └── SSL: is the certificate valid?
```

### Minute 15-30: Fix or Mitigate

```
□ If you found the root cause:
  └── Fix it
  └── Test locally
  └── Deploy the fix
  └── Verify on production

□ If you can't find the root cause yet:
  └── Put up a maintenance page (better than a broken page)
  └── Disable the broken feature if possible (feature flag, API route removal)
  └── Communicate to users (see Communication section)
  └── Continue investigating without time pressure
```

## Communication

### Who Needs to Know

```
□ Users seeing the problem:
  └── Status page update, in-app banner, or social media post
  └── Template: "We're aware of [brief description]. Working on a fix. 
       [Feature] may be unavailable for [estimated time]."

□ Team members (if applicable):
  └── Slack/Discord message with: what's broken, severity, who's on it

□ Yourself (solo founder):
  └── Write a quick note of what you've done so far
  └── If you're stuck, this note helps when you come back fresh
```

### What to Say (Templates)

**Initial acknowledgment:**
> We're aware that [feature/service] is currently experiencing issues. We're investigating and will update shortly.

**Update with progress:**
> Update: We've identified the cause of [issue]. Working on a fix. Estimated resolution: [time].

**Resolved:**
> [Feature/service] has been restored. The issue was caused by [brief, non-technical explanation]. We've implemented [fix/prevention] to prevent recurrence.

## Common Incident Patterns

### 1. Deployment Broke Something

**Symptoms:** Errors started immediately after a deploy.
**Fix:** Rollback to previous deployment. Then investigate what changed.

```
□ Rollback
□ Compare the failing deploy with the previous working version
□ Check for: missing env vars, changed API routes, broken imports
```

### 2. Database Connection Failures

**Symptoms:** 500 errors on pages that read/write data. Static pages work fine.
**Fix:** Check connection string, pooling, and provider status.

```
□ Can you connect to the database from a local client?
□ Is the connection string correct in the deployment environment?
□ Are you using connection pooling? (Required for serverless)
□ Has the database provider had an outage? Check their status page.
□ Have you exceeded your connection limit?
```

### 3. API Provider Outage

**Symptoms:** Specific features fail. Errors mention timeout or 503.
**Fix:** Add fallbacks and graceful degradation.

```
□ Check the provider's status page (status.openai.com, etc.)
□ If provider is down: can you serve a cached response?
□ If provider is down: can you disable the feature gracefully?
□ Add a try/catch that returns a user-friendly error instead of crashing
```

### 4. SSL/DNS Issues

**Symptoms:** Browser shows "Not Secure" or "Can't reach site." No server errors.
**Fix:** Check DNS and SSL configuration.

```
□ Is the domain resolving? (dig yourdomain.com or nslookup)
□ Is the SSL certificate valid? (check expiry date)
□ Did you recently change DNS providers or hosting?
□ DNS propagation can take up to 48 hours — was a change made recently?
```

### 5. Runaway Costs / Rate Limiting

**Symptoms:** API returns 429 (rate limited) or provider sends billing alert.
**Fix:** Disable the endpoint, fix the loop, add limits.

```
□ Disable the endpoint or function causing the issue
□ Check logs for retry loops or recursive calls
□ Add rate limiting and retry backoff (see Cost Governance skill)
□ Set a hard spending cap on the provider
```

### 6. Security Incident

**Symptoms:** Unusual activity, unauthorised access, data exposure.
**Fix:** Contain first, investigate second.

```
□ Rotate ALL exposed credentials immediately
  └── API keys, database passwords, OAuth secrets, tokens
□ Revoke active sessions (force all users to re-authenticate)
□ Check git history for recently committed secrets
□ Check access logs for unauthorised requests
□ If user data is exposed: consult legal obligations (data breach notification)
□ Document everything for the post-mortem
```

## Post-Incident Review

After the incident is resolved (within 24 hours):

```
□ Write a brief incident report:
  └── What happened?
  └── When did it start and when was it resolved?
  └── What was the impact? (users affected, duration, data loss?)
  └── What was the root cause?
  └── What did you do to fix it?
  └── What will you do to prevent it from happening again?

□ Implement preventive measures:
  └── Add monitoring/alerting for this failure mode
  └── Add a test that would have caught this
  └── Update deployment checklist if applicable
  └── Update documentation if the fix involved non-obvious steps

□ File the report:
  └── Keep incident reports in a known location (e.g., docs/incidents/)
  └── They're invaluable when a similar issue happens in 6 months
```

### Incident Report Template

```markdown
# Incident Report: [Brief Title]

**Date:** YYYY-MM-DD
**Severity:** SEV 1/2/3/4
**Duration:** [start time] to [end time] ([total minutes])
**Impact:** [who was affected and how]

## Timeline
- HH:MM — [First sign of issue]
- HH:MM — [Incident confirmed]
- HH:MM — [Actions taken]
- HH:MM — [Resolved]

## Root Cause
[What actually caused the problem]

## Resolution
[What you did to fix it]

## Prevention
[What you'll do to prevent recurrence]
- [ ] Action item 1
- [ ] Action item 2
```

## Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│          INCIDENT RESPONSE RUNBOOK               │
├─────────────────────────────────────────────────┤
│                                                 │
│  MINUTE 0-5:                                    │
│  □ Confirm the problem is real                  │
│  □ Can you rollback? DO IT NOW.                 │
│                                                 │
│  MINUTE 5-15:                                   │
│  □ Check error logs                             │
│  □ Identify scope (all users? some?)            │
│  □ Check external dependencies                  │
│                                                 │
│  MINUTE 15-30:                                  │
│  □ Fix if root cause found                      │
│  □ Mitigate if not (maintenance page)           │
│  □ Communicate to affected users                │
│                                                 │
│  AFTER:                                         │
│  □ Write incident report within 24 hours        │
│  □ Implement prevention measures                │
│  □ Update monitoring and tests                  │
│                                                 │
│  GOLDEN RULE:                                   │
│  Rollback first, investigate second.            │
│                                                 │
└─────────────────────────────────────────────────┘
```
