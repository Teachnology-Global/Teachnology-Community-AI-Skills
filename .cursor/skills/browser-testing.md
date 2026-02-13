---
description: >
  Executes browser-based testing using Cursor's @Browser tools. Captures screenshots,
  validates UI behavior, and generates visual test reports. Use when: (1) testing UI
  features, (2) validating user flows, (3) capturing visual evidence, (4) running
  E2E tests, (5) generating test documentation with screenshots.
globs: ["**/*.spec.ts", "**/*.test.ts", "**/e2e/**", "**/tests/**"]
alwaysApply: false
---

# Browser Testing

## Purpose

Execute browser-based tests against the test plan using Cursor's built-in browser tools. Capture screenshots as evidence and generate visual test reports.

## Activation

This skill activates when you mention:
- "test in browser", "browser test"
- "E2E test", "end-to-end"
- "take screenshots", "visual test"
- "test this flow", "test the UI"
- "run against test plan"

## Browser Tools Reference

| Tool | Purpose |
|------|---------|
| `browser_navigate` | Go to URL |
| `browser_snapshot` | Get page accessibility tree (preferred) |
| `browser_click` | Click element |
| `browser_type` | Type into input |
| `browser_hover` | Hover over element |
| `browser_select_option` | Select dropdown option |
| `browser_press_key` | Press keyboard key |
| `browser_wait_for` | Wait for text/element |
| `browser_console_messages` | Get console output |
| `browser_network_requests` | Get network activity |

## Test Execution Workflow

### Step 1: Prepare Test Environment

Before running browser tests:

```markdown
## Test Environment Check

- [ ] Local dev server running (`npm run dev`)
- [ ] Test database seeded
- [ ] Test user credentials ready
- [ ] Expected test plan loaded

**Server URL**: http://localhost:3000
**Test Plan**: TP-2024-01-15-001
```

### Step 2: Execute Test Case

For each test case in the plan:

```markdown
## Executing: TC-001 - Successful User Signup

### Test Information
- **Test Case ID**: TC-001
- **Requirement**: US-001
- **Priority**: Critical

### Execution Steps

**Step 1: Navigate to signup page**
```
browser_navigate: http://localhost:3000/signup
```
📸 Screenshot: `screenshots/TC-001/01-signup-page.png`

**Step 2: Verify page loaded**
```
browser_snapshot
```
✅ Found: "Create your account" heading
✅ Found: Email input field
✅ Found: Password input field
✅ Found: Submit button

**Step 3: Enter email**
```
browser_type: 
  element: "Email input field"
  ref: "#email"
  text: "test@example.com"
```
📸 Screenshot: `screenshots/TC-001/02-email-entered.png`

**Step 4: Enter password**
```
browser_type:
  element: "Password input field"  
  ref: "#password"
  text: "SecurePass123!"
```
📸 Screenshot: `screenshots/TC-001/03-password-entered.png`

**Step 5: Submit form**
```
browser_click:
  element: "Sign Up button"
  ref: "[data-testid='signup-submit']"
```

**Step 6: Wait for success**
```
browser_wait_for:
  text: "Welcome"
```
📸 Screenshot: `screenshots/TC-001/04-success.png`

### Result
| Expected | Actual | Status |
|----------|--------|--------|
| Account created | Account created | ✅ PASS |
| Redirect to dashboard | Redirected to /dashboard | ✅ PASS |
| Welcome message shown | "Welcome, test@example.com" | ✅ PASS |

**Test Result**: ✅ PASSED
**Duration**: 3.2s
**Screenshots**: 4 captured
```

### Step 3: Handle Failures

When a test fails:

```markdown
## Test Failure: TC-005 - Login with invalid password

### Failure Details
- **Expected**: Error message "Invalid password"
- **Actual**: Generic error "Something went wrong"
- **Screenshot**: `screenshots/TC-005/failure.png`

### Debug Information
```
browser_console_messages
```
Console output:
- [ERROR] Authentication failed: 401
- [WARN] Rate limit approaching

```
browser_network_requests
```
Network:
- POST /api/auth/login → 401 Unauthorized

### Recommended Actions
1. [ ] Check error message mapping
2. [ ] Verify API error response format
3. [ ] Update expected result or fix code

**Bug Report**: Create issue with screenshots attached
```

## Visual Test Report Format

```markdown
# Visual Test Report

## Test Run Information
| Field | Value |
|-------|-------|
| **Run ID** | BTR-2024-01-15-001 |
| **Test Plan** | TP-2024-01-15-001 |
| **Environment** | localhost:3000 |
| **Browser** | Chromium |
| **Date** | 2024-01-15 14:30 UTC |

## Summary

| Status | Count |
|--------|-------|
| ✅ Passed | 24 |
| ❌ Failed | 2 |
| ⏭️ Skipped | 1 |
| **Total** | **27** |

## Test Results with Screenshots

### ✅ TC-001: Successful User Signup

| Step | Description | Screenshot | Status |
|------|-------------|------------|--------|
| 1 | Navigate to /signup | ![Step 1](screenshots/TC-001/01.png) | ✅ |
| 2 | Enter email | ![Step 2](screenshots/TC-001/02.png) | ✅ |
| 3 | Enter password | ![Step 3](screenshots/TC-001/03.png) | ✅ |
| 4 | Click submit | ![Step 4](screenshots/TC-001/04.png) | ✅ |
| 5 | Verify success | ![Step 5](screenshots/TC-001/05.png) | ✅ |

**Duration**: 3.2s | **Result**: PASSED

---

### ❌ TC-005: Login with invalid password

| Step | Description | Screenshot | Status |
|------|-------------|------------|--------|
| 1 | Navigate to /login | ![Step 1](screenshots/TC-005/01.png) | ✅ |
| 2 | Enter email | ![Step 2](screenshots/TC-005/02.png) | ✅ |
| 3 | Enter wrong password | ![Step 3](screenshots/TC-005/03.png) | ✅ |
| 4 | Click submit | ![Step 4](screenshots/TC-005/04.png) | ✅ |
| 5 | Verify error message | ![Step 5](screenshots/TC-005/05-FAIL.png) | ❌ |

**Failure Reason**: Expected "Invalid password", got "Something went wrong"
**Duration**: 2.8s | **Result**: FAILED

---

## Coverage vs Test Plan

| Test Case | Requirement | Automated | Executed | Result |
|-----------|-------------|-----------|----------|--------|
| TC-001 | US-001 | ✅ | ✅ | ✅ Pass |
| TC-002 | US-001 | ✅ | ✅ | ✅ Pass |
| TC-003 | US-001 | ✅ | ✅ | ✅ Pass |
| TC-004 | US-002 | ✅ | ✅ | ✅ Pass |
| TC-005 | US-002 | ✅ | ✅ | ❌ Fail |

## Accessibility Observations

During test execution, accessibility issues detected:

| Page | Issue | Severity | Screenshot |
|------|-------|----------|------------|
| /signup | Missing form label | Serious | ![](a11y/signup-label.png) |
| /login | Low contrast on link | Moderate | ![](a11y/login-contrast.png) |

## Performance Observations

| Page | LCP | FID | CLS | Status |
|------|-----|-----|-----|--------|
| /signup | 1.8s | 45ms | 0.02 | ✅ Good |
| /login | 1.2s | 32ms | 0.01 | ✅ Good |
| /dashboard | 3.1s | 120ms | 0.15 | ⚠️ Needs work |
```

## Testing Patterns

### Pattern: Form Validation

```markdown
## Form Validation Test Pattern

### Valid Input Test
1. Navigate to form
2. Snapshot initial state
3. Fill all fields with valid data
4. Submit
5. Verify success state
6. Capture screenshots at each step

### Invalid Input Test
1. Navigate to form
2. Leave required field empty OR enter invalid data
3. Submit
4. Verify error message appears
5. Verify error is accessible (aria-live)
6. Capture error state screenshot

### Boundary Test
1. Test minimum length
2. Test maximum length
3. Test special characters
4. Capture each state
```

### Pattern: Authentication Flow

```markdown
## Authentication Flow Test Pattern

### Login Flow
1. Navigate to /login
2. Snapshot login form
3. Enter credentials
4. Submit
5. Wait for redirect
6. Verify authenticated state
7. Verify session cookie set

### Logout Flow
1. Click logout button
2. Wait for redirect to login
3. Verify session cleared
4. Verify protected route redirects

### Session Persistence
1. Login
2. Close browser (browser_navigate to about:blank)
3. Navigate back to app
4. Verify still authenticated (if remember me)
```

### Pattern: CRUD Operations

```markdown
## CRUD Test Pattern

### Create
1. Navigate to create form
2. Fill fields
3. Submit
4. Verify item appears in list
5. Screenshot: before, form filled, after creation

### Read
1. Navigate to list view
2. Verify items displayed
3. Click item to view details
4. Verify detail page content
5. Screenshot: list, detail

### Update
1. Navigate to item detail
2. Click edit
3. Modify fields
4. Save
5. Verify changes persisted
6. Screenshot: before edit, during, after

### Delete
1. Navigate to item
2. Click delete
3. Confirm deletion
4. Verify item removed from list
5. Screenshot: before, confirmation, after
```

## Screenshot Management

### Naming Convention

```
screenshots/
├── {test-case-id}/
│   ├── 01-{step-description}.png
│   ├── 02-{step-description}.png
│   └── FAIL-{step-description}.png
├── a11y/
│   └── {page}-{issue}.png
└── visual-regression/
    ├── baseline/
    └── current/
```

### Capturing Screenshots

Since Cursor's browser tools don't have a direct screenshot function, use snapshots and document states:

```markdown
## Screenshot Capture Approach

1. Use `browser_snapshot` to capture page state
2. Document the visual state in markdown
3. For actual screenshots, use browser DevTools or:
   - Playwright: `page.screenshot()`
   - Puppeteer: `page.screenshot()`
   
### Recommended: Generate Playwright Test

From browser test steps, generate runnable Playwright:

```typescript
// tests/e2e/TC-001-signup.spec.ts
import { test, expect } from '@playwright/test';

test('TC-001: Successful user signup', async ({ page }) => {
  // Step 1: Navigate
  await page.goto('/signup');
  await page.screenshot({ path: 'screenshots/TC-001/01-signup-page.png' });
  
  // Step 2: Enter email
  await page.fill('#email', 'test@example.com');
  await page.screenshot({ path: 'screenshots/TC-001/02-email-entered.png' });
  
  // Step 3: Enter password
  await page.fill('#password', 'SecurePass123!');
  await page.screenshot({ path: 'screenshots/TC-001/03-password-entered.png' });
  
  // Step 4: Submit
  await page.click('[data-testid="signup-submit"]');
  
  // Step 5: Verify success
  await expect(page.locator('text=Welcome')).toBeVisible();
  await page.screenshot({ path: 'screenshots/TC-001/04-success.png' });
});
```

## Integration

### With Test Plan

- Reads test cases from test plan
- Executes each case sequentially
- Updates test plan with results
- Links screenshots to test cases

### With Test Automation

- Generates runnable test code
- Creates Playwright/Cypress specs
- Embeds screenshot assertions

### With Pre-Release

- Must pass all critical browser tests
- Visual report attached to release
- Failed tests block deployment

## Commands

| Command | Action |
|---------|--------|
| "Test [feature] in browser" | Execute browser test |
| "Run test plan in browser" | Execute all test cases |
| "Screenshot this flow" | Capture visual evidence |
| "Generate test report" | Create visual report |
| "What failed?" | Show failed test details |

