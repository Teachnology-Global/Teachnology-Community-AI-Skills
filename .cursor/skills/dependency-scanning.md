---
description: >
  Scans project dependencies for known vulnerabilities, outdated packages, and supply
  chain risks. Enforces update policies and tracks dependency health over time.
  Use when: (1) adding new packages, (2) auditing existing dependencies, (3) reviewing
  security advisories, (4) preparing for release, (5) investigating supply chain risks.
globs: ["package.json", "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "requirements.txt", "Pipfile.lock", "go.sum", "Cargo.lock", "pom.xml", "*.csproj"]
alwaysApply: false
---

# Dependency Scanning

## Purpose

Catch vulnerable, outdated, or risky dependencies before they reach production. This goes beyond license compliance to cover security vulnerabilities, maintenance status, and supply chain integrity.

## Activation

This skill activates when you mention:
- "dependency scan", "audit dependencies"
- "npm audit", "pip audit", "cargo audit"
- "vulnerable package", "CVE"
- "outdated packages", "update dependencies"
- "supply chain", "dependency risk"

Also activates when:
- Adding new packages to any manifest file
- Reviewing lock file changes in PRs
- Running pre-release checks

## Scanning Workflow

### 1. Vulnerability Scan

Check all dependencies against known vulnerability databases.

```bash
# JavaScript/TypeScript
npm audit --audit-level=high
# or
npx better-npm-audit audit --level high

# Python
pip-audit
# or
safety check

# Go
govulncheck ./...

# Rust
cargo audit

# Ruby
bundle audit check --update

# Multi-language
trivy fs --severity CRITICAL,HIGH .
grype dir:.
```

### 2. Outdated Package Check

```bash
# JavaScript
npm outdated
npx npm-check-updates

# Python
pip list --outdated

# Go
go list -u -m all

# Rust
cargo outdated
```

### 3. Supply Chain Risk Assessment

For every new dependency, evaluate:

| Factor | What to Check | Red Flag |
|--------|---------------|----------|
| **Maintainers** | Active maintainer count | Single maintainer, no activity in 12+ months |
| **Downloads** | Weekly download count | Under 1,000 weekly for critical functionality |
| **Age** | Package age and history | Brand new package (under 6 months) for core functionality |
| **Typosquatting** | Name similarity to popular packages | Off-by-one character from known package |
| **Install scripts** | postinstall/preinstall hooks | Any install script that makes network calls |
| **Permissions** | File system or network access | Unexpected scope for stated purpose |
| **Source** | GitHub repo matches published package | No source repo, or source differs from published |

### 4. Dependency Health Report

```markdown
## Dependency Health Report

**Date**: [timestamp]
**Total Dependencies**: [count] (direct: [X], transitive: [Y])

### Vulnerability Summary
| Severity | Count | Action |
|----------|-------|--------|
| Critical | 0 | Block deployment |
| High | 1 | Block deployment |
| Medium | 3 | Review and plan |
| Low | 7 | Log and monitor |

### Critical/High Findings

#### CVE-2024-XXXXX: [Package Name] v1.2.3
- **Severity**: High
- **Description**: [What the vulnerability does]
- **Fix**: Upgrade to v1.2.4+
- **Impact**: [How it affects your project]
- **Patched Version**: 1.2.4

### Outdated Packages (Major Versions Behind)
| Package | Current | Latest | Risk |
|---------|---------|--------|------|
| react | 17.0.2 | 18.2.0 | Medium (breaking changes) |

### Supply Chain Concerns
| Package | Concern | Recommendation |
|---------|---------|----------------|
| [name] | Single maintainer | Monitor closely, have fallback plan |
```

## Update Policy

### Patch Updates (x.x.PATCH)
- Apply automatically via CI
- No approval needed
- Must pass all tests

### Minor Updates (x.MINOR.x)
- Review changelog
- Run full test suite
- Apply in batches weekly

### Major Updates (MAJOR.x.x)
- Requires Human Approval
- Review breaking changes
- Create migration plan
- Update one at a time
- Full regression testing

## CI Integration

```yaml
# GitHub Actions
dependency-scan:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    
    - name: Vulnerability scan
      run: npm audit --audit-level=high
      
    - name: Check for critical CVEs
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        severity: 'CRITICAL,HIGH'
        exit-code: '1'
```

## Lock File Hygiene

- **Always commit lock files** (package-lock.json, yarn.lock, etc.)
- **Review lock file diffs** in PRs for unexpected changes
- **Regenerate periodically** to pick up transitive dependency patches
- **Never manually edit** lock files

## Integration

### With Security Gate
- Dependency scan runs as part of security gate
- Critical/high vulnerabilities block deployment

### With License Compliance
- Runs alongside license checks
- Both must pass for release approval

### With Human Approval
- Major version updates trigger approval
- New dependencies with supply chain concerns trigger review

### With Pre-Release
- Full dependency scan required before release
- Report attached to release documentation
