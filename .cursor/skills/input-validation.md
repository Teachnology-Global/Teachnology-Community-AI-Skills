---
description: >
  Enforces input validation and output sanitisation across all user-facing surfaces.
  Prevents XSS, SQL injection, path traversal, and data corruption from unvalidated
  input. Critical for non-technical founders using Cursor — AI-generated code
  frequently skips validation, shipping exploitable forms and APIs.
  Use when: (1) building forms or API endpoints, (2) reviewing user-submitted data
  handling, (3) accepting file uploads, (4) rendering user-controlled content,
  (5) auditing existing input handling.
globs: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "**/*.py", "**/*.html", "**/*.vue", "**/*.svelte", "**/api/**"]
alwaysApply: false
tags: [product]
---

# Input Validation

## Purpose

Every piece of data that enters your application from the outside world — form fields, URL parameters, API payloads, file uploads, cookie values, environment variables from external sources — is untrusted. Cursor-generated code frequently skips validation in favour of "just making it work." This skill ensures that unvalidated input doesn't become a security vulnerability, a corrupted database, or a confusing user experience.

## Why This Matters for Non-Technical Builders

When you ask Cursor to "build a contact form" or "create an API endpoint", it will typically generate code that:

- Accepts any string without length limits (allows megabyte payloads)
- Doesn't check types (a field expecting a number accepts code)
- Passes user input directly to database queries (SQL injection)
- Renders user input directly to HTML (XSS)
- Accepts any file type for uploads

None of these bugs look broken during testing. They surface when someone actively tries to exploit them — or when a user accidentally sends malformed data that crashes your app.

## Activation

This skill activates when you mention:
- "form", "user input", "API endpoint", "POST request"
- "validation", "sanitise", "sanitize", "escape"
- "XSS", "injection", "SQL injection", "CSRF"
- "file upload", "user-submitted", "accept input"
- "input field", "query parameter", "request body"

Also activates when:
- Creating or reviewing form components
- Building API routes that accept POST/PUT/PATCH
- Handling file uploads
- Rendering user-provided content in HTML

## The Golden Rule

**Validate on the server. Always.**

Client-side validation (JavaScript in the browser) is for user experience — immediate feedback, helpful error messages. It is not security. Anyone can bypass browser-side validation in under 30 seconds using browser devtools. Your server must validate every input independently, as if the client-side validation doesn't exist.

```
Data Flow:

User Input
    │
    ▼
[Client-Side Validation] ← Nice to have. NOT security.
    │
    ▼
[Server-Side Validation] ← REQUIRED. This is the gate.
    │
    ▼
[Business Logic / Database]
    │
    ▼
[Output Encoding] ← REQUIRED when rendering back to HTML.
```

## Core Validation Checklist

For every input your application accepts:

- [ ] **Type** — Is it the right type? (string, number, boolean, array)
- [ ] **Required** — Is it present when it should be?
- [ ] **Length/Size** — Does it fit within expected bounds?
- [ ] **Format** — Does it match the expected pattern (email, phone, date)?
- [ ] **Range** — Is a number within an acceptable range?
- [ ] **Allowlist** — For enumerated values, is it one of the allowed values?
- [ ] **Context** — Will it be used in SQL? HTML? A file path? Apply context-specific encoding.

## Validation Patterns

### Server-Side Validation (Node.js with Zod)

Zod is a TypeScript schema validation library. This is the recommended approach for Cursor projects because it generates both runtime validation and TypeScript types.

```typescript
import { z } from 'zod';

// Define your schema
const ContactSchema = z.object({
  name: z.string()
    .min(1, 'Name is required')
    .max(100, 'Name must be under 100 characters')
    .trim(),
  
  email: z.string()
    .email('Invalid email address')
    .max(255)
    .toLowerCase(),
  
  message: z.string()
    .min(10, 'Message too short')
    .max(2000, 'Message too long')
    .trim(),
  
  // Enumerated values — only allow known options
  subject: z.enum(['general', 'billing', 'support', 'other']),
  
  // Optional field with validation
  phone: z.string()
    .regex(/^\+?[\d\s\-\(\)]{7,20}$/, 'Invalid phone format')
    .optional(),
});

// In your API route
export async function POST(req: Request) {
  const body = await req.json();
  
  const result = ContactSchema.safeParse(body);
  
  if (!result.success) {
    return Response.json(
      { errors: result.error.flatten().fieldErrors },
      { status: 400 }
    );
  }
  
  // result.data is now type-safe and validated
  const { name, email, message, subject } = result.data;
  // ...
}
```

### Preventing SQL Injection

SQL injection happens when user input is concatenated into a SQL string. Never build SQL strings by hand.

```typescript
// ❌ DANGEROUS — SQL injection
const user = await db.query(
  `SELECT * FROM users WHERE email = '${email}'`
);
// An attacker inputs: ' OR '1'='1
// Query becomes: SELECT * FROM users WHERE email = '' OR '1'='1'
// Returns ALL users

// ✅ Safe — parameterised query
const user = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);

// ✅ Safe — ORM (Prisma, Drizzle)
const user = await prisma.user.findFirst({
  where: { email: email }
});
```

```python
# Python — same principle
# ❌ DANGEROUS
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")

# ✅ Safe — parameterised
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
```

### Preventing XSS (Cross-Site Scripting)

XSS happens when user-controlled content is rendered as HTML without encoding.

```tsx
// React is safe by default — it escapes output
// ✅ Safe — React escapes this automatically
<p>{userContent}</p>

// ❌ DANGEROUS — bypasses React's escaping
<p dangerouslySetInnerHTML={{ __html: userContent }} />

// If you MUST render HTML from user input (e.g., rich text editor output):
import DOMPurify from 'dompurify';
<p dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

```javascript
// Plain JavaScript
// ❌ DANGEROUS
element.innerHTML = userInput;

// ✅ Safe — sets text, not HTML
element.textContent = userInput;

// ✅ Safe — if you need HTML, sanitise first
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(userInput);
```

### File Upload Validation

File uploads are a high-risk input type. Validate on the server — client-side type checks are trivially bypassed.

```typescript
import path from 'path';
import crypto from 'crypto';

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

async function validateUpload(file: File): Promise<void> {
  // Check MIME type (check content, not just extension)
  if (!ALLOWED_TYPES.includes(file.type)) {
    throw new Error(`File type not allowed: ${file.type}`);
  }
  
  // Check file size
  if (file.size > MAX_FILE_SIZE) {
    throw new Error('File too large (max 5MB)');
  }
  
  // Generate a safe filename — never use the user-provided name directly
  const ext = file.type === 'application/pdf' ? '.pdf' : '.img';
  const safeFilename = crypto.randomUUID() + ext;
  
  // Never: store at a user-provided path
  // Never: use the original filename without sanitisation
  
  return safeFilename;
}

// Also: store uploads OUTSIDE your web root, or in object storage
// Never store uploaded files at a path that can be directly served
```

### URL Parameter and Query String Validation

```typescript
// Next.js API route example
export async function GET(req: Request) {
  const url = new URL(req.url);
  const id = url.searchParams.get('id');
  const page = url.searchParams.get('page');
  
  // ❌ Never pass URL params directly to DB
  // await db.query(`SELECT * FROM posts WHERE id = ${id}`)
  
  // ✅ Validate type and range
  const parsedId = parseInt(id ?? '', 10);
  if (isNaN(parsedId) || parsedId <= 0) {
    return Response.json({ error: 'Invalid id' }, { status: 400 });
  }
  
  const parsedPage = parseInt(page ?? '1', 10);
  const safePage = Math.max(1, Math.min(parsedPage, 100)); // cap at 100
  
  // Now safe to use
  const post = await db.post.findUnique({ where: { id: parsedId } });
  // ...
}
```

### Path Traversal Prevention

```typescript
import path from 'path';

const ALLOWED_DIRECTORY = '/app/uploads';

function getSafeFilePath(userFilename: string): string {
  // Remove dangerous characters and path components
  const safeFilename = path.basename(userFilename); // strips directory components
  const fullPath = path.join(ALLOWED_DIRECTORY, safeFilename);
  
  // Verify the resolved path is still inside the allowed directory
  if (!fullPath.startsWith(ALLOWED_DIRECTORY)) {
    throw new Error('Path traversal detected');
  }
  
  return fullPath;
}

// ❌ DANGEROUS — allows reading any file
// const file = fs.readFileSync(`/app/uploads/${userInput}`);
// Input: ../../etc/passwd → reads /etc/passwd

// ✅ Safe
// const file = fs.readFileSync(getSafeFilePath(userInput));
```

## AI-Generated Code Patterns to Watch For

Cursor will often generate these dangerous patterns. Know what to look for in code review:

```typescript
// 🚨 RED FLAG: String concatenation in queries
db.query(`WHERE id = ${req.params.id}`)
db.execute(`SELECT * FROM ${tableName}`)

// 🚨 RED FLAG: dangerouslySetInnerHTML without sanitisation
dangerouslySetInnerHTML={{ __html: userContent }}

// 🚨 RED FLAG: Using original filename for storage
fs.writeFile(req.file.originalname, data)
path.join(uploadDir, req.file.originalname)

// 🚨 RED FLAG: eval() with any external data
eval(userCode)
new Function(userInput)

// 🚨 RED FLAG: Redirect to user-provided URL without validation
res.redirect(req.query.next)  // Open redirect

// 🚨 RED FLAG: Validation only on client side
// App.tsx: if (!email.includes('@')) return error
// api/contact.ts: db.insert({ email })  // No server validation
```

## Validation Libraries

| Language | Library | Purpose |
|----------|---------|---------|
| TypeScript/JS | **Zod** | Schema validation + type inference |
| TypeScript/JS | **Joi** | Schema validation (older, widely used) |
| TypeScript/JS | **DOMPurify** | HTML sanitisation for XSS |
| Python | **Pydantic** | Schema validation + type coercion |
| Python | **Cerberus** | Flexible schema validation |

## Pre-Deployment Checklist

Before shipping any feature that accepts user input:

- [ ] All API endpoints validate request body with a schema library
- [ ] No SQL built via string concatenation — all queries parameterised or using ORM
- [ ] User-controlled HTML is sanitised with DOMPurify before rendering
- [ ] File uploads: type checked, size limited, filename regenerated
- [ ] URL params: type-coerced and range-checked before database use
- [ ] Error responses don't expose stack traces or internal details to users
- [ ] Form validation exists on both client (UX) and server (security)

## Integration

### With Security Gate
- SAST tools catch common injection patterns — input validation failures show up as security findings
- Unparameterised queries block deployment at the security gate

### With AI Output Validation
- Review all AI-generated form handling and API endpoints for missing validation
- Check database query generation for parameterisation

### With Error Handling
- Validation errors should surface as friendly user messages, not stack traces
- Log validation failures server-side for monitoring anomalous patterns

### With Testing Standards
- Write tests with deliberately invalid inputs: empty strings, too-long strings, SQL fragments, HTML tags
- Validation boundaries (max length, allowed types) should have explicit test cases