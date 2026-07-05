---
description: >
  Governs npm/pip/cargo dependency security to prevent supply chain attacks. Covers
  package vetting, lockfile hygiene, install script controls, and incident response
  for compromised dependencies. Updated after June 2026 node-gyp and Red Hat npm
  supply chain compromises. Use when: (1) adding a new dependency, (2) updating
  packages, (3) reviewing PRs that change lockfiles, (4) responding to dependency
  vulnerability alerts, (5) deploying to production.
globs: ["**/package.json", "**/package-lock.json", "**/yarn.lock", "**/pnpm-lock.yaml", "**/requirements.txt", "**/Pipfile", "**/Cargo.toml", "**/go.sum"]
alwaysApply: false
tags: [security]
---

# Supply Chain Security

## Purpose

Modern applications rely on hundreds of third-party packages. A single compromised package can give attackers full access to your codebase, credentials, and infrastructure. This skill ensures dependencies are vetted, monitored, and respond quickly to compromises.

## Why This Matters: 2026 Supply Chain Crisis

### June 2026 Attacks (Active Threats)

**Node-gyp Supply Chain Compromise:**
- 57 npm packages compromised with hundreds of malicious versions
- Self-propagating worm via build scripts
- Executes during `npm install` on packages with native modules
- **Severity: Critical** — affects any project with native Node.js dependencies

**Red Hat npm Miasma Campaign:**
- 90+ versions of `@redhat-cloud-services/*` packages compromised
- Credential theft from GitHub, cloud platforms, local systems
- Malicious code in `preinstall` hooks (runs before package installs)
- **Severity: Critical** — persistent credential harvesting

**Pattern:** Attackers target the build/install phase — code runs *during* `npm install`, before your application even starts. Standard code review doesn't catch this.

### Historical Context

- **Nov 2024:** `leadmagic/led-node` — 300K+ downloads, credential theft
- **2023:** `ua-parser-js` — 7M weekly downloads, crypto miner injection
- **Ongoing:** Typosquatting attacks (e.g., `expresss` vs `express`, `colour` vs `color`)

**For non-technical founders:** Every package you install is like hiring an employee you've never met. They get access to your code and can run commands on your machine. Supply chain security is background checks for your code's dependencies.

## Activation

This skill activates when:
- Adding a new dependency (`npm install`, `pip install`, `cargo add`)
- Updating packages (`npm update`, `pip install --upgrade`)
- PR changes `package.json`, `package-lock.json`, `requirements.txt`, etc.
- Receiving a Dependabot/Snyk security alert
- Deploying to production (dependency audit required)

## Pre-Install Vetting

### Before Adding Any Package

```markdown
## Package Vetting Checklist: [package-name]

**Source Verification**
- [ ] Is this the official package? (check publisher/organisation)
- [ ] GitHub repository exists and is actively maintained?
- [ ] Check for typosquatting: compare to popular packages
- [ ] Review the package's own dependencies (check for suspicious deps)

**Popularity & Trust**
- [ ] Weekly downloads > 10K? (indicates community use)
- [ ] GitHub stars and contributors?
- [ ] Used by reputable projects? (check "dependents" on npm/GitHub)
- [ ] Maintainer has a track record? (check other packages they publish)

**Security Signals**
- [ ] No recent security advisories on the package
- [ ] Package doesn't run install scripts unless necessary
- [ ] Package size reasonable? (large packages may hide malicious code)
- [ ] Package has a security policy or SECURITY.md?

**Necessity**
- [ ] Do I actually need this package?
- [ ] Is there a lighter alternative?
- [ ] Could I implement this functionality myself? (for simple utilities)
```

### Red Flags: Do NOT Install

- Package name similar to popular package but with typos (`expresss`, `reactt`)
- Publisher with no other packages or very new account
- Package has install scripts that download from external URLs
- README is empty or doesn't match package functionality
- Package requests unusual permissions (network access for utilities)
- Recently transferred ownership (common attack vector)

## Install-Time Controls

### Disable Install Scripts (Default)

```bash
# Recommended: Disable install scripts by default
npm config set ignore-scripts true

# When you need scripts for a specific package:
npm install package-name --ignore-scripts=false

# Or in package.json:
{
  "scripts": {
    "postinstall": "node scripts/verify-deps.js"
  }
}
```

**Why:** Install scripts (`preinstall`, `install`, `postinstall`) run arbitrary code during `npm install`. The June 2026 Red Hat attack used `preinstall` hooks. Disabling scripts by default prevents most supply chain attacks.

### Lockfile Hygiene

```bash
# Always commit lockfiles (package-lock.json, yarn.lock, etc.)
git add package-lock.json
git commit -m "chore: update dependencies"

# Review lockfile changes in PRs
git diff main -- package-lock.json

# Check for suspicious additions:
# - New packages you didn't install
# - Changed integrity hashes
# - Added install scripts
```

**What to look for in lockfile diffs:**
```json
// ✅ Normal: Version bump with new integrity hash
"package-name": {
  "version": "1.2.3",
  "integrity": "sha512-abc123..."
}

// 🚨 Suspicious: Integrity hash changed for same version
"package-name": {
  "version": "1.2.3",
  "integrity": "sha512-different-hash..."  // Why did the hash change?
}

// 🚨 Suspicious: New package you didn't install
"unexpected-package": {
  "version": "1.0.0",
  "integrity": "sha512-xyz789..."
}
```

### Pinned Versions (Production)

```json
// package.json
{
  "dependencies": {
    // ❌ Range versions (can install newer, potentially compromised versions)
    "express": "^4.18.0",
    
    // ✅ Pinned versions (explicit control)
    "express": "4.18.2"
  }
}
```

**Trade-off:** Pinned versions require manual updates. For production apps, pin versions and use Dependabot/automation for safe updates.

## Monitoring & Detection

### Automated Vulnerability Scanning

```bash
# npm audit (built-in)
npm audit
npm audit fix  # Auto-fix safe updates
npm audit fix --force  # Include breaking changes

# Snyk (comprehensive)
npm install -g snyk
snyk test
snyk monitor  # Continuous monitoring

# GitHub Dependabot (free for public repos)
# Enable in repository Settings → Security → Dependabot alerts
```

### Continuous Monitoring Setup

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "your-username"
    commit-message:
      prefix: "deps"
```

### Weekly Dependency Audit (Cron Job)

```bash
#!/bin/bash
# scripts/audit-dependencies.sh

echo "Running dependency audit..."

# Check for known vulnerabilities
npm audit --audit-level=moderate

# Check for outdated packages
npm outdated --json > outdated.json

# Check for suspicious packages (using npm's package quality API)
node scripts/check-package-quality.js

# Send report to Slack/email
if [ -n "$(npm audit --json | jq '.vulnerabilities | length')" ]; then
  echo "Vulnerabilities found!" | slack-send
fi
```

## Incident Response: Compromised Dependency

```markdown
## Dependency Compromise Response Plan

### Immediate Actions (First 15 Minutes)
1. **Stop deployment** — prevent spread to production
2. **Identify scope** — which environments use this package?
3. **Check exposure** — did the package run install scripts?
4. **Isolate affected systems** — disconnect from network if needed

### Investigation
1. **Check package version history:**
   ```bash
   npm view package-name versions --json
   npm view package-name@compromised-version
   ```
2. **Review install logs:**
   ```bash
   npm install package-name@compromised-version --dry-run --loglevel=verbose
   ```
3. **Audit credentials:**
   - Rotate all secrets the compromised environment could access
   - Check for new SSH keys, API tokens, or user accounts
   - Review cloud provider access logs

4. **Check for persistence:**
   - New cron jobs or systemd services
   - Modified shell configs (.bashrc, .zshrc)
   - New users or SSH keys

### Remediation
1. **Remove compromised package:**
   ```bash
   npm uninstall package-name
   rm -rf node_modules package-lock.json
   npm install  # Reinstall from clean state
   ```
2. **Update lockfile:**
   ```bash
   git add package-lock.json
   git commit -m "security: remove compromised package-name@version"
   ```
3. **Notify affected parties:**
   - Team members who cloned the repo
   - CI/CD environments that built with the package
   - Production systems if deployed

### Post-Incident
1. **Root cause analysis** — how did the package get added?
2. **Process improvement** — what vetting step was missed?
3. **Update this skill** — add the specific package to blocked list
```

## Team Governance

### Approved Package Registry

```yaml
# .cursor/approved-packages.yaml
# Last reviewed: 2026-07-01

approved:
  # Web frameworks
  - name: "express"
    versions: ["4.18.2", "4.19.1"]
    approved_by: "Jason"
    approved_date: "2026-06-15"
    
  - name: "fastify"
    versions: ["4.26.0"]
    approved_by: "Jason"
    approved_date: "2026-06-20"
    
  # Database
  - name: "pg"
    versions: ["8.11.3"]
    approved_by: "Jason"
    approved_date: "2026-06-10"

blocked:
  # Known compromised packages
  - name: "@redhat-cloud-services/*"
    reason: "June 2026 Miasma campaign - credential theft"
    blocked_date: "2026-06-15"
    
  - name: "node-gyp-affected-packages"
    reason: "June 2026 supply chain worm"
    blocked_date: "2026-06-20"
```

### PR Review: Dependency Changes

```markdown
## PR Checklist: Dependency Updates

If this PR modifies package.json, package-lock.json, or any lockfile:

- [ ] **Lockfile changes match package.json changes**
- [ ] **No unexpected packages added** (check for typosquatting)
- [ ] **Integrity hashes present** for all packages
- [ ] **Install scripts reviewed** (any `preinstall`/`postinstall` hooks?)
- [ ] **Package vetting completed** (publisher, popularity, security)
- [ ] **Tested locally** with clean `node_modules`
- [ ] **No credential-related code** in new packages

For major dependency updates:
- [ ] **Changelog reviewed** for breaking changes
- [ ] **Test suite passes** with new version
- [ ] **Production impact assessed** (API changes, deprecations)
```

## Integration

### With Dependency Scanning
- Supply chain security is the "pre-install" complement to dependency scanning
- Scanning finds known CVEs; supply chain security prevents unknown compromises

### With Secrets Management
- Compromised packages target secrets first
- Secrets rotation is part of incident response

### With Deployment Checklist
- Dependency audit required before production deployment
- Lockfile integrity check in pre-deploy validation

### With MCP Security
- MCP servers are npm packages — same supply chain risks
- Apply package vetting to MCP server dependencies

## Checklist: Supply Chain Security

- [ ] **Install scripts disabled by default** (`npm config set ignore-scripts true`)
- [ ] **Lockfile committed** and reviewed in PRs
- [ ] **Dependencies pinned** in production (exact versions)
- [ ] **Vulnerability scanning enabled** (npm audit, Dependabot, Snyk)
- [ ] **Weekly audit cron job** running
- [ ] **Approved package registry** maintained
- [ ] **Incident response plan** documented and tested
- [ ] **Team trained** on supply chain risks and red flags

## For Non-Technical Founders

**The 30-second version:**
Every package you install is code written by strangers. Most are trustworthy, but some are compromised. Before adding a package:
1. Check if it's popular (thousands of downloads)
2. Verify the publisher is legitimate
3. Use exact versions, not "latest"
4. Run `npm audit` regularly
5. If something seems off, don't install it

**Budget impact:** Supply chain attacks cost $100K+ in incident response, credential rotation, and customer notification. Prevention costs $0 (just awareness and process).

## Additional Resources

- [npm Security Best Practices](https://docs.npmjs.com/packages-and-modules/securing-your-code)
- [Snyk Vulnerability Database](https://snyk.io/vuln/)
- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)
- [Package Phobia](https://packagephobia.com/) — check package size before installing
