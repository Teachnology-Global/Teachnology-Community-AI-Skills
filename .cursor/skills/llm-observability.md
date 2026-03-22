---
description: >
  Instruments LLM-powered features for production visibility: tracing calls, monitoring
  response quality, detecting failures, and controlling costs per user. Essential for
  non-technical founders who ship AI features and have no insight into whether they
  actually work after launch.
  Use when: (1) building any feature that calls an LLM API, (2) shipping an AI chatbot,
  assistant, or content generator, (3) debugging unexpectedly high API bills,
  (4) investigating user complaints about AI quality, (5) setting up production monitoring.
globs: ["**/api/**/*", "**/lib/ai*", "**/lib/llm*", "**/services/ai*", "**/services/openai*", "**/utils/ai*"]
alwaysApply: false
tags: [product]
---

# LLM Observability

## Purpose

Most non-technical founders ship an AI feature, watch it work in testing, and have no idea what's happening in production. When it breaks or costs $400 overnight, there's nothing to debug.

This skill adds the minimum viable observability layer for any LLM-powered feature: logging calls, tracking quality, catching errors early, and understanding cost per user.

## Activation

This skill activates when you mention:
- "AI feature", "LLM feature", "chatbot", "AI assistant"
- "OpenAI", "Anthropic", "Gemini", "AI API"
- "tracing", "monitoring AI", "AI logs"
- "why is my AI costing so much", "AI not working in production"
- "hallucination", "bad AI response", "quality monitoring"
- "Langfuse", "LangSmith", "Arize"

Also activates when:
- Building or reviewing any file that calls `openai.chat.completions.create` or equivalent
- An AI feature is about to be deployed to production for the first time
- Debugging production complaints about AI response quality

## Why This Matters for Non-Technical Founders

Without observability, you're flying blind:

| What Happens | What You See Without Observability |
|---|---|
| AI starts hallucinating for 20% of users | User complaints 3 days later |
| Prompt change breaks a use case | Confused support tickets |
| API error rate spikes to 15% | Users just leave, you never know why |
| Costs jump 4x after a traffic spike | Surprise bill at month end |
| One user is consuming 40% of your token budget | No idea until you're over quota |

With observability, you get alerts when any of this starts happening, and you have the data to fix it quickly.

## Minimum Viable Observability Stack

### Option 1: Langfuse (Recommended — free tier, open source)

Langfuse is free to start, open source, and designed for exactly this use case. Self-host or use their cloud.

```bash
npm install langfuse
```

```typescript
// lib/ai/langfuse.ts
import Langfuse from 'langfuse';

export const langfuse = new Langfuse({
  secretKey: process.env.LANGFUSE_SECRET_KEY!,
  publicKey: process.env.LANGFUSE_PUBLIC_KEY!,
  baseUrl: process.env.LANGFUSE_HOST ?? 'https://cloud.langfuse.com',
  flushAt: 20,
  flushInterval: 10000,
});
```

```typescript
// lib/ai/traced-completion.ts
import OpenAI from 'openai';
import { langfuse } from './langfuse';

const openai = new OpenAI();

interface TracedCompletionOptions {
  userId: string;
  feature: string;         // e.g. "lesson-plan-generator"
  systemPrompt: string;
  userMessage: string;
  model?: string;
  maxTokens?: number;
}

export async function tracedCompletion({
  userId,
  feature,
  systemPrompt,
  userMessage,
  model = 'gpt-4o-mini',
  maxTokens = 1000,
}: TracedCompletionOptions) {
  // Create a trace — one trace per user-facing operation
  const trace = langfuse.trace({
    name: feature,
    userId,
    metadata: { model, maxTokens },
  });

  // Create a generation span inside the trace
  const generation = trace.generation({
    name: `${feature}-completion`,
    model,
    input: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userMessage },
    ],
  });

  try {
    const response = await openai.chat.completions.create({
      model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ],
      max_tokens: maxTokens,
    });

    const content = response.choices[0]?.message?.content ?? '';
    const usage = response.usage;

    // Record the output and token usage
    generation.end({
      output: content,
      usage: {
        input: usage?.prompt_tokens ?? 0,
        output: usage?.completion_tokens ?? 0,
        total: usage?.total_tokens ?? 0,
      },
    });

    return { content, trace };
  } catch (error) {
    // Record the error in the trace
    generation.end({
      output: null,
      level: 'ERROR',
      statusMessage: error instanceof Error ? error.message : 'Unknown error',
    });
    throw error;
  } finally {
    // Flush on edge functions (serverless)
    await langfuse.flushAsync();
  }
}
```

### Option 2: Minimal DIY Logging (No extra tools)

If you're not ready for Langfuse, log the minimum to your existing database:

```typescript
// lib/ai/logged-completion.ts
import OpenAI from 'openai';
import { db } from '@/lib/db'; // your database client

const openai = new OpenAI();

export async function loggedCompletion({
  userId,
  feature,
  systemPrompt,
  userMessage,
  model = 'gpt-4o-mini',
  maxTokens = 1000,
}: {
  userId: string;
  feature: string;
  systemPrompt: string;
  userMessage: string;
  model?: string;
  maxTokens?: number;
}) {
  const startedAt = Date.now();
  let tokensUsed = 0;
  let success = false;
  let errorMessage: string | null = null;

  try {
    const response = await openai.chat.completions.create({
      model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ],
      max_tokens: maxTokens,
    });

    tokensUsed = response.usage?.total_tokens ?? 0;
    success = true;

    return response.choices[0]?.message?.content ?? '';
  } catch (error) {
    errorMessage = error instanceof Error ? error.message : 'Unknown error';
    throw error;
  } finally {
    // Always log, even on failure
    await db.ai_calls.create({
      data: {
        user_id: userId,
        feature,
        model,
        tokens_used: tokensUsed,
        latency_ms: Date.now() - startedAt,
        success,
        error_message: errorMessage,
        created_at: new Date(),
      },
    });
  }
}
```

```sql
-- Migration: ai_calls logging table
CREATE TABLE ai_calls (
  id          SERIAL PRIMARY KEY,
  user_id     TEXT NOT NULL,
  feature     TEXT NOT NULL,
  model       TEXT NOT NULL,
  tokens_used INTEGER NOT NULL DEFAULT 0,
  latency_ms  INTEGER NOT NULL DEFAULT 0,
  success     BOOLEAN NOT NULL DEFAULT TRUE,
  error_message TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ai_calls_user_id_idx ON ai_calls (user_id);
CREATE INDEX ai_calls_feature_idx ON ai_calls (feature);
CREATE INDEX ai_calls_created_at_idx ON ai_calls (created_at DESC);
```

## Alerting on Quality Degradation

### Error Rate Alert (Simple — works with any logging)

```typescript
// scripts/check-ai-health.ts
// Run on a cron (every 15 minutes)

import { db } from '@/lib/db';

const ALERT_ERROR_RATE_THRESHOLD = 0.1; // 10%
const WINDOW_MINUTES = 15;

export async function checkAIHealth() {
  const windowStart = new Date(Date.now() - WINDOW_MINUTES * 60 * 1000);

  const calls = await db.ai_calls.findMany({
    where: { created_at: { gte: windowStart } },
  });

  if (calls.length < 10) return; // Not enough data

  const errorRate = calls.filter((c) => !c.success).length / calls.length;

  if (errorRate > ALERT_ERROR_RATE_THRESHOLD) {
    await sendAlert({
      title: '⚠️ AI Error Rate Spike',
      message: `${(errorRate * 100).toFixed(1)}% of AI calls failing in last ${WINDOW_MINUTES}min (${calls.length} calls)`,
      severity: 'high',
    });
  }
}
```

### Per-User Cost Alert

```typescript
// Prevent one user from blowing your budget
const DAILY_TOKEN_LIMIT_PER_USER = 50_000; // ~$0.05 at gpt-4o-mini pricing

export async function checkUserTokenBudget(userId: string): Promise<boolean> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const usage = await db.ai_calls.aggregate({
    where: {
      user_id: userId,
      created_at: { gte: today },
      success: true,
    },
    _sum: { tokens_used: true },
  });

  const totalTokens = usage._sum.tokens_used ?? 0;

  if (totalTokens > DAILY_TOKEN_LIMIT_PER_USER) {
    // Log the limit hit (useful for detecting abuse or bugs)
    await db.ai_limit_events.create({
      data: {
        user_id: userId,
        tokens_used: totalTokens,
        limit: DAILY_TOKEN_LIMIT_PER_USER,
        created_at: new Date(),
      },
    });
    return false; // Caller should block this request
  }

  return true;
}
```

## Evaluating Response Quality

### User Feedback Signal (Most Reliable)

The simplest quality signal: let users tell you.

```tsx
// components/AIResponseFeedback.tsx
'use client';

import { useState } from 'react';

export function AIResponseFeedback({ traceId }: { traceId: string }) {
  const [submitted, setSubmitted] = useState(false);

  const submitFeedback = async (score: 1 | -1) => {
    await fetch('/api/ai-feedback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ traceId, score }),
    });
    setSubmitted(true);
  };

  if (submitted) return <span className="text-sm text-gray-500">Thanks for the feedback</span>;

  return (
    <div className="flex gap-2 mt-2">
      <button
        onClick={() => submitFeedback(1)}
        className="text-sm text-gray-500 hover:text-green-600"
        aria-label="Good response"
      >
        👍
      </button>
      <button
        onClick={() => submitFeedback(-1)}
        className="text-sm text-gray-500 hover:text-red-600"
        aria-label="Bad response"
      >
        👎
      </button>
    </div>
  );
}
```

```typescript
// api/ai-feedback/route.ts
import { langfuse } from '@/lib/ai/langfuse';

export async function POST(req: Request) {
  const { traceId, score } = await req.json();

  // Send score back to Langfuse — surfaces in their dashboard
  await langfuse.score({
    traceId,
    name: 'user-feedback',
    value: score, // 1 = good, -1 = bad
  });

  return Response.json({ ok: true });
}
```

### Automated Quality Checks (Deterministic)

For features with structured outputs, validate the shape:

```typescript
// lib/ai/validators.ts
import { z } from 'zod';

// Example: lesson plan generator
const LessonPlanSchema = z.object({
  title: z.string().min(5).max(200),
  objectives: z.array(z.string()).min(1).max(5),
  activities: z.array(
    z.object({
      duration_minutes: z.number().min(1).max(60),
      description: z.string().min(10),
    }),
  ).min(1),
  assessment: z.string().min(20),
});

export function validateLessonPlan(rawOutput: string): {
  valid: boolean;
  errors: string[];
  parsed?: z.infer<typeof LessonPlanSchema>;
} {
  try {
    // AI should output JSON — use JSON mode (OpenAI) or structured outputs
    const parsed = JSON.parse(rawOutput);
    const result = LessonPlanSchema.safeParse(parsed);

    if (result.success) {
      return { valid: true, errors: [], parsed: result.data };
    }

    return {
      valid: false,
      errors: result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`),
    };
  } catch {
    return { valid: false, errors: ['Output is not valid JSON'] };
  }
}
```

## Production Observability Checklist

Before shipping any AI feature to production:

### Logging
- [ ] Every LLM call logs: user_id, feature name, model, tokens used, latency, success/failure
- [ ] Errors logged with message (not just "failed")
- [ ] Latency measured and logged (slow responses are a quality signal)

### Alerting
- [ ] Alert if error rate exceeds 10% in any 15-minute window
- [ ] Alert if average latency exceeds 10 seconds
- [ ] Alert if daily token usage exceeds budget threshold
- [ ] Alert if a single user consumes abnormal token volume

### Cost
- [ ] Per-user daily token limit enforced in code (not just hoped for)
- [ ] Monthly spend cap set on the API provider dashboard (hard stop)
- [ ] Tokens logged so you can see cost breakdown by feature

### Quality
- [ ] User feedback signal (👍/👎 or equivalent) on AI responses
- [ ] Structured outputs validated with schema (Zod/Pydantic) where possible
- [ ] At least one test that validates AI output shape (not just that it doesn't error)

### Visibility
- [ ] You can answer "what's the error rate for [feature] in the last hour?" without a support ticket
- [ ] You can answer "who are my top 10 token consumers today?" in under 2 minutes
- [ ] You have a dashboard (Langfuse, or a simple SQL query) you check weekly

## Red Flags in AI Features (for Review)

When reviewing AI-powered code, flag these:

```typescript
// ❌ No logging
const response = await openai.chat.completions.create({ ... });
return response.choices[0]?.message?.content;

// ❌ No error handling
const response = await openai.chat.completions.create({ ... });
// If this throws, it bubbles to the user with a 500 error

// ❌ No per-user limits
// Any user can hit the AI endpoint unlimited times

// ❌ No max_tokens
const response = await openai.chat.completions.create({
  model: 'gpt-4o',
  messages: [...],
  // No max_tokens — can consume unlimited tokens
});

// ✅ Traced, capped, error-handled
const response = await tracedCompletion({
  userId: session.user.id,
  feature: 'lesson-plan-generator',
  systemPrompt: LESSON_PLAN_PROMPT,
  userMessage: userInput,
  model: 'gpt-4o-mini',
  maxTokens: 1000,
});
```

## Integration

### With AI Cost Management
- This skill provides the observability layer; AI Cost Management provides the spending controls
- Use both: cost management sets the limits, observability tells you when limits are nearly reached

### With Error Handling
- AI errors should follow the same error classification system as all other errors
- LLM API errors (rate limits, context length, model errors) each need distinct handling

### With Human Approval
- If your AI feature can take consequential actions (send emails, modify data), log those specifically and require human confirmation before execution

### With AI Output Validation
- Observability tells you what's failing in production; AI Output Validation prevents bad code from shipping in the first place
- Use observability data to improve validation rules over time
