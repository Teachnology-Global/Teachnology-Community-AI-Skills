---
description: >
  Prevents cloud cost disasters by implementing budget alerts, spend monitoring, and
  auto-scaling safeguards. Covers AWS, GCP, Azure, Vercel, Railway, and AI API costs
  (OpenAI, Anthropic, Replicate). Critical for founders/teachers bootstrapping products
  or managing tight runways. Use when: (1) setting up a new cloud account, (2) experiencing
  unexpected bills, (3) preparing for traffic spikes, (4) reviewing monthly infrastructure
  costs, (5) before launching a marketing campaign or going viral.
globs: ["**/*.md", "**/*.json", "**/*.yml", "**/*.yaml", "**/*.tf", "**/*.env"]
alwaysApply: false
tags: [product, cost, reliability]
---

# Cloud Cost Alerts

## Purpose

Cloud costs can spiral from $50/month to $5,000/month overnight. A misconfigured auto-scaler, an infinite loop hitting an AI API, or a forgotten staging environment can burn through your runway before you notice. This skill implements guardrails to catch cost anomalies early.

## Why This Matters

**For non-technical founders:** You ran a TikTok ad. It went viral. 100,000 users signed up. Your AWS bill jumped from $200 to $8,000 because auto-scaling spun up 50 servers. You didn't have a spend cap. You're now in debt to AWS.

**For teachers learning to code:** You built a lesson plan generator using GPT-4. A student found an infinite loop bug: it kept regenerating until the page closed. Over the weekend, it made 12,000 API calls. Your OpenAI bill: $600 (your monthly budget was $50).

**The reality:** Cloud providers will happily let you spend unlimited money. It's your job to stop them.

## Critical Checks: Before You Launch

**Run these before ANY public launch or marketing campaign:**

1. **Set hard spend caps**
   - AWS: Billing → Budgets → Create budget with 80%/100% alerts
   - OpenAI: Settings → Usage → Monthly budget (hard cap, not just alerts)
   - Vercel: Settings → Usage → Set spending limit
   - Railway: Project settings → Usage limit

2. **Enable auto-scaling limits**
   - AWS EC2 Auto Scaling: Set `MaxSize` (e.g., 5 instances max)
   - AWS Lambda: Set `Reserved Concurrency` (e.g., 100 concurrent executions max)
   - Vercel: No native limit — use middleware to reject requests over threshold
   - Railway: Autoscaling → Set max replicas

3. **Review current spend trajectory**
   - Current month-to-date spend
   - Projected month-end (daily average × remaining days)
   - Highest-spend services (identify cost drivers)
   - Unused resources (idle instances, unattached storage)

**For Cursor agent:** Run `aws ce get-cost-and-usage` or check dashboard screenshots weekly.

## Budget Alert Setup

### AWS

**Console setup:**
1. Go to AWS Billing Dashboard → Budgets
2. Click "Create budget"
3. Select "Budget template" → "Monthly cost budget"
4. Name: "Monthly Spend Alert"
5. Budget amount: Your monthly limit (e.g., $500)
6. Alert thresholds:
   - 50% ($250) → Email notification
   - 80% ($400) → Email + Slack alert
   - 100% ($500) → Email + Slack + SMS
7. Click "Create budget"

**Infrastructure as Code (Terraform):**
```terraform
resource "aws_budgets_budget" "monthly" {
  name              = "monthly-cloud-spend"
  budget_type       = "COST"
  limit_amount      = "500"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["finance@yourapp.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["founder@yourapp.com", "finance@yourapp.com"]
  }
}
```

### OpenAI / Anthropic

**OpenAI:**
1. Go to platform.openai.com/settings/organization/billing
2. Set "Monthly budget" (hard cap — stops usage at limit)
3. Set "Usage alert" at 80% (email notification)

**Anthropic:**
1. Console → Settings → Usage
2. Set monthly spend limit
3. Enable email alerts at 80%, 100%

**API-level protection (recommended):**
```typescript
// middleware/cost-guard.ts
import { Redis } from '@upstash/redis';

const redis = new Redis({ url: process.env.REDIS_URL });
const DAILY_OPENAI_BUDGET = 50; // $50/day

export async function checkOpenAIBudget() {
  const today = new Date().toISOString().split('T')[0];
  const spend = await redis.get(`openai:spend:${today}`);
  
  if (parseFloat(spend || '0') >= DAILY_OPENAI_BUDGET) {
    throw new Error('Daily OpenAI budget exceeded. Requests paused until midnight.');
  }
}

export async function trackOpenAISpend(costUSD: number) {
  const today = new Date().toISOString().split('T')[0];
  await redis.incrbyfloat(`openai:spend:${today}`, costUSD);
  await redis.expire(`openai:spend:${today}`, 86400); // 24h TTL
}

// Usage in your code:
await checkOpenAIBudget();
const response = await openai.chat.completions.create({...});
const cost = calculateCost(response.usage, 'gpt-4o-mini');
await trackOpenAISpend(cost);
```

### Vercel / Railway / Render

**Vercel:**
- Settings → Usage → Spending limit
- Set hard cap (e.g., $100/month)
- Enable email alerts at 80%

**Railway:**
- Project settings → Usage → Set monthly limit
- Railway will pause services at limit (graceful degradation)

**Render:**
- Billing → Set spend cap
- Render will notify but NOT pause — monitor manually

## Auto-Scaling Safeguards

**The #1 cause of cloud cost disasters:** Auto-scalers that spin up unlimited resources.

### AWS EC2 Auto Scaling

**Dangerous:**
```terraform
# BAD: No max limit
resource "aws_autoscaling_group" "web" {
  min_size = 2
  desired_capacity = 2
  # max_size not set = defaults to unlimited in some configs
}
```

**Safe:**
```terraform
resource "aws_autoscaling_group" "web" {
  min_size         = 2
  desired_capacity = 2
  max_size         = 5  # Hard cap: never exceed 5 instances
  
  # Use step scaling, not target tracking (more predictable)
  tag {
    key                 = "CostCenter"
    value               = "web-tier"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "web-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300  # 5 min between scale-ups
  autoscaling_group_name = aws_autoscaling_group.web.name
}
```

### AWS Lambda

**Dangerous:**
```terraform
# BAD: Unlimited concurrency
resource "aws_lambda_function" "api" {
  # No reserved concurrency set
}
```

**Safe:**
```terraform
resource "aws_lambda_function" "api" {
  reserved_concurrent_executions = 100  # Hard cap: max 100 concurrent
  
  # Also set timeout to prevent long-running functions
  timeout = 30  # 30 seconds max
}

# Add concurrency alarm
resource "aws_cloudwatch_metric_alarm" "lambda_concurrency" {
  alarm_name          = "lambda-high-concurrency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"  # Alert at 80% of reserved
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]
}
```

### Vercel Serverless

**Vercel has no native concurrency limit.** Implement in middleware:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import { Redis } from '@upstash/redis';

const redis = new Redis({ url: process.env.REDIS_URL });
const MAX_CONCURRENT = 50;

export async function middleware(request: Request) {
  const concurrent = await redis.get('vercel:concurrent');
  
  if (parseInt(concurrent || '0') >= MAX_CONCURRENT) {
    return NextResponse.json(
      { error: 'Service busy. Please try again in 30 seconds.' },
      { status: 503 }
    );
  }
  
  await redis.incr('vercel:concurrent');
  await redis.expire('vercel:concurrent', 60);
  
  const response = NextResponse.next();
  
  // Decrement on response (use waitUntil for edge functions)
  response.headers.set('X-Concurrent-Decr', 'true');
  
  return response;
}
```

## Spend Monitoring Script

**Run weekly in Cursor agent or heartbeat:**

```bash
#!/bin/bash
# cloud-cost-check.sh

set -e

echo "📊 Cloud Cost Report — $(date +'%Y-%m-%d')"

# AWS (requires aws-cli configured)
if command -v aws &> /dev/null; then
  echo ""
  echo "AWS:"
  AWS_SPEND=$(aws ce get-cost-and-usage \
    --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --query 'ResultsByPeriod[0].Total.UnblendedCost.Amount' \
    --output text 2>/dev/null || echo "N/A")
  
  AWS_PROJECTED=$(echo "$AWS_SPEND * 30 / $(date +%d)" | bc 2>/dev/null || echo "N/A")
  echo "  Month-to-date: $$AWS_SPEND"
  echo "  Projected: $$AWS_PROJECTED"
fi

# OpenAI (requires OPENAI_KEY env var)
if [ -n "$OPENAI_KEY" ]; then
  echo ""
  echo "OpenAI:"
  OPENAI_SPEND=$(curl -s -H "Authorization: Bearer $OPENAI_KEY" \
    "https://api.openai.com/v1/usage" | jq -r '.total_usage / 100' 2>/dev/null || echo "N/A")
  echo "  Month-to-date: $$OPENAI_SPEND"
fi

# Check for anomalies
echo ""
echo "⚠️ Anomaly Check:"
if [ "$AWS_SPEND" != "N/A" ]; then
  PREV_WEEK=$(aws ce get-cost-and-usage \
    --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
    --granularity DAILY \
    --metrics "UnblendedCost" \
    --query 'ResultsByPeriod | length' 2>/dev/null || echo "0")
  
  if [ "$PREV_WEEK" -gt 0 ]; then
    echo "  Last 7 days data available"
  fi
fi

echo ""
echo "✅ Check complete. Review dashboards for details."
```

**Cron it:**
```bash
# Every Monday at 9am
0 9 * * 1 /path/to/cloud-cost-check.sh | mail -s "Weekly Cloud Costs" founder@yourapp.com
```

## Cost Optimization Checklist

**Monthly review (30 minutes):**

- [ ] **Unused resources:** Check for idle EC2 instances, unattached EBS volumes, unused Elastic IPs
- [ ] **Right-sizing:** Are instances oversized? (Use AWS Compute Optimizer)
- [ ] **Reserved instances:** Commit to 1-year RIs for baseline workloads (30-60% savings)
- [ ] **Spot instances:** Use for batch jobs, CI/CD, non-critical workloads (70% savings)
- [ ] **Storage tiers:** Move old S3 data to Glacier ($0.004/GB vs $0.023/GB)
- [ ] **CDN:** Use Cloudflare free tier (unlimited bandwidth)
- [ ] **AI model selection:** Use GPT-4o-mini ($0.15/1M tokens) for non-critical tasks, not GPT-4 ($30/1M tokens)

**For Cursor agent:** Run `aws ce get-cost-and-usage --time-period Start=$(date -d '30 days ago' +%Y-%m-%d) --granularity MONTHLY` and identify top 3 cost drivers.

## Common Cost Disasters & Prevention

**Disaster 1: Infinite loop hits AI API**
- **Cause:** Bug causes retries without backoff
- **Fix:** See `third-party-service-monitoring.md` — always implement timeouts + circuit breakers

**Disaster 2: Staging environment left running**
- **Cause:** Developer spun up staging for testing, forgot to shut down
- **Fix:** Auto-delete staging environments after 7 days (use AWS Instance Scheduler or Railway ephemeral environments)

**Disaster 3: Auto-scaling during DDoS**
- **Cause:** Attack traffic triggers scaling to 100 instances
- **Fix:** Set `max_size` on auto-scalers, use AWS Shield Standard (free DDoS protection), implement rate limiting at CDN

**Disaster 4: Forgotten cron job**
- **Cause:** Lambda function runs every minute, even when not needed
- **Fix:** Review all scheduled tasks quarterly. Disable non-essential crons. Use EventBridge rules to pause during off-hours.

**Disaster 5: Data transfer costs**
- **Cause:** US-based server, EU users, cross-region data transfer fees
- **Fix:** Use CloudFront (cheaper data transfer), deploy in user's region, enable CDN caching

## Emergency Response: Cost Spike Detected

**When you notice an abnormal bill:**

1. **Identify the source (5 minutes)**
   - AWS: Cost Explorer → Group by service → Sort by cost
   - OpenAI: Usage page → Filter by date → Check for anomalous days
   - Vercel: Analytics → Serverless function invocations

2. **Stop the bleeding (10 minutes)**
   - AWS: Shut down suspicious instances, disable auto-scalers
   - OpenAI: Rotate API key immediately (stops all usage)
   - Lambda: Set reserved concurrency to 0 (pauses function)
   - Vercel: Disable function via dashboard

3. **Investigate root cause (1 hour)**
   - Check CloudWatch logs for errors/infinite loops
   - Review recent deployments (did something change?)
   - Check for compromised credentials (rotate all keys)

4. **Request refund (24 hours)**
   - AWS: Support → Create case → Billing → "Accidental usage"
   - AWS often grants one-time courtesy refunds for first-time mistakes
   - OpenAI: Support → Explain bug → Request credit (50/50 success rate)

5. **Prevent recurrence (1 week)**
   - Add the cost alert you were missing
   - Implement auto-scaling limits
   - Add daily spend checks to heartbeat

## Pre-Launch Checklist

**Run Cursor agent before any marketing campaign:**

```bash
grep -r "autoscaling\|auto-scaling\|MAX_" --include="*.tf" --include="*.yml" infrastructure/
```

Verify:
- [ ] All auto-scalers have `max_size` set
- [ ] Lambda functions have `reserved_concurrent_executions`
- [ ] AI API budgets have hard caps (not just alerts)
- [ ] Cloud spend alerts configured at 50%, 80%, 100%
- [ ] Tested failover to fallback model/provider
- [ ] Estimated cost of 10x traffic spike (can you afford it?)
- [ ] Contact info for cloud provider support is accessible

## Related Skills

- `third-party-service-monitoring.md` — Monitoring external services
- `cost-governance.md` — General cost management
- `monitoring-alerting.md` — Full observability stack
- `incident-response.md` — Emergency procedures
- `api-rate-limiting.md` — Preventing runaway API usage

## TL;DR

1. Set hard spend caps on ALL cloud providers (not just alerts)
2. Auto-scalers MUST have `max_size` — unlimited scaling = unlimited bills
3. Monitor weekly: current spend, projected month-end, top cost drivers
4. AI APIs: Set daily budget + implement middleware-level spend tracking
5. Before launch: Estimate 10x traffic cost, can you afford it?
6. Emergency: Rotate API keys, disable functions, then investigate
7. AWS grants one-time courtesy refunds — ask if you mess up

**For TYO community:** Cloud providers are not your friend. They will happily charge you $10,000 for a bug. Set caps, monitor weekly, and assume auto-scaling will betray you.
