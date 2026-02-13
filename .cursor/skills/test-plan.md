---
description: >
  Generates and maintains comprehensive test plans derived from PRDs. Automatically
  updates when features change. Creates traceable test cases linked to requirements.
  Use when: (1) starting a new feature, (2) PRD is created or updated, (3) planning
  QA coverage, (4) reviewing test completeness, (5) human-in-the-loop adds features.
globs: ["**/prd*.md", "**/PRD*.md", "**/requirements*.md", "**/test-plan*.md"]
alwaysApply: false
---

# Test Plan Management

## Purpose

Automatically generate and maintain test plans that trace directly to PRD requirements. Ensures every requirement has test coverage and test plans stay synchronized as features evolve.

## Activation

This skill activates when you mention:
- "test plan", "testing strategy"
- "QA coverage", "test cases"
- "requirements coverage", "traceability"
- "what should we test", "how to test"

Also activates when:
- A PRD is created or modified
- Human-in-the-loop approves new features
- Features are marked complete
- You ask about test coverage

## Test Plan Structure

### Master Test Plan Template

```markdown
# Test Plan: [Feature/Project Name]

## Metadata
| Field | Value |
|-------|-------|
| **Plan ID** | TP-YYYY-MM-DD-NNN |
| **PRD Reference** | [Link to PRD] |
| **Version** | 1.0 |
| **Last Updated** | YYYY-MM-DD |
| **Status** | [Draft | Active | Complete] |

## Requirements Traceability Matrix

| Req ID | Requirement | Test Cases | Coverage |
|--------|-------------|------------|----------|
| US-001 | User can sign up | TC-001, TC-002, TC-003 | ✅ Full |
| US-002 | User can log in | TC-004, TC-005 | ✅ Full |
| FR-001 | Password must be 8+ chars | TC-006 | ✅ Full |
| NFR-001 | Page loads < 2s | TC-007 | ⚠️ Partial |

## Test Cases

### TC-001: Successful user signup
**Requirement**: US-001
**Priority**: Critical
**Type**: Functional | E2E

**Preconditions**:
- User is not logged in
- Email not already registered

**Steps**:
1. Navigate to /signup
2. Enter valid email
3. Enter valid password (8+ chars)
4. Click "Sign Up"

**Expected Result**:
- Account created
- Confirmation email sent
- Redirected to dashboard

**Automation Status**: [ ] Manual | [x] Automated
**Browser Test ID**: BT-001

---

### TC-002: Signup with existing email
...

## Test Environments

| Environment | URL | Database | Purpose |
|-------------|-----|----------|---------|
| Local | localhost:3000 | Local Neon branch | Development |
| Preview | preview.vercel.app | Preview Neon branch | PR testing |
| Staging | staging.example.com | Staging DB | Pre-production |
| Production | example.com | Production DB | Smoke tests only |

## Execution Schedule

| Test Suite | Trigger | Environment |
|------------|---------|-------------|
| Unit Tests | Every commit | Local |
| Integration | Every PR | Preview |
| E2E Critical Path | Every merge to main | Staging |
| Full E2E | Nightly | Staging |
| Smoke Tests | Post-deploy | Production |
```

## Workflow: PRD to Test Plan

### Step 1: Extract Requirements

When a PRD is provided, extract:

```markdown
## Extracted Requirements

### User Stories
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-001 | As a user, I want to sign up | Email validated, password 8+ chars |

### Functional Requirements
| ID | Requirement | Testable |
|----|-------------|----------|
| FR-001 | Password minimum 8 characters | ✅ Yes |
| FR-002 | Email must be unique | ✅ Yes |

### Non-Functional Requirements
| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-001 | Page load time | LCP | < 2.5s |
| NFR-002 | Uptime | Availability | 99.9% |
```

### Step 2: Generate Test Cases

For each requirement, generate test cases:

```markdown
## Generated Test Cases for US-001 (User Signup)

### Positive Cases
- TC-001: Valid signup with email and password
- TC-002: Signup with minimum password length (8 chars)
- TC-003: Signup with maximum length inputs

### Negative Cases
- TC-004: Signup with invalid email format
- TC-005: Signup with password < 8 chars
- TC-006: Signup with existing email
- TC-007: Signup with empty fields

### Edge Cases
- TC-008: Signup with special characters in password
- TC-009: Signup with Unicode email
- TC-010: Signup with SQL injection attempt
- TC-011: Signup with XSS payload

### Accessibility Cases
- TC-012: Signup form keyboard navigable
- TC-013: Error messages announced to screen reader
- TC-014: Form labels properly associated
```

### Step 3: Link to Browser Tests

Each test case should reference browser automation:

```markdown
### TC-001: Valid signup with email and password

**Browser Test Reference**: `tests/e2e/signup.spec.ts:12`

**Browser Test Steps**:
1. `browser_navigate` → /signup
2. `browser_snapshot` → Capture initial state
3. `browser_type` → Enter email in #email field
4. `browser_type` → Enter password in #password field
5. `browser_click` → Click submit button
6. `browser_wait_for` → "Welcome" text appears
7. `browser_snapshot` → Capture success state

**Screenshots**:
- [ ] Initial form state
- [ ] Filled form before submit
- [ ] Success confirmation
```

## Keeping Test Plans Updated

### When PRD Changes

```markdown
## Test Plan Update Required

**Trigger**: PRD US-003 added (Password reset feature)

### New Test Cases Needed

| Test Case | Requirement | Priority |
|-----------|-------------|----------|
| TC-020 | Request password reset | Critical |
| TC-021 | Reset with valid token | Critical |
| TC-022 | Reset with expired token | High |
| TC-023 | Reset with invalid token | High |

### Updated Traceability Matrix

| Req ID | Requirement | Test Cases | Coverage |
|--------|-------------|------------|----------|
| US-003 | Password reset | TC-020 to TC-023 | 🆕 New |

---
⚠️ **Action Required**: Generate browser tests for new cases
```

### When Human-in-the-Loop Adds Features

The skill listens for HITL decisions and updates automatically:

```markdown
## HITL Feature Addition Detected

**Decision ID**: HITL-2024-01-15-001
**Feature**: "Remember me" checkbox on login

### Test Plan Impact

**New Requirements**:
- FR-010: "Remember me" extends session to 30 days
- FR-011: Default is unchecked (privacy-first)

**New Test Cases**:
- TC-030: Login with "remember me" checked
- TC-031: Login with "remember me" unchecked
- TC-032: Session persists after browser restart (checked)
- TC-033: Session expires on browser close (unchecked)

**Browser Tests to Generate**:
- [ ] tests/e2e/login-remember-me.spec.ts
```

## Test Coverage Report

```markdown
## Test Coverage Summary

**Date**: YYYY-MM-DD
**PRD Version**: 1.3
**Test Plan Version**: 1.3

### Coverage by Requirement Type

| Type | Total | Covered | Coverage |
|------|-------|---------|----------|
| User Stories | 12 | 12 | 100% |
| Functional | 25 | 23 | 92% |
| Non-Functional | 8 | 5 | 63% |
| **Total** | **45** | **40** | **89%** |

### Uncovered Requirements

| Req ID | Requirement | Reason | Action |
|--------|-------------|--------|--------|
| NFR-003 | Support 10k concurrent users | No load test env | Planned Q2 |
| FR-024 | Export to PDF | Feature not complete | Blocked |

### Test Execution Status

| Suite | Total | Pass | Fail | Skip |
|-------|-------|------|------|------|
| Unit | 234 | 230 | 2 | 2 |
| Integration | 45 | 43 | 1 | 1 |
| E2E | 28 | 26 | 2 | 0 |
| **Total** | **307** | **299** | **5** | **3** |

### Browser Test Automation

| Status | Count | Percentage |
|--------|-------|------------|
| Automated | 24 | 86% |
| Manual | 4 | 14% |
| **Total** | **28** | 100% |
```

## Integration with Other Skills

### With Human Approval

When HITL adds a feature:
1. Detect the new requirement
2. Generate test cases automatically
3. Update traceability matrix
4. Queue browser tests for creation

### With Documentation

- Test plans stored in `docs/test-plans/`
- Linked from PRD and ADRs
- Changelog updated when test plan changes

### With Browser Testing

- Test cases reference browser test IDs
- Browser tests execute against test plan
- Results feed back to coverage report

### With Pre-Release

Before release:
- All critical test cases must pass
- Coverage must meet threshold
- No untested requirements in release scope

## Commands

| Command | Action |
|---------|--------|
| "Generate test plan from PRD" | Create full test plan |
| "Update test plan" | Sync with PRD changes |
| "Show test coverage" | Display coverage report |
| "What's not tested?" | List uncovered requirements |
| "Add test case for [feature]" | Create new test case |

