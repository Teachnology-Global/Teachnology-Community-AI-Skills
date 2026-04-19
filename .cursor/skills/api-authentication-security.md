---
description: >
  Governs secure API authentication patterns: JWT implementation, OAuth flows,
  session management, CORS configuration, token lifecycle, and common auth mistakes
  that non-technical founders make. Covers NextAuth/Auth.js, Clerk, Supabase Auth,
  and custom JWT. Use when: (1) implementing login/signup, (2) adding OAuth providers,
  (3) configuring CORS, (4) managing token refresh, (5) reviewing authentication code.
globs: ["**/auth/**", "**/middleware.*", "**/.env*", "**/api/auth/**", "**/*Session*", "**/*Token*"]
alwaysApply: false
tags: [product]
---

# API Authentication Security

## Purpose

Authentication is the most common security failure point for apps built by non-technical founders and teachers. Get it wrong and every user account, every piece of data, and every API call is exposed.

This skill covers:
- JWT (JSON Web Token) best practices and pitfalls
- OAuth 2.0 / OIDC flows for social login
- Session vs token-based auth decisions
- CORS misconfiguration prevention
- Token lifecycle: creation, refresh, revocation
- Password storage (bcrypt/argon2, never MD5/SHA)

**2026 context:** OAuth 2.1 is finalised (combines RFC 6749, 6750, 7636, 8252 — PKCE is now mandatory for all client types). Authorization Code + PKCE is the required flow for all clients — implicit flow is removed.

## Activation

This skill activates when you mention:
- "JWT", "JSON Web Token", "token-based auth"
- "OAuth", "Google login", "GitHub login", "Sign in with Apple"
- "session", "NextAuth", "Auth.js", "Clerk", "Supabase Auth"
- "CORS", "cross-origin", "preflight"
- "password hashing", "bcrypt", "argon2"
- "login", "signup", "logout", "authentication"
- "token refresh", "token expiry", "token revocation"
- "API key auth", "Bearer token"

Also activates when:
- Implementing `/api/auth/*` endpoints
- Setting up OAuth providers in any auth library
- Configuring CORS middleware
- Storing password hashes

## Critical Rules

### 1. Password Storage — Never Hash Wrong

```typescript
// BAD — SHA-256 is fast, unsalted, and crackable in seconds
import crypto from 'crypto';
const hash = crypto.createHash('sha256').update(password).digest('hex');

// BAD — MD5 (broken, fast, rainbow tables)
const hash = crypto.createHash('md5').update(password).digest('hex');

// GOOD — bcrypt with automatic salt, appropriate work factor
import bcrypt from 'bcrypt';
const hash = await bcrypt.hash(password, 12); // Work factor 12 for 2026

// GOOD — argon2id (current best practice, memory-hard)
import argon2 from 'argon2';
const hash = await argon2.hash(password, {
  type: argon2.argon2id,
  memoryCost: 65536,    // 64 MB
  timeCost: 3,
  parallelism: 1,
});
```

**Work factor guide for 2026:**
| Algorithm | Minimum Work Factor | Target Hash Time |
|-----------|-------------------|------------------|
| bcrypt    | 12                | ~200ms           |
| argon2id  | 64 MB / 3 iters   | ~200ms           |

**Never** use: MD5, SHA-1, SHA-256, PBKDF2 with < 310,000 iterations.

### 2. JWT Implementation — Do It Right

```typescript
// BAD — No expiry, sensitive data in payload, weak signing
const token = jwt.sign({
  userId: user.id,
  email: user.email,         // Don't put PII in JWT
  role: user.role,
  password: user.password,   // NEVER put password in JWT
}, 'secret123', {             // Never use a hardcoded secret
  expiresIn: '999 years'      // Tokens MUST expire
});

// GOOD — Minimal payload, short expiry, env-based secret
const token = jwt.sign({
  sub: user.id,              // Use standard claim 'sub' for subject
  role: user.role,           // Only what's needed for auth decisions
}, process.env.JWT_SECRET!, {  // Secret from environment variable
  algorithm: 'HS256',        // Minimum for HMAC (RS256 for asymmetric)
  expiresIn: '15m',          // Short-lived access token
  issuer: 'your-app.com',
  audience: 'your-app.com',
});

// For refresh tokens: longer expiry, separate secret, store in DB
const refreshToken = jwt.sign({
  sub: user.id,
  jti: generateRandomId(),   // Unique token ID for revocation
}, process.env.JWT_REFRESH_SECRET!, {
  expiresIn: '7d',
  algorithm: 'HS256',
});
```

**JWT Security Rules:**
1. **Never store sensitive data in JWT payload** — JWTs are base64-encoded, not encrypted. Anyone can decode the payload.
2. **Always set expiry** — `exp` claim. Access tokens: 15 min max. Refresh tokens: 7 days max.
3. **Use separate secrets** for access and refresh tokens.
4. **Store refresh tokens in the database** with a revocation mechanism.
5. **Use `RS256` (asymmetric)** if the token needs to be verified by multiple services.
6. **Validate `iss`, `aud`, `exp`, `sub`** on every verification.
7. **Include a `jti` claim** for token revocation/invalidation.

### 3. Session vs Token Auth — Choose Correctly

| Pattern | Use When | Security Profile |
|---------|----------|-----------------|
| **HTTP-only cookies (sessions)** | Web apps with server-side rendering | Best for browser-based apps |
| **JWT in localStorage** | SPA + API (not recommended) | Vulnerable to XSS |
| **JWT in HTTP-only cookie** | SPA + API (recommended) | Protected from XSS, requires CSRF protection |
| **JWT in Authorization header** | Mobile apps, service-to-service | Standard for non-browser clients |

**Recommendation for Next.js + Vercel:** Use HTTP-only cookies with the `iron-session` or `@auth/core` library. Let the library manage the cookie lifecycle.

```typescript
// Next.js Route Handler — HTTP-only secure cookie
import { cookies } from 'next/headers';

// Set after successful login
const cookieStore = await cookies();
cookieStore.set({
  name: 'session',
  value: sessionToken,
  httpOnly: true,        // JavaScript can't read it
  secure: true,          // HTTPS only (true in production)
  sameSite: 'lax',       // CSRF protection
  maxAge: 60 * 60 * 24 * 7, // 7 days
  path: '/',
});
```

### 4. OAuth 2.1 — PKCE Is Now Mandatory

OAuth 2.1 (finalised in 2025) removed the Implicit Flow entirely. **Every OAuth flow must use PKCE** (Proof Key for Code Exchange).

For non-technical founders: if you use NextAuth, Auth.js, or Clerk, PKCE is likely handled automatically. But verify:

```typescript
// NextAuth v5 (Auth.js) — PKCE enabled by default
import NextAuth from 'next-auth';
import Google from 'next-auth/providers/google';

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers: [
    Google({
      // PKCE is used by default in v5
      // authorization: { params: { prompt: 'consent' } } // Optional
    }),
  ],
});
```

**Red Flags — your auth setup is insecure if:**
- You see `response_type: 'token'` (implicit flow — deprecated)
- No `code_verifier` / `code_challenge` in the flow
- OAuth state parameter is missing (CSRF vulnerability)
- Redirect URIs are not strictly validated

### 5. CORS — Misconfiguration Is a Common Mistake

```typescript
// BAD — Allow everything (disables CORS protection entirely)
const cors = {
  origin: '*',                    // Never use wildcard for API endpoints
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  credentials: true,              // credentials: true + origin: '*' = BLOCKED by browsers
};

// BAD — Allow specific origin but all methods
const cors = {
  origin: 'https://your-frontend.com',
  methods: '*',
};

// GOOD — Specific origin, specific methods, credentials
const cors = {
  origin: process.env.FRONTEND_URL!,  // From environment variable
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  credentials: true,                   // Allow cookies in cross-origin requests
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 600,                         // Cache preflight for 10 minutes
};
```

**CORS Rules:**
1. **Never use `origin: '*'`** on any endpoint that handles authenticated requests
2. **Never use `origin: '*'` with `credentials: true`** — browsers reject this anyway
3. **Use exact domain matches** (not wildcards) for `origin`
4. **For multiple allowed origins**, implement a whitelist check, not a wildcard
5. **Restrict `methods` to only what's needed** on each route
6. **Restrict `allowedHeaders` to only what's needed**

### 6. Token Refresh — Avoid the Infinite Loop Trap

```typescript
// BAD — No error handling, infinite refresh loop
async function apiCall(url: string) {
  let response = await fetch(url, {
    headers: { Authorization: `Bearer ${getAccessToken()}` },
  });

  if (response.status === 401) {
    await refreshAccessToken();
    return await apiCall(url); // Infinite loop if refresh keeps failing
  }
  return response;
}

// GOOD — Single refresh attempt, max retries, error propagation
async function apiCall(url: string, options: RequestInit, maxRetries = 1) {
  let retryCount = 0;

  while (retryCount <= maxRetries) {
    const response = await fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        Authorization: `Bearer ${getAccessToken()}`,
      },
    });

    if (response.status === 401 && retryCount < maxRetries) {
      const refreshed = await refreshAccessToken();
      if (!refreshed) {
        // Redirect to login, don't keep retrying
        window.location.href = '/login?expired=true';
        throw new Error('Token refresh failed');
      }
      retryCount++;
      continue; // Retry with new token
    }

    return response;
  }
}
```

**Refresh token best practices:**
- **Maximum 1 retry** per API call (prevents infinite loops)
- **Always redirect to login on refresh failure** (don't silently fail)
- **Use refresh token rotation** (issue new refresh token on each use, revoke the old one)
- **Implement refresh token reuse detection** (if old refresh token is used, revoke the entire session)

### 7. Rate Limiting on Auth Endpoints

```typescript
// Next.js — Rate limit login attempts
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const loginLimiter = new Ratelimit({
  redis: Redis.fromEnv(),
  // 5 login attempts per minute per IP
  limiter: Ratelimit.slidingWindow(5, '1 m'),
});

// In your login route handler:
const { success, reset } = await loginLimiter.limit(ipAddress);
if (!success) {
  return NextResponse.json(
    { error: 'Too many login attempts. Try again later.' },
    { status: 429, headers: { 'Retry-After': String(Math.ceil((reset - Date.now()) / 1000)) } }
  );
}
```

**Auth rate limiting targets:**
| Endpoint | Limit | Window |
|----------|-------|--------|
| Login | 5 attempts | 1 minute |
| Password reset | 3 attempts | 1 hour |
| OTP/SMS verification | 5 attempts | 5 minutes |
| Token refresh | 10 attempts | 1 minute |
| Registration | 3 per IP | 1 hour |

### 8. Checklist for Auth Implementation Review

Before any auth code ships, verify:

- [ ] Passwords hashed with bcrypt (≥12) or argon2id
- [ ] JWTs have `exp`, `iss`, `aud` claims
- [ ] JWTs do NOT contain passwords, emails, or other PII
- [ ] Access tokens expire within 15 minutes
- [ ] Refresh tokens stored in DB with revocation support
- [ ] OAuth uses PKCE (no implicit flow)
- [ ] State parameter present on all OAuth requests
- [ ] CORS origin is NOT `'*'` on authenticated endpoints
- [ ] Login/register/reset endpoints are rate-limited
- [ ] HTTP-only, Secure, SameSite cookies for session storage
- [ ] Token refresh has max retry count (no infinite loop)
- [ ] Refresh token rotation implemented
- [ ] Logout revokes all tokens (access + refresh)
- [ ] Session fixation protection (regenerate session ID on login)
- [ ] Brute-force protection (account lockout or CAPTCHA after N failures)

## Common TYO Community Mistakes

| What They Do | Why It's Wrong | The Fix |
|---|---|---|
| Store JWT in localStorage | XSS steals all tokens | Use HTTP-only cookies |
| `origin: '*'` in CORS API | Any website can call your API | Use allowlist of domains |
| SHA-256 for passwords | Crackable in seconds | bcrypt(12) or argon2id |
| No `exp` on JWTs | Tokens valid forever | Set expiry: access=15m, refresh=7d |
| No rate limiting on login | Brute-force attacks | Use sliding window limiter |
| Hardcoded OAuth secrets | Leaked in git / frontend | Environment variables only |
| OAuth redirect to `localhost` in prod | Attackers intercept tokens | Validate redirect URIs server-side |
| No token revocation on logout | Token works until expiry even after logout | Blacklist/revoke on logout |

## Quick Start by Platform

### Next.js + Auth.js (recommended)
```bash
npx auth init
# Auto-generates NextAuth config with secure defaults
```

### Supabase Auth
```bash
# Use Supabase's built-in auth — handles sessions, OAuth, rate limiting
npx create-next-app with-supabase
```

### Clerk (fastest, paid)
```bash
npx clerk create
# Full auth out of the box with MFA, session management, social login
```
