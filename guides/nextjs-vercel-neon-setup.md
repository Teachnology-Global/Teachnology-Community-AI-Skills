# Governance Framework Setup Guide
## For Next.js + Vercel + Neon DB Projects

A step-by-step guide for adding the Cursor Governance Skills Framework to your project.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Installation](#2-installation)
3. [Configuration](#3-configuration)
4. [Vercel Integration](#4-vercel-integration)
5. [Neon DB Security](#5-neon-db-security)
6. [GitHub Actions Setup](#6-github-actions-setup)
7. [Daily Workflow](#7-daily-workflow)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

### What You Need

| Tool | Version | Check Command |
|------|---------|---------------|
| Node.js | 18+ | `node --version` |
| npm/pnpm/yarn | Latest | `npm --version` |
| Git | Any | `git --version` |
| Cursor IDE | Latest | Download from [cursor.com](https://cursor.com) |
| Python | 3.8+ (optional) | `python --version` |

### Your Project Should Have

- [ ] A Next.js project (new or existing)
- [ ] Git repository initialized
- [ ] Vercel account connected
- [ ] Neon DB project created

### Install Security Tools (Optional but Recommended)

These tools enable automated scanning:

```bash
# Install Semgrep (SAST)
pip install semgrep
# or: brew install semgrep

# Install Trivy (dependency scanning)
brew install trivy
# or: choco install trivy (Windows)

# Install Gitleaks (secret detection)
brew install gitleaks
# or: choco install gitleaks (Windows)
```

---

## 2. Installation

### Step 2.1: Clone the Framework

```bash
# Navigate to a temporary location
cd ~/Downloads

# Clone the governance framework
git clone https://github.com/Teachnology-Global/cursor-governance-skills.git governance-framework
```

### Step 2.2: Copy Files to Your Project

```bash
# Navigate to your Next.js project
cd /path/to/your/nextjs-project

# Create the .cursor directory if it doesn't exist
mkdir -p .cursor/skills

# Copy the skills
cp -r ~/Downloads/governance-framework/.cursor/skills/* .cursor/skills/

# Copy the Cursor rules file
cp ~/Downloads/governance-framework/.cursorrules .cursorrules

# Copy the configuration template
cp ~/Downloads/governance-framework/governance.yaml governance.yaml

# Copy the scripts
mkdir -p scripts/governance
cp ~/Downloads/governance-framework/scripts/* scripts/governance/

# Copy the templates
mkdir -p docs/templates
cp ~/Downloads/governance-framework/templates/* docs/templates/
```

### Step 2.3: Verify Installation

Your project should now have:

```
your-nextjs-project/
├── .cursor/
│   └── skills/
│       ├── accessibility.md
│       ├── browser-testing.md
│       ├── code-quality.md
│       ├── dependency-scanning.md
│       ├── documentation.md
│       ├── human-approval.md
│       ├── license-compliance.md
│       ├── pre-release.md
│       ├── privacy-guard.md
│       ├── secrets-management.md
│       ├── security-gate.md
│       ├── test-automation.md
│       ├── test-plan.md
│       └── testing-standards.md
├── .cursorrules
├── governance.yaml
├── scripts/
│   └── governance/
│       ├── security-scan.sh
│       ├── security-scan.ps1
│       ├── privacy-scan.py
│       ├── a11y-audit.js
│       └── github-workflow.yml
├── docs/
│   └── templates/
│       ├── adr.md
│       ├── changelog-entry.md
│       └── ... (other templates)
├── src/                    # Your Next.js code
├── package.json
└── ... (other project files)
```

### Step 2.4: Add to .gitignore (Optional)

If you want to keep governance config but not track certain files:

```bash
# Add to .gitignore
echo "# Governance scan outputs" >> .gitignore
echo "*-results.json" >> .gitignore
echo "*.sarif" >> .gitignore
```

---

## 3. Configuration

### Step 3.1: Edit governance.yaml

Open `governance.yaml` and customise for your Next.js + Vercel + Neon project:

```yaml
# governance.yaml
version: "1.0.0"

project:
  name: "Your Project Name"
  type: web  # Next.js is a web project

skills:
  # Security - Important for Vercel deployments
  security:
    enabled: true
    severity_threshold: high
    scanners:
      sast: true
      sca: true
      secrets: true
      container: false  # Not using Docker directly with Vercel
      iac: false        # Unless you have Terraform
    exclude:
      - "node_modules/"
      - ".next/"
      - "coverage/"
      - "**/*.test.*"
      - "**/*.spec.*"

  # Human Approval - Always on
  human_approval:
    enabled: true
    always_require_for:
      - security
      - privacy
      - breaking_changes
      - database_schema  # Important for Neon!

  # Documentation
  documentation:
    enabled: true
    require_changelog: true
    paths:
      changelog: "CHANGELOG.md"
      adr_directory: "docs/adr/"
      api_docs: "docs/api/"

  # Privacy - Critical for user data in Neon DB
  privacy:
    enabled: true
    regulations:
      - GDPR
      - CCPA
    sensitive_fields:
      - password
      - ssn
      - credit_card
      - api_key
      - secret
    pii_patterns:
      - email
      - phone
      - address
      - birth_date
      - ip_address

  # Accessibility - Required for production web apps
  accessibility:
    enabled: true
    standard: "WCAG21"
    level: "AA"
    include:
      - "src/**/*.tsx"
      - "src/**/*.jsx"
      - "app/**/*.tsx"       # Next.js App Router
      - "pages/**/*.tsx"     # Next.js Pages Router
      - "components/**/*.tsx"
    block_on:
      - critical
      - serious

  # Code Quality
  code_quality:
    enabled: true
    complexity:
      cyclomatic_max: 10
      file_lines_max: 500
      function_lines_max: 50
    linting:
      enabled: true
      config_file: ".eslintrc.json"  # or eslint.config.js

  # Testing
  testing:
    enabled: true
    coverage:
      minimum: 80
      enforce: true
      exclude:
        - "**/*.config.*"
        - "**/middleware.*"
    patterns:
      - "**/*.test.ts"
      - "**/*.test.tsx"
      - "**/__tests__/**"

  # License Compliance
  license_compliance:
    enabled: true
    allowed:
      - MIT
      - Apache-2.0
      - BSD-2-Clause
      - BSD-3-Clause
      - ISC
      - 0BSD
    forbidden:
      - GPL-2.0
      - GPL-3.0
      - AGPL-3.0

# Environment-specific overrides
environments:
  development:
    security:
      severity_threshold: medium
    testing:
      coverage:
        minimum: 60
        enforce: false
  
  preview:  # Vercel preview deployments
    security:
      severity_threshold: high
    testing:
      coverage:
        minimum: 70
  
  production:
    security:
      severity_threshold: high
      block_on_secrets: true
    testing:
      coverage:
        minimum: 80
        enforce: true

# Vercel CI integration
ci:
  pull_request:
    - security
    - code_quality
    - testing
    - license_compliance
  
  pre_deploy:
    - security
    - privacy
    - accessibility
```

### Step 3.2: Set Up ESLint for Next.js

Ensure your ESLint config includes accessibility:

```bash
# Install accessibility plugin
npm install --save-dev eslint-plugin-jsx-a11y
```

Update `.eslintrc.json`:

```json
{
  "extends": [
    "next/core-web-vitals",
    "plugin:jsx-a11y/recommended"
  ],
  "plugins": ["jsx-a11y"],
  "rules": {
    "jsx-a11y/alt-text": "error",
    "jsx-a11y/anchor-is-valid": "error",
    "jsx-a11y/click-events-have-key-events": "error",
    "jsx-a11y/no-static-element-interactions": "error"
  }
}
```

### Step 3.3: Set Up Testing

If you don't have testing set up:

```bash
# Install Jest and React Testing Library
npm install --save-dev jest @testing-library/react @testing-library/jest-dom jest-environment-jsdom

# Install coverage tools
npm install --save-dev @jest/globals
```

Create `jest.config.js`:

```javascript
const nextJest = require('next/jest');

const createJestConfig = nextJest({
  dir: './',
});

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    'app/**/*.{js,jsx,ts,tsx}',
    '!**/*.d.ts',
    '!**/node_modules/**',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
};

module.exports = createJestConfig(customJestConfig);
```

Add to `package.json`:

```json
{
  "scripts": {
    "test": "jest",
    "test:coverage": "jest --coverage",
    "test:watch": "jest --watch"
  }
}
```

---

## 4. Vercel Integration

### Step 4.1: Create GitHub Actions Workflow

Create `.github/workflows/governance.yml`:

```yaml
name: Governance Gate

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  NODE_VERSION: '20'

jobs:
  # ============================================
  # Security Checks
  # ============================================
  security:
    name: Security Gate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      # SAST - Static Analysis
      - name: Run Semgrep
        uses: semgrep/semgrep-action@v1
        with:
          config: >-
            p/typescript
            p/react
            p/nextjs
            p/security-audit
        continue-on-error: true

      # SCA - Dependency Vulnerabilities
      - name: Run npm audit
        run: npm audit --audit-level=high
        continue-on-error: true

      # Secret Detection
      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  # ============================================
  # Code Quality
  # ============================================
  quality:
    name: Code Quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type Check
        run: npx tsc --noEmit

  # ============================================
  # Tests
  # ============================================
  test:
    name: Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests with coverage
        run: npm run test:coverage

      - name: Check coverage threshold
        run: |
          COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage below 80% threshold"
            exit 1
          fi

  # ============================================
  # License Check
  # ============================================
  licenses:
    name: License Compliance
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Check licenses
        run: |
          npx license-checker --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD;Unlicense;CC0-1.0"

  # ============================================
  # Accessibility (for changed components)
  # ============================================
  accessibility:
    name: Accessibility
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Run accessibility tests
        run: npm run test:a11y || echo "No a11y tests configured"
        continue-on-error: true

  # ============================================
  # Gate Decision
  # ============================================
  gate:
    name: Governance Gate Decision
    needs: [security, quality, test, licenses]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Check all gates
        run: |
          if [[ "${{ needs.security.result }}" == "failure" ]] || \
             [[ "${{ needs.quality.result }}" == "failure" ]] || \
             [[ "${{ needs.test.result }}" == "failure" ]] || \
             [[ "${{ needs.licenses.result }}" == "failure" ]]; then
            echo "❌ Governance gate FAILED"
            exit 1
          fi
          echo "✅ All governance gates passed"
```

### Step 4.2: Configure Vercel

In your Vercel project settings:

1. **Go to**: Project → Settings → Git
2. **Enable**: "Required status checks"
3. **Add checks**:
   - `Governance Gate Decision`
   - `Security Gate`
   - `Code Quality`
   - `Tests`

This prevents deployments if governance checks fail.

### Step 4.3: Environment Variables

In Vercel dashboard, add environment variables:

```
# Required for Neon
DATABASE_URL=postgresql://...

# Recommended: separate for preview vs production
DATABASE_URL (Production) = your-prod-neon-url
DATABASE_URL (Preview) = your-dev-neon-url
```

**Important**: Never commit database URLs to git!

---

## 5. Neon DB Security

### Step 5.1: Secure Connection Strings

Create `lib/db.ts`:

```typescript
import { neon } from '@neondatabase/serverless';

// Validate environment variable exists
if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL environment variable is required');
}

// Create secure connection
export const sql = neon(process.env.DATABASE_URL);

// For connection pooling (recommended for production)
import { Pool } from '@neondatabase/serverless';

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: true,  // Always use SSL
});
```

### Step 5.2: PII in Database

When storing user data in Neon, follow these patterns:

```typescript
// ✅ Good: Encrypt sensitive data before storage
import { encrypt, decrypt } from '@/lib/encryption';

async function createUser(email: string, ssn: string) {
  const encryptedSSN = await encrypt(ssn);
  
  await sql`
    INSERT INTO users (email, ssn_encrypted)
    VALUES (${email}, ${encryptedSSN})
  `;
}

// ✅ Good: Use parameterized queries (prevents SQL injection)
async function getUser(id: string) {
  return await sql`SELECT * FROM users WHERE id = ${id}`;
}

// ❌ Bad: Never interpolate user input directly
async function badQuery(userInput: string) {
  // DANGEROUS - SQL injection vulnerability!
  return await sql(`SELECT * FROM users WHERE name = '${userInput}'`);
}
```

### Step 5.3: Database Schema Changes

**Always use Human Approval for schema changes!**

The framework will automatically pause when you discuss:
- Adding/removing columns
- Creating/dropping tables
- Changing data types
- Adding indexes

Example workflow:
```
You: "I need to add a phone_number column to the users table"

AI: "🛑 Human Approval Required

**Category**: Database Schema Change

This will add a PII field (phone_number) to the users table.

**Options**:
1. Add as encrypted field with proper consent mechanism
2. Add as plain text (not recommended for PII)
3. Skip - find alternative approach

**Privacy Considerations**:
- Phone numbers are PII under GDPR/CCPA
- Will need consent checkbox in UI
- Must be included in data export/deletion

Waiting for your decision..."
```

### Step 5.4: Data Deletion (Right to Erasure)

Create `lib/gdpr.ts`:

```typescript
import { sql } from './db';

export async function deleteUserData(userId: string) {
  // Start transaction
  await sql`BEGIN`;
  
  try {
    // Delete from all tables containing user data
    await sql`DELETE FROM user_preferences WHERE user_id = ${userId}`;
    await sql`DELETE FROM user_sessions WHERE user_id = ${userId}`;
    await sql`DELETE FROM audit_logs WHERE user_id = ${userId}`;
    await sql`DELETE FROM users WHERE id = ${userId}`;
    
    // Log the deletion (anonymized)
    await sql`
      INSERT INTO deletion_audit (deleted_at, deletion_type)
      VALUES (NOW(), 'user_request')
    `;
    
    await sql`COMMIT`;
    
    return { success: true };
  } catch (error) {
    await sql`ROLLBACK`;
    throw error;
  }
}
```

---

## 6. GitHub Actions Setup

### Step 6.1: Create Workflow File

Already created in Step 4.1 above.

### Step 6.2: Add Required Secrets

In GitHub repo settings → Secrets and variables → Actions:

| Secret | Value | Purpose |
|--------|-------|---------|
| `VERCEL_TOKEN` | Your Vercel token | Deployments |
| `VERCEL_ORG_ID` | Your org ID | Deployments |
| `VERCEL_PROJECT_ID` | Your project ID | Deployments |

### Step 6.3: Branch Protection

In GitHub repo settings → Branches → Add rule:

- **Branch name pattern**: `main`
- **Require status checks**: ✅
- **Required checks**:
  - `Governance Gate Decision`
  - `Vercel`
- **Require pull request reviews**: ✅
- **Dismiss stale reviews**: ✅

---

## 7. Daily Workflow

### Starting Work

1. **Open project in Cursor**
2. **Create feature branch**:
   ```bash
   git checkout -b feature/my-feature
   ```
3. **Start coding** - skills activate automatically

### During Development

The AI will automatically:
- **Pause for approval** on PRD deviations, security changes, schema changes
- **Flag accessibility issues** when creating UI components
- **Check for PII** when handling user data
- **Enforce code quality** standards

### Example Interactions

**When adding a form:**
```
You: "Create a signup form with email and password"

AI: *Creates accessible form with:*
- Proper labels
- ARIA attributes
- Keyboard navigation
- Error handling

Then asks: "Should I also add:
1. Password strength indicator
2. Terms of service checkbox (required for GDPR)
3. Marketing consent (optional, unchecked by default)

This form collects PII (email). Ensure your privacy policy covers this."
```

**When deploying:**
```
You: "Deploy to production"

AI: "🛑 Pre-Release Checklist Required

Running governance gates...

| Gate | Status |
|------|--------|
| Security | ✅ Passed |
| Privacy | ✅ Passed |
| Accessibility | ⚠️ 2 moderate issues |
| Tests | ✅ 87% coverage |
| Licenses | ✅ All permitted |

**Accessibility Issues:**
1. Button missing aria-label (moderate)
2. Colour contrast 4.2:1 on muted text (moderate)

**Options:**
1. Fix issues then deploy
2. Deploy with documented exceptions
3. Cancel deployment

Awaiting your decision..."
```

### Committing Code

```bash
# Run local checks first
npm run lint
npm run test
npm run build

# Commit with conventional format
git commit -m "feat: add user signup form

- Added accessible signup form component
- Includes GDPR consent checkbox
- Password validation with strength indicator

Closes #123"

# Push and create PR
git push origin feature/my-feature
```

### Pull Request

When you create a PR:
1. GitHub Actions runs all governance checks
2. Vercel creates preview deployment
3. All checks must pass before merge is allowed
4. Request review from team member

---

## 8. Troubleshooting

### "Skill not activating"

**Check:**
1. Is `.cursor/skills/` directory present?
2. Is `.cursorrules` in project root?
3. Restart Cursor IDE

### "Security scan failing"

**Common fixes:**
```bash
# Update dependencies
npm audit fix

# Check for secrets
git secrets --scan

# Review findings
cat security-results.json
```

### "Coverage below threshold"

**Check:**
```bash
# See what's not covered
npm run test:coverage

# Look at coverage report
open coverage/lcov-report/index.html
```

### "License violation"

**Find the problem:**
```bash
npx license-checker --summary
npx license-checker --failOn "GPL-3.0" --json
```

**Fix options:**
1. Find alternative package with permissive license
2. Document exception in `governance.yaml`
3. Get legal approval

### "Vercel deployment blocked"

**Check:**
1. All GitHub checks passing?
2. Required reviewers approved?
3. Branch protection rules met?

### "Neon connection failing"

**Check:**
```bash
# Verify env var is set
echo $DATABASE_URL

# Test connection
npx neon-cli connection-string --project-id your-project
```

---

## Quick Reference Card

### Commands

```bash
# Security scan
./scripts/governance/security-scan.sh

# Privacy scan
python scripts/governance/privacy-scan.py src/

# Accessibility audit
node scripts/governance/a11y-audit.js src/

# License check
npx license-checker --onlyAllow "MIT;Apache-2.0;BSD-3-Clause;ISC"

# Full test suite
npm run test:coverage
```

### Governance Triggers

| Say This | Skill Activates |
|----------|-----------------|
| "deploy", "release" | Pre-Release Gate |
| "add column", "schema" | Human Approval (DB) |
| "user data", "PII" | Privacy Guard |
| "form", "button", "modal" | Accessibility |
| "add package", "install" | License Compliance |

### File Locations

| File | Purpose |
|------|---------|
| `.cursor/skills/` | Skill definitions |
| `.cursorrules` | Cursor AI rules |
| `governance.yaml` | Project config |
| `docs/adr/` | Architecture decisions |
| `CHANGELOG.md` | Version history |

---

## Need Help?

1. **Check the skill file** for detailed guidance
2. **Ask the AI** - "How does the security gate work?"
3. **Review templates** in `docs/templates/`

---

*Happy building! 🚀*

