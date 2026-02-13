---
description: >
  Validates dependency licenses for compliance with project requirements. Prevents
  GPL contamination and ensures legal use of open source. Use when: (1) adding new
  dependencies, (2) auditing existing dependencies, (3) preparing for release,
  (4) reviewing license compatibility, (5) open source compliance checks.
globs: ["package.json", "package-lock.json", "requirements.txt", "Pipfile", "go.mod", "Cargo.toml", "pom.xml", "*.csproj"]
alwaysApply: false
---

# License Compliance

## Purpose

Ensure all dependencies have compatible licenses and prevent legal issues from GPL contamination or restricted licenses.

## Activation

This skill activates when you mention:
- "license", "licensing"
- "dependency", "dependencies"
- "npm install", "pip install", "go get"
- "open source", "OSS compliance"
- "GPL", "MIT", "Apache"

Also activates when:
- Adding new packages
- Running dependency audits
- Preparing releases
- Reviewing `package.json`, `requirements.txt`, etc.

## License Categories

### ✅ Permissive (Always Allowed)

| License | Notes |
|---------|-------|
| MIT | Most permissive, minimal requirements |
| Apache-2.0 | Permissive with patent grant |
| BSD-2-Clause | Simple permissive |
| BSD-3-Clause | Permissive with no-endorsement clause |
| ISC | Functionally equivalent to MIT |
| CC0-1.0 | Public domain dedication |
| Unlicense | Public domain equivalent |
| WTFPL | Do What The F*** You Want |
| 0BSD | Zero-clause BSD |

### ⚠️ Copyleft (Requires Review)

| License | Risk | Notes |
|---------|------|-------|
| LGPL-2.1 | Medium | OK if dynamically linked |
| LGPL-3.0 | Medium | OK if dynamically linked |
| MPL-2.0 | Low | File-level copyleft only |
| EPL-1.0 | Medium | Weak copyleft |
| EPL-2.0 | Medium | Weak copyleft with secondary license |

### ❌ Restricted (Require Approval or Forbidden)

| License | Risk | Notes |
|---------|------|-------|
| GPL-2.0 | High | Copyleft infects entire work |
| GPL-3.0 | High | Stronger copyleft |
| AGPL-3.0 | Critical | Network copyleft (SaaS trigger) |
| SSPL-1.0 | Critical | Service-level copyleft |
| BSL-1.1 | High | Business Source License |
| CC-BY-NC | Forbidden | Non-commercial restriction |
| Proprietary | Forbidden | Unless explicitly licensed |

## Compliance Workflow

### 1. Before Adding Dependency

```
1. Check license on npm/PyPI/crates.io
2. Verify against allowed list
3. If copyleft → requires review
4. If restricted → requires approval + legal review
5. Document decision
```

### 2. Scanning Tools

```bash
# JavaScript/TypeScript
npx license-checker --summary
npx license-checker --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC"

# Python
pip-licenses --format=markdown
pip-licenses --fail-on="GPL-3.0;AGPL-3.0"

# Go
go-licenses check ./...

# Rust
cargo deny check licenses

# Multi-language
fossa analyze
snyk test --license
```

### 3. CI Integration

```yaml
# GitHub Actions
license-check:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    
    - name: Check licenses
      run: |
        npx license-checker --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD;Unlicense"
        
    - name: Fail on GPL
      run: |
        npx license-checker --failOn "GPL-2.0;GPL-3.0;AGPL-3.0"
```

## Decision Tree

```
New Dependency?
    │
    ├─→ Check License
    │       │
    │       ├─→ Permissive (MIT, Apache, BSD)?
    │       │       └─→ ✅ APPROVE - Document and proceed
    │       │
    │       ├─→ Weak Copyleft (LGPL, MPL)?
    │       │       └─→ ⚠️ REVIEW
    │       │           ├─→ Dynamic linking only? → ✅ OK
    │       │           └─→ Static/bundled? → Needs legal review
    │       │
    │       ├─→ Strong Copyleft (GPL)?
    │       │       └─→ 🛑 STOP
    │       │           ├─→ Dev-only tool? → Maybe OK
    │       │           └─→ Runtime dependency? → Find alternative
    │       │
    │       └─→ AGPL/SSPL?
    │               └─→ ❌ REJECT - Find alternative
    │
    └─→ No License?
            └─→ ❌ REJECT - Cannot use legally
```

## License Compatibility Matrix

When combining licenses:

| Project License | Can Include |
|-----------------|-------------|
| MIT | MIT, BSD, ISC, Apache-2.0, Unlicense |
| Apache-2.0 | MIT, BSD, ISC, Apache-2.0, Unlicense |
| LGPL-3.0 | All permissive + LGPL (with dynamic linking) |
| GPL-3.0 | All permissive + LGPL + GPL-3.0 |
| Proprietary | Only permissive licenses |

## Common Scenarios

### Scenario 1: Adding Popular Package

```typescript
// Checking react (MIT) - ✅ Safe
npm install react

// Checking lodash (MIT) - ✅ Safe
npm install lodash

// Checking axios (MIT) - ✅ Safe
npm install axios
```

### Scenario 2: GPL Development Tool

```typescript
// Using GPL tool for development only
// eslint-plugin-example (GPL-3.0)

// ✅ OK if:
// - Only in devDependencies
// - Not bundled with production code
// - Not required at runtime
```

### Scenario 3: Finding Alternatives

```markdown
## GPL Dependency Replacement

**Problem**: Package `example-lib` is GPL-3.0

**Alternatives Evaluated**:
| Package | License | Features | Decision |
|---------|---------|----------|----------|
| alt-lib-1 | MIT | 90% feature parity | ✅ Selected |
| alt-lib-2 | Apache-2.0 | 100% feature parity | Backup option |
| Build in-house | N/A | Full control | If no alternatives |
```

## Documentation Requirements

### For Approved Dependencies

```markdown
## Dependency: [name]
- **Version**: x.y.z
- **License**: MIT
- **Purpose**: [why needed]
- **Reviewed**: [date]
- **Approved by**: [name]
```

### For Exception Requests

```markdown
## License Exception Request

**Package**: [name]
**License**: [license]
**Requested by**: [name]
**Date**: [date]

### Justification
[Why this specific package is necessary]

### Alternatives Considered
[What was evaluated and rejected]

### Risk Mitigation
[How copyleft risk is contained]

### Legal Review
- [ ] Legal team consulted
- [ ] Written approval obtained
- [ ] Compliance measures documented

### Approval
- [ ] Engineering Lead
- [ ] Legal Counsel
- [ ] CTO/VP Engineering
```

## License Report Format

```markdown
## License Compliance Report

**Project**: [name]
**Date**: [timestamp]
**Total Dependencies**: [count]

### Summary
| License | Count | Status |
|---------|-------|--------|
| MIT | 145 | ✅ Allowed |
| Apache-2.0 | 32 | ✅ Allowed |
| BSD-3-Clause | 12 | ✅ Allowed |
| ISC | 8 | ✅ Allowed |
| LGPL-3.0 | 2 | ⚠️ Review |
| Unknown | 1 | ❌ Action |

### Action Required

#### Unknown License
- **Package**: example-utils@1.2.3
- **Action**: Contact maintainer or find alternative

#### LGPL Dependencies
- **Package**: some-lib@2.0.0
- **Usage**: Dynamic linking only
- **Status**: Compliant

### Compliance Status
[✅ COMPLIANT | ⚠️ REVIEW NEEDED | ❌ NON-COMPLIANT]
```

## Integration

### With Security Gate

- License check runs alongside vulnerability scan
- Both must pass before deployment

### With Human Approval

- Copyleft licenses trigger approval request
- Exceptions require documented approval

### With Documentation

- All dependencies documented
- License decisions captured

## Tools Reference

| Tool | Languages | Command |
|------|-----------|---------|
| license-checker | Node.js | `npx license-checker` |
| pip-licenses | Python | `pip-licenses` |
| go-licenses | Go | `go-licenses check ./...` |
| cargo-deny | Rust | `cargo deny check licenses` |
| FOSSA | Multi | `fossa analyze` |
| Snyk | Multi | `snyk test --license` |
| WhiteSource | Multi | (Commercial) |
| Black Duck | Multi | (Commercial) |

