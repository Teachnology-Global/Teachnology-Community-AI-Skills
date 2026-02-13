---
description: >
  Generates complete test automation code from test plans with screenshot capture.
  Creates Playwright, Cypress, or Jest tests with visual documentation. Use when:
  (1) automating manual test cases, (2) generating E2E test suites, (3) creating
  visual regression tests, (4) documenting test execution with screenshots.
globs: ["**/*.spec.ts", "**/*.spec.tsx", "**/*.test.ts", "**/e2e/**", "**/playwright/**", "**/cypress/**"]
alwaysApply: false
---

# Test Automation

## Purpose

Generate complete, runnable test automation code from test plans. Include screenshot capture at every step for visual documentation and regression testing.

## Activation

This skill activates when you mention:
- "automate tests", "generate tests"
- "create E2E tests", "write Playwright tests"
- "test automation", "automated testing"
- "visual regression", "screenshot tests"
- "convert test plan to code"

## Supported Frameworks

| Framework | Best For | Screenshot Support |
|-----------|----------|-------------------|
| Playwright | E2E, Cross-browser | ✅ Built-in |
| Cypress | E2E, Component | ✅ Built-in |
| Jest + Testing Library | Unit, Integration | ⚠️ With puppeteer |
| Vitest | Unit, Integration | ⚠️ With browser mode |

## Generation Workflow

### Step 1: Parse Test Plan

Extract test cases from test plan:

```markdown
## Test Case Input

**TC-001**: Successful user signup
- Navigate to /signup
- Enter email: test@example.com
- Enter password: SecurePass123!
- Click submit
- Verify: Welcome message displayed
```

### Step 2: Generate Test Code

#### Playwright (Recommended)

```typescript
// tests/e2e/signup.spec.ts
import { test, expect } from '@playwright/test';

/**
 * Test Case: TC-001
 * Requirement: US-001 - User Signup
 * Priority: Critical
 * 
 * @see docs/test-plans/TP-2024-01.md#tc-001
 */
test.describe('User Signup', () => {
  
  test('TC-001: Successful signup with valid credentials', async ({ page }) => {
    // =============================================
    // Step 1: Navigate to signup page
    // =============================================
    await test.step('Navigate to signup', async () => {
      await page.goto('/signup');
      await page.screenshot({ 
        path: 'test-results/TC-001/01-signup-page.png',
        fullPage: true 
      });
      
      // Verify page loaded
      await expect(page.locator('h1')).toContainText('Create your account');
    });

    // =============================================
    // Step 2: Fill email field
    // =============================================
    await test.step('Enter email', async () => {
      const emailInput = page.locator('#email');
      await emailInput.fill('test@example.com');
      await page.screenshot({ 
        path: 'test-results/TC-001/02-email-entered.png' 
      });
      
      // Verify no validation error
      await expect(page.locator('#email-error')).not.toBeVisible();
    });

    // =============================================
    // Step 3: Fill password field
    // =============================================
    await test.step('Enter password', async () => {
      const passwordInput = page.locator('#password');
      await passwordInput.fill('SecurePass123!');
      await page.screenshot({ 
        path: 'test-results/TC-001/03-password-entered.png' 
      });
      
      // Verify password strength indicator (if present)
      const strengthIndicator = page.locator('[data-testid="password-strength"]');
      if (await strengthIndicator.isVisible()) {
        await expect(strengthIndicator).toContainText(/strong/i);
      }
    });

    // =============================================
    // Step 4: Submit form
    // =============================================
    await test.step('Submit signup form', async () => {
      await page.screenshot({ 
        path: 'test-results/TC-001/04-before-submit.png' 
      });
      
      await page.click('[data-testid="signup-submit"]');
    });

    // =============================================
    // Step 5: Verify success
    // =============================================
    await test.step('Verify successful signup', async () => {
      // Wait for navigation or success message
      await expect(page).toHaveURL(/dashboard|welcome/);
      
      // Or wait for success message
      await expect(page.locator('text=Welcome')).toBeVisible({ timeout: 10000 });
      
      await page.screenshot({ 
        path: 'test-results/TC-001/05-success.png',
        fullPage: true 
      });
    });
  });

  test('TC-002: Signup fails with invalid email', async ({ page }) => {
    await page.goto('/signup');
    
    await test.step('Enter invalid email', async () => {
      await page.fill('#email', 'not-an-email');
      await page.fill('#password', 'SecurePass123!');
      await page.screenshot({ path: 'test-results/TC-002/01-invalid-email.png' });
    });

    await test.step('Submit and verify error', async () => {
      await page.click('[data-testid="signup-submit"]');
      
      // Verify error message
      await expect(page.locator('#email-error')).toBeVisible();
      await expect(page.locator('#email-error')).toContainText(/valid email/i);
      
      await page.screenshot({ path: 'test-results/TC-002/02-error-shown.png' });
    });
  });

  test('TC-003: Signup fails with short password', async ({ page }) => {
    await page.goto('/signup');
    
    await page.fill('#email', 'test@example.com');
    await page.fill('#password', 'short');
    await page.click('[data-testid="signup-submit"]');
    
    await expect(page.locator('#password-error')).toContainText(/8 characters/i);
    await page.screenshot({ path: 'test-results/TC-003/01-password-error.png' });
  });
});
```

#### Cypress Alternative

```typescript
// cypress/e2e/signup.cy.ts

/**
 * Test Case: TC-001
 * Requirement: US-001 - User Signup
 */
describe('User Signup', () => {
  
  beforeEach(() => {
    // Reset database state
    cy.task('db:seed');
  });

  it('TC-001: Successful signup with valid credentials', () => {
    // Step 1: Navigate
    cy.visit('/signup');
    cy.screenshot('TC-001/01-signup-page');
    cy.get('h1').should('contain', 'Create your account');

    // Step 2: Enter email
    cy.get('#email').type('test@example.com');
    cy.screenshot('TC-001/02-email-entered');

    // Step 3: Enter password
    cy.get('#password').type('SecurePass123!');
    cy.screenshot('TC-001/03-password-entered');

    // Step 4: Submit
    cy.screenshot('TC-001/04-before-submit');
    cy.get('[data-testid="signup-submit"]').click();

    // Step 5: Verify success
    cy.url().should('include', '/dashboard');
    cy.contains('Welcome').should('be.visible');
    cy.screenshot('TC-001/05-success');
  });

  it('TC-002: Signup fails with invalid email', () => {
    cy.visit('/signup');
    cy.get('#email').type('not-an-email');
    cy.get('#password').type('SecurePass123!');
    cy.get('[data-testid="signup-submit"]').click();
    
    cy.get('#email-error')
      .should('be.visible')
      .and('contain', 'valid email');
    cy.screenshot('TC-002/01-error-shown');
  });
});
```

### Step 3: Generate Visual Report

After test execution, generate visual report:

```typescript
// scripts/generate-test-report.ts
import * as fs from 'fs';
import * as path from 'path';

interface TestResult {
  testCase: string;
  requirement: string;
  status: 'passed' | 'failed' | 'skipped';
  duration: number;
  screenshots: string[];
  error?: string;
}

function generateVisualReport(results: TestResult[]): string {
  let report = `# Visual Test Report

## Summary
| Status | Count |
|--------|-------|
| ✅ Passed | ${results.filter(r => r.status === 'passed').length} |
| ❌ Failed | ${results.filter(r => r.status === 'failed').length} |
| ⏭️ Skipped | ${results.filter(r => r.status === 'skipped').length} |

## Test Results with Screenshots

`;

  for (const result of results) {
    const icon = result.status === 'passed' ? '✅' : 
                 result.status === 'failed' ? '❌' : '⏭️';
    
    report += `### ${icon} ${result.testCase}

**Requirement**: ${result.requirement}
**Duration**: ${result.duration}ms
**Status**: ${result.status.toUpperCase()}

`;

    if (result.screenshots.length > 0) {
      report += `#### Screenshots\n\n`;
      report += `| Step | Screenshot |\n|------|------------|\n`;
      
      result.screenshots.forEach((screenshot, index) => {
        report += `| Step ${index + 1} | ![](${screenshot}) |\n`;
      });
      report += '\n';
    }

    if (result.error) {
      report += `#### Error Details
\`\`\`
${result.error}
\`\`\`

`;
    }

    report += '---\n\n';
  }

  return report;
}
```

## Test Templates

### Authentication Suite

```typescript
// tests/e2e/auth.spec.ts
import { test, expect, Page } from '@playwright/test';

test.describe('Authentication', () => {
  
  // Reusable login helper
  async function login(page: Page, email: string, password: string) {
    await page.goto('/login');
    await page.fill('#email', email);
    await page.fill('#password', password);
    await page.click('[data-testid="login-submit"]');
  }

  test.describe('Login', () => {
    test('TC-010: Valid login', async ({ page }) => {
      await test.step('Navigate and login', async () => {
        await login(page, 'user@example.com', 'password123');
        await page.screenshot({ path: 'test-results/TC-010/01-login.png' });
      });

      await test.step('Verify logged in', async () => {
        await expect(page).toHaveURL('/dashboard');
        await expect(page.locator('[data-testid="user-menu"]')).toBeVisible();
        await page.screenshot({ path: 'test-results/TC-010/02-dashboard.png' });
      });
    });

    test('TC-011: Invalid password', async ({ page }) => {
      await login(page, 'user@example.com', 'wrongpassword');
      
      await expect(page.locator('[role="alert"]')).toContainText(/invalid/i);
      await page.screenshot({ path: 'test-results/TC-011/01-error.png' });
    });

    test('TC-012: Account lockout after 5 attempts', async ({ page }) => {
      for (let i = 0; i < 5; i++) {
        await login(page, 'user@example.com', 'wrongpassword');
        await page.screenshot({ path: `test-results/TC-012/attempt-${i + 1}.png` });
      }

      await expect(page.locator('[role="alert"]')).toContainText(/locked/i);
      await page.screenshot({ path: 'test-results/TC-012/locked.png' });
    });
  });

  test.describe('Logout', () => {
    test.beforeEach(async ({ page }) => {
      await login(page, 'user@example.com', 'password123');
    });

    test('TC-020: Successful logout', async ({ page }) => {
      await page.click('[data-testid="user-menu"]');
      await page.click('[data-testid="logout"]');
      
      await expect(page).toHaveURL('/login');
      await page.screenshot({ path: 'test-results/TC-020/01-logged-out.png' });
    });
  });
});
```

### CRUD Operations Suite

```typescript
// tests/e2e/crud.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Items CRUD', () => {
  
  test.beforeEach(async ({ page }) => {
    // Login and navigate
    await page.goto('/login');
    await page.fill('#email', 'user@example.com');
    await page.fill('#password', 'password123');
    await page.click('[data-testid="login-submit"]');
    await page.waitForURL('/dashboard');
  });

  test('TC-030: Create new item', async ({ page }) => {
    await test.step('Open create form', async () => {
      await page.click('[data-testid="create-item"]');
      await page.screenshot({ path: 'test-results/TC-030/01-create-form.png' });
    });

    await test.step('Fill form', async () => {
      await page.fill('#item-name', 'Test Item');
      await page.fill('#item-description', 'This is a test item');
      await page.screenshot({ path: 'test-results/TC-030/02-form-filled.png' });
    });

    await test.step('Submit and verify', async () => {
      await page.click('[data-testid="submit-item"]');
      await expect(page.locator('text=Test Item')).toBeVisible();
      await page.screenshot({ path: 'test-results/TC-030/03-item-created.png' });
    });
  });

  test('TC-031: Read item details', async ({ page }) => {
    await page.click('[data-testid="item-row"]:first-child');
    await expect(page.locator('[data-testid="item-detail"]')).toBeVisible();
    await page.screenshot({ path: 'test-results/TC-031/01-item-detail.png' });
  });

  test('TC-032: Update item', async ({ page }) => {
    await page.click('[data-testid="item-row"]:first-child');
    await page.click('[data-testid="edit-item"]');
    await page.screenshot({ path: 'test-results/TC-032/01-edit-form.png' });
    
    await page.fill('#item-name', 'Updated Item Name');
    await page.click('[data-testid="save-item"]');
    
    await expect(page.locator('text=Updated Item Name')).toBeVisible();
    await page.screenshot({ path: 'test-results/TC-032/02-item-updated.png' });
  });

  test('TC-033: Delete item', async ({ page }) => {
    const itemCount = await page.locator('[data-testid="item-row"]').count();
    await page.screenshot({ path: 'test-results/TC-033/01-before-delete.png' });
    
    await page.click('[data-testid="item-row"]:first-child [data-testid="delete-item"]');
    await page.click('[data-testid="confirm-delete"]');
    await page.screenshot({ path: 'test-results/TC-033/02-after-delete.png' });
    
    await expect(page.locator('[data-testid="item-row"]')).toHaveCount(itemCount - 1);
  });
});
```

### Accessibility Test Suite

```typescript
// tests/e2e/accessibility.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Accessibility', () => {
  
  const pages = [
    { name: 'Home', path: '/' },
    { name: 'Login', path: '/login' },
    { name: 'Signup', path: '/signup' },
    { name: 'Dashboard', path: '/dashboard', authenticated: true },
  ];

  for (const pageInfo of pages) {
    test(`A11Y-${pageInfo.name}: WCAG 2.1 AA compliance`, async ({ page }) => {
      if (pageInfo.authenticated) {
        // Login first
        await page.goto('/login');
        await page.fill('#email', 'user@example.com');
        await page.fill('#password', 'password123');
        await page.click('[data-testid="login-submit"]');
      }

      await page.goto(pageInfo.path);
      await page.screenshot({ 
        path: `test-results/a11y/${pageInfo.name.toLowerCase()}.png`,
        fullPage: true 
      });

      const accessibilityScanResults = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
        .analyze();

      // Save violations to file
      if (accessibilityScanResults.violations.length > 0) {
        const report = JSON.stringify(accessibilityScanResults.violations, null, 2);
        require('fs').writeFileSync(
          `test-results/a11y/${pageInfo.name.toLowerCase()}-violations.json`,
          report
        );
      }

      expect(accessibilityScanResults.violations).toEqual([]);
    });
  }
});
```

## Configuration Files

### Playwright Config

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  
  reporter: [
    ['html', { outputFolder: 'test-results/html-report' }],
    ['json', { outputFile: 'test-results/results.json' }],
    ['list'],
  ],
  
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'on',
    video: 'on-first-retry',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

## Integration

### With Test Plan

- Reads test cases from `docs/test-plans/`
- Generates matching test file structure
- Maintains traceability via test IDs

### With Browser Testing

- Tests execute using Playwright browser
- Screenshots captured at each step
- Results feed back to visual report

### With Pre-Release

- All automated tests must pass
- Coverage verified against test plan
- Visual report attached to release

## Commands

| Command | Action |
|---------|--------|
| "Generate tests for [feature]" | Create test file from test plan |
| "Add screenshots to tests" | Enhance tests with capture |
| "Create visual report" | Generate HTML report |
| "Convert manual test to automated" | Transform test case to code |

