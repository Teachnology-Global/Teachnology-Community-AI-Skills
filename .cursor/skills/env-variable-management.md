---
description: >
  Governs environment variable handling across development, staging, and production.
  Prevents secret leakage, ensures consistent configuration across environments,
  and provides safe patterns for non-technical founders managing API keys and config.
  Use when: (1) setting up a new project, (2) adding API keys or secrets,
  (3) configuring environment-specific settings, (4) deploying to new environments,
  (5) debugging configuration issues, (6) onboarding team members.
globs: [".env*", "*.config.*", "docker-compose*.yml", "**/Dockerfile*", ".github/workflows/**"]
alwaysApply: false
tags: [product]
---

# Environment Variable Management

## Purpose

Environment variables are how your app keeps secrets secret and configures behaviour per environment (local dev vs staging vs production). Mismanagement is the #1 way non-technical founders accidentally expose API keys, database credentials, or payment secrets.

**For teachers and non-technical founders:** Think of environment variables as the "settings" your app reads when it starts up. Some settings are safe to share (like "what colour is the header"), but others are passwords to your services (like your Stripe or OpenAI API key). This skill makes sure you handle them safely.

## Activation

This skill activates when you mention:
- "environment variable", "env var", ".env"
- "API key", "secret key", "access token"
- "configuration", "config"
- "staging", "production config"
- "where do I put my API key"

Also activates when:
- Creating or modifying `.env` files
- Adding new API integrations
- Setting up CI/CD pipelines
- Deploying to new environments

## Critical Rules

### 1. Never Commit .env Files

```gitignore
# .gitignore — ALWAYS include these
.env
.env.local
.env.*.local
.env.production
.env.staging
!.env.example
```

### 2. Use .env.example as a Template

```bash
# .env.example — committed to git, contains NO real values
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
OPENAI_API_KEY=sk-your-key-here
STRIPE_SECRET_KEY=sk_test_your-key-here
STRIPE_WEBHOOK_SECRET=whsec_your-secret-here
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 3. Environment Hierarchy

```
.env.example        → Committed (template, no secrets)
.env.local          → Your local dev (gitignored)
.env.staging        → Staging config (gitignored, managed by CI/CD)
.env.production     → Production config (gitignored, managed by platform)
```

## Safe Patterns by Framework

### Next.js / React

```bash
# Server-only (never sent to browser)
DATABASE_URL=...
OPENAI_API_KEY=...
STRIPE_SECRET_KEY=...

# Client-safe (NEXT_PUBLIC_ prefix = bundled into JS)
NEXT_PUBLIC_APP_URL=https://myapp.com
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...
```

**⚠️ Rule:** Never put secrets in `NEXT_PUBLIC_` variables. They are visible to anyone who views your page source.

### Node.js (Express, Fastify)

```javascript
// Use dotenv or dotenv-expand
import 'dotenv/config';

// Validate required variables at startup
const required = ['DATABASE_URL', 'OPENAI_API_KEY'];
for (const key of required) {
  if (!process.env[key]) {
    console.error(`❌ Missing required env var: ${key}`);
    process.exit(1);
  }
}
```

### Python (Django, Flask, FastAPI)

```python
import os
from pathlib import Path

# Load from .env file
from dotenv import load_dotenv
load_dotenv()

# Access with defaults
DATABASE_URL = os.environ["DATABASE_URL"]  # Raises error if missing
DEBUG = os.environ.get("DEBUG", "false").lower() == "true"
```

## Secret Rotation Checklist

When a secret is exposed (committed to git, shared in chat, leaked in logs):

```markdown
## Secret Exposure Response

1. [ ] Rotate the secret immediately at the provider
2. [ ] Update the secret in all environments (dev, staging, prod)
3. [ ] Remove the secret from git history (git-filter-repo or BFG)
4. [ ] Check logs for unauthorised usage
5. [ ] Review access logs at the provider (Stripe, OpenAI, etc.)
6. [ ] Update .env.example if the variable name changed
7. [ ] Notify team if the secret was shared
```

## Common TYO Community Mistakes

| Mistake | Why It's Bad | Fix |
|---------|-------------|-----|
| Hardcoding API key in source code | Visible in git history forever | Use .env files |
| Sharing .env in Discord/Slack | Chat logs are permanent | Share .env.example only |
| Using production keys in dev | Accidentally charges real money | Use test/sandbox keys |
| Committing .env to git | Anyone with repo access sees secrets | Add to .gitignore |
| Using `NEXT_PUBLIC_` for secrets | Bundled into browser JS | Server-only vars |
| Same secrets across all environments | One breach = all compromised | Separate per environment |

## Platform-Specific Setup

### Vercel

```bash
# Add via CLI
vercel env add OPENAI_API_KEY production
vercel env add OPENAI_API_KEY preview

# Or via dashboard: Settings → Environment Variables
```

### Railway

```bash
# Add via CLI
railway variables set OPENAI_API_KEY=sk-...

# Or via dashboard: Variables tab
```

### Docker Compose

```yaml
services:
  app:
    env_file:
      - .env.production
    environment:
      - NODE_ENV=production
```

## Cross-References

- **Secrets Management**: For advanced secret handling (vaults, rotation)
- **Security Gate**: For scanning for leaked secrets in code
- **Git Security**: For preventing secret commits
- **Deployment Checklist**: For env var verification before deploy
