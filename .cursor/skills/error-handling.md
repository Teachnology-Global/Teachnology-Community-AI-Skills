---
description: >
  Ensures robust error handling throughout applications with proper error boundaries,
  user-friendly messages, logging, and graceful degradation. Critical for maintaining
  good user experience when things go wrong and debugging issues in production.
  Use when: (1) handling API failures, (2) implementing try-catch blocks, (3) building
  error boundaries, (4) designing user feedback, (5) setting up error monitoring.
globs: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "**/*.py", "**/*.go"]
alwaysApply: false
---

# Error Handling Standards

## Purpose

Prevent crashes, provide meaningful feedback to users, and enable fast debugging when things go wrong. Good error handling is what separates professional applications from prototypes.

## Activation

This skill activates when you mention:
- "error", "exception", "try-catch", "error handling"
- "crash", "failure", "fallback", "graceful degradation" 
- "logging", "monitoring", "debugging"
- "error boundary", "error message", "user feedback"
- "validation", "form error", "API failure"

Also activates when working on:
- API integration code
- Form validation
- Async operations
- User-facing features

## The Error Handling Hierarchy

### 1. Prevent Errors (Best)
```typescript
// Input validation prevents bad data
function calculateDiscount(price: number, percentage: number): number {
  if (price < 0) throw new Error('Price cannot be negative');
  if (percentage < 0 || percentage > 100) throw new Error('Percentage must be 0-100');
  
  return price * (percentage / 100);
}

// Type safety prevents runtime errors  
interface User {
  id: string;
  email: string;
  name: string;
}

// Never access properties that might not exist
function getDisplayName(user: User | null): string {
  return user?.name || 'Anonymous User';
}
```

### 2. Handle Expected Errors (Good)
```typescript
// API calls can fail - plan for it
async function fetchUser(id: string): Promise<User | null> {
  try {
    const response = await fetch(`/api/users/${id}`);
    
    if (!response.ok) {
      if (response.status === 404) {
        return null; // User not found is expected
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    return await response.json();
  } catch (error) {
    // Log for debugging but don't crash the app
    console.error('Failed to fetch user:', error);
    throw error; // Re-throw so caller can decide what to do
  }
}
```

### 3. Catch Unexpected Errors (Necessary)
```typescript
// Global error boundaries prevent white screens
class ErrorBoundary extends React.Component {
  state = { hasError: false, error: null };
  
  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }
  
  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log to error tracking service
    console.error('React error boundary caught:', error, errorInfo);
    
    // Report to error tracking (Sentry, LogRocket, etc.)
    if (typeof window !== 'undefined') {
      // Only in browser
      window.reportError?.(error);
    }
  }
  
  render() {
    if (this.state.hasError) {
      return (
        <div className="error-fallback">
          <h2>Something went wrong</h2>
          <p>We've been notified and are working on a fix.</p>
          <button onClick={() => window.location.reload()}>
            Refresh Page
          </button>
        </div>
      );
    }
    
    return this.props.children;
  }
}
```

## User-Friendly Error Messages

### The Error Message Hierarchy

| Level | Audience | Example | When to Use |
|-------|----------|---------|-------------|
| **User** | End users | "Your email address is already in use" | Always show users |
| **Developer** | Your team | "ValidationError: email uniqueness constraint failed" | Logs only |
| **Technical** | Support/debug | "INSERT INTO users (email) VALUES ('test@example.com') - ERROR 1062 (23000)" | Debug logs only |

### Good vs Bad Error Messages

```typescript
// ❌ Bad: Technical jargon, no help
"Uncaught TypeError: Cannot read property 'map' of undefined"

// ✅ Good: Clear problem + solution
"No search results found. Try different keywords or check your spelling."

// ❌ Bad: Vague, scary
"An error occurred"  

// ✅ Good: Specific, actionable
"Your password must contain at least 8 characters, including one number and one uppercase letter."

// ❌ Bad: Blaming the user
"You entered an invalid email address"

// ✅ Good: Helpful, constructive  
"Please enter a valid email address like name@example.com"
```

### Error Message Component

```typescript
interface ErrorMessageProps {
  title?: string;
  message: string;
  action?: {
    label: string;
    onClick: () => void;
  };
  severity?: 'error' | 'warning' | 'info';
}

export function ErrorMessage({ 
  title = 'Something went wrong', 
  message, 
  action,
  severity = 'error' 
}: ErrorMessageProps) {
  const icons = {
    error: '⚠️',
    warning: '⚡',
    info: 'ℹ️'
  };
  
  return (
    <div className={`error-message error-message--${severity}`}>
      <div className="error-message__icon">
        {icons[severity]}
      </div>
      <div className="error-message__content">
        <h3 className="error-message__title">{title}</h3>
        <p className="error-message__message">{message}</p>
        {action && (
          <button 
            className="error-message__action"
            onClick={action.onClick}
          >
            {action.label}
          </button>
        )}
      </div>
    </div>
  );
}

// Usage examples
<ErrorMessage 
  message="Please check your internet connection and try again."
  action={{ label: 'Retry', onClick: retryFunction }}
/>

<ErrorMessage 
  title="Email already exists"
  message="An account with this email address already exists. Try signing in instead."
  action={{ label: 'Sign In', onClick: () => router.push('/login') }}
/>
```

## Form Validation Patterns

### Real-time Validation

```typescript
interface FormErrors {
  [field: string]: string | undefined;
}

function useFormValidation<T>(validationRules: ValidationRules<T>) {
  const [errors, setErrors] = useState<FormErrors>({});
  
  const validateField = (name: keyof T, value: any): string | undefined => {
    const rules = validationRules[name];
    if (!rules) return undefined;
    
    for (const rule of rules) {
      const error = rule(value);
      if (error) return error;
    }
    
    return undefined;
  };
  
  const validate = (data: T): boolean => {
    const newErrors: FormErrors = {};
    let hasErrors = false;
    
    Object.keys(validationRules).forEach(field => {
      const error = validateField(field as keyof T, data[field as keyof T]);
      if (error) {
        newErrors[field] = error;
        hasErrors = true;
      }
    });
    
    setErrors(newErrors);
    return !hasErrors;
  };
  
  return { errors, validateField, validate };
}

// Validation rules
const userValidation = {
  email: [
    (value: string) => !value ? 'Email is required' : undefined,
    (value: string) => !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value) 
      ? 'Please enter a valid email address' : undefined
  ],
  password: [
    (value: string) => !value ? 'Password is required' : undefined,
    (value: string) => value.length < 8 
      ? 'Password must be at least 8 characters' : undefined,
    (value: string) => !/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(value)
      ? 'Password must contain uppercase, lowercase, and number' : undefined
  ]
};

// Usage in form
function SignUpForm() {
  const [formData, setFormData] = useState({ email: '', password: '' });
  const { errors, validateField, validate } = useFormValidation(userValidation);
  
  const handleChange = (name: string, value: string) => {
    setFormData(prev => ({ ...prev, [name]: value }));
    
    // Validate on blur or after user stops typing
    setTimeout(() => validateField(name, value), 300);
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validate(formData)) {
      return; // Don't submit if validation fails
    }
    
    try {
      await createUser(formData);
    } catch (error) {
      // Handle server errors
      if (error.status === 409) {
        setErrors({ email: 'An account with this email already exists' });
      } else {
        setErrors({ _form: 'Failed to create account. Please try again.' });
      }
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <div>
        <input 
          type="email"
          value={formData.email}
          onChange={e => handleChange('email', e.target.value)}
          className={errors.email ? 'error' : ''}
        />
        {errors.email && <span className="field-error">{errors.email}</span>}
      </div>
      
      <div>
        <input 
          type="password"
          value={formData.password}
          onChange={e => handleChange('password', e.target.value)}
          className={errors.password ? 'error' : ''}
        />
        {errors.password && <span className="field-error">{errors.password}</span>}
      </div>
      
      {errors._form && <ErrorMessage message={errors._form} />}
      
      <button type="submit">Create Account</button>
    </form>
  );
}
```

## API Error Handling

### Standardized Error Response

```typescript
// Define consistent error structure
interface APIError {
  code: string;
  message: string;
  details?: Record<string, any>;
  timestamp: string;
  requestId: string;
}

// Create error classes
class APIException extends Error {
  constructor(
    public code: string,
    message: string,
    public details?: Record<string, any>,
    public statusCode: number = 500
  ) {
    super(message);
    this.name = 'APIException';
  }
}

// Express.js error handler
const errorHandler = (err: Error, req: Request, res: Response, next: NextFunction) => {
  const requestId = req.headers['x-request-id'] || crypto.randomUUID();
  
  // Log the full error for debugging
  console.error(`[${requestId}] ${err.name}: ${err.message}`, {
    stack: err.stack,
    url: req.url,
    method: req.method,
    userAgent: req.get('User-Agent')
  });
  
  // Send appropriate response to client
  if (err instanceof APIException) {
    const errorResponse: APIError = {
      code: err.code,
      message: err.message,
      details: err.details,
      timestamp: new Date().toISOString(),
      requestId
    };
    
    return res.status(err.statusCode).json({ error: errorResponse });
  }
  
  // Don't leak internal errors to client
  const genericError: APIError = {
    code: 'INTERNAL_ERROR',
    message: 'An unexpected error occurred. Please try again later.',
    timestamp: new Date().toISOString(),
    requestId
  };
  
  res.status(500).json({ error: genericError });
};

// Usage in route handlers
app.post('/api/users', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    
    // Validate input
    if (!email) {
      throw new APIException('VALIDATION_ERROR', 'Email is required', { field: 'email' }, 400);
    }
    
    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      throw new APIException('USER_EXISTS', 'A user with this email already exists', { email }, 409);
    }
    
    // Create user
    const user = await User.create({ email, password });
    res.status(201).json({ user });
    
  } catch (error) {
    next(error); // Pass to error handler
  }
});

app.use(errorHandler);
```

### Frontend API Client

```typescript
class APIClient {
  async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    try {
      const response = await fetch(`${this.baseURL}${endpoint}`, {
        ...options,
        headers: {
          'Content-Type': 'application/json',
          ...options.headers
        }
      });
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new APIError(response.status, errorData.error || {});
      }
      
      return await response.json();
    } catch (error) {
      if (error instanceof APIError) {
        throw error;
      }
      
      // Network error, server down, etc.
      throw new APIError(0, {
        code: 'NETWORK_ERROR',
        message: 'Unable to connect to the server. Please check your connection.'
      });
    }
  }
}

class APIError extends Error {
  constructor(public status: number, public error: APIError) {
    super(error.message);
    this.name = 'APIError';
  }
}

// Usage with error handling
async function createUser(userData: CreateUserRequest) {
  try {
    return await apiClient.request<User>('/users', {
      method: 'POST',
      body: JSON.stringify(userData)
    });
  } catch (error) {
    if (error instanceof APIError) {
      switch (error.error.code) {
        case 'USER_EXISTS':
          throw new Error('An account with this email already exists');
        case 'VALIDATION_ERROR':
          throw new Error(`Invalid ${error.error.details?.field}: ${error.error.message}`);
        case 'NETWORK_ERROR':
          throw new Error('Please check your internet connection and try again');
        default:
          throw new Error('Failed to create account. Please try again.');
      }
    }
    
    // Unexpected error
    throw new Error('Something unexpected happened. Please try again.');
  }
}
```

## Graceful Degradation

### Feature Fallbacks

```typescript
// Progressive enhancement - core features work even if enhancements fail
function SearchForm() {
  const [query, setQuery] = useState('');
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  
  // Autocomplete is nice-to-have, not essential
  const fetchSuggestions = useMemo(() => 
    debounce(async (searchQuery: string) => {
      if (searchQuery.length < 2) {
        setSuggestions([]);
        return;
      }
      
      try {
        const results = await apiClient.request<string[]>(`/search/suggestions?q=${searchQuery}`);
        setSuggestions(results);
        setShowSuggestions(true);
      } catch (error) {
        // Autocomplete fails? No problem, search still works
        console.warn('Autocomplete unavailable:', error);
        setSuggestions([]);
        setShowSuggestions(false);
      }
    }, 300), []
  );
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!query.trim()) return;
    
    try {
      // Core search functionality - this MUST work
      const results = await apiClient.request<SearchResult[]>(`/search?q=${query}`);
      onResults(results);
    } catch (error) {
      // If search fails, that's a real problem
      setError('Search is temporarily unavailable. Please try again later.');
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <div className="search-input-container">
        <input
          type="text"
          value={query}
          onChange={e => {
            setQuery(e.target.value);
            fetchSuggestions(e.target.value);
          }}
          placeholder="Search..."
        />
        
        {/* Suggestions are optional enhancement */}
        {showSuggestions && suggestions.length > 0 && (
          <ul className="suggestions">
            {suggestions.map(suggestion => (
              <li key={suggestion} onClick={() => setQuery(suggestion)}>
                {suggestion}
              </li>
            ))}
          </ul>
        )}
      </div>
      
      <button type="submit">Search</button>
    </form>
  );
}
```

## Logging & Monitoring

### Structured Logging

```typescript
interface LogEntry {
  timestamp: string;
  level: 'debug' | 'info' | 'warn' | 'error';
  message: string;
  context?: Record<string, any>;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
  user?: {
    id: string;
    email: string;
  };
  request?: {
    id: string;
    method: string;
    url: string;
    userAgent: string;
  };
}

class Logger {
  private log(level: LogEntry['level'], message: string, context?: Record<string, any>, error?: Error) {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      context,
      error: error ? {
        name: error.name,
        message: error.message,
        stack: error.stack
      } : undefined
    };
    
    // In development, pretty print to console
    if (process.env.NODE_ENV === 'development') {
      console[level === 'debug' ? 'log' : level](
        `[${level.toUpperCase()}] ${message}`,
        context || '',
        error || ''
      );
      return;
    }
    
    // In production, structured JSON for log aggregation
    console.log(JSON.stringify(entry));
  }
  
  debug(message: string, context?: Record<string, any>) {
    this.log('debug', message, context);
  }
  
  info(message: string, context?: Record<string, any>) {
    this.log('info', message, context);
  }
  
  warn(message: string, context?: Record<string, any>, error?: Error) {
    this.log('warn', message, context, error);
  }
  
  error(message: string, context?: Record<string, any>, error?: Error) {
    this.log('error', message, context, error);
  }
}

const logger = new Logger();

// Usage examples
logger.info('User created', { userId: '123', email: 'user@example.com' });
logger.error('Failed to process payment', { orderId: 'ord_123', amount: 99.99 }, error);
```

## Testing Error Scenarios

```typescript
// Test that errors are handled gracefully
describe('UserCreation', () => {
  test('handles duplicate email error', async () => {
    // Mock API to return 409 error
    jest.spyOn(apiClient, 'request').mockRejectedValueOnce(
      new APIError(409, { code: 'USER_EXISTS', message: 'User already exists' })
    );
    
    const { getByText, getByLabelText } = render(<SignUpForm />);
    
    fireEvent.change(getByLabelText('Email'), { target: { value: 'test@example.com' }});
    fireEvent.click(getByText('Create Account'));
    
    await waitFor(() => {
      expect(getByText('An account with this email already exists')).toBeInTheDocument();
    });
  });
  
  test('handles network error gracefully', async () => {
    // Mock network failure
    jest.spyOn(apiClient, 'request').mockRejectedValueOnce(
      new APIError(0, { code: 'NETWORK_ERROR', message: 'Network error' })
    );
    
    const { getByText } = render(<SignUpForm />);
    
    fireEvent.click(getByText('Create Account'));
    
    await waitFor(() => {
      expect(getByText(/check your internet connection/)).toBeInTheDocument();
    });
  });
});
```

## Checklist

Before deploying error-prone features:

- [ ] **Input validation** - Prevent bad data at the source
- [ ] **Try-catch blocks** - Around all async operations and external calls
- [ ] **User-friendly messages** - No technical jargon in user-facing errors
- [ ] **Error boundaries** - React components wrapped to prevent crashes
- [ ] **Graceful degradation** - Core features work even if enhancements fail
- [ ] **Logging** - Errors logged with context for debugging
- [ ] **Monitoring** - Error rates tracked and alerting configured
- [ ] **Testing** - Error scenarios included in test suite
- [ ] **Documentation** - Error codes and recovery steps documented

## Integration

### With Security Gate
- Error handling patterns are part of security review
- Information leakage through errors flagged as vulnerability
- Error monitoring helps detect attacks

### With Human Approval
- New error handling patterns require review
- Changes to user-facing error messages need approval
- Critical error conditions trigger human oversight

### With Documentation
- Error codes and meanings documented for users
- Recovery procedures documented for operators
- Debugging runbooks created for common errors