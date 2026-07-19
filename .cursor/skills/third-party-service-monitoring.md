---
description: >
  Monitors and manages dependencies on third-party services (APIs, CDNs, external tools).
  Covers uptime tracking, failure handling, vendor communication, and backup strategies.
  Critical for founders/teachers building products that rely on OpenAI, Stripe, Twilio, Supabase,
  or any external service. Use when: (1) integrating a new third-party API, (2) experiencing
  service degradation, (3) planning for vendor lock-in, (4) reviewing architecture single points
  of failure, (5) preparing for investor/partner due diligence.
globs: ["**/*.md", "**/*.json", "**/*.ts", "**/*.js", "**/*.py"]
alwaysApply: false
tags: [product, reliability]
---

# Third-Party Service Monitoring

## Purpose

Your product depends on services you don't control. When they break, your users blame you — not Twilio, not OpenAI, not your CDN. This skill ensures you track, monitor, and prepare for third-party service failures.

## Why This Matters

**For non-technical founders:** You've built an AI tutoring app. OpenAI's API has a 2-hour outage. Your users can't get help with homework. They cancel subscriptions. Your MRR drops 15%. You had no plan.

**For teachers learning to code:** You built a classroom tool that emails parents via SendGrid. SendGrid flags your account as spam (false positive). Emails stop going out. Parents complain to the principal. You don't know why.

**The reality:** Modern apps are 70% third-party services. You need to know when they break, how badly, and what to do.

## Critical Checks: Before You Integrate

**Run these before adding ANY third-party service:**

1. **Check the status page**
   - Does the service have a public status page? (e.g., status.openai.com, status.stripe.com)
   - Bookmark it. Check it weekly.
   - Subscribe to email/SMS alerts for critical services.

2. **Review the SLA (Service Level Agreement)**
   - What uptime do they guarantee? (99.9% = 8.7 hours downtime/year allowed)
   - What's the compensation if they miss it? (Credits, not cash — you can't pay rent with credits)
   - What's NOT covered? (Most SLAs exclude "beta" features, which is most AI APIs)

3. **Understand rate limits**
   - How many requests per minute/hour/day?
   - What happens when you exceed them? (429 errors, account suspension)
   - Can you buy higher limits? At what cost?
   - See `api-rate-limiting.md` for implementation patterns.

4. **Identify vendor lock-in**
   - How hard is it to switch providers? (OpenAI → Anthropic requires prompt rewrites)
   - Is your data portable? (Can you export user data if they shut down?)
   - Do they use proprietary formats? (Firebase Firestore → migration nightmare)

**Decision framework:**
- **Critical path** (payment, auth, core AI): Use best-in-class, accept lock-in, build fallbacks
- **Commodity** (CDN, email, storage): Use cheapest reliable option, keep switching easy
- **Nice-to-have** (analytics, A/B testing): Can tolerate 24h+ downtime

## Runtime Monitoring

**For Cursor Agent / coding sessions:**

When building with third-party services, always implement:

```typescript
// BAD: Silent failures
const response = await openai.chat.completions.create({...});
return response.choices[0].message.content;

// GOOD: Error tracking + fallback
import * as Sentry from '@sentry/node';

async function callOpenAI(prompt: string): Promise<string> {
  const startTime = Date.now();
  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      timeout: 15000, // 15s timeout
    });
    
    const latency = Date.now() - startTime;
    if (latency > 5000) {
      console.warn(`OpenAI slow: ${latency}ms`);
    }
    
    return response.choices[0]?.message?.content || FALLBACK_RESPONSE;
  } catch (error) {
    Sentry.captureException(error, {
      tags: { service: 'openai', endpoint: 'chat.completions' },
      extra: { latency: Date.now() - startTime },
    });
    
    // Fallback: cached response or degraded mode
    if (error.status === 429) {
      return getCachedResponse(prompt) || RATE_LIMIT_MESSAGE;
    }
    if (error.status >= 500) {
      return SERVICE_UNAVAILABLE_MESSAGE;
    }
    throw error; // Re-throw unexpected errors
  }
}
```

**Key patterns:**
- **Timeouts**: 15s for AI, 5s for payments, 3s for everything else
- **Retries with backoff**: For 429/5xx errors only (never 4xx client errors)
- **Circuit breakers**: Stop calling a service after 3 failures, retry after 30s
- **Graceful degradation**: Show cached results, queue requests, offer manual mode

**For Cursor agent:** Run `grep -r "fetch\|axios\|openai\|stripe" --include="*.ts" --include="*.js"` and verify every call has:
- Timeout (<30s)
- Error handling (try/catch with specific error types)
- Logging (Sentry, DataDog, or at minimum console.error)
- Fallback behavior (what happens when it fails?)

## Uptime Tracking

**Free tier (recommended for MVPs):**

1. **UptimeRobot** (uptimerobot.com)
   - Monitors up to 50 endpoints every 5 minutes (free)
   - Alerts via email, SMS, Slack, Discord
   - Set up monitors for:
     - Your app's health endpoint (`/api/health`)
     - Critical third-party services' status pages
     - Your payment webhook endpoint

2. **StatusPage integration**
   - Create a public status page (Atlassian Statuspage free tier, Instatus free)
   - Show: your app status + third-party dependencies
   - Example: "OpenAI API: ✅ | Stripe: ✅ | YourApp: ⚠️ Degraded"

**Paid tier (when you have revenue):**

- **Better Uptime / Hetrix:** $20/mo for 1-minute checks, multi-region
- **Pingdom:** $15/mo, good for transaction monitoring (test full user flows)
- **DataDog:** $15/host/mo, full observability (use when you have 5+ services)

**What to monitor:**

| Service | Endpoint | Expectation | Action on Failure |
|---------|----------|-------------|-------------------|
| Your app | `/health` | 200 in <500ms | Page on-call, investigate |
| OpenAI | `api.openai.com` | 200 in <10s | Switch to fallback model |
| Stripe | `api.stripe.com` | 200 in <3s | Queue charges, retry |
| YourDB | Connection test | Success in <2s | Scale up/read replica |
| CDN | Static asset | 200 in <1s | Invalidate cache |

## Vendor Communication

**When a service has an outage:**

1. **Check status page first** (don't email support yet)
   - If it's a known incident, they're already working on it
   - Estimated resolution time is usually posted

2. **If your app is impacted:**
   - Post on YOUR status page: "Experiencing degraded service due to [vendor] outage"
   - Email affected users if critical (e.g., "Tutoring sessions may fail for next 2 hours")
   - Never blame the vendor publicly — just state facts

3. **If you need to escalate:**
   - Reply to status page incident updates (they monitor these)
   - Use premium support channels if you pay for them
   - Tweet @vendor_support (public pressure works for major outages)

**Template: User communication during third-party outage**

```
Subject: [YourApp] experiencing temporary issues

Hi [Name],

We're aware that [feature, e.g., "AI tutoring sessions"] are currently unavailable.

**Cause:** Our [service provider, e.g., "AI partner"] is experiencing an outage.
**Impact:** [Specific impact, e.g., "New tutoring sessions cannot start"]
**Expected resolution:** [timeframe from vendor status page, e.g., "1-2 hours"]

**What you can do now:**
- [Alternative action 1, e.g., "Review past session summaries"]
- [Alternative action 2, e.g., "Schedule a session with a human tutor"]

We'll email you when service is restored.

Thanks for your patience,
The [YourApp] Team
```

## Vendor Risk Assessment

**Quarterly review (30 minutes):**

For each critical third-party service, verify:

1. **Financial health**
   - Are they still growing? (Check blog, press releases)
   - Any layoffs? (signal of trouble)
   - Funding runway? (Crunchbase for startups)

2. **Product direction**
   - Still investing in the product you use?
   - Pricing changes? (Rate increases = budget impact)
   - Feature deprecations? (Migration planning needed)

3. **Security posture**
   - Any breaches in the last quarter? (haveibeenpwned.com for their domain)
   - SOC 2 / ISO 27001 still current? (Ask for certificate)
   - New compliance certifications? (GDPR, HIPAA, COPPA for edu)

4. **Support quality**
   - Response time to tickets? (Track last 3 interactions)
   - Resolution time? (Average across last quarter)
   - Knowledge base updated? (Stale docs = red flag)

**Red flags (consider switching):**
- 3+ unplanned outages in 90 days
- Security breach with poor communication
- Pricing increase >20% without notice
- Key features deprecated without migration path
- Support response >48 hours for critical issues

## Fallback Strategies

**For Cursor agent / architecture decisions:**

When a service has no fallback, you have a single point of failure. Mitigate with:

**Pattern 1: Multi-provider (for critical AI)**
```typescript
const AI_PROVIDERS = [
  { name: 'openai', client: openai, model: 'gpt-4o-mini' },
  { name: 'anthropic', client: anthropic, model: 'claude-3-5-sonnet' },
  { name: 'groq', client: groq, model: 'llama-3.1-70b-versatile' },
];

async function generateCompletion(prompt: string): Promise<string> {
  for (const provider of AI_PROVIDERS) {
    try {
      return await provider.client.completions.create({
        model: provider.model,
        messages: [{ role: 'user', content: prompt }],
        timeout: 10000,
      });
    } catch (error) {
      console.warn(`${provider.name} failed, trying next`);
      Sentry.captureException(error, { tags: { provider: provider.name } });
      continue;
    }
  }
  throw new Error('All AI providers failed');
}
```

**Pattern 2: Queue + retry (for non-urgent)**
```typescript
import { Queue } from 'bullmq';

const emailQueue = new Queue('email', { connection: redis });

async function sendEmail(to: string, subject: string, body: string) {
  await emailQueue.add('send', { to, subject, body }, {
    attempts: 5,
    backoff: { type: 'exponential', delay: 2000 },
    removeOnComplete: true,
  });
}
```

**Pattern 3: Manual mode (for payments)**
```typescript
if (stripeUnavailable) {
  // Show bank transfer instructions
  // Queue order for manual processing later
  // Email finance team
  return {
    paymentMethod: 'manual',
    instructions: 'Please wire to [bank details]',
    orderQueued: true,
  };
}
```

## Cost Monitoring

Third-party services are your biggest variable cost. Monitor weekly:

**For Cursor agent:** Run `grep -r "process.env.*_KEY\|_API_KEY" --include="*.ts" --include="*.env"` and for each service:

1. **Current spend:** Check dashboard (OpenAI usage page, Stripe dashboard, etc.)
2. **Projected month-end:** Current daily spend × remaining days
3. **Budget alert threshold:** 80% of monthly budget = Slack alert
4. **Anomaly detection:** >2x normal daily spend = immediate investigation

**Cost alert setup:**
- Most services have built-in budget alerts (enable them!)
- OpenAI: Settings → Usage → Budget alerts
- AWS: Billing → Budgets
- Stripe: Settings → Billing → Spend limits

**Example monitoring script (run in heartbeat):**
```bash
#!/bin/bash
# Check OpenAI spend
OPENAI_SPEND=$(curl -s -H "Authorization: Bearer $OPENAI_KEY" \
  "https://api.openai.com/v1/usage" | jq '.total_usage')
OPENAI_BUDGET=10000 # $100 in cents

if [ $OPENAI_SPEND -gt $((OPENAI_BUDGET * 80 / 100)) ]; then
  echo "⚠️ OpenAI spend at $(($OPENAI_SPEND / 100))% of budget"
fi
```

## Pre-Commit Checklist

**Run Cursor agent:** `grep -r "third-party\|external\|3rd-party" --include="*.md" docs/`

Verify docs answer:
- [ ] Which third-party services do we use?
- [ ] What's the backup plan if each one fails?
- [ ] Who do we contact at each vendor? (Support email, account manager)
- [ ] What are our current spend and limits?
- [ ] When did we last review vendor health?

## Common Issues & Quick Fixes

**Issue: Service returns 503 (Service Unavailable)**
- **Cause:** Vendor is overloaded or having an outage
- **Fix:** Implement exponential backoff + circuit breaker (see patterns above)

**Issue: 429 Too Many Requests**
- **Cause:** You've hit rate limits
- **Fix:** See `api-rate-limiting.md`. Common solutions: request queue, caching, upgrading tier

**Issue: Sudden 10x cost spike**
- **Cause:** Infinite loop, retry storm, or compromised API key
- **Fix:** Rotate API key immediately, check logs for abnormal usage, implement spend caps

**Issue: Vendor deprecated your API version**
- **Cause:** You're using an old API (e.g., OpenAI `gpt-3.5-turbo`)
- **Fix:** Check vendor changelog, migrate to current API, test in staging first

## Related Skills

- `api-rate-limiting.md` — Handling rate limits gracefully
- `error-handling.md` — General error handling patterns
- `monitoring-alerting.md` — Full observability stack
- `cost-governance.md` — Cloud cost management
- `backup-recovery.md` — Data loss prevention
- `incident-response.md` — When things go wrong

## TL;DR

1. Check vendor status pages weekly, subscribe to alerts
2. Every third-party call needs: timeout (<30s), error handling, fallback
3. Monitor uptime with UptimeRobot (free) or Better Uptime (paid)
4. Track spend weekly, set 80% budget alerts
5. Quarterly vendor health review (30 min per service)
6. Always have a fallback for critical path services
7. Communicate outages to users honestly — they'll find out anyway

**For TYO community:** Your app is only as reliable as its weakest dependency. Assume every third-party service will fail at the worst possible time. Plan accordingly.
