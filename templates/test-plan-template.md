# Test Plan: [Feature/Project Name]

## Metadata

| Field | Value |
|-------|-------|
| **Plan ID** | TP-YYYY-MM-DD-NNN |
| **PRD Reference** | [Link to PRD] |
| **Version** | 1.0 |
| **Created** | YYYY-MM-DD |
| **Last Updated** | YYYY-MM-DD |
| **Author** | [Name] |
| **Status** | [Draft | Active | Complete | Archived] |

---

## 1. Overview

### 1.1 Purpose
[Brief description of what this test plan covers]

### 1.2 Scope

**In Scope:**
- [Feature 1]
- [Feature 2]

**Out of Scope:**
- [Excluded item 1]
- [Excluded item 2]

### 1.3 Test Objectives
- [ ] Verify all functional requirements
- [ ] Validate non-functional requirements (performance, security)
- [ ] Ensure accessibility compliance (WCAG 2.1 AA)
- [ ] Confirm privacy requirements met

---

## 2. Requirements Traceability

### 2.1 User Stories

| Req ID | Requirement | Priority | Test Cases | Status |
|--------|-------------|----------|------------|--------|
| US-001 | [User story description] | Critical | TC-001, TC-002 | 🟢 Covered |
| US-002 | [User story description] | High | TC-003 | 🟢 Covered |
| US-003 | [User story description] | Medium | - | 🔴 Not Covered |

### 2.2 Functional Requirements

| Req ID | Requirement | Test Cases | Status |
|--------|-------------|------------|--------|
| FR-001 | [Functional requirement] | TC-004 | 🟢 |
| FR-002 | [Functional requirement] | TC-005, TC-006 | 🟢 |

### 2.3 Non-Functional Requirements

| Req ID | Requirement | Metric | Target | Test Case |
|--------|-------------|--------|--------|-----------|
| NFR-001 | Page load time | LCP | < 2.5s | TC-050 |
| NFR-002 | API response time | p95 | < 200ms | TC-051 |
| NFR-003 | Uptime | Availability | 99.9% | Monitoring |

---

## 3. Test Cases

### 3.1 Functional Tests

#### TC-001: [Test Case Name]

| Field | Value |
|-------|-------|
| **Requirement** | US-001 |
| **Priority** | Critical |
| **Type** | Functional |
| **Automation** | [Automated | Manual | Planned] |

**Preconditions:**
- [Precondition 1]
- [Precondition 2]

**Test Steps:**

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | [Action] | [Expected result] |
| 2 | [Action] | [Expected result] |
| 3 | [Action] | [Expected result] |

**Postconditions:**
- [State after test]

**Test Data:**
```json
{
  "input": "value",
  "expected": "result"
}
```

**Browser Test Reference:** `tests/e2e/feature.spec.ts:L12`

**Screenshots Required:**
- [ ] Initial state
- [ ] After action
- [ ] Final state

---

#### TC-002: [Test Case Name]

[Repeat format for each test case]

---

### 3.2 Negative Tests

#### TC-010: [Invalid Input Test]

| Field | Value |
|-------|-------|
| **Requirement** | FR-001 |
| **Priority** | High |
| **Type** | Negative |

**Test Steps:**

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter invalid data | Error message displayed |
| 2 | Verify error is accessible | Error announced to screen reader |

---

### 3.3 Edge Cases

#### TC-020: [Boundary Test]

| Field | Value |
|-------|-------|
| **Requirement** | FR-002 |
| **Priority** | Medium |
| **Type** | Edge Case |

**Test Steps:**

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Test minimum value | Accepted |
| 2 | Test maximum value | Accepted |
| 3 | Test beyond maximum | Rejected with error |

---

### 3.4 Accessibility Tests

#### TC-030: [Keyboard Navigation]

| Field | Value |
|-------|-------|
| **WCAG Criterion** | 2.1.1 Keyboard |
| **Level** | A |
| **Priority** | Critical |

**Test Steps:**

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tab through all interactive elements | All elements focusable |
| 2 | Activate buttons with Enter/Space | Buttons activate |
| 3 | Navigate dropdowns with arrows | Options selectable |

---

### 3.5 Security Tests

#### TC-040: [Input Validation]

| Field | Value |
|-------|-------|
| **Security Concern** | XSS Prevention |
| **OWASP** | A7:2017 |
| **Priority** | Critical |

**Test Steps:**

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter `<script>alert('xss')</script>` | Input sanitized |
| 2 | Verify no script execution | No alert shown |

---

## 4. Test Environments

| Environment | URL | Database | Purpose |
|-------------|-----|----------|---------|
| Local | localhost:3000 | Local/Neon Dev | Development testing |
| Preview | pr-123.vercel.app | Neon Branch | PR validation |
| Staging | staging.example.com | Neon Staging | Pre-production |
| Production | example.com | Neon Prod | Smoke tests only |

---

## 5. Test Data

### 5.1 Test Users

| User | Email | Password | Role | Purpose |
|------|-------|----------|------|---------|
| Admin | admin@test.com | TestAdmin123! | admin | Admin flows |
| User | user@test.com | TestUser123! | user | Standard flows |
| New User | - | - | - | Signup tests |

### 5.2 Test Data Sets

| Data Set | Location | Purpose |
|----------|----------|---------|
| Seed data | `tests/fixtures/seed.sql` | Database setup |
| Mock API | `tests/mocks/api.json` | API mocking |
| Test images | `tests/fixtures/images/` | Upload tests |

---

## 6. Execution Schedule

| Test Suite | Trigger | Environment | Duration |
|------------|---------|-------------|----------|
| Unit Tests | Every commit | Local | ~2 min |
| Integration | Every PR | Preview | ~5 min |
| E2E Critical | Merge to main | Staging | ~10 min |
| E2E Full | Nightly | Staging | ~30 min |
| Smoke | Post-deploy | Production | ~5 min |

---

## 7. Entry/Exit Criteria

### 7.1 Entry Criteria

- [ ] Code complete and merged to feature branch
- [ ] Build passing
- [ ] Test environment available
- [ ] Test data prepared

### 7.2 Exit Criteria

- [ ] All critical test cases executed
- [ ] No critical or high severity bugs open
- [ ] Test coverage ≥ 80%
- [ ] All automated tests passing
- [ ] Accessibility audit passed

---

## 8. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Test environment unavailable | Medium | High | Use local fallback |
| Test data corruption | Low | High | Reset before each run |
| Flaky tests | Medium | Medium | Add retries, investigate |

---

## 9. Defect Management

### Severity Definitions

| Severity | Definition | Example |
|----------|------------|---------|
| Critical | System unusable | Crash, data loss |
| High | Major feature broken | Cannot complete core flow |
| Medium | Feature impaired | Workaround available |
| Low | Minor issue | Cosmetic, typo |

### Defect Workflow

```
Found → Logged → Triaged → In Progress → Fixed → Verified → Closed
```

---

## 10. Sign-off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| QA Lead | | | |
| Dev Lead | | | |
| Product Owner | | | |

---

## Appendix

### A. Change History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | YYYY-MM-DD | [Name] | Initial version |

### B. References

- PRD: [Link]
- Design: [Link]
- API Docs: [Link]

---

*Template from Cursor Governance Framework*

