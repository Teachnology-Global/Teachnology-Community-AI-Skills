---
description: >
  Enforces human approval for decisions that deviate from PRD or exceed documented 
  specifications. Automatically pauses execution and presents structured options with
  tradeoffs. Use when: (1) implementation deviates from requirements, (2) architecture 
  affects multiple components, (3) security-sensitive changes, (4) breaking API changes,
  (5) adding external dependencies, (6) privacy-impacting code changes.
globs: ["**/*"]
alwaysApply: true
---

# Human Approval

## Purpose

AI must pause and request human input for decisions that:
- Deviate from documented requirements (PRD)
- Have architectural implications
- Affect security or privacy
- Cannot be easily reversed

## Activation

This skill is **always active**. It triggers automatically when detecting:

### Automatic Triggers

| Category | Examples |
|----------|----------|
| **PRD Deviation** | Feature scope expansion, contradicting requirements |
| **Architecture** | New components, schema changes, API modifications |
| **Security** | Auth changes, encryption, access control |
| **Breaking Changes** | API contracts, data models, configs |
| **Dependencies** | New third-party libraries, external APIs |
| **Performance** | Algorithm changes, caching strategies |
| **Privacy** | PII handling, consent, data retention |

### Manual Triggers

User can explicitly request:
- "Let me decide"
- "I need to approve this"
- "Show me options"
- "What are the tradeoffs?"
- "Pause for my input"

## Approval Request Format

When triggered, present this structure:

```markdown
## 🛑 Human Approval Required

### Category
[PRD Deviation | Architecture | Security | Breaking Change | Dependencies | Performance | Privacy]

### Context

**Location**: [file/component affected]

**What Triggered This**:
[Clear explanation of what was detected]

**PRD Reference** (if applicable):
> [Quote the relevant requirement]

### Why Human Input Needed

[Explain why AI cannot make this decision autonomously]

### Options

#### Option 1: [Name] ✅ Recommended
[Description of this approach]

**Pros:**
- [Benefit 1]
- [Benefit 2]

**Cons:**
- [Drawback 1]

**Effort**: [Low | Medium | High]
**Risk**: [Low | Medium | High]

---

#### Option 2: [Name]
[Description of this approach]

**Pros:**
- [Benefit 1]

**Cons:**
- [Drawback 1]
- [Drawback 2]

**Effort**: [Low | Medium | High]
**Risk**: [Low | Medium | High]

---

#### Option 3: Custom
Provide your own direction.

### Your Decision

Please respond with:
1. **Choice**: Option number or custom instructions
2. **Additional context**: Any constraints or requirements
3. **Documentation**: ADR needed? Changelog entry?

---
⏱️ **Waiting for your input before proceeding**
```

## Decision Categories

### PRD Deviation

**When**: Implementation approach differs from documented requirements

**Required in request**:
- Exact PRD quote
- How current approach differs
- Impact on scope/timeline

**Outcomes**:
- Proceed as PRD specifies
- Update PRD (requires stakeholder approval)
- Document exception

### Architecture

**When**: Changes affect system structure

**Required in request**:
- Components affected
- Reversibility assessment  
- Technical debt implications

**Outcomes**:
- Proceed with ADR documentation
- Defer pending research
- Escalate to tech lead

### Security

**When**: Authentication, encryption, or access control changes

**Required in request**:
- Security implications
- Attack surface changes
- Mitigation measures

**Outcomes**:
- Approve with controls
- Require security review
- Block until assessment

**Note**: Security decisions always require explicit approval. No defaults.

### Breaking Changes

**When**: API contracts, data models, or configs change incompatibly

**Required in request**:
- Affected consumers
- Migration path
- Communication plan

**Outcomes**:
- Approve with migration guide
- Defer to next major version
- Find non-breaking alternative

### Dependencies

**When**: Adding external libraries or services

**Required in request**:
- License compatibility
- Security track record
- Maintenance status
- Alternatives considered

**Outcomes**:
- Approve dependency
- Select alternative
- Build in-house

### Privacy

**When**: Changes to personal data handling

**Required in request**:
- Data types affected
- Legal implications
- Consent requirements

**Outcomes**:
- Approve with privacy controls
- Require legal review
- Block until DPIA complete

## Decision Logging

Every decision must be logged:

```markdown
## Decision Log Entry

**ID**: HITL-[YYYY-MM-DD]-[NNN]
**Date**: [timestamp]
**Category**: [category]
**Approver**: [name]

### Trigger
[What triggered the pause]

### Decision
**Selected**: [Option chosen]
**Rationale**: [Why this option]

### Follow-up
- [ ] ADR created: [Yes/No]
- [ ] Changelog entry: [Yes/No]  
- [ ] Stakeholders notified: [Yes/No]
```

## Best Practices

### Do

- Present clear, actionable options (2-3 max)
- Include a recommendation with reasoning
- Show tradeoffs honestly
- Document every decision
- Include "escape hatch" for custom approach

### Don't

- Make assumptions about human preference
- Skip logging for "obvious" decisions
- Proceed without explicit approval for security
- Present more than 3 detailed options
- Rush the human - allow time to think

## Integration with Other Skills

| Trigger | Related Skill | Action |
|---------|---------------|--------|
| Security decision made | Security Gate | Inform production readiness |
| Architecture decision | Documentation | Create ADR |
| Privacy decision | Privacy Guard | Run compliance check |
| Dependency approved | Security Gate | Add to scan scope |

## Timeout Behaviour

- **No automatic timeout for security decisions**
- For non-security: Remind after 24 hours of inactivity
- Never auto-approve based on timeout

## Quick Reference

| Situation | Action |
|-----------|--------|
| PRD says X, I want to do Y | **PAUSE** |
| Adding new dependency | **PAUSE** |
| Changing database schema | **PAUSE** |
| Changing API contract | **PAUSE** |
| Touching auth/security code | **PAUSE** |
| Handling PII differently | **PAUSE** |
| Performance-critical change | **PAUSE** |
| Internal refactor, same API | Log and continue |
| Bug fix with clear solution | Log and continue |
| Style/formatting changes | Continue |

