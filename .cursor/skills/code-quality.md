---
description: >
  Enforces code quality standards including linting, complexity limits, formatting,
  and maintainability metrics. Prevents technical debt accumulation. Use when:
  (1) reviewing code changes, (2) setting up new projects, (3) refactoring code,
  (4) establishing team standards, (5) addressing tech debt.
globs: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "**/*.py", "**/*.go", "**/*.java", "**/*.cs"]
alwaysApply: true
---

# Code Quality

## Purpose

Maintain high code quality standards to reduce bugs, improve maintainability, and prevent technical debt accumulation.

## Activation

This skill is **always active** during code changes. It also activates explicitly when you mention:
- "code quality", "code review"
- "linting", "lint errors"
- "refactor", "clean up"
- "complexity", "maintainability"
- "tech debt", "code smell"

## Quality Gates

### Must Pass Before Commit

| Check | Threshold | Action if Failed |
|-------|-----------|------------------|
| Linting | Zero errors | Block |
| Type errors | Zero errors | Block |
| Complexity | Cyclomatic ≤ 10 | Block |
| Test coverage | ≥ 80% | Warn/Block (configurable) |
| Security | No high/critical | Block |

### Complexity Limits

| Metric | Limit | Why |
|--------|-------|-----|
| Cyclomatic complexity | ≤ 10 per function | Testability |
| Cognitive complexity | ≤ 15 per function | Readability |
| File length | ≤ 500 lines | Maintainability |
| Function length | ≤ 50 lines | Single responsibility |
| Parameters | ≤ 5 per function | Interface simplicity |
| Nesting depth | ≤ 4 levels | Readability |

## Linting Standards

### JavaScript/TypeScript

```json
// Recommended ESLint config extends
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking"
  ],
  "rules": {
    "no-console": "warn",
    "no-debugger": "error",
    "no-unused-vars": "error",
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/explicit-function-return-type": "warn"
  }
}
```

### Python

```toml
# pyproject.toml - Ruff configuration
[tool.ruff]
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "UP",  # pyupgrade
    "S",   # bandit (security)
]
line-length = 100
target-version = "py311"
```

### Go

```yaml
# .golangci.yml
linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - typecheck
    - unused
    - gocyclo
    - gofmt
    - misspell
```

## Code Patterns

### ✅ Good Patterns

```typescript
// Clear naming
function calculateOrderTotal(items: OrderItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// Single responsibility
class OrderValidator {
  validate(order: Order): ValidationResult {
    return this.validateItems(order.items)
      .chain(() => this.validateCustomer(order.customer))
      .chain(() => this.validatePayment(order.payment));
  }
}

// Early returns reduce nesting
function processUser(user: User | null): Result {
  if (!user) return Result.error('User not found');
  if (!user.isActive) return Result.error('User inactive');
  if (!user.hasPermission) return Result.error('Permission denied');
  
  return Result.ok(user.process());
}

// Descriptive error handling
async function fetchUserData(id: string): Promise<User> {
  try {
    const response = await api.get(`/users/${id}`);
    return response.data;
  } catch (error) {
    if (error instanceof NotFoundError) {
      throw new UserNotFoundError(id);
    }
    throw new UserFetchError(id, error);
  }
}
```

### ❌ Bad Patterns

```typescript
// Cryptic naming
function calc(x: any[]): number {
  return x.reduce((a, b) => a + b.p * b.q, 0);
}

// God function - does too much
function processOrder(order: any) {
  // validate
  // calculate totals
  // apply discounts
  // check inventory
  // process payment
  // send notifications
  // update analytics
  // ... 500 more lines
}

// Deep nesting
function process(data) {
  if (data) {
    if (data.items) {
      for (const item of data.items) {
        if (item.valid) {
          if (item.type === 'special') {
            // logic buried 5 levels deep
          }
        }
      }
    }
  }
}

// Swallowing errors
try {
  await riskyOperation();
} catch (e) {
  // silently ignored - BAD
}
```

## Refactoring Triggers

Automatically suggest refactoring when detecting:

| Pattern | Trigger | Suggested Action |
|---------|---------|------------------|
| Long function | > 50 lines | Extract methods |
| Deep nesting | > 4 levels | Early returns, extract |
| Large file | > 500 lines | Split into modules |
| Duplicate code | > 3 occurrences | Extract to shared function |
| Complex conditional | > 3 conditions | Extract to named function |
| Magic numbers | Literals in logic | Extract to constants |
| Long parameter list | > 5 params | Use options object |

## Code Smell Detection

Flag these patterns for review:

### Naming Issues
- Single-letter variables (except loop indices)
- Abbreviations without context
- Generic names (`data`, `info`, `temp`, `result`)
- Inconsistent naming conventions

### Structure Issues
- Functions with boolean parameters (split into two functions)
- Classes with "Manager", "Handler", "Processor" suffix (often too broad)
- Deeply nested callbacks (use async/await)
- Mutable global state

### Comment Smells
- TODO/FIXME without issue reference
- Commented-out code
- Comments explaining what (should be obvious from code)
- Outdated comments

## Quality Report Format

```markdown
## Code Quality Report

**File**: [path]
**Date**: [timestamp]

### Summary
| Metric | Value | Limit | Status |
|--------|-------|-------|--------|
| Cyclomatic Complexity | 8 | 10 | ✅ |
| Cognitive Complexity | 12 | 15 | ✅ |
| Lines of Code | 245 | 500 | ✅ |
| Lint Errors | 0 | 0 | ✅ |
| Type Errors | 0 | 0 | ✅ |

### Issues Found

#### [Severity]: [Issue Type]
- **Location**: file.ts:42
- **Description**: [what's wrong]
- **Suggestion**: [how to fix]

### Recommendations
- [ ] Consider extracting `processData` function (45 lines)
- [ ] Add explicit return type to `calculateTotal`
```

## Integration

### With Security Gate

- Quality checks run before security scans
- Both must pass for deployment approval

### With Human Approval

- Complexity violations trigger review request
- Major refactoring requires approval

### With Documentation

- API changes require doc updates
- Complex logic should have explanatory comments

### With Testing

- New code requires test coverage
- Refactoring must not reduce coverage

## Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: lint
        name: Lint
        entry: npm run lint
        language: system
        pass_filenames: false
        
      - id: typecheck
        name: Type Check
        entry: npm run typecheck
        language: system
        pass_filenames: false
        
      - id: complexity
        name: Complexity Check
        entry: npx eslint --rule 'complexity: [error, 10]'
        language: system
        types: [javascript, typescript]
```

## IDE Integration

### VS Code Settings

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.organizeImports": true
  },
  "eslint.validate": ["javascript", "typescript", "typescriptreact"]
}
```

## Exceptions

Document exceptions in code:

```typescript
// eslint-disable-next-line complexity -- [ISSUE-123] Legacy code, refactor planned Q2
function legacyComplexFunction() {
  // ... complex but documented
}
```

All exceptions require:
1. Issue ticket reference
2. Planned remediation
3. Code review approval

