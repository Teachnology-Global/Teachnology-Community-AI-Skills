# Testing Workflow Guide

A comprehensive guide to using the integrated testing skills in the Cursor Governance Framework.

---

## Overview

The framework includes three testing skills that work together as an integrated system:

| Skill | Purpose | Triggers |
|-------|---------|----------|
| **Test Plan** | Generate & maintain test plans from PRDs | "test plan", "QA coverage" |
| **Browser Testing** | Execute E2E tests with Cursor @Browser | "test in browser", "E2E test" |
| **Test Automation** | Generate Playwright/Cypress code | "generate tests", "automate" |

---

## How They Work Together

```
┌─────────────────────────────────────────────────────────────────┐
│                    TESTING WORKFLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. PRD Created/Updated                                         │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────┐                                           │
│  │   TEST PLAN     │  ← Extracts requirements                  │
│  │   SKILL         │  ← Generates test cases                   │
│  └────────┬────────┘  ← Creates traceability matrix            │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ TEST AUTOMATION │  ← Generates Playwright/Cypress code      │
│  │     SKILL       │  ← Adds screenshot capture                │
│  └────────┬────────┘  ← Creates test suites                    │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │ BROWSER TESTING │  ← Executes via Cursor @Browser           │
│  │     SKILL       │  ← Captures screenshots at each step      │
│  └────────┬────────┘  ← Generates visual reports               │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │  HUMAN APPROVAL │  ← New feature added                      │
│  │   (triggers)    │                                           │
│  └────────┬────────┘                                           │
│           │                                                     │
│           └──────────► TEST PLAN auto-updates with new cases   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Usage

### Step 1: Generate Test Plan from PRD

When you have a PRD, ask the AI to generate a test plan:

```
You: "Generate a test plan from the PRD"
```

**What happens:**
1. AI parses the PRD to extract requirements
2. Generates test cases for each requirement
3. Creates a traceability matrix
4. Identifies coverage gaps

**Output example:**

```markdown
## Requirements Traceability Matrix

| Req ID | Requirement | Test Cases | Coverage |
|--------|-------------|------------|----------|
| US-001 | User can sign up | TC-001, TC-002, TC-003 | ✅ Full |
| US-002 | User can log in | TC-004, TC-005 | ✅ Full |
| FR-001 | Password min 8 chars | TC-006 | ✅ Full |

## Generated Test Cases

### TC-001: Successful user signup
- **Requirement**: US-001
- **Priority**: Critical
- **Steps**:
  1. Navigate to /signup
  2. Enter valid email
  3. Enter valid password
  4. Click submit
  5. Verify success message
```

---

### Step 2: Generate Automated Tests

Once you have a test plan, generate runnable test code:

```
You: "Generate Playwright tests for the signup feature"
```

**What happens:**
1. AI reads test cases from the test plan
2. Generates Playwright (or Cypress) test code
3. Includes screenshot capture at every step
4. Creates proper test structure

**Output example:**

```typescript
// tests/e2e/signup.spec.ts
import { test, expect } from '@playwright/test';

test.describe('User Signup', () => {
  
  test('TC-001: Successful signup with valid credentials', async ({ page }) => {
    
    // Step 1: Navigate to signup page
    await test.step('Navigate to signup', async () => {
      await page.goto('/signup');
      await page.screenshot({ 
        path: 'test-results/TC-001/01-signup-page.png',
        fullPage: true 
      });
    });

    // Step 2: Enter email
    await test.step('Enter email', async () => {
      await page.fill('#email', 'test@example.com');
      await page.screenshot({ 
        path: 'test-results/TC-001/02-email-entered.png' 
      });
    });

    // Step 3: Enter password
    await test.step('Enter password', async () => {
      await page.fill('#password', 'SecurePass123!');
      await page.screenshot({ 
        path: 'test-results/TC-001/03-password-entered.png' 
      });
    });

    // Step 4: Submit form
    await test.step('Submit form', async () => {
      await page.click('[data-testid="signup-submit"]');
    });

    // Step 5: Verify success
    await test.step('Verify success', async () => {
      await expect(page.locator('text=Welcome')).toBeVisible();
      await page.screenshot({ 
        path: 'test-results/TC-001/04-success.png' 
      });
    });
  });
});
```

---

### Step 3: Execute Tests with Browser Testing

For quick validation or debugging, use Cursor's built-in browser:

```
You: "Test the signup flow in browser"
```

**What happens:**
1. AI uses Cursor @Browser tools to execute the test
2. Captures page state at each step
3. Takes screenshots for documentation
4. Reports pass/fail with evidence

**Example execution:**

```markdown
## Executing: TC-001 - Successful User Signup

**Step 1: Navigate to signup page**
```
browser_navigate: http://localhost:3000/signup
```
📸 Screenshot: `screenshots/TC-001/01-signup-page.png`
✅ Page loaded successfully

**Step 2: Enter email**
```
browser_type: 
  element: "Email input"
  ref: "#email"
  text: "test@example.com"
```
📸 Screenshot: `screenshots/TC-001/02-email-entered.png`
✅ Email entered

**Step 3: Enter password**
```
browser_type:
  element: "Password input"  
  ref: "#password"
  text: "SecurePass123!"
```
📸 Screenshot: `screenshots/TC-001/03-password-entered.png`
✅ Password entered

**Step 4: Submit form**
```
browser_click:
  element: "Sign Up button"
  ref: "[data-testid='signup-submit']"
```
✅ Form submitted

**Step 5: Verify success**
```
browser_wait_for:
  text: "Welcome"
```
📸 Screenshot: `screenshots/TC-001/04-success.png`
✅ Welcome message displayed

---
**Result: ✅ PASSED**
**Duration: 3.2s**
**Screenshots: 4 captured**
```

---

### Step 4: Auto-Update When Features Change

When Human-in-the-Loop approves a new feature, the test plan updates automatically:

```
You: "Add a 'Remember me' checkbox to the login form"

AI: "🛑 Human Approval Required
[Options presented...]"

You: "Approved - go with option 1"

AI: "✅ Feature approved. Updating test plan...

## Test Plan Update

**New Requirement Added:**
- FR-010: 'Remember me' extends session to 30 days

**New Test Cases Generated:**
- TC-030: Login with 'remember me' checked
- TC-031: Login with 'remember me' unchecked  
- TC-032: Session persists after browser restart
- TC-033: Session expires on browser close

**Traceability Matrix Updated:**
| FR-010 | Remember me | TC-030 to TC-033 | ✅ Covered |

**Browser Tests Queued:**
- [ ] Generate automated tests for TC-030 to TC-033
"
```

---

## Integration Points

### With Other Governance Skills

| When This Happens | These Skills React |
|-------------------|-------------------|
| PRD created | **Test Plan** generates test cases |
| Human Approval adds feature | **Test Plan** auto-adds new cases |
| "Test this flow" | **Browser Testing** executes E2E |
| "Generate tests" | **Test Automation** creates code |
| Pre-release check | Tests must pass, coverage verified |
| Accessibility issue found | **Browser Testing** flags in report |

### With Pre-Release Gate

Before any release:
- All critical test cases must pass
- Test coverage must meet threshold (default: 80%)
- Visual test report attached to release
- Failed tests block deployment

---

## Visual Test Report

After test execution, a visual report is generated:

```markdown
# Visual Test Report

## Summary
| Status | Count |
|--------|-------|
| ✅ Passed | 24 |
| ❌ Failed | 2 |
| ⏭️ Skipped | 1 |

## Test Results with Screenshots

### ✅ TC-001: Successful User Signup

| Step | Screenshot | Status |
|------|------------|--------|
| Navigate to /signup | ![](screenshots/TC-001/01.png) | ✅ |
| Enter email | ![](screenshots/TC-001/02.png) | ✅ |
| Enter password | ![](screenshots/TC-001/03.png) | ✅ |
| Submit form | ![](screenshots/TC-001/04.png) | ✅ |
| Verify success | ![](screenshots/TC-001/05.png) | ✅ |

**Duration**: 3.2s | **Result**: PASSED

---

### ❌ TC-005: Login with invalid password

| Step | Screenshot | Status |
|------|------------|--------|
| Navigate to /login | ![](screenshots/TC-005/01.png) | ✅ |
| Enter wrong password | ![](screenshots/TC-005/02.png) | ✅ |
| Verify error message | ![](screenshots/TC-005/03-FAIL.png) | ❌ |

**Failure**: Expected "Invalid password", got "Something went wrong"
**Duration**: 2.8s | **Result**: FAILED
```

---

## Quick Reference

### Commands

| Say This | What Happens |
|----------|--------------|
| "Generate test plan from PRD" | Creates test cases from requirements |
| "Update test plan" | Syncs with PRD changes |
| "Show test coverage" | Displays coverage report |
| "Generate Playwright tests" | Creates automated test code |
| "Test [feature] in browser" | Executes E2E test with screenshots |
| "Run test plan in browser" | Executes all test cases |
| "What's not tested?" | Lists uncovered requirements |

### File Locations

| File | Purpose |
|------|---------|
| `docs/test-plans/` | Test plan documents |
| `tests/e2e/` | Automated test files |
| `test-results/` | Screenshots and reports |
| `templates/test-plan-template.md` | Test plan template |

### Browser Tools Available

| Tool | Purpose |
|------|---------|
| `browser_navigate` | Go to URL |
| `browser_snapshot` | Capture page state |
| `browser_click` | Click element |
| `browser_type` | Enter text |
| `browser_hover` | Hover over element |
| `browser_select_option` | Select dropdown |
| `browser_press_key` | Press key |
| `browser_wait_for` | Wait for text/element |
| `browser_console_messages` | Get console output |
| `browser_network_requests` | Get network activity |

---

## Best Practices

### 1. Start with the PRD
Always generate test plans from the PRD to ensure requirements traceability.

### 2. Keep Test Plans Updated
When features change through Human Approval, let the test plan auto-update.

### 3. Screenshot Everything
Visual evidence helps with debugging and serves as documentation.

### 4. Run Before Release
Include test execution in your pre-release checklist.

### 5. Review Failed Tests
Don't ignore failures - they often catch real bugs.

---

## Example Workflow: New Feature

```
1. Product creates PRD for "User Profile" feature

2. You: "Generate test plan from the PRD"
   → Test Plan skill creates TC-050 to TC-065

3. You: "Generate Playwright tests for user profile"
   → Test Automation skill creates tests/e2e/profile.spec.ts

4. You: "Test the profile page in browser"
   → Browser Testing skill executes and captures screenshots

5. You: "Add avatar upload to user profile"
   AI: "🛑 Human Approval Required..."
   You: "Approved"
   → Test Plan auto-adds TC-066 to TC-070 for avatar upload

6. You: "Ready for release"
   → Pre-Release skill runs all tests, verifies coverage
   → Visual report attached to release
```

---

## Troubleshooting

### "Test plan not generating"
- Ensure PRD is in recognized format
- Check that requirements are clearly stated
- Try: "Extract requirements from this PRD first"

### "Browser tests failing"
- Verify dev server is running
- Check element selectors are correct
- Use `browser_snapshot` to debug page state

### "Screenshots not capturing"
- For Cursor @Browser: screenshots are documented, not saved as files
- For Playwright: check `test-results/` directory
- Verify write permissions

### "Coverage not updating"
- Re-run: "Update test plan"
- Check test case IDs match
- Verify traceability matrix

---

*Part of the Cursor Governance Framework*

