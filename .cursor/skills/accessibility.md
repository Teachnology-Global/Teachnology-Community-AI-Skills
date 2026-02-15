---
description: >
  Validates WCAG 2.2 Level AA compliance for web interfaces. Checks semantic HTML,
  ARIA attributes, colour contrast, keyboard navigation, and screen reader compatibility.
  Use when: (1) building user interfaces, (2) conducting accessibility audits,
  (3) reviewing PRs for a11y compliance, (4) fixing accessibility issues,
  (5) implementing accessible components. Updated for 2026 compliance deadlines.
globs: ["**/*.html", "**/*.tsx", "**/*.jsx", "**/*.vue", "**/*.svelte"]
alwaysApply: false
---

# Accessibility

## Purpose

Ensure web interfaces are usable by everyone, including people with disabilities. Target WCAG 2.2 Level AA compliance (current standard as of 2026, with federal compliance deadlines in April 2026).

## Activation

This skill activates when you mention:
- "accessibility", "a11y"
- "WCAG", "screen reader"
- "keyboard navigation", "focus"
- "colour contrast", "alt text"
- "ARIA", "semantic HTML"

Also activates when working on:
- UI components
- Forms
- Navigation
- Modals/dialogs
- Interactive widgets

## WCAG 2.2 Principles (POUR)

| Principle | Meaning | Key Checks |
|-----------|---------|------------|
| **Perceivable** | Can users perceive the content? | Alt text, contrast, captions, focus appearance |
| **Operable** | Can users operate the interface? | Keyboard, focus, timing, drag operations |
| **Understandable** | Can users understand it? | Labels, errors, consistency, help text |
| **Robust** | Does it work with assistive tech? | Valid HTML, ARIA, status messages |

### WCAG 2.2 New Success Criteria (Required)

| Level | Criterion | Description |
|-------|-----------|-------------|
| **AA** | **2.4.11 Focus Not Obscured (Minimum)** | When element receives keyboard focus, it's not entirely hidden |
| **AA** | **2.4.12 Focus Not Obscured (Enhanced)** | No part of focused element is hidden by author-created content |
| **AA** | **2.5.7 Dragging Movements** | All drag functionality has single pointer alternative |
| **AA** | **2.5.8 Target Size (Minimum)** | Interactive targets minimum 24×24 CSS pixels |
| **AA** | **3.2.6 Consistent Help** | Help mechanism in consistent order across pages |
| **AA** | **3.3.7 Redundant Entry** | Don't require re-entering information already provided |
| **AA** | **3.3.8 Accessible Authentication (Minimum)** | No cognitive tests for authentication |

## Critical Checklist

Must pass before deployment:

### Images & Media
- [ ] All images have `alt` attributes
- [ ] Decorative images have `alt=""`
- [ ] Videos have captions
- [ ] Audio has transcripts

### Structure
- [ ] Page has single `<h1>`
- [ ] Headings in logical order (h1→h2→h3)
- [ ] Landmarks used (`<main>`, `<nav>`, `<aside>`)
- [ ] Lists use proper elements (`<ul>`, `<ol>`)

### Forms
- [ ] All inputs have associated `<label>`
- [ ] Required fields marked programmatically
- [ ] Error messages identify the field
- [ ] Error messages suggest correction

### Keyboard
- [ ] All functionality via keyboard
- [ ] Visible focus indicator
- [ ] Logical tab order
- [ ] No keyboard traps

### Color
- [ ] Text contrast: 4.5:1 minimum
- [ ] Large text: 3:1 minimum
- [ ] Not sole means of conveying info

## Component Patterns

### Images

```html
<!-- Informative image -->
<img src="chart.png" alt="Sales increased 25% from Q1 to Q2">

<!-- Decorative image -->
<img src="decoration.svg" alt="" role="presentation">

<!-- Complex image with long description -->
<figure>
  <img src="infographic.png" alt="2024 market analysis">
  <figcaption>
    Full description of the infographic contents...
  </figcaption>
</figure>
```

### Buttons & Links

```html
<!-- Button with visible text -->
<button>Submit Form</button>

<!-- Icon button - needs accessible name -->
<button aria-label="Close dialog">
  <svg aria-hidden="true"><!-- icon --></svg>
</button>

<!-- Link that opens new window -->
<a href="/doc.pdf" target="_blank">
  User Guide (PDF, opens in new tab)
</a>
```

### Forms

```html
<form>
  <div class="field">
    <label for="email">Email address</label>
    <input 
      type="email" 
      id="email"
      required
      aria-describedby="email-hint email-error"
    >
    <p id="email-hint" class="hint">We'll never share your email</p>
    <p id="email-error" class="error" role="alert" hidden>
      Please enter a valid email address
    </p>
  </div>
  
  <button type="submit">Subscribe</button>
</form>
```

### Skip Link

```html
<body>
  <a href="#main-content" class="skip-link">
    Skip to main content
  </a>
  
  <header><!-- nav etc --></header>
  
  <main id="main-content">
    <!-- page content -->
  </main>
</body>

<style>
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  padding: 8px;
  background: #000;
  color: #fff;
  z-index: 100;
}
.skip-link:focus {
  top: 0;
}
</style>
```

### Modal Dialog

```html
<div 
  role="dialog" 
  aria-modal="true" 
  aria-labelledby="dialog-title"
  aria-describedby="dialog-desc"
>
  <h2 id="dialog-title">Confirm Deletion</h2>
  <p id="dialog-desc">This action cannot be undone.</p>
  
  <div class="actions">
    <button type="button">Cancel</button>
    <button type="button" class="danger">Delete</button>
  </div>
</div>
```

**Dialog requirements:**
- Focus moves to dialog when opened
- Focus trapped inside dialog
- Escape key closes dialog
- Focus returns to trigger on close

### Tab Panel

```html
<div class="tabs">
  <div role="tablist" aria-label="Account settings">
    <button 
      role="tab" 
      id="tab-1"
      aria-selected="true" 
      aria-controls="panel-1"
    >
      Profile
    </button>
    <button 
      role="tab" 
      id="tab-2"
      aria-selected="false" 
      aria-controls="panel-2"
      tabindex="-1"
    >
      Security
    </button>
  </div>
  
  <div role="tabpanel" id="panel-1" aria-labelledby="tab-1">
    Profile content...
  </div>
  <div role="tabpanel" id="panel-2" aria-labelledby="tab-2" hidden>
    Security content...
  </div>
</div>
```

**Keyboard interaction:**
- Arrow keys move between tabs
- Tab key moves into panel
- Home/End go to first/last tab

### Live Regions

```html
<!-- Polite - waits for silence -->
<div aria-live="polite" aria-atomic="true">
  3 items in cart
</div>

<!-- Assertive - interrupts -->
<div role="alert">
  Error: Payment failed. Please try again.
</div>

<!-- Status update -->
<div role="status">
  Saving...
</div>
```

## Focus Management

### Visible Focus

```css
/* Always provide visible focus */
:focus {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}

/* Enhanced for focus-visible (keyboard only) */
:focus:not(:focus-visible) {
  outline: none;
}
:focus-visible {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}
```

### Focus Order

- Tab order should follow visual order
- Use `tabindex="0"` to make elements focusable
- Use `tabindex="-1"` for programmatic focus only
- Never use `tabindex` > 0

### Managing Focus

```javascript
// Move focus to new content
function showModal(modal) {
  modal.hidden = false;
  modal.querySelector('h2').focus();
}

// Return focus when closing
function closeModal(modal, trigger) {
  modal.hidden = true;
  trigger.focus();
}
```

## Colour Contrast

### Requirements

| Element | Minimum Ratio |
|---------|---------------|
| Normal text (< 18pt) | 4.5:1 |
| Large text (≥ 18pt or 14pt bold) | 3:1 |
| UI components | 3:1 |
| Non-text graphics | 3:1 |

### Testing

```css
/* Check these combinations */
body {
  /* Light theme */
  background: #ffffff;
  color: #333333; /* 12.6:1 ✅ */
}

.muted {
  color: #767676; /* 4.5:1 ✅ exactly minimum */
}

.error {
  color: #d32f2f; /* Check on your background */
}
```

## Testing Approach

### Automated (Catches ~30-40%)

```javascript
// Jest + axe-core
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('component is accessible', async () => {
  const { container } = render(<MyComponent />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

### Manual Testing Required

| Test | How |
|------|-----|
| Keyboard nav | Tab through everything |
| Focus order | Does it make sense? |
| Screen reader | Test with VoiceOver/NVDA |
| Zoom | Works at 200%? |
| Colour only | Info without colour? |

## 2026 Compliance Requirements

**Federal Deadlines:**
- **April 24, 2026**: ADA Title II compliance for state/local government (population 50,000+)
- **Late 2026**: WCAG 2.2 becomes ISO/IEC 40500:2026 standard
- **Ongoing**: EU Accessibility Act, WCAG 2.2 AA expected

**Target Standard**: WCAG 2.2 Level AA (backward compatible with 2.1)

## Accessibility Report

```markdown
## Accessibility Audit

**Date**: [timestamp]
**Standard**: WCAG 2.2 Level AA

### Summary
| Severity | Count |
|----------|-------|
| Critical | 0 |
| Serious | 2 |
| Moderate | 5 |
| Minor | 3 |

### Serious Issues

#### Missing form labels
- **Element**: `<input type="text" name="search">`
- **Location**: Header search
- **Impact**: Screen readers can't identify field
- **Fix**: Add `<label for="search">Search</label>`

### Testing Completed
- [x] Automated (axe-core)
- [x] Keyboard navigation
- [x] Screen reader (VoiceOver)
- [x] Colour contrast
- [ ] User testing with disabilities
```

## Integration

### With Security Gate

- Accessibility audit runs before deployment
- Serious issues block deployment
- Report included in release notes

### With Human Approval

- Novel UI patterns require approval
- Accessibility exceptions documented
- Trade-offs acknowledged

### With Documentation

- Accessible component patterns documented
- Keyboard shortcuts documented
- Screen reader behaviour documented

