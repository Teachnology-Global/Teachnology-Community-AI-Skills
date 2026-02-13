---
description: >
  Enforces testing standards including coverage requirements, test patterns, and
  quality guidelines. Ensures code is properly tested before deployment. Use when:
  (1) writing new features, (2) fixing bugs, (3) reviewing test coverage,
  (4) setting up test infrastructure, (5) discussing testing strategy.
globs: ["**/*.test.*", "**/*.spec.*", "**/__tests__/**", "**/test/**"]
alwaysApply: false
---

# Testing Standards

## Purpose

Ensure all code is properly tested with appropriate coverage, clear assertions, and maintainable test suites.

## Activation

This skill activates when you mention:
- "test", "testing", "tests"
- "coverage", "test coverage"
- "unit test", "integration test", "e2e"
- "TDD", "test-driven"
- "mock", "stub", "fixture"

Also activates when:
- Creating new functions/classes
- Fixing bugs (regression tests needed)
- Reviewing PRs

## Coverage Requirements

### Minimum Thresholds

| Environment | Minimum Coverage | Enforce |
|-------------|-----------------|---------|
| Development | 60% | Warn |
| Staging | 80% | Block |
| Production | 80% | Block |

### Coverage Types

| Type | Target | Description |
|------|--------|-------------|
| Line | 80% | Lines executed |
| Branch | 75% | Decision paths taken |
| Function | 90% | Functions called |
| Statement | 80% | Statements executed |

### What to Exclude

```javascript
// jest.config.js or vitest.config.js
coveragePathIgnorePatterns: [
  '/node_modules/',
  '/__tests__/',
  '/__mocks__/',
  '/dist/',
  '*.config.*',
  '*.d.ts',
  'index.ts',  // barrel files
]
```

## Test Types

### Unit Tests (Required)

Test individual functions/classes in isolation.

```typescript
// ✅ Good unit test
describe('calculateTotal', () => {
  it('sums item prices correctly', () => {
    const items = [
      { price: 10, quantity: 2 },
      { price: 5, quantity: 3 }
    ];
    
    expect(calculateTotal(items)).toBe(35);
  });
  
  it('returns 0 for empty array', () => {
    expect(calculateTotal([])).toBe(0);
  });
  
  it('handles decimal prices', () => {
    const items = [{ price: 10.99, quantity: 1 }];
    
    expect(calculateTotal(items)).toBeCloseTo(10.99);
  });
});
```

### Integration Tests (Recommended for APIs)

Test component interactions.

```typescript
// ✅ Good integration test
describe('POST /api/orders', () => {
  it('creates order and updates inventory', async () => {
    const response = await request(app)
      .post('/api/orders')
      .send({ productId: '123', quantity: 2 })
      .expect(201);
    
    expect(response.body.orderId).toBeDefined();
    
    // Verify side effect
    const inventory = await getInventory('123');
    expect(inventory.quantity).toBe(initialQuantity - 2);
  });
});
```

### E2E Tests (Recommended for Web Apps)

Test full user flows.

```typescript
// ✅ Good E2E test
describe('Checkout Flow', () => {
  it('completes purchase successfully', async () => {
    await page.goto('/products');
    await page.click('[data-testid="add-to-cart"]');
    await page.click('[data-testid="checkout"]');
    await page.fill('#email', 'test@example.com');
    await page.fill('#card', '4242424242424242');
    await page.click('[data-testid="place-order"]');
    
    await expect(page.locator('.confirmation')).toBeVisible();
  });
});
```

## Test Patterns

### Arrange-Act-Assert (AAA)

```typescript
// ✅ Clear AAA structure
it('applies discount to order total', () => {
  // Arrange
  const order = createOrder({ subtotal: 100 });
  const discount = createDiscount({ percent: 10 });
  
  // Act
  const result = applyDiscount(order, discount);
  
  // Assert
  expect(result.total).toBe(90);
  expect(result.discountApplied).toBe(true);
});
```

### Given-When-Then (BDD)

```typescript
// ✅ BDD style
describe('given a logged-in user', () => {
  beforeEach(() => {
    login(testUser);
  });
  
  describe('when viewing their profile', () => {
    it('then displays their email', async () => {
      const profile = await getProfile();
      expect(profile.email).toBe(testUser.email);
    });
  });
});
```

### Test Data Builders

```typescript
// ✅ Use builders for complex objects
const testUser = new UserBuilder()
  .withEmail('test@example.com')
  .withRole('admin')
  .build();

// Instead of:
const testUser = {
  id: '123',
  email: 'test@example.com',
  name: 'Test',
  role: 'admin',
  createdAt: new Date(),
  // ... 20 more fields
};
```

## Test Quality Checklist

### Each Test Should

- [ ] Test ONE behavior
- [ ] Have a descriptive name
- [ ] Be independent (no shared state)
- [ ] Be deterministic (same result every run)
- [ ] Be fast (< 100ms for unit tests)
- [ ] Assert meaningful outcomes

### Test Suite Should

- [ ] Cover happy paths
- [ ] Cover edge cases
- [ ] Cover error conditions
- [ ] Have no flaky tests
- [ ] Run in any order
- [ ] Clean up after itself

## Anti-Patterns

### ❌ Bad Test Practices

```typescript
// BAD: Testing implementation details
it('calls processOrder internally', () => {
  const spy = jest.spyOn(service, 'processOrder');
  service.handleOrder(order);
  expect(spy).toHaveBeenCalled();  // Tests HOW, not WHAT
});

// BAD: Multiple assertions testing different things
it('handles order', () => {
  const result = handleOrder(order);
  expect(result.status).toBe('success');
  expect(result.total).toBe(100);
  expect(result.items.length).toBe(3);
  expect(result.shipping).toBeDefined();
  expect(sendEmail).toHaveBeenCalled();  // Too much!
});

// BAD: Non-descriptive test name
it('works', () => { ... });
it('test 1', () => { ... });

// BAD: Shared mutable state
let testData;  // Shared across tests!
beforeEach(() => { testData = { count: 0 }; });
it('increments', () => { testData.count++; });
it('is zero', () => { expect(testData.count).toBe(0); });  // FAILS!

// BAD: Testing third-party code
it('axios makes HTTP requests', () => { ... });  // Not your code
```

### ✅ Good Test Practices

```typescript
// GOOD: Test behavior, not implementation
it('returns order confirmation with total', () => {
  const result = handleOrder(order);
  expect(result.status).toBe('success');
  expect(result.total).toBe(100);
});

// GOOD: Separate test for side effect
it('sends confirmation email after order', () => {
  handleOrder(order);
  expect(emailService.send).toHaveBeenCalledWith(
    expect.objectContaining({ type: 'order-confirmation' })
  );
});

// GOOD: Descriptive name
it('returns error when order has no items', () => { ... });
it('applies 10% discount for orders over $100', () => { ... });

// GOOD: Isolated test data
it('increments count', () => {
  const data = { count: 0 };  // Local to test
  increment(data);
  expect(data.count).toBe(1);
});
```

## Mocking Guidelines

### When to Mock

| Mock | Don't Mock |
|------|------------|
| External APIs | Core business logic |
| Database (in unit tests) | Pure functions |
| Time/dates | Data transformations |
| Random values | The code under test |
| File system | Simple dependencies |
| Network requests | |

### Mocking Examples

```typescript
// ✅ Mock external service
jest.mock('./emailService', () => ({
  send: jest.fn().mockResolvedValue({ sent: true })
}));

// ✅ Mock time
jest.useFakeTimers();
jest.setSystemTime(new Date('2024-01-15'));

// ✅ Mock API response
server.use(
  rest.get('/api/users/:id', (req, res, ctx) => {
    return res(ctx.json({ id: req.params.id, name: 'Test' }));
  })
);
```

## Bug Fix Testing

Every bug fix MUST include a regression test:

```typescript
// 1. Write failing test that reproduces bug
it('handles empty string input without crashing (fixes #123)', () => {
  // This used to throw "Cannot read property of undefined"
  expect(() => processInput('')).not.toThrow();
  expect(processInput('')).toEqual({ valid: false });
});

// 2. Fix the bug
// 3. Test passes
// 4. Bug can never return
```

## Test Report Format

```markdown
## Test Results

**Suite**: [name]
**Date**: [timestamp]
**Duration**: [time]

### Summary
| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Tests Passed | 142/145 | 100% | ⚠️ |
| Line Coverage | 84% | 80% | ✅ |
| Branch Coverage | 78% | 75% | ✅ |
| Function Coverage | 92% | 90% | ✅ |

### Failed Tests
1. `OrderService.test.ts` - "applies discount correctly"
   - Expected: 90
   - Received: 100
   
### Uncovered Lines
- `src/utils/legacy.ts:45-67` - Legacy error handling
- `src/api/webhooks.ts:23-31` - Webhook retry logic

### Recommendations
- [ ] Fix failing discount test
- [ ] Add tests for webhook retry logic
```

## Integration

### With Code Quality

- Coverage checked alongside linting
- Both must pass for PR approval

### With Security Gate

- Security-related code requires tests
- Auth flows must have integration tests

### With Human Approval

- Major test infrastructure changes need approval
- Coverage exceptions require justification

### With Documentation

- Test examples serve as documentation
- API tests document expected behavior

