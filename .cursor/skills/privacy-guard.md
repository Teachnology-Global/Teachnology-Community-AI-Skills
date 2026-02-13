---
description: >
  Enforces GDPR, CCPA, and privacy-by-design compliance. Scans for PII handling,
  validates encryption and consent mechanisms, and triggers privacy impact assessments.
  Use when: (1) implementing features that handle personal data, (2) reviewing data
  handling for compliance, (3) validating consent mechanisms, (4) checking data
  retention, (5) ensuring right-to-deletion implementation.
globs: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "**/*.py", "**/*.java", "**/*.cs"]
alwaysApply: false
---

# Privacy Guard

## Purpose

Ensure all code handling personal data complies with GDPR, CCPA, and privacy-by-design principles.

## Activation

This skill activates when you mention:
- "privacy", "GDPR", "CCPA"
- "personal data", "PII"
- "consent", "data protection"
- "right to delete", "data erasure"
- "privacy compliance", "data handling"

Also activates when detecting:
- Database models with user data
- Forms collecting personal information
- API endpoints returning user data
- Logging statements with potential PII

## Personal Data Categories

### Identification Data

| Category | Sensitivity | Examples |
|----------|-------------|----------|
| Direct Identifiers | Critical | SSN, passport, driver's license |
| Contact Info | High | Email, phone, address |
| Financial | Critical | Credit card, bank account, income |
| Biometric | Critical | Fingerprint, facial, voice |
| Health | Critical | Medical records, conditions |
| Location | High | GPS, IP address, check-ins |
| Behavioral | Medium | Browsing history, preferences |

### Detection Patterns

Look for these patterns in code:

**Field Names:**
```
email, phone, address, ssn, dob, birth_date, 
credit_card, card_number, first_name, last_name,
social_security, passport, ip_address, location
```

**Data Patterns:**
```
Email: [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
Phone: [\+]?[(]?[0-9]{1,3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}
SSN: \b\d{3}[-]?\d{2}[-]?\d{4}\b
Credit Card: \b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b
```

## Compliance Checklist

### GDPR Requirements

#### Data Processing Principles (Article 5)

- [ ] **Lawfulness**: Valid legal basis for processing
- [ ] **Fairness**: Transparent about data use
- [ ] **Purpose Limitation**: Process only for stated purposes
- [ ] **Data Minimization**: Collect only necessary data
- [ ] **Accuracy**: Keep data accurate and updated
- [ ] **Storage Limitation**: Retain only as long as necessary
- [ ] **Security**: Appropriate protection measures
- [ ] **Accountability**: Can demonstrate compliance

#### Privacy by Design (Article 25)

- [ ] Data minimization by default
- [ ] Pseudonymization where possible
- [ ] Encryption at rest and in transit
- [ ] Least privilege access
- [ ] Audit trails for data access

#### Right to Erasure (Article 17)

- [ ] Deletion API endpoint exists
- [ ] All data sources covered (DB, cache, backups)
- [ ] Third-party deletion propagation
- [ ] Response within 30 days
- [ ] Audit log of deletion requests

### CCPA Requirements

- [ ] **Right to Know**: Can disclose what data is collected
- [ ] **Right to Delete**: Can delete data on request
- [ ] **Right to Opt-Out**: "Do Not Sell" mechanism
- [ ] **Non-Discrimination**: No penalty for exercising rights

## Code Review Patterns

### ✅ Good Patterns

```python
# Encrypted storage
user.email = encrypt(email, key=get_encryption_key())

# Consent check before processing
if not user.has_consented('marketing'):
    raise ConsentRequired('Marketing consent needed')

# Data minimization - only return needed fields
def get_user_profile(user_id):
    return {
        'display_name': user.display_name,
        'avatar': user.avatar_url,
        # Don't return: email, phone, address
    }

# Complete deletion
async def delete_user_data(user_id):
    await db.users.delete(user_id)
    await cache.invalidate(f"user:{user_id}")
    await analytics.anonymize(user_id)
    await notify_third_parties(user_id, 'deletion')
```

### ❌ Bad Patterns

```python
# PII in logs
logger.info(f"Processing user {user.email}")  # VIOLATION

# Unencrypted sensitive data
user.ssn = request.form['ssn']  # VIOLATION

# Missing consent check
send_marketing_email(user.email)  # VIOLATION

# Incomplete deletion
def delete_user(user_id):
    db.users.delete(user_id)  # Missing: cache, backups, third parties
```

## Privacy Impact Assessment

### When Required

Conduct PIA when:
- New processing of personal data
- Significant changes to existing processing
- New third-party data sharing
- Cross-border data transfer
- Large-scale processing
- Automated decision-making

### PIA Workflow

1. **Scope**: Identify data processing activities
2. **Inventory**: Catalog personal data types
3. **Purpose**: Document processing purposes
4. **Legal Basis**: Identify legal justification
5. **Risk Assessment**: Evaluate privacy risks
6. **Mitigation**: Propose risk controls
7. **Review**: Flag for DPO consultation
8. **Document**: Generate PIA report

## Privacy Report Format

```markdown
## Privacy Compliance Report

**Date**: [timestamp]
**Scope**: [files/components scanned]

### Summary
| Category | Count | Severity |
|----------|-------|----------|
| PII Fields Found | X | - |
| Unencrypted PII | X | Critical |
| PII in Logs | X | High |
| Missing Consent | X | High |
| Incomplete Deletion | X | Medium |

### Critical Findings

#### [Finding ID]: [Title]
- **File**: path/to/file:line
- **Issue**: [description]
- **Data Type**: [what PII is affected]
- **GDPR Article**: [if applicable]
- **Recommendation**: [how to fix]

### Action Required
- [ ] Fix critical findings before deployment
- [ ] Schedule DPO review for high findings
- [ ] Document risk acceptance for medium/low
```

## Human Approval Triggers

This skill triggers Human Approval for:

| Trigger | Reason |
|---------|--------|
| New PII collection | Must justify necessity |
| Third-party sharing | Requires data agreement |
| Cross-border transfer | Needs legal review |
| Purpose change | May need new consent |
| Automated decisions | Affects individuals |
| Sensitive data | Health, biometric, financial |

## Integration

### With Security Gate

- Privacy findings included in security report
- Unencrypted PII blocks deployment
- PII in logs blocks deployment

### With Human Approval

- New PII fields require approval
- Data sharing decisions logged
- Privacy exceptions documented

### With Documentation

- Privacy decisions captured in ADRs
- Data handling documented in API docs
- Privacy policy changes in changelog

