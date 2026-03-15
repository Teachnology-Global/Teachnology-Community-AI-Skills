---
description: >
  Prevents unexpected LLM API bills and production cost overruns when building
  AI-powered features. Covers token budgeting, spend alerts, caching strategies,
  model selection, and hard spending limits. Essential for non-technical founders
  and teachers building with OpenAI, Anthropic, or other LLM APIs — a single
  misconfigured feature can generate hundreds of dollars in charges overnight.
  Use when: (1) adding AI/LLM features to a project, (2) reviewing API call code,
  (3) setting up a new OpenAI or Anthropic project, (4) debugging unexpectedly
  high bills, (5) preparing an AI feature for production.
globs: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.py", "**/api/**", "**/*.env*", "**/openai*", "**/anthropic*"]
alwaysApply: false
---

# AI Cost Management

## Purpose

Building with LLM APIs is powerful and fast. It is also the easiest way to wake up to an unexpected $500 bill.

LLM costs are unlike traditional API costs. A single API call can be cheap (fractions of a cent) or expensive (dollars) depending on how much text you send and receive. A loop that calls an LLM once per user action, with a large system prompt, in a feature with 1,000 active users, can burn through a month's budget in hours.

This skill ensures that AI features are built with cost visibility, sensible defaults, and hard limits — before they hit production.

## Why This Hits Non-Technical Builders Hard

When Cursor generates AI feature code, it will typically write the simplest thing that works:
- Full context window with every message
- GPT-4 or Claude 3.5 Sonnet for everything (including tasks that don't need it)
- No caching (same prompt called repeatedly)
- No token limits on user inputs
- No spend monitoring

The code runs fine in development where you make 10 test calls. The hidden cost surfaces in production with real user load.

## Activation

This skill activates when you mention:
- "OpenAI", "Anthropic", "LLM", "language model", "ChatGPT", "Claude", "Gemini"
- "token", "tokens", "token usage", "token budget"
- "API cost", "billing", "spend", "bill shock", "expensive"
- "AI feature", "chat feature", "AI assistant"
- "prompt", "system prompt", "context window"
- "rate limit", "usage limit", "quota"

Also activates when:
- Adding an LLM API call to any file
- Reviewing AI feature code
- Setting up API keys for OpenAI or Anthropic

## Cost Fundamentals

### How LLM Pricing Works

LLMs charge per token. Roughly:
- 1 token ≈ 4 characters ≈ 0.75 words
- 1,000 words ≈ 1,333 tokens
- A typical ChatGPT response: 200–500 tokens
- A detailed system prompt: 500–2,000 tokens
- A full document analysis: 5,000–100,000+ tokens

**Input tokens** (what you send) and **output tokens** (what the model generates) are priced separately. Output tokens typically cost 3–5× more than input tokens.

### Example: Hidden Cost Accumulation

```
Feature: AI-powered FAQ assistant

System prompt:          1,200 tokens (your instructions)
FAQ knowledge base:     8,000 tokens (sent every call)
User message:             50 tokens
Response:                300 tokens

Total per call: ~9,550 tokens (~$0.03 with GPT-4o)

With 500 users/day × 5 questions each = 2,500 calls/day
Daily cost: $75
Monthly cost: $2,250

With caching the FAQ knowledge base:
Input drops to ~1,250 tokens per call
Monthly cost: ~$300  ← 87% saving
```

### Current Pricing Reference (March 2026 — check provider sites for latest)

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Best For |
|-------|----------------------|----------------------|----------|
| GPT-4o | ~$2.50 | ~$10.00 | Complex reasoning, multimodal |
| GPT-4o mini | ~$0.15 | ~$0.60 | Simple tasks, high volume |
| Claude 3.5 Sonnet | ~$3.00 | ~$15.00 | Long context, complex tasks |
| Claude 3.5 Haiku | ~$0.25 | ~$1.25 | Fast, cheap, simple tasks |
| Claude 3 Opus | ~$15.00 | ~$75.00 | Rarely needed; very expensive |

**Rule of thumb:** Start with the cheapest model that produces acceptable output. Upgrade only when you have evidence the cheaper model isn't good enough.

## Hard Limits (Set These First)

Before writing a single line of AI feature code, set spending limits at the provider level.

### OpenAI

```bash
# Set monthly budget alert and hard limit
# Dashboard → Settings → Limits

# Hard limit: blocks new API calls when reached
# Soft limit: sends you an email warning

# Recommended for new projects:
# Hard limit: $20/month (raise as you validate usage)
# Soft limit: $10/month (warning at 50% of hard limit)
```

```typescript
// Also set per-request token limits in code
const response = await openai.chat.completions.create({
  model: 'gpt-4o-mini',
  messages: [...],
  max_tokens: 500,    // ← ALWAYS set this. Default is model maximum.
  // Without this, a single call can return 4,096+ tokens
});
```

### Anthropic

```bash
# Dashboard → Settings → Usage Limits
# Set monthly spend limit (hard limit)
# Set email alert threshold
```

```typescript
// Per-request limit
const response = await anthropic.messages.create({
  model: 'claude-3-5-haiku-20241022',
  max_tokens: 500,    // ← REQUIRED in Anthropic's API (not optional)
  messages: [...],
});
```

## Token Budget Patterns

### Limit User Input Length

```typescript
const MAX_USER_MESSAGE_TOKENS = 500; // ~375 words

function truncateToTokenBudget(text: string, maxTokens: number): string {
  // Rough estimate: 1 token ≈ 4 characters
  const maxChars = maxTokens * 4;
  if (text.length <= maxChars) return text;
  return text.slice(0, maxChars) + '... [truncated]';
}

// In your API handler
const safeUserMessage = truncateToTokenBudget(userInput, MAX_USER_MESSAGE_TOKENS);

// Better: use tiktoken for accurate token counting
import { encoding_for_model } from 'tiktoken';
const enc = encoding_for_model('gpt-4o');
const tokens = enc.encode(userMessage);
if (tokens.length > MAX_USER_MESSAGE_TOKENS) {
  return Response.json({ error: 'Message too long (max 500 words)' }, { status: 400 });
}
```

### Trim Conversation History

Sending full conversation history grows unboundedly. Trim it:

```typescript
function trimConversationHistory(
  messages: Message[],
  maxTokens: number = 3000
): Message[] {
  // Always keep the system message
  const systemMessages = messages.filter(m => m.role === 'system');
  const conversationMessages = messages.filter(m => m.role !== 'system');
  
  // Keep the most recent messages, trim oldest first
  let totalTokens = 0;
  const kept: Message[] = [];
  
  for (const msg of [...conversationMessages].reverse()) {
    const estimated = Math.ceil(msg.content.length / 4);
    if (totalTokens + estimated > maxTokens) break;
    kept.unshift(msg);
    totalTokens += estimated;
  }
  
  return [...systemMessages, ...kept];
}
```

### Cache Repeated Prompts

If you send the same (or nearly the same) system prompt repeatedly, cache the response for identical inputs:

```typescript
import { createHash } from 'crypto';

const responseCache = new Map<string, { response: string; timestamp: number }>();
const CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour

function getCacheKey(systemPrompt: string, userMessage: string): string {
  return createHash('sha256')
    .update(systemPrompt + '||' + userMessage)
    .digest('hex');
}

async function cachedLLMCall(systemPrompt: string, userMessage: string): Promise<string> {
  const cacheKey = getCacheKey(systemPrompt, userMessage);
  const cached = responseCache.get(cacheKey);
  
  if (cached && Date.now() - cached.timestamp < CACHE_TTL_MS) {
    return cached.response; // Free — no API call
  }
  
  const response = await callLLM(systemPrompt, userMessage);
  responseCache.set(cacheKey, { response, timestamp: Date.now() });
  return response;
}

// For production: use Redis or a persistent cache instead of in-memory Map
```

### Use OpenAI Prompt Caching

OpenAI and Anthropic both support **prompt caching** — if the beginning of your prompt is identical across calls, they charge a fraction of the normal price for the cached portion.

```typescript
// Anthropic: cache_control on long, stable system content
const response = await anthropic.messages.create({
  model: 'claude-3-5-haiku-20241022',
  max_tokens: 500,
  system: [
    {
      type: 'text',
      text: longStableSystemPrompt,
      cache_control: { type: 'ephemeral' }, // Cache this portion
    }
  ],
  messages: [{ role: 'user', content: userMessage }],
});
// First call: full price. Subsequent calls with same system: ~90% discount on that section.
```

## Model Selection Strategy

```typescript
// Route to the right model for each task

type TaskComplexity = 'simple' | 'standard' | 'complex';

function selectModel(task: TaskComplexity): string {
  switch (task) {
    case 'simple':
      // Classification, yes/no, simple extraction, short summaries
      return 'gpt-4o-mini'; // ~15× cheaper than GPT-4o
    
    case 'standard':
      // Multi-step reasoning, content generation, code review
      return 'gpt-4o';
    
    case 'complex':
      // Very long documents, complex analysis, nuanced judgment
      return 'claude-3-5-sonnet-20241022';
    
    default:
      return 'gpt-4o-mini'; // Default to cheaper
  }
}

// Examples:
// "Is this message spam?" → simple → gpt-4o-mini
// "Write a product description" → standard → gpt-4o
// "Analyse this 50-page contract" → complex → claude-3-5-sonnet
```

## Usage Monitoring

Track token usage per request so you can spot expensive patterns:

```typescript
// Log token usage in every API response
const response = await openai.chat.completions.create({
  model: 'gpt-4o-mini',
  messages: [...],
  max_tokens: 500,
});

// Always log this
console.log('LLM usage', {
  model: response.model,
  prompt_tokens: response.usage?.prompt_tokens,
  completion_tokens: response.usage?.completion_tokens,
  total_tokens: response.usage?.total_tokens,
  estimated_cost_usd: calculateCost(response),
  feature: 'faq-assistant', // Tag by feature
  user_id: userId,           // Tag by user (for abuse detection)
});

function calculateCost(response: ChatCompletion): number {
  const inputCost = (response.usage?.prompt_tokens ?? 0) / 1_000_000 * 0.15; // gpt-4o-mini input
  const outputCost = (response.usage?.completion_tokens ?? 0) / 1_000_000 * 0.60; // gpt-4o-mini output
  return inputCost + outputCost;
}
```

## Rate Limiting Per User

Without per-user rate limits, a single user (or bot) can generate runaway costs:

```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(20, '1 h'), // 20 AI requests per user per hour
});

export async function POST(req: Request) {
  const userId = getUserId(req);
  
  const { success, remaining } = await ratelimit.limit(`ai_requests:${userId}`);
  
  if (!success) {
    return Response.json(
      { error: 'AI request limit reached. Try again later.' },
      { 
        status: 429,
        headers: { 'X-RateLimit-Remaining': '0' }
      }
    );
  }
  
  // Proceed with AI call
}
```

## Pre-Production AI Cost Checklist

Before shipping any AI-powered feature:

- [ ] **Provider hard limit set** — monthly spend cap configured in OpenAI/Anthropic dashboard
- [ ] **Soft limit / alert set** — email notification before hitting hard limit
- [ ] **`max_tokens` set on every API call** — never rely on model defaults
- [ ] **User input length limited** — validate max message length before calling LLM
- [ ] **Conversation history trimmed** — not growing unboundedly
- [ ] **Per-user rate limit** — prevent single-user cost spikes
- [ ] **Model appropriate for task** — not using GPT-4 Opus for simple classification
- [ ] **Token usage logged** — every call records prompt/completion tokens and estimated cost
- [ ] **Caching for repeated prompts** — identical inputs return cached responses
- [ ] **Cost estimate for production load** — calculated expected monthly cost at target user scale

## Estimating Production Costs

Before launching, run this estimate:

```
Monthly Cost Estimate Template

Feature: [name]
Model: [model name]
Input cost per 1M tokens: $[X]
Output cost per 1M tokens: $[Y]

Per-call usage:
  System prompt:     [N] tokens
  Average user input:[N] tokens
  Average response:  [N] tokens
  Total per call:    [N] tokens
  Estimated cost:    $[X]

Expected usage:
  Daily active users: [N]
  Calls per user/day: [N]
  Daily calls:        [N]
  Daily cost:         $[X]
  Monthly cost:       $[X × 30]

Worst case (10× spike): $[X × 300]
```

If the worst-case monthly cost is unacceptable: add rate limits, pick a cheaper model, or add caching before launching.

## Integration

### With API Rate Limiting
- Per-user AI rate limits complement the broader API rate limiting skill
- Quota costs for AI are typically much higher per-call than standard API costs — treat them separately

### With Secrets Management
- AI API keys are high-value credentials — rotate on any suspected exposure
- Leaked OpenAI key with no spend limit = immediate financial risk, not just security risk
- Always set spend limits before distributing a key to any environment

### With Error Handling
- 429 (rate limit) and 503 (provider outage) responses from AI APIs need graceful handling
- Expose retry-after timing to the user; don't silently retry in ways that compound costs

### With Environment Consistency
- Use different API keys for dev/staging/prod
- Set very low spend limits on dev/staging keys (dev doesn't need a $200/month limit)
- Track spend separately by environment to catch dev runaway usage
