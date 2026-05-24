---
description: >
  Governs safe use of feature flags for gradual rollouts, A/B testing, and kill switches.
  Essential for non-technical founders who need to ship safely without full confidence.
  Covers flag lifecycle, naming conventions, cleanup discipline, audit trails, and
  security risks of flags that bypass authentication or payment logic.
  Use when: (1) adding a feature flag, (2) running A/B tests, (3) implementing gradual rollouts,
  (4) cleaning up old flags, (5) using flags for access control or payment logic.
globs: ["**/flags/**", "**/feature-flags/**", "**/*flag*", "**/config/**", "**/*featureToggle*"]
alwaysApply: false
tags: [product]
---

# Feature Flag Governance

## Purpose

Feature flags let you ship incomplete code safely — toggle features on/off without deploying. For non-technical founders building with AI, they are a critical safety net. But flags are runtime code changes, and mismanaged flags create hidden complexity, security bypasses, and dead code that nobody remembers exists.

**For teachers and non-technical founders:** A feature flag is like a light switch for your code. Flip it off and the feature disappears for users. But if you forget about that switch, or leave it pointing at a broken feature, it will confuse you later. The rules below keep your flags safe and clean.

## Activation

This skill activates when you mention:
- "feature flag", "feature toggle", "kill switch"
- "A/B test", "gradual rollout", "canary release"
- "LaunchDarkly", "Flagsmith", "OpenFeature", "Unleash"
- "roll out to 10%", "rollout percentage"
- "experiment", "split test", "multivariate test"

Also activates when:
- Adding any code pattern that checks a flag value before executing
- Creating new flag definitions or flag schemas
- Building an experiment or A/B test system
- Implementing progressive rollouts or gradual releases

## Core Principles

### 1. Flags Are Temporary — Have a Cleanup Plan

Every flag should be created with a planned removal date and conditions:

```markdown
## Feature Flag: [name]

**Purpose:** [what it controls]
**Created:** [date]
**Owner:** [person responsible]
**Expected removal date:** [date or condition]
**Cleanup task created?** [link to issue/ticket]
```

**Rule:** No flag lives longer than 90 days without review. After 90 days, it's either:
- Rolled out to 100% and code cleaned up (flag removed entirely)
- Rolled back and dead code deleted
- Extended with documented justification

### 2. Never Use Flags for Security Controls

```markdown
DANGEROUS:
❌ Feature flag that bypasses authentication: flags['skip-auth']
❌ Feature flag that controls payment bypass: flags['free-access']
❌ Feature flag that disables rate limiting: flags['no-rate-limit']
❌ Feature flag that turns off HTTPS: flags['dev-http-mode']

SAFE:
✅ Feature flag for gradual UI rollout: flags['new-dashboard-ui']
✅ Feature flag for A/B test pricing display: flags['pricing-layout-b']
✅ Feature flag for experimental search algorithm: flags['search-v2']
✅ Feature flag for beta feature access: flags['beta-analytics']
```

**Why:** Feature flags are runtime configuration — they can be toggled by accident, misconfigured, or exposed to users. Security decisions must be code-level, not flag-level.

### 3. Flag Naming Conventions

```markdown
FORMAT: <type>-<team>-<short-description>

TYPES:
  - 'exp': A/B test or experiment (auto-expire after test ends)
  - 'ops': Operational toggle (kill switch, maintenance mode)
  - 'perm': Permissioned access (beta, early access)
  - 'roll': Gradual rollout (new feature percentage)

EXAMPLES:
  - exp-marketing-hero-test
  - ops-database-failover
  - perm-beta-analytics
  - roll-checkout-redesign

PROHIBITED:
  - 'flag1', 'test-flag', 'new-thing' (no context)
  - 'enable-auth', 'disable-security' (security-adjacent)
  - Flags with no owner or documented purpose
```

### 4. Audit Trail for Flag Changes

Every flag change must be traceable:

```typescript
// Log every flag change
interface FlagAuditEntry {
  flagName: string;
  previousValue: any;
  newValue: any;
  changedBy: string;
  timestamp: string;
  reason: string;
}

// If using feature flag service, enable audit logging
// For self-built flag systems, always implement audit
```

## Feature Flag Implementation Patterns

### ✅ Safe: Gradual Rollout

```typescript
// Safely roll out a new feature to increasing percentages
function shouldEnableNewFeature(userId: string, flagName: string): boolean {
  const rollout = featureFlags.getPercentage(flagName); // e.g., 25 for 25%

  // Deterministic: same user always gets same result for same percentage
  const hash = hashString(userId + flagName);
  const userPercent = hash % 100;

  return userPercent < rollout;
}

// Usage
if (shouldEnableNewFeature(user.id, 'roll-checkout-redesign')) {
  return <NewCheckoutFlow />;
}
return <LegacyCheckoutFlow />;
```

### ✅ Safe: Kill Switch

```typescript
// Emergency disable for unstable features
function isCheckoutFeatureEnabled(): boolean {
  // Kill switch takes priority — if disabled, NEVER show new feature
  if (!featureFlags.getBoolean('ops-checkout-kill-switch')) {
    return false;
  }

  // Then check gradual rollout
  return shouldEnableNewFeature(user.id, 'roll-checkout-redesign');
}
```

### ✅ Safe: A/B Test with Tracking

```typescript
function assignABTest(userId: string, testName: string): 'A' | 'B' {
  const hash = hashString(userId + testName);
  const assignment = hash % 2 === 0 ? 'A' : 'B';

  // Log the assignment for analysis
  analytics.track('ab_test_assignment', {
    test: testName,
    assignment,
    userId: user.id,
  });

  return assignment;
}

// Usage
const layout = assignABTest(user.id, 'exp-pricing-layout');
return layout === 'A' ? <PricingGridA /> : <PricingGridB />;
```

## Flag Lifecycle Management

### Phase 1: Creation
```markdown
1. Create flag with documented purpose, owner, and removal criteria
2. Start at 0% (disabled) — add explicit enable step
3. Test with internal accounts first
4. Document expected impact on user experience
```

### Phase 2: Rollout
```markdown
1. Enable for internal team (5-10%)
2. Monitor error rates and performance
3. Gradually increase: 25% → 50% → 75% → 100%
4. Wait at least 24 hours between each increase
5. Set up alerts for the new feature code path
```

### Phase 3: Cleanup
```markdown
1. At 100% rollout, create code cleanup ticket
2. Remove all feature flag checks (both branches)
3. Remove the flag definition from config/service
4. Close the ticket with confirmation of removal
5. Verify in next deployment that flag code is truly gone
```

## Governance Checklist

Before shipping any feature flag:

- [ ] **Purpose documented** — what does this flag control?
- [ ] **Owner assigned** — who is responsible for cleanup?
- [ ] **Removal date set** — when should this flag be removed?
- [ ] **Not security-adjacent** — does not control auth, payments, rate limits
- [ ] **Naming convention followed** — type-team-description format
- [ ] **Starts disabled** — zero rollout percentage initially
- [ ] **Rollout plan documented** — how will it be phased in?
- [ ] **Alerts configured** — monitoring on both code paths (flag on and off)
- [ ] **Legacy path maintained** — if flag is disabled, the old code still works
- [ ] **Cleanup ticket created** — code removal task is tracked

## Red Flags

Flag configuration must be rejected or investigated if it has:

- Flags controlling authentication bypass or permission escalation
- Default value that exposes incomplete features to all users
- No documented owner or removal criteria
- Flags with "everyone" as the target audience (should use a deployment instead)
- Multiple flags controlling the same feature area (consolidate first)
- Flags that have been unchanged for 90+ days
- Flag values that differ between environments without documented reason
- Flags used to hide known bugs (fix the bug, don't flag it away)

## Integration

### With Deployment Checklist
- Active feature flags listed in deployment documentation
- Flag status checked before production deploy
- Flags with pending rollouts require explicit deploy approval

### With Monitoring & Alerting
- Separate error tracking for flag-on and flag-off code paths
- Alert if error rate differs significantly between flag states
- Monitor rollout percentage changes

### With Incident Response
- Kill-switch flags should be documented in incident runbooks
- If a feature causes issues, the first response should be check/flip the relevant flag
- Post-incident: document whether flags helped or hindered response

## Quick Reference

```
FEATURE FLAG DECISION TREE:

1. Is this controlling security/auth/payments?
   → YES: Don't use a flag. Change the code.
   → NO: Continue

2. Is this for a gradual rollout of real features?
   → YES: Create 'roll-*' flag with rollout plan
   → NO: Continue

3. Is this for an A/B test experiment?
   → YES: Create 'exp-*' flag with end date
   → NO: Continue

4. Is this a kill switch for emergency disable?
   → YES: Create 'ops-*' flag with clear documentation
   → NO: Do you actually need a flag?
```