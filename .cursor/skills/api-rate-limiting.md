---
description: >
  Prevents API quota exhaustion, service disruption, and unexpected costs by implementing
  proper rate limiting, caching, and retry logic. Essential for applications using
  external APIs like OpenAI, Stripe, or any third-party service with usage limits.
  Use when: (1) integrating external APIs, (2) building public APIs, (3) preventing
  service abuse, (4) optimizing API costs, (5) handling high traffic loads.
globs: ["**/api/**/*", "**/pages/api/**/*", "**/routes/**/*", "**/*.api.*", "**/services/**/*"]
alwaysApply: false
---

# API Rate Limiting

## Purpose

Prevent your application from being throttled, blocked, or incurring unexpected costs due to excessive API usage. Protect both your app and your users' experience.

## Activation

This skill activates when you mention:
- "API", "rate limit", "quota", "throttle"
- "API key", "usage limit", "cost control"
- "429 error", "too many requests"
- "caching", "retry logic", "exponential backoff"
- "OpenAI", "Stripe", "third-party API"

Also activates when working on:
- API integration code
- External service calls
- Public API endpoints
- High-traffic features

## Common Rate Limit Scenarios

| Service | Typical Limits | Consequences |
|---------|---------------|--------------|
| **OpenAI API** | 10,000 requests/min, token-based | $$ charges, 429 errors |
| **Stripe** | 100 requests/sec | Payment failures |
| **Google Maps** | 40,000 requests/month free | Service cutoff |
| **Twitter API** | 300 requests/15min | Account suspension |
| **GitHub API** | 5,000 requests/hour | Development blocked |
| **Your own API** | Whatever you set | User frustration |

## Implementation Patterns

### Client-Side Rate Limiting

```typescript
class APIClient {
  private requests: number[] = [];
  private readonly maxRequests: number;
  private readonly windowMs: number;

  constructor(maxRequests = 100, windowMs = 60000) { // 100 req/min
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
  }

  private canMakeRequest(): boolean {
    const now = Date.now();
    // Remove old requests outside the window
    this.requests = this.requests.filter(time => now - time < this.windowMs);
    return this.requests.length < this.maxRequests;
  }

  async makeRequest<T>(url: string, options?: RequestInit): Promise<T> {
    if (!this.canMakeRequest()) {
      const waitTime = this.windowMs - (Date.now() - this.requests[0]);
      throw new Error(`Rate limited. Try again in ${Math.ceil(waitTime / 1000)}s`);
    }

    this.requests.push(Date.now());
    
    const response = await fetch(url, options);
    
    if (response.status === 429) {
      const retryAfter = response.headers.get('retry-after');
      const waitSeconds = retryAfter ? parseInt(retryAfter) : 60;
      throw new Error(`Rate limited by server. Retry after ${waitSeconds}s`);
    }
    
    return response.json();
  }
}
```

### Server-Side Rate Limiting (Express.js)

```javascript
import rateLimit from 'express-rate-limit';
import Redis from 'redis';

// Basic memory-based limiter
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests, please try again later',
    retryAfter: Math.ceil(900) // seconds
  },
  standardHeaders: true, // Return rate limit info in headers
  legacyHeaders: false,
});

// Redis-based limiter for distributed systems
const redisClient = new Redis(process.env.REDIS_URL);

const distributedLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:',
  }),
  windowMs: 15 * 60 * 1000,
  max: 100,
});

// Different limits for different endpoints
app.use('/api/', apiLimiter);
app.use('/api/expensive-operation', rateLimit({ max: 5 })); // Stricter
app.use('/api/public', rateLimit({ max: 1000 })); // More lenient
```

### Intelligent Retry with Exponential Backoff

```typescript
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  baseDelayMs = 1000
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries) throw error;
      
      // Check if it's a rate limit error
      if (error.status === 429 || error.message.includes('rate limit')) {
        const delayMs = baseDelayMs * Math.pow(2, attempt - 1); // Exponential
        const jitterMs = Math.random() * 1000; // Add jitter
        
        console.log(`Rate limited. Retrying attempt ${attempt + 1} after ${delayMs + jitterMs}ms`);
        await new Promise(resolve => setTimeout(resolve, delayMs + jitterMs));
      } else {
        throw error; // Don't retry non-rate-limit errors
      }
    }
  }
}

// Usage
const result = await retryWithBackoff(
  () => openai.chat.completions.create({ ... }),
  maxRetries: 5,
  baseDelayMs: 2000
);
```

## Caching Strategy

```typescript
interface CacheEntry<T> {
  data: T;
  timestamp: number;
  ttl: number;
}

class APICache {
  private cache = new Map<string, CacheEntry<any>>();

  set<T>(key: string, data: T, ttlMs = 300000): void { // 5min default
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl: ttlMs
    });
  }

  get<T>(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry) return null;
    
    const age = Date.now() - entry.timestamp;
    if (age > entry.ttl) {
      this.cache.delete(key);
      return null;
    }
    
    return entry.data as T;
  }

  // Create cache key from request parameters
  createKey(endpoint: string, params: Record<string, any>): string {
    const sortedParams = Object.keys(params)
      .sort()
      .map(key => `${key}=${params[key]}`)
      .join('&');
    return `${endpoint}?${sortedParams}`;
  }
}

// Usage in API service
class OpenAIService {
  private cache = new APICache();
  private client: OpenAI;

  async generateCompletion(prompt: string, options = {}): Promise<string> {
    const cacheKey = this.cache.createKey('completion', { prompt, ...options });
    
    // Try cache first
    const cached = this.cache.get<string>(cacheKey);
    if (cached) {
      console.log('Cache hit - saved API call');
      return cached;
    }

    // Make API call with retry logic
    const result = await retryWithBackoff(
      () => this.client.chat.completions.create({
        messages: [{ role: 'user', content: prompt }],
        ...options
      })
    );

    const content = result.choices[0]?.message?.content || '';
    
    // Cache the result (TTL: 1 hour for AI completions)
    this.cache.set(cacheKey, content, 3600000);
    
    return content;
  }
}
```

## Cost Monitoring

### Track API Usage

```typescript
interface UsageMetrics {
  endpoint: string;
  requests: number;
  cost: number;
  timestamp: number;
}

class APIUsageTracker {
  private metrics: UsageMetrics[] = [];

  track(endpoint: string, cost = 0): void {
    const existing = this.metrics.find(m => 
      m.endpoint === endpoint && 
      Date.now() - m.timestamp < 3600000 // Same hour
    );

    if (existing) {
      existing.requests++;
      existing.cost += cost;
    } else {
      this.metrics.push({
        endpoint,
        requests: 1,
        cost,
        timestamp: Date.now()
      });
    }
  }

  getDailyReport(): UsageMetrics[] {
    const dayAgo = Date.now() - 86400000;
    return this.metrics
      .filter(m => m.timestamp > dayAgo)
      .reduce((acc, curr) => {
        const existing = acc.find(a => a.endpoint === curr.endpoint);
        if (existing) {
          existing.requests += curr.requests;
          existing.cost += curr.cost;
        } else {
          acc.push({ ...curr });
        }
        return acc;
      }, [] as UsageMetrics[]);
  }

  checkBudget(dailyBudget = 10): { exceeded: boolean; usage: number } {
    const today = this.getDailyReport();
    const totalCost = today.reduce((sum, m) => sum + m.cost, 0);
    return {
      exceeded: totalCost > dailyBudget,
      usage: totalCost
    };
  }
}
```

## Public API Protection

### Multi-Layer Defense

```javascript
// 1. API Key Authentication
const authenticateAPIKey = async (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  if (!apiKey) {
    return res.status(401).json({ error: 'API key required' });
  }
  
  // Verify key exists and is active
  const keyData = await db.apiKey.findUnique({ 
    where: { key: apiKey },
    include: { user: true }
  });
  
  if (!keyData || !keyData.active) {
    return res.status(401).json({ error: 'Invalid API key' });
  }
  
  req.apiKey = keyData;
  next();
};

// 2. Usage-Based Rate Limiting
const usageLimiter = (req, res, next) => {
  const { user } = req.apiKey;
  
  // Check if user has exceeded their plan limits
  if (user.monthlyRequests >= user.plan.maxRequests) {
    return res.status(429).json({
      error: 'Monthly quota exceeded',
      limit: user.plan.maxRequests,
      used: user.monthlyRequests,
      resetsAt: new Date(user.billingCycleStart.getTime() + 30*24*60*60*1000)
    });
  }
  
  next();
};

// 3. Track Usage
const trackUsage = async (req, res, next) => {
  // Increment usage counter
  await db.user.update({
    where: { id: req.apiKey.userId },
    data: { monthlyRequests: { increment: 1 } }
  });
  
  next();
};

app.use('/api/v1', authenticateAPIKey, usageLimiter, trackUsage);
```

## Error Handling

### User-Friendly Rate Limit Responses

```typescript
interface RateLimitError {
  error: 'rate_limit_exceeded';
  message: string;
  retryAfter: number; // seconds
  limits: {
    requests: number;
    window: string;
    remaining: number;
  };
}

function createRateLimitError(
  retryAfterSeconds: number,
  maxRequests: number,
  windowName: string,
  remaining = 0
): RateLimitError {
  return {
    error: 'rate_limit_exceeded',
    message: `Rate limit exceeded. You can make ${maxRequests} requests per ${windowName}. Try again in ${retryAfterSeconds} seconds.`,
    retryAfter: retryAfterSeconds,
    limits: {
      requests: maxRequests,
      window: windowName,
      remaining
    }
  };
}

// Frontend handling
async function handleAPICall(apiCall: () => Promise<any>) {
  try {
    return await apiCall();
  } catch (error) {
    if (error.status === 429) {
      const rateLimitData = error.data as RateLimitError;
      
      // Show user-friendly message
      toast.error(
        `Too many requests. Please wait ${rateLimitData.retryAfter} seconds before trying again.`
      );
      
      // Optionally auto-retry
      setTimeout(() => {
        handleAPICall(apiCall);
      }, rateLimitData.retryAfter * 1000);
      
      return null;
    }
    
    throw error; // Re-throw other errors
  }
}
```

## Monitoring & Alerts

### Track Key Metrics

```yaml
# monitoring.yml - Add to your observability stack
rate_limiting:
  metrics:
    - name: api_requests_total
      type: counter
      labels: [endpoint, status_code, api_key]
    
    - name: rate_limit_exceeded_total
      type: counter  
      labels: [endpoint, reason]
    
    - name: api_response_time
      type: histogram
      labels: [endpoint]
    
    - name: cache_hit_rate
      type: gauge
      labels: [service]

  alerts:
    - name: high_rate_limit_rejections
      condition: rate(rate_limit_exceeded_total) > 10/min
      severity: warning
      
    - name: api_budget_exceeded
      condition: daily_api_cost > $50
      severity: critical
```

## Checklist

Before deploying API integrations:

- [ ] **Rate limiting implemented** - Client and/or server-side
- [ ] **Retry logic added** - Exponential backoff with jitter
- [ ] **Caching in place** - Appropriate TTL for your data
- [ ] **Cost monitoring** - Track usage and set budget alerts  
- [ ] **Error handling** - User-friendly rate limit messages
- [ ] **Documentation** - Rate limits and retry behavior documented
- [ ] **Testing** - Simulated rate limit scenarios tested
- [ ] **Monitoring** - Metrics and alerts configured

## Integration

### With Security Gate
- Rate limiting is part of API security review
- Budget overruns flag as security incidents
- Public API protections mandatory

### With Human Approval  
- New API integrations require review
- Cost-sensitive operations need approval
- Rate limit changes need sign-off

### With Documentation
- API limits documented for users
- Retry strategies explained
- Cost implications transparent