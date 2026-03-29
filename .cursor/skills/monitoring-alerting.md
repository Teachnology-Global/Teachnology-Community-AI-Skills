---
description: >
  Ensures every production application has visibility into errors, downtime, and
  performance degradation before users start complaining. Covers error tracking,
  uptime monitoring, performance metrics, alert routing, and on-call runbooks.
  Use when: (1) launching a new product or feature, (2) setting up a new deployment,
  (3) reviewing whether an app has adequate production visibility, (4) adding
  monitoring after an incident, (5) asking "how will I know if this breaks?"
globs: ["**/vercel.json", "**/fly.toml", "**/railway.json", "**/.github/**", "**/next.config.*", "**/app.js", "**/server.ts"]
alwaysApply: false
tags: [product]
---

# Monitoring & Alerting

## Purpose

You should find out your app is broken before your users do. Without monitoring, you find out through support tickets — hours after the fact, with no data to diagnose the problem.

For non-technical founders: this skill exists because "I'll set up monitoring later" is how you end up staring at logs at midnight with no idea what broke or when.

## Activation

This skill activates when you mention:
- "monitoring", "alerting", "alerts", "on-call"
- "error tracking", "Sentry", "Bugsnag", "Rollbar"
- "uptime", "downtime", "status page"
- "production error", "how will I know if this breaks"
- "logs", "logging", "observability"
- "performance", "slow", "response time", "latency"

Also activates when:
- Deploying to production for the first time
- Setting up a new Vercel/Railway/Fly project
- Reviewing a production-ready checklist
- After an incident where monitoring was absent

## The Three-Layer Stack

Every production app needs all three layers. Most non-technical founders start with zero.

```
Layer 1: ERROR TRACKING       — "Something threw an exception"
  → Sentry (free tier: 5,000 errors/month)

Layer 2: UPTIME MONITORING    — "The site is down"
  → BetterStack / UptimeRobot / Checkly (free tiers available)

Layer 3: PERFORMANCE METRICS  — "The site is slow / the AI feature is expensive"
  → Vercel Analytics (built-in) / Langfuse for AI features (see LLM Observability skill)
```

You need layer 1 and layer 2 as a minimum. Layer 3 for any app with AI features or high traffic.

## Layer 1: Error Tracking (Sentry)

### Setup (Next.js + Vercel)

```bash
npx @sentry/wizard@latest -i nextjs
```

This creates `sentry.client.config.ts`, `sentry.server.config.ts`, and instruments your app automatically.

### Minimum Configuration

```typescript
// sentry.client.config.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  
  // Sample rate — 1.0 means capture 100% of errors
  // Reduce to 0.1 (10%) if you hit free tier limits at scale
  tracesSampleRate: 1.0,
  
  // Only run in production — avoid noise from dev/staging
  enabled: process.env.NODE_ENV === "production",
  
  // Tag errors with environment for filtering
  environment: process.env.NEXT_PUBLIC_ENVIRONMENT ?? "production",
  
  // ⚠️ IMPORTANT: Never send PII in error context
  // beforeSend hook to strip personal data:
  beforeSend(event) {
    // Remove user email from error context
    if (event.user) {
      delete event.user.email;
      delete event.user.ip_address;
    }
    return event;
  },
});
```

### Capturing Expected Errors

```typescript
// Not all errors are bugs — capture context for the ones that are
import * as Sentry from "@sentry/nextjs";

// ✅ Capture an error with context
try {
  await processPayment(orderId);
} catch (error) {
  Sentry.captureException(error, {
    tags: { area: "payments", orderId },
    // ⚠️ Never include card numbers, CVV, or full PAN here
  });
  throw error; // re-throw so the user sees the error too
}

// ✅ Capture a warning (not an exception)
Sentry.captureMessage("Slow DB query detected", {
  level: "warning",
  extra: { queryMs: elapsed },
});
```

### Required Sentry Alert Rules

Set these up in Sentry → Alerts → Create Alert:

```markdown
Alert 1: First Seen Error (new issue type)
  Condition: A new issue is created
  Action: Notify [your email or Slack channel]
  Why: New error types need immediate attention — you haven't seen them before.

Alert 2: Error Spike
  Condition: Number of events > 10 in 5 minutes
  Action: Notify [your email or Slack channel]
  Why: A sudden spike means something changed — deployment, traffic surge, external API failure.

Alert 3: Critical Path Errors (auth, payments)
  Condition: Issue in transaction "checkout" OR "login" is seen > 1 time in 1 hour
  Action: Page [your phone via PagerDuty / SMS]
  Why: Auth and payment failures cost you revenue every minute. Don't wait for email.
```

### What NOT to Log

```typescript
// ❌ Never send PII to error tracking
Sentry.captureException(error, {
  extra: {
    userEmail: user.email,        // ❌ PII
    creditCard: order.cardLast4,  // ❌ PII
    ipAddress: req.ip,            // ❌ PII
    sessionToken: req.headers.authorization, // ❌ Credential
  }
});

// ✅ Use anonymised identifiers only
Sentry.captureException(error, {
  extra: {
    userId: user.id,              // ✅ Non-identifying internal ID
    orderId: order.id,            // ✅ Internal reference
    region: user.country,         // ✅ Low-specificity geographic data
  }
});
```

## Layer 2: Uptime Monitoring

### BetterStack (Recommended — Free Tier)

BetterStack's free tier includes 10 monitors, 3-minute check intervals, and a public status page.

```markdown
Setup:
1. Create account at betterstack.com
2. Add monitor → URL → https://yourapp.com/api/health
3. Set check interval: 1 minute (paid) or 3 minutes (free)
4. Add alert contact: your email + Slack webhook
5. Enable status page (public — link in your app footer)

Monitor your critical endpoints:
- https://yourapp.com (homepage)
- https://yourapp.com/api/health (dedicated health endpoint — see below)
- https://yourapp.com/login (auth flow)
- Any API endpoint your users depend on
```

### Build a Health Endpoint

Every production app needs a `/api/health` endpoint. It should verify your app's critical dependencies are reachable:

```typescript
// app/api/health/route.ts (Next.js App Router)
import { NextResponse } from "next/server";
import { db } from "@/lib/db";

export async function GET() {
  const checks: Record<string, boolean> = {};
  let allHealthy = true;

  // Check 1: Database connectivity
  try {
    await db.execute("SELECT 1");
    checks.database = true;
  } catch {
    checks.database = false;
    allHealthy = false;
  }

  // Check 2: (Optional) External API availability
  // Only check if your app cannot function without it
  // Don't check APIs that are optional or degradable
  
  const status = allHealthy ? 200 : 503;
  
  return NextResponse.json(
    {
      status: allHealthy ? "healthy" : "degraded",
      checks,
      timestamp: new Date().toISOString(),
      // ⚠️ Do not expose internal IP, version, or stack details here
      // (attackers use health endpoints for reconnaissance)
    },
    { status }
  );
}
```

**Security note:** Return a 503 when unhealthy, not 500. Don't include stack traces or version numbers in the health endpoint response.

### UptimeRobot (Alternative Free Option)

- Free tier: 50 monitors, 5-minute check intervals
- Adds up to 5 contacts for alerts
- Simpler setup, no status page on free tier

## Layer 3: Performance Monitoring

### Vercel Analytics (Built-In)

If you're on Vercel, enable Speed Insights and Web Analytics in the dashboard:

```bash
npm install @vercel/analytics @vercel/speed-insights
```

```typescript
// app/layout.tsx
import { Analytics } from "@vercel/analytics/react";
import { SpeedInsights } from "@vercel/speed-insights/next";

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
```

This gives you Core Web Vitals (LCP, FID, CLS) without any additional configuration.

### Core Web Vitals Targets

| Metric | Good | Needs Work | Poor |
|--------|------|-----------|------|
| **LCP** (Largest Contentful Paint) | < 2.5s | 2.5–4s | > 4s |
| **FID** (First Input Delay) | < 100ms | 100–300ms | > 300ms |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 0.1–0.25 | > 0.25 |
| **TTFB** (Time to First Byte) | < 800ms | 800ms–1.8s | > 1.8s |

### For AI Features: LLM Observability

If your app uses AI features (OpenAI, Anthropic, etc.), Layer 3 also means tracking AI-specific metrics. See the **LLM Observability** skill for full guidance. At minimum:

```typescript
// Log every AI call to your database
const start = Date.now();
const response = await openai.chat.completions.create({ ... });
const durationMs = Date.now() - start;

await db.insert(aiCallLogs).values({
  model: response.model,
  promptTokens: response.usage.prompt_tokens,
  completionTokens: response.usage.completion_tokens,
  durationMs,
  userId,             // For per-user cost tracking
  feature: "chat",    // Tag by feature
  timestamp: new Date(),
});
```

## Pre-Launch Monitoring Checklist

Do this before going live, not after your first incident:

```markdown
## Monitoring Pre-Launch Checklist

Error Tracking:
- [ ] Sentry (or equivalent) installed and configured
- [ ] Sentry DSN set in production environment variables (not committed to code)
- [ ] PII stripped from error context (beforeSend hook configured)
- [ ] Test alert fired (throw a deliberate error, confirm Sentry received it)
- [ ] Alert rules configured: new issue, error spike, critical path errors
- [ ] Sentry environment set to "production" (not "development")

Uptime Monitoring:
- [ ] /api/health endpoint built and returns 200 (healthy) / 503 (degraded)
- [ ] Health endpoint monitored by BetterStack / UptimeRobot
- [ ] At least the homepage is monitored
- [ ] Alert contact (email + Slack) configured and tested
- [ ] Status page set up (optional but professional)

Performance:
- [ ] Vercel Analytics / Speed Insights enabled (if on Vercel)
- [ ] Core Web Vitals baseline captured before launch
- [ ] For AI features: LLM call logging in place

Alerting & On-Call:
- [ ] Someone is reachable when an alert fires
  (even if it's just: "Jason checks Slack at 9am")
- [ ] Runbook written for the most likely failure: "What do I do if the DB goes down?"
- [ ] Rollback plan documented (known working deployment ID)
```

## Simple Runbook Template

Every production app should have a one-page runbook. It doesn't need to be long — it needs to exist when you're panicking at midnight:

```markdown
# [App Name] Production Runbook

## Contacts
- Primary: [Your name] — [phone/Slack]
- Backup: [Dev/contractor name] — [contact]

## If the App is Down
1. Check status page: [your status page URL]
2. Check Vercel/Railway/Fly dashboard for deployment errors
3. Check Sentry for recent error spikes
4. Roll back to last known good deployment:
   - Vercel: Deployments tab → previous deployment → Promote to Production
   - Railway: Deployments → ... → Rollback
5. If rollback doesn't fix it: [next step — check DB, check env vars]
6. Notify users if downtime > 15 minutes: post to [status page / Twitter / community]

## If Errors Spike (Sentry Alert)
1. Open Sentry → Issues → sort by "First Seen"
2. Identify new issues that appeared after the last deployment
3. If deployment caused it: rollback (see above)
4. If it's a third-party API failure: check [Stripe/OpenAI/etc.] status page

## Database Down
1. Check [Neon/Supabase/PlanetScale] status page
2. Check connection string in environment variables (not expired, not rotated)
3. Check connection pool exhaustion (common cause: too many concurrent requests)
4. Contact: [DB support channel]

## Escalation
If unresolved after 30 minutes: [emergency contact, or: accept the downtime and post a status update]
```

## Alert Fatigue: Keep Alerts Actionable

More alerts ≠ better monitoring. Alert fatigue means you start ignoring everything.

```markdown
RULE: Every alert must have a clear action

✅ Actionable alert: "5 errors on /checkout in the last 5 minutes → check Sentry"
✅ Actionable alert: "Site is down → check Vercel dashboard and roll back"

❌ Alert fatigue: "100 warnings about slow DB queries" (every hour, nothing to do)
❌ Alert fatigue: "Sentry resolved an issue" (not actionable, just noise)

Tuning guide:
- Start with 3-5 alerts maximum
- Each alert has a named owner (even if it's just you)
- After every false alert: tune the threshold or remove it
- After every missed incident: add the alert that would have caught it
```

## Integration

### With Deployment Checklist
- Monitoring pre-launch checklist runs before every production deploy
- Health endpoint test is part of the deployment verification step
- Sentry environment must match deployment environment

### With LLM Observability
- AI feature monitoring (token usage, error rates, latency) is a specialised extension of Layer 3
- See the LLM Observability skill for per-user rate limits, cost tracking, and hallucination detection

### With Incident Response
- Monitoring alerts are the trigger that starts the Incident Response runbook
- The runbook template above is a simplified version of the full Incident Response skill
- When an alert fires at scale: switch to the Incident Response skill for structured coordination

### With AI Cost Management
- Error budget applies to AI spend too — set a budget alert in your AI provider dashboard
- Runaway AI calls (loops, no max_tokens) will appear as cost spikes before they appear as outages
- Monitor AI spend as part of Layer 3; cost alert is part of your alert set
