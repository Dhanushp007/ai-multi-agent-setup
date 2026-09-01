---
name: test-generation
description: Use this skill when asked to write tests, generate a test suite, add unit or integration tests, or improve test coverage — automatically selected for "write tests for this", "add test coverage", or "generate test cases".
license: MIT
---

# Test Generation

## When to Use This Skill

- Writing tests for new or existing code with no or insufficient coverage
- Adding edge-case and error-path tests to an existing suite
- Generating test data factories and mock patterns
- Setting up an integration or E2E test harness
- Improving coverage metrics before a release

---

## Process

### 1. Understand the Code Under Test

Before writing a single test:
- Read the function/class/module signature and docstring
- Identify all inputs, outputs, and side effects
- Trace every code path (branches, loops, early returns, throws)
- Note external dependencies (DB, HTTP, filesystem, time, randomness)

```bash
# Find all exported symbols to test
grep -n "^export " src/module.ts

# Check existing test coverage
npx jest --coverage --collectCoverageFrom="src/module.ts"
python -m pytest --cov=module --cov-report=term-missing
dotnet test /p:CollectCoverage=true
```

### 2. Inventory the Test Cases

For each function, enumerate cases in this order:

| Category | Description | Priority |
|----------|-------------|----------|
| Happy path | Valid inputs, expected outputs | P0 |
| Boundary values | Min, max, zero, empty, one | P0 |
| Invalid inputs | Null, undefined, wrong type, negative | P1 |
| Error paths | Throws, rejects, network failure | P1 |
| Concurrency | Race conditions, parallel calls | P2 |
| Large inputs | Performance at scale | P2 |
| Security | Injection, overflow, path traversal | P1 |

### 3. Choose the Right Test Type

| Type | Use When | Tools |
|------|---------|-------|
| **Unit** | Pure functions, isolated classes | Jest, Pytest, xUnit |
| **Integration** | DB queries, external services | Supertest, pytest-django, EF InMemory |
| **E2E** | Full user flows in a browser | Playwright, Cypress |
| **Contract** | API consumer/provider agreements | Pact |
| **Snapshot** | UI component rendering stability | Jest snapshots, Storybook |

### 4. Set Up Test Infrastructure

#### Node.js / TypeScript
```typescript
// jest.config.ts
export default {
  preset: 'ts-jest',
  testEnvironment: 'node',
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
  coverageThreshold: { global: { lines: 80 } },
};
```

#### Python
```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=src --cov-report=term-missing --cov-fail-under=80"
```

#### .NET
```xml
<!-- Directory.Build.props -->
<PropertyGroup>
  <CollectCoverage>true</CollectCoverage>
  <CoverletOutputFormat>lcov</CoverletOutputFormat>
  <Threshold>80</Threshold>
</PropertyGroup>
```

### 5. Write Unit Tests

Follow the **Arrange – Act – Assert** (AAA) pattern:

```typescript
// TypeScript / Jest
describe('calculateDiscount', () => {
  // Happy path
  it('applies 10% discount to eligible order', () => {
    // Arrange
    const order = { total: 100, memberTier: 'gold' };
    // Act
    const result = calculateDiscount(order);
    // Assert
    expect(result).toBe(90);
  });

  // Boundary
  it('returns original price when total is zero', () => {
    expect(calculateDiscount({ total: 0, memberTier: 'gold' })).toBe(0);
  });

  // Error path
  it('throws when memberTier is invalid', () => {
    expect(() => calculateDiscount({ total: 100, memberTier: 'unknown' }))
      .toThrow('Unknown member tier: unknown');
  });
});
```

```python
# Python / pytest
class TestCalculateDiscount:
    def test_applies_discount_to_eligible_order(self):
        order = Order(total=100, member_tier="gold")
        assert calculate_discount(order) == 90

    def test_returns_zero_for_zero_total(self):
        assert calculate_discount(Order(total=0, member_tier="gold")) == 0

    def test_raises_for_invalid_tier(self):
        with pytest.raises(ValueError, match="Unknown member tier"):
            calculate_discount(Order(total=100, member_tier="unknown"))
```

### 6. Mock External Dependencies

#### Principle: mock at the boundary, not deep inside

```typescript
// Mock HTTP client
jest.mock('../httpClient', () => ({
  get: jest.fn().mockResolvedValue({ data: { id: 1, name: 'Alice' } }),
}));

// Mock DB
jest.mock('../db', () => ({
  users: {
    findUnique: jest.fn().mockResolvedValue({ id: 1, email: 'a@b.com' }),
  },
}));

// Stub time for deterministic tests
jest.useFakeTimers();
jest.setSystemTime(new Date('2024-01-15T00:00:00Z'));
```

```python
# pytest-mock / unittest.mock
def test_send_email(mocker):
    mock_smtp = mocker.patch('myapp.email.smtplib.SMTP')
    send_welcome_email('user@example.com')
    mock_smtp.return_value.__enter__.return_value.sendmail.assert_called_once()
```

### 7. Create Test Data Factories

Avoid brittle `{ id: 1, name: 'test' }` literals — use factories:

```typescript
// TypeScript factory with overrides
function makeUser(overrides: Partial<User> = {}): User {
  return {
    id: crypto.randomUUID(),
    email: `user-${Date.now()}@example.com`,
    name: 'Test User',
    role: 'member',
    createdAt: new Date('2024-01-01'),
    ...overrides,
  };
}

// Usage
const admin = makeUser({ role: 'admin' });
const suspended = makeUser({ suspended: true });
```

```python
# Python dataclass factory
from dataclasses import dataclass, field
import uuid

@dataclass
class UserFactory:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    email: str = field(default_factory=lambda: f"user-{uuid.uuid4().hex[:8]}@example.com")
    role: str = "member"

    def build(self, **overrides):
        data = {k: v for k, v in vars(self).items()}
        data.update(overrides)
        return User(**data)
```

### 8. Write Integration Tests

```typescript
// Supertest + Express
describe('POST /api/users', () => {
  let app: Express;
  let db: TestDatabase;

  beforeAll(async () => { db = await createTestDatabase(); app = createApp(db); });
  afterAll(async () => { await db.destroy(); });
  afterEach(async () => { await db.truncate('users'); });

  it('creates a user and returns 201', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ email: 'new@example.com', password: 'Secret123!' })
      .expect(201);

    expect(res.body).toMatchObject({ email: 'new@example.com' });
    expect(res.body.password).toBeUndefined(); // never returned
  });
});
```

### 9. Write E2E Tests with Playwright

```typescript
// playwright/tests/login.spec.ts
test('user can log in and see dashboard', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('alice@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: 'Sign in' }).click();

  await expect(page).toHaveURL('/dashboard');
  await expect(page.getByRole('heading', { name: 'Welcome, Alice' })).toBeVisible();
});
```

---

## Tools & Resources

- **Jest** (JS/TS): https://jestjs.io/
- **Vitest** (Vite projects): https://vitest.dev/
- **Pytest** (Python): https://pytest.org/
- **xUnit** (.NET): https://xunit.net/
- **Playwright** (E2E): https://playwright.dev/
- **Testing Library**: https://testing-library.com/
- **Faker.js / Faker (Python)**: generate realistic test data

---

## Checklist

- [ ] Reviewed the code under test — all code paths identified
- [ ] Test cases inventoried (happy path, boundary, error, security)
- [ ] Appropriate test type chosen (unit / integration / E2E)
- [ ] Test infrastructure configured (runner, coverage thresholds)
- [ ] Unit tests written with AAA pattern
- [ ] External dependencies mocked at boundaries
- [ ] Test data factories created (no magic literals)
- [ ] Integration tests cover DB/HTTP interactions
- [ ] E2E tests cover critical user flows (if applicable)
- [ ] Coverage threshold met (≥ 80% lines)
- [ ] Tests are deterministic (no flakiness from time/random/order)
- [ ] Test names describe behaviour, not implementation
