---
description: >
  Enforces secure handling of secrets, API keys, environment variables, and sensitive
  configuration. Prevents credential leaks and ensures proper secret rotation practices.
  Use when: (1) configuring environment variables, (2) adding API keys or tokens,
  (3) setting up CI/CD secrets, (4) reviewing code for hardcoded credentials,
  (5) rotating secrets after a breach or staff change.
globs: ["**/.env*", "**/*.config.*", "**/docker-compose*", "**/.github/**", "**/vercel.json"]
alwaysApply: false
---

# Secrets Management

## Purpose

Keep secrets out of code, logs, and version control. Ensure proper handling of API keys, database credentials, tokens, and any sensitive configuration across all environments.

## Activation

This skill activates when you mention:
- "environment variable", "env var", ".env"
- "API key", "secret", "token", "credential"
- "rotate secrets", "key rotation"
- "vault", "secrets manager"
- "hardcoded password", "leaked key"

Also activates when detecting:
- New .env files or changes to existing ones
- Hardcoded strings that look like credentials
- CI/CD configuration changes
- Docker or deployment config modifications

## Golden Rules

1. **Never commit secrets to git.** Not even "temporarily".
2. **Never log secrets.** Not even in debug mode.
3. **Never send secrets in URLs.** Query parameters get logged everywhere.
4. **Never hardcode secrets.** Always use environment variables.
5. **Never share secrets in chat/email.** Use a secrets manager or encrypted channel.

## Environment File Setup

### .env File Structure

```bash
# .env.example (commit this - no real values)
DATABASE_URL=postgresql://user:password@host:5432/db
API_KEY=your-api-key-here
STRIPE_SECRET_KEY=sk_test_...
NEXTAUTH_SECRET=generate-with-openssl-rand-base64-32

# .env.local (never commit - real values)
DATABASE_URL=postgresql://real-user:real-pass@neon.tech:5432/mydb
API_KEY=ak_live_abc123...
```

### .gitignore (Non-Negotiable)

```gitignore
# Secrets - never commit these
.env
.env.local
.env.production
.env.*.local
*.pem
*.key
*_rsa
*_dsa
*_ecdsa
*_ed25519
```

### Environment Variable Validation

Validate at startup, fail fast if secrets are missing:

```typescript
// lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url('DATABASE_URL must be a valid URL'),
  API_KEY: z.string().min(10, 'API_KEY looks too short'),
  NEXTAUTH_SECRET: z.string().min(32, 'NEXTAUTH_SECRET must be at least 32 chars'),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
});

// Validate on import - app won't start with missing/invalid secrets
export const env = envSchema.parse(process.env);
```

```python
# Python equivalent
import os
from dataclasses import dataclass

@dataclass
class Config:
    database_url: str
    api_key: str
    secret_key: str

    @classmethod
    def from_env(cls) -> 'Config':
        missing = []
        for field in ['DATABASE_URL', 'API_KEY', 'SECRET_KEY']:
            if not os.environ.get(field):
                missing.append(field)
        if missing:
            raise ValueError(f"Missing required environment variables: {', '.join(missing)}")
        
        return cls(
            database_url=os.environ['DATABASE_URL'],
            api_key=os.environ['API_KEY'],
            secret_key=os.environ['SECRET_KEY'],
        )
```

## Secret Detection Patterns

### What to Flag

| Pattern | Example | Severity |
|---------|---------|----------|
| Hardcoded API key | `apiKey = "sk_live_abc123"` | Critical |
| Hardcoded password | `password = "mypassword"` | Critical |
| Private key in code | `-----BEGIN RSA PRIVATE KEY-----` | Critical |
| Connection string with credentials | `postgres://user:pass@host/db` | Critical |
| JWT secret in code | `jwt.sign(data, "mysecretkey")` | Critical |
| AWS credentials | `AKIA...` pattern | Critical |
| Secret in URL | `https://api.com?key=abc123` | High |
| Secret in log statement | `console.log(apiKey)` | High |
| Hardcoded token | `token = "ghp_xxxxx"` | Critical |

### Automated Detection

```bash
# Gitleaks (recommended)
gitleaks detect --source=. --verbose

# TruffleHog
trufflehog filesystem . --only-verified

# git-secrets (AWS focused)
git secrets --scan
```

## Platform-Specific Guidance

### Vercel
```bash
# Set secrets via CLI (preferred)
vercel env add DATABASE_URL production
vercel env add API_KEY preview production

# Or via dashboard: Project > Settings > Environment Variables
# Always scope to specific environments
```

### GitHub Actions
```yaml
# Use GitHub Secrets, never hardcode
jobs:
  deploy:
    steps:
      - name: Use secret
        env:
          API_KEY: ${{ secrets.API_KEY }}
        run: echo "Key is set (not printing it!)"
```

### Docker
```yaml
# docker-compose.yml - reference .env, don't inline
services:
  app:
    env_file:
      - .env
    # NEVER do this:
    # environment:
    #   - API_KEY=hardcoded_value
```

## Secret Rotation

### When to Rotate

| Trigger | Action | Urgency |
|---------|--------|---------|
| Suspected leak | Rotate immediately | Emergency |
| Team member leaves | Rotate shared secrets | Within 24 hours |
| Regular schedule | Rotate all secrets | Quarterly |
| Dependency breach | Rotate affected keys | Within 48 hours |
| Secret found in git history | Rotate and clean history | Emergency |

### Rotation Checklist

```markdown
## Secret Rotation: [Secret Name]

- [ ] Generate new secret/key
- [ ] Update in secrets manager/platform
- [ ] Update all environments (dev, staging, prod)
- [ ] Verify application works with new secret
- [ ] Revoke old secret
- [ ] Update documentation
- [ ] Notify affected team members
- [ ] Audit access logs for old secret usage
```

### If a Secret Leaks to Git

```bash
# 1. Rotate the secret IMMEDIATELY (before cleaning git)
# 2. Then clean git history (preferred: git filter-repo):
pip install git-filter-repo
git filter-repo --invert-paths --path path/to/secret-file

# Or the older git filter-branch (deprecated but still works):
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/secret-file' \
  --prune-empty --tag-name-filter cat -- --all

# Or use BFG Repo-Cleaner (faster):
bfg --delete-files .env
bfg --replace-text passwords.txt

# 3. Force push
git push origin --force --all

# 4. Contact platform (GitHub/GitLab) to purge caches
```

## Integration

### With Security Gate
- Secret detection runs as part of every security scan
- Any detected secret blocks deployment immediately
- No exceptions without documented emergency process

### With Human Approval
- Adding new secret types triggers review
- Changes to secret management infrastructure need approval
- Rotation after incidents requires sign-off

### With Privacy Guard
- Database credentials protect PII
- API keys for third-party data processors need tracking
- Encryption keys for PII storage are critical secrets

### With Pre-Release
- Verify no secrets in codebase before release
- Confirm all environments have required secrets configured
- Check secret rotation status
