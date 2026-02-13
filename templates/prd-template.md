# Product Requirements Document (PRD)

## Document Information

| Field | Value |
|-------|-------|
| **PRD ID** | PRD-YYYY-NNN |
| **Title** | [Feature/Product Name] |
| **Author** | [Name] |
| **Created** | YYYY-MM-DD |
| **Last Updated** | YYYY-MM-DD |
| **Status** | [Draft | Review | Approved | In Development | Released] |
| **Version** | 1.0 |

---

## 1. Overview

### 1.1 Summary
[One paragraph description of what this feature/product does and why it matters]

### 1.2 Problem Statement
[What problem does this solve? Who has this problem? How are they solving it today?]

### 1.3 Goals
| Goal | Metric | Target |
|------|--------|--------|
| [e.g., Reduce checkout time] | [e.g., Average checkout duration] | [e.g., < 30 seconds] |
| | | |

### 1.4 Non-Goals
[What is explicitly NOT in scope for this PRD]

- ❌ [Non-goal 1]
- ❌ [Non-goal 2]

---

## 2. Background

### 2.1 Context
[Relevant background information, history, previous attempts]

### 2.2 User Research
[Summary of user research, interviews, surveys, data]

### 2.3 Competitive Analysis
| Competitor | How they solve it | Gaps |
|------------|-------------------|------|
| | | |

---

## 3. Requirements

### 3.1 User Stories

#### US-001: [Story Title]
**As a** [user type]  
**I want** [capability]  
**So that** [benefit]

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

**Priority:** [Must Have | Should Have | Could Have | Won't Have]

---

#### US-002: [Story Title]
**As a** [user type]  
**I want** [capability]  
**So that** [benefit]

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]

**Priority:** [Must Have | Should Have | Could Have | Won't Have]

---

### 3.2 Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-001 | [The system shall...] | Must Have | |
| FR-002 | [The system shall...] | Should Have | |
| FR-003 | [The system shall...] | Could Have | |

### 3.3 Non-Functional Requirements

| Category | Requirement | Target |
|----------|-------------|--------|
| **Performance** | Page load time | < 2 seconds |
| **Performance** | API response time | < 200ms p95 |
| **Availability** | Uptime | 99.9% |
| **Scalability** | Concurrent users | 10,000 |
| **Security** | [Requirement] | [Target] |
| **Accessibility** | WCAG compliance | Level AA |
| **Privacy** | Data regulations | GDPR, CCPA |

---

## 4. User Experience

### 4.1 User Flow
```
[Start] → [Step 1] → [Decision Point] → [Step 2] → [End]
                         ↓
                    [Alternative Path]
```

### 4.2 Wireframes/Mockups
[Link to Figma/design files or embed images]

### 4.3 Key Screens

#### Screen: [Name]
- **Purpose**: [What this screen does]
- **Entry Points**: [How users get here]
- **Key Elements**: [Main UI components]
- **Exit Points**: [Where users go next]

---

## 5. Technical Considerations

### 5.1 Architecture
[High-level architecture description or diagram]

### 5.2 Dependencies
| Dependency | Type | Status |
|------------|------|--------|
| [Service/API] | Internal | Available |
| [Library] | External | To evaluate |

### 5.3 Data Requirements
| Data Entity | Source | Storage | Retention |
|-------------|--------|---------|-----------|
| | | | |

### 5.4 API Changes
| Endpoint | Method | Change Type | Description |
|----------|--------|-------------|-------------|
| | | New/Modified/Deprecated | |

### 5.5 Security Considerations
- [ ] Authentication required
- [ ] Authorization/permissions
- [ ] Data encryption
- [ ] Input validation
- [ ] Rate limiting
- [ ] Audit logging

### 5.6 Privacy Considerations
- [ ] PII involved: [List fields]
- [ ] Consent required: [Yes/No]
- [ ] PIA required: [Yes/No - Link if yes]

---

## 6. Release Plan

### 6.1 Phases

| Phase | Scope | Target Date |
|-------|-------|-------------|
| Alpha | [Limited features] | YYYY-MM-DD |
| Beta | [Expanded features] | YYYY-MM-DD |
| GA | [Full release] | YYYY-MM-DD |

### 6.2 Feature Flags
| Flag | Purpose | Default |
|------|---------|---------|
| | | |

### 6.3 Rollout Strategy
- [ ] Percentage rollout: ___% → ___% → 100%
- [ ] Geographic rollout: [Region 1] → [Region 2]
- [ ] User segment rollout: [Segment]

### 6.4 Rollback Plan
[How to revert if issues arise]

---

## 7. Success Metrics

### 7.1 Key Performance Indicators (KPIs)

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| [e.g., Conversion rate] | 2% | 5% | [How measured] |
| | | | |

### 7.2 Monitoring
| Metric | Alert Threshold | Dashboard |
|--------|-----------------|-----------|
| | | |

---

## 8. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | [H/M/L] | [H/M/L] | [How to mitigate] |
| | | | |

---

## 9. Open Questions

| # | Question | Owner | Due Date | Resolution |
|---|----------|-------|----------|------------|
| 1 | [Question] | [Name] | [Date] | [Answer when resolved] |

---

## 10. Appendix

### 10.1 Glossary
| Term | Definition |
|------|------------|
| | |

### 10.2 References
- [Link to related documents]
- [Link to research]
- [Link to designs]

### 10.3 Change Log
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | YYYY-MM-DD | [Name] | Initial version |

---

## Approvals

| Role | Name | Approved | Date |
|------|------|----------|------|
| Product Manager | | [ ] | |
| Engineering Lead | | [ ] | |
| Design Lead | | [ ] | |
| QA Lead | | [ ] | |
| Security | | [ ] | |
| Legal/Privacy | | [ ] | |

---

*Template from Cursor Governance Framework*

---

## Governance Notes

> **Human-in-the-Loop Triggers**: Any implementation that deviates from the requirements 
> documented in this PRD must trigger a Human Approval request. The AI assistant should:
> 1. Quote the specific PRD requirement
> 2. Explain how the proposed approach differs
> 3. Present options with tradeoffs
> 4. Wait for explicit approval before proceeding

> **Documentation Requirements**: Upon completion, ensure:
> - [ ] CHANGELOG.md updated
> - [ ] ADR created for architecture decisions
> - [ ] API documentation updated (if applicable)
> - [ ] Migration guide created (if breaking changes)

