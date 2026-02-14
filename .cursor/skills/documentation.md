---
description: >
  Ensures consistent documentation for every feature using established patterns.
  Generates ADRs, API docs, changelog entries, and migration guides. Use when:
  (1) implementing new features, (2) making architectural decisions, (3) changing
  APIs, (4) releasing new versions, (5) introducing breaking changes.
globs: ["**/*"]
alwaysApply: false
---

# Documentation

## Purpose

Every feature must be documented consistently. This skill ensures no documentation debt accumulates.

## Activation

This skill activates when you mention:
- "document this", "add documentation"
- "create ADR", "architecture decision"
- "changelog", "release notes"
- "migration guide", "breaking change"
- "API docs", "document endpoint"

Also activates automatically after completing features.

## Documentation Requirements

### What Needs Documentation

| Change Type | Required Documentation |
|-------------|----------------------|
| New feature | Changelog entry |
| API change | API docs + Changelog |
| Architecture decision | ADR + Changelog |
| Breaking change | Migration guide + ADR + Changelog |
| Bug fix | Changelog entry |
| Security fix | Changelog (Security section) |

### When to Create ADR

Create an Architecture Decision Record when:
- Choosing between multiple valid approaches
- Decisions affect multiple components
- Establishing patterns used project-wide
- Making hard-to-reverse decisions
- Selecting technologies or frameworks

## Documentation Templates

### Architecture Decision Record (ADR)

```markdown
# ADR-[NNN]: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXX]

## Date
YYYY-MM-DD

## Context

[What is the issue motivating this decision? What forces are at play?]

## Decision

[What is the change being proposed?]

## Consequences

### Positive
- [Benefit 1]
- [Benefit 2]

### Negative  
- [Tradeoff 1]

### Neutral
- [Side effect that's neither good nor bad]

## Alternatives Considered

### [Alternative A]
- **Pros**: [list]
- **Cons**: [list]
- **Rejected because**: [reason]
```

### Changelog Entry

Follow [Keep a Changelog](https://keepachangelog.com) format:

```markdown
## [Version] - YYYY-MM-DD

### Added
- New feature description (#PR)

### Changed
- What was modified (#PR)

### Deprecated
- What's being phased out (#PR)

### Removed
- What was removed (#PR)

### Fixed
- Bug fix description (#PR)

### Security
- Security fix description (CVE if applicable) (#PR)
```

**Writing good changelog entries:**
- Write for users, not developers
- Explain the impact, not the implementation
- Reference PR/issue numbers
- Mark breaking changes prominently

### Migration Guide

```markdown
# Migration Guide: v[X] to v[Y]

## Overview
[Brief summary of what changed and why]

## Breaking Changes

### [Change 1]

**Before (v[X]):**
```code
// Old way
oldFunction(param)
```

**After (v[Y]):**
```code
// New way  
newFunction(param, options)
```

**Steps to migrate:**
1. Find all calls to `oldFunction`
2. Replace with `newFunction`
3. Add required `options` parameter

### [Change 2]
...

## Deprecations

| Deprecated | Replacement | Removal Version |
|------------|-------------|-----------------|
| `oldFunc()` | `newFunc()` | v3.0.0 |

## Behavioural Changes

Changes that don't require code updates but affect runtime:

| Behaviour | Before | After |
|----------|--------|-------|
| Default timeout | 30s | 60s |
```

### API Documentation

```markdown
# [Endpoint Name]

## [METHOD] /path/to/endpoint

[What this endpoint does]

### Authentication
[Required auth, scopes]

### Request

**Headers:**
| Header | Required | Description |
|--------|----------|-------------|
| Authorization | Yes | Bearer token |

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| id | string | Yes | Resource identifier |

**Body:**
```json
{
  "field": "value"
}
```

### Response

**Success (200):**
```json
{
  "id": "123",
  "data": {}
}
```

**Errors:**
| Code | Description |
|------|-------------|
| 400 | Invalid request |
| 401 | Unauthorised |
| 404 | Not found |

### Example

```bash
curl -X POST https://api.example.com/endpoint \
  -H "Authorization: Bearer token" \
  -d '{"field": "value"}'
```
```

## Documentation Workflow

### After Feature Implementation

1. **Determine documentation needs**
   - Did behaviour change? → Changelog
   - Did API change? → API docs + Changelog
   - Was architecture decision made? → ADR
   - Is it breaking? → Migration guide

2. **Create documentation**
   - Use templates above
   - Include code examples
   - Cross-reference related docs

3. **Validate completeness**
   - [ ] All public APIs documented
   - [ ] Changelog entry exists
   - [ ] ADR created (if architectural)
   - [ ] Migration guide (if breaking)
   - [ ] Examples are runnable
   - [ ] Cross-references accurate

## Code Example Requirements

All documentation code examples must be:

### Complete
Include all imports and setup:

```javascript
// ❌ Bad - missing imports
const result = await client.fetch('data');

// ✅ Good - complete
import { Client } from '@company/sdk';

const client = new Client({ apiKey: process.env.API_KEY });
const result = await client.fetch('data');
```

### Runnable
Copy-paste should work:

```javascript
// ❌ Bad - placeholder values
const config = { key: 'YOUR_KEY_HERE' };

// ✅ Good - uses environment
const config = { key: process.env.API_KEY };
```

### Error-Handled
Show proper error handling:

```javascript
// ❌ Bad - no error handling
const data = await api.getData();
console.log(data);

// ✅ Good - handles errors
try {
  const data = await api.getData();
  console.log(data);
} catch (error) {
  console.error('Failed to fetch:', error.message);
  process.exit(1);
}
```

## File Organisation

```
docs/
├── adr/
│   ├── README.md           # Index of all ADRs
│   ├── ADR-001-*.md
│   └── ADR-002-*.md
├── api/
│   ├── README.md           # API overview
│   └── endpoints/
│       └── [endpoint].md
├── guides/
│   ├── getting-started.md
│   └── migration/
│       └── v1-to-v2.md
└── CHANGELOG.md
```

## Integration

### With Human Approval

When architectural decisions are approved via Human Approval skill:
- Automatically prompt for ADR creation
- Pre-fill ADR with decision context
- Link ADR to approval log

### With Security Gate

Before deployment:
- Verify changelog exists for changes
- Check API docs updated if endpoints changed
- Ensure migration guide for breaking changes

## Common Issues

### "Documentation is out of sync"

**Solution:**
- Run doc validation in CI
- Generate docs from code where possible
- Regular documentation audits

### "Missing cross-references"

**Solution:**
- Use consistent linking format
- Validate links in CI
- Maintain index files

