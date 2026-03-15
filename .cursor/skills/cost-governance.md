---
description: >
  Governs API costs, cloud spending, and usage limits for AI-powered applications.
  Prevents surprise bills from OpenAI, Anthropic, Vercel, database providers, and
  other pay-per-use services. Critical for solo founders and small teams.
  Use when: (1) setting up a new API integration, (2) configuring usage limits,
  (3) investigating unexpected costs, (4) budgeting for a new project,
  (5) optimising an existing application's running costs.
globs: ["**/*.config.*", "**/vercel.json", "**/.env*", "**/package.json"]
alwaysApply: false
---

# Cost Governance

## Purpose

AI-powered applications use pay-per-use services that can generate surprise bills fast. A runaway loop, a missing cache, or an uncapped API endpoint can cost hundreds of dollars overnight. This skill ensures you set limits, monitor costs, and design for predictable spending.

## Why This Matters

Real examples from the community:
- A solo founder's OpenAI bill hit $800 in one weekend because a retry loop ran 40,000 times
- A Vercel project exceeded the free tier by 10x because serverless functions had no timeout
- A Neon database bill spiked because connection pooling wasn't configured and each request opened a new connection
- A Stripe webhook handler re-processed events in a loop, charging customers multiple times

**For non-technical founders:** Every API call costs money. Most services charge per request, per token, or per compute-second. Without limits, a bug can drain your account. Set limits before you ship, not after the bill arrives.

## Activation

This skill activates when you mention:
- "API costs", "usage limits", "billing", "budget"
- "surprise bill", "unexpected charges", "overage"
- "OpenAI costs", "Anthropic costs", "Vercel costs"
- "rate limiting", "throttling", "caching"
- "cost optimisation", "reduce costs", "save money"

## Setup Checklist (Every New Project)

```
□ Set spending limits on all API providers (see provider-specific sections below)
□ Configure alerts at 50% and 80% of your monthly budget
□ Implement caching for repeated API calls
□ Add rate limiting to all public-facing API endpoints
□ Set timeouts on all serverless functions
□ Configure connection pooling for databases
□ Document your expected monthly cost in the project README
□ Set up a monthly cost review reminder
```

## Provider-Specific Guidance

### OpenAI / Anthropic (LLM APIs)

**The biggest risk:** Uncontrolled token usage. A single GPT-4 / Claude call can cost $0.01-0.15. At scale, this adds up fast.

```
□ Set monthly spending limit in the provider dashboard
  └── OpenAI: Settings → Billing → Usage limits
  └── Anthropic: Settings → Spending Limits
□ Set a hard cap (service stops) AND a soft cap (email alert)
□ Use the cheapest model that works for the task
  └── Don't use GPT-4o / Claude Opus for tasks GPT-4o-mini / Claude Haiku can handle
  └── Model selection should be a config variable, not hardcoded
□ Cache responses for identical or near-identical inputs
□ Implement token counting before sending requests
  └── Reject or truncate inputs that would exceed your per-request budget
□ Add retry limits with exponential backoff (max 3 retries)
  └── Never retry in a tight loop without a delay
□ Log every API call with: model, token count, cost, timestamp
  └── You can't optimise what you can't measure
```

**Cost reference (as of early 2026):**

| Model | Input (per 1M tokens) | Output (per 1M tokens) |
|---|---|---|
| GPT-4o | $2.50 | $10.00 |
| GPT-4o-mini | $0.15 | $0.60 |
| Claude Opus 4 | $15.00 | $75.00 |
| Claude Sonnet 4 | $3.00 | $15.00 |
| Claude Haiku 3.5 | $0.80 | $4.00 |

*Prices change. Check the provider's pricing page before budgeting.*

### Vercel

**The biggest risk:** Serverless function invocations and bandwidth on the free/hobby tier.

```
□ Set function timeout (default is 10s — lower it if possible)
  └── vercel.json: "functions": { "api/**": { "maxDuration": 10 } }
□ Use ISR (Incremental Static Regeneration) instead of SSR where possible
  └── SSR = function invocation on every request = costs money
  └── ISR = cached static page with periodic revalidation = much cheaper
□ Enable Vercel's spending limit (Settings → Billing → Spend Management)
□ Monitor Edge Middleware — it runs on EVERY request, including static assets
  └── Keep middleware logic minimal and fast
□ Use Vercel Analytics sparingly — it's metered on Pro plans
□ Check image optimisation usage (Vercel Image Optimization is metered)
```

### Database (Neon / Supabase / PlanetScale)

**The biggest risk:** Connection count and compute time.

```
□ Use connection pooling for ALL serverless deployments
  └── Neon: use the -pooler connection string
  └── Supabase: use port 6543 (pooler), not 5432 (direct)
□ Set connection limits appropriate to your plan
□ Add query timeouts to prevent runaway queries
  └── statement_timeout = '30s' in Neon
□ Index your most-queried columns
  └── Missing indexes = full table scans = slow queries = more compute time = higher bills
□ Monitor storage usage — databases charge for storage
□ Set up auto-suspend for dev/staging databases (Neon supports this)
```

### Stripe

**The biggest risk:** Webhook handlers that re-process events.

```
□ Implement idempotency for all webhook handlers
  └── Store processed event IDs and skip duplicates
□ Verify webhook signatures to prevent replay attacks
□ Handle Stripe's retry logic — they retry failed webhooks for up to 3 days
□ Test in Stripe's test mode before going live
□ Set up Stripe Radar rules to prevent fraudulent charges
```

### ElevenLabs / Voice APIs

**The biggest risk:** Character count. Voice generation is expensive per character.

```
□ Know your plan's character limit and set alerts at 50%
□ Cache generated audio — never regenerate the same text twice
□ Truncate or summarise long inputs before sending to voice API
□ Use the cheapest voice model that meets quality requirements
□ Monitor character usage weekly
```

## Design Patterns for Cost Control

### 1. Cache Everything You Can

```typescript
// Before calling an expensive API, check cache
const cacheKey = createHash('sha256').update(prompt).digest('hex');
const cached = await cache.get(cacheKey);
if (cached) return cached;

const result = await openai.chat.completions.create({ ... });
await cache.set(cacheKey, result, { ttl: 3600 }); // 1 hour
return result;
```

### 2. Rate Limit Public Endpoints

```typescript
// Use a rate limiter on any endpoint that calls a paid API
import { Ratelimit } from "@upstash/ratelimit";

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, "1 m"), // 10 requests per minute
});

// In your API route:
const { success } = await ratelimit.limit(identifier);
if (!success) return new Response("Rate limited", { status: 429 });
```

### 3. Set Hard Timeouts

```typescript
// Never let a function run forever
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 10000); // 10s

try {
  const result = await fetch(url, { signal: controller.signal });
} finally {
  clearTimeout(timeout);
}
```

### 4. Model Routing

```typescript
// Use the cheapest model that works for each task
const model = task === "classification" ? "gpt-4o-mini" 
            : task === "generation"     ? "gpt-4o"
            : "gpt-4o-mini"; // default to cheap
```

## Monthly Cost Review

Run this check on the 1st of every month:

```
□ Review actual spend vs budget for each provider
□ Identify the top 3 cost drivers
□ Check for any anomalies (sudden spikes, unusual patterns)
□ Verify all spending limits and alerts are still configured
□ Update cost estimates in the project README if actual differs from expected
□ Check if cheaper model versions have been released since last review
□ Review cache hit rates — low hit rates mean wasted API calls
```

## Budget Template

For planning purposes, estimate your monthly costs:

```
Project: _______________
Expected monthly users: ___

API Costs:
  LLM (model × avg tokens × requests/day × 30): $___
  Voice generation (characters/month):           $___
  Other APIs:                                    $___

Infrastructure:
  Hosting (Vercel/Railway/Fly.io plan):          $___
  Database (Neon/Supabase plan):                 $___
  Domain + DNS:                                  $___

Services:
  Auth (Clerk/Auth0/Supabase):                   $___
  Email (Resend/SendGrid):                       $___
  Monitoring (Sentry/LogRocket):                 $___

Total estimated monthly cost:                    $___
Break-even point (at $X/customer):               ___ customers
```

## Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│             COST GOVERNANCE                      │
├─────────────────────────────────────────────────┤
│                                                 │
│  BEFORE SHIPPING:                               │
│  □ Spending limits set on all providers         │
│  □ Alerts at 50% and 80% of budget             │
│  □ Rate limiting on public API endpoints        │
│  □ Caching for repeated API calls               │
│  □ Timeouts on all serverless functions         │
│  □ Connection pooling for databases             │
│                                                 │
│  DESIGN RULES:                                  │
│  □ Use cheapest model that works                │
│  □ Cache before calling                         │
│  □ Never retry without backoff                  │
│  □ Log every paid API call                      │
│                                                 │
│  MONTHLY:                                       │
│  □ Review actual vs budget                      │
│  □ Check for anomalies                          │
│  □ Verify limits still configured               │
│                                                 │
│  🚨 IF SURPRISE BILL:                           │
│  1. Disable the endpoint/function immediately   │
│  2. Check logs for runaway loops or retries     │
│  3. Set a hard spending cap                     │
│  4. Fix the root cause before re-enabling       │
│                                                 │
└─────────────────────────────────────────────────┘
```
