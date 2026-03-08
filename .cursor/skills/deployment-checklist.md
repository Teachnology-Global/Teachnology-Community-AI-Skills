---
description: >
  A focused go/no-go checklist for deploying to Vercel, Railway, Fly.io, or any
  hosting platform. Shorter and more actionable than the full pre-release skill.
  Optimised for the "I'm about to press deploy" moment.
  Use when: (1) about to deploy to production, (2) deploying for the first time,
  (3) deploying after a significant change, (4) unsure if something will break in prod.
globs: ["**/vercel.json", "**/fly.toml", "**/railway.json", "**/Dockerfile", "**/next.config.*"]
alwaysApply: false
---

# Deployment Checklist

## Purpose

A quick, focused checklist for the moment before you deploy. Not a comprehensive audit (see Pre-Release Checklist for that) — this is the "did I forget anything obvious?" list that prevents the most common deployment disasters.

## Activation

This skill activates when you mention:
- "deploy", "push to production", "ship it"
- "vercel deploy", "railway deploy", "fly deploy"
- "go live", "launch", "release"
- "is this ready to deploy?"
- "deployment checklist", "pre-deploy"

## The Checklist

### 🔴 STOP — Before You Do Anything

```
□ Are you deploying to the RIGHT project/environment?
  └── Verify: project name, team, and environment (preview vs production)
  └── Triple-check if you have multiple Vercel/Railway projects
□ Is there live content or data that isn't in your repo?
  └── CMS content, user-uploaded files, database records
  └── If yes: DO NOT deploy from a fresh clone without checking
□ Do you have a rollback plan?
  └── Know the previous deployment ID or commit hash
  └── Vercel: note the current deployment URL before deploying
```

### 🟡 Environment & Secrets

```
□ All environment variables are set in the hosting platform
  └── Not just in your local .env — in the actual deployment config
  └── Vercel: Settings → Environment Variables
  └── Railway: Variables tab
□ No secrets are hardcoded in the codebase
  └── Quick check: grep -r "sk-" --include="*.ts" --include="*.js" --include="*.env"
  └── Quick check: grep -r "password" --include="*.ts" --include="*.js"
□ API keys are using production keys, not test/dev keys
  └── Stripe: live key (sk_live_), not test key (sk_test_)
  └── Database: production connection string, not localhost
□ Environment variables match between your .env.example and the platform
```

### 🟡 Database

```
□ Database migrations have been run on production
  └── Or: your ORM auto-migrates and you've tested that it works
□ No destructive migrations (DROP TABLE, DROP COLUMN) without a backup
□ Connection string uses connection pooling for serverless
  └── Neon: use the pooled connection string (-pooler suffix)
  └── Supabase: use the pooled port (6543, not 5432)
□ Database has a recent backup (if the deploy touches schema)
```

### 🟡 Build & Code

```
□ Build succeeds locally: npm run build (or equivalent)
  └── Fix all TypeScript errors and build warnings
  └── Ignore "unused variable" warnings at your peril
□ No console.log() statements leaking sensitive data
□ Error pages exist (404, 500) and don't expose stack traces
□ API routes return proper status codes (not 200 for errors)
□ CORS is configured correctly (if you have an API)
□ Rate limiting is in place for public API endpoints
```

### 🟡 Functionality

```
□ Test the critical user path end to end locally
  └── Can a user sign up, do the core thing, and pay? Test it.
□ Payment integration works (if applicable)
  └── Stripe webhook endpoint is registered and verified
  └── Webhook signing secret is set in environment variables
□ Auth works (if applicable)
  └── Can log in, can log out, protected routes are protected
  └── OAuth callback URLs point to production domain, not localhost
□ Email sending works (if applicable)
  └── FROM address, reply-to, and domain verification are set up
```

### 🟢 Deploy

```
□ Deploy to preview/staging first if available
  └── Vercel: PRs auto-deploy to preview — check that URL first
□ Watch the build logs for errors or warnings
□ After deploy: visit the production URL and test the critical path
□ Check the browser console for errors
□ Test on mobile (or at least resize the browser)
```

### 🟢 Post-Deploy (5 minutes after)

```
□ Core functionality works on the live URL
□ No console errors in the browser
□ API endpoints respond correctly
□ Database connections are healthy
□ Monitoring/error tracking is receiving events (Sentry, LogRocket, etc.)
□ SSL certificate is valid (padlock in browser)
```

## Platform-Specific Notes

### Vercel

```
□ Check vercel.json for redirects/rewrites — do they still make sense?
□ Serverless function timeout is set appropriately (default 10s)
  └── Long-running tasks need background functions or queues
□ If using ISR: check revalidation intervals
□ Middleware runs on every request — make sure it's not blocking
□ Sacred deployments: if told "don't deploy over X", check first
  └── Compare live site vs repo before deploying
```

### Railway

```
□ Health check endpoint is configured
□ Start command is correct in railway.json or Procfile
□ Volume mounts are set up (if using persistent storage)
□ Custom domain DNS is pointing to Railway
```

### Fly.io

```
□ fly.toml is correct for your app type
□ Regions are set (fly regions list)
□ Scaling is appropriate (fly scale show)
□ Secrets are set (fly secrets list)
```

## Common Disasters (and How to Avoid Them)

| Disaster | Prevention |
|---|---|
| Deployed over a sacred deployment | Check deployment IDs before deploying. Ask if unsure. |
| Missing environment variable | Compare .env.example with platform variables before deploy |
| Wrong database (dev data in prod) | Verify connection string contains "prod" or production host |
| Stripe test key in production | Verify key prefix: `sk_live_` not `sk_test_` |
| OAuth redirect to localhost | Check callback URLs in OAuth provider dashboard |
| CORS blocking the frontend | Test API calls from the production domain, not localhost |
| Build passes locally, fails in CI | Ensure node version matches, check for OS-specific deps |

## Rollback Protocol

If something goes wrong after deploy:

### Vercel
```bash
# List recent deployments
npx vercel ls --token $VERCEL_TOKEN

# Promote previous deployment to production
npx vercel promote <deployment-url> --token $VERCEL_TOKEN
```

### Railway
```bash
# Railway auto-keeps previous deployments
# Use the dashboard to rollback to previous deploy
```

### Git-based rollback
```bash
# Revert the last commit and redeploy
git revert HEAD
git push origin main
```

## Relationship to Other Skills

- **Pre-Release Checklist** — the comprehensive version. Use that for major releases. Use this for routine deploys.
- **Secrets Management** — covers credential handling in depth. This checklist is the "did I set the env vars?" quick check.
- **Security Gate** — covers security scanning. This checklist assumes scanning has been done.

## Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│          DEPLOYMENT GO/NO-GO                     │
├─────────────────────────────────────────────────┤
│                                                 │
│  🔴 STOP:                                      │
│  □ Right project? Right environment?            │
│  □ Live content that isn't in git?              │
│  □ Rollback plan ready?                         │
│                                                 │
│  🟡 CHECK:                                      │
│  □ Env vars set on platform (not just local)    │
│  □ Production keys (not test keys)              │
│  □ Build succeeds: npm run build                │
│  □ Critical path tested end to end              │
│  □ Database migrated and backed up              │
│                                                 │
│  🟢 DEPLOY:                                     │
│  □ Preview/staging first                        │
│  □ Watch build logs                             │
│  □ Test live URL after deploy                   │
│  □ Check browser console for errors             │
│                                                 │
│  ❌ IF BROKEN: rollback immediately,            │
│     investigate after                           │
│                                                 │
└─────────────────────────────────────────────────┘
```
