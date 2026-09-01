---
name: api-design
description: Use this skill when asked to design an API, create OpenAPI specs, define REST endpoints, set up GraphQL schemas, or review API contracts — automatically selected for "design this API", "write an OpenAPI spec", "define endpoints", or "review the API design".
license: MIT
---

# API Design

## When to Use This Skill

- Designing new REST or GraphQL APIs from scratch
- Reviewing and improving an existing API contract
- Writing OpenAPI 3.1 specifications
- Establishing versioning, auth, and error response standards
- Generating API documentation from code or spec

---

## Process

### 1. Gather Requirements

Before writing any spec:
- Who are the consumers (internal service, mobile app, third-party)?
- What are the core domain entities and operations?
- What are the SLA requirements (latency, uptime, rate limits)?
- Will this API be public or private?
- Does it need versioning from day one?

### 2. Choose the API Paradigm

| Paradigm | Best For | Avoid When |
|----------|---------|-----------|
| **REST** | CRUD resources, public APIs, wide client compat | Real-time, complex queries |
| **GraphQL** | Flexible queries, aggregation, BFF pattern | Simple CRUD, non-JS teams |
| **gRPC** | Internal microservices, streaming, high performance | Browsers, public APIs |
| **WebSocket** | Real-time bidirectional (chat, live data) | Request-response workloads |

### 3. REST Resource Design

#### Naming Rules
```
# Resources: plural nouns, lowercase, hyphens
GET    /users                    # list
POST   /users                    # create
GET    /users/{id}               # read one
PATCH  /users/{id}               # partial update
PUT    /users/{id}               # full replace
DELETE /users/{id}               # delete

# Nested resources (use sparingly — max 2 levels)
GET    /users/{userId}/orders    # orders belonging to a user
POST   /users/{userId}/orders

# Actions (when CRUD doesn't fit — use verbs as sub-resources)
POST   /users/{id}/activate
POST   /orders/{id}/cancel
POST   /payments/{id}/refund

# Bad — avoid verb in path
POST   /createUser               # ❌
GET    /getUserById/{id}         # ❌
POST   /user/do-activate         # ❌
```

#### HTTP Methods & Status Codes
```
GET     → 200 OK, 404 Not Found
POST    → 201 Created (with Location header), 400 Bad Request, 409 Conflict
PATCH   → 200 OK, 400 Bad Request, 404 Not Found
PUT     → 200 OK, 201 Created, 400 Bad Request
DELETE  → 204 No Content, 404 Not Found
```

### 4. Write the OpenAPI 3.1 Spec

```yaml
# openapi.yml
openapi: '3.1.0'
info:
  title: Users API
  version: '1.0.0'
  description: Manages user accounts and profiles.
  contact:
    name: Platform Team
    email: platform@example.com
  license:
    name: MIT

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://api-staging.example.com/v1
    description: Staging

tags:
  - name: users
    description: User account management

paths:
  /users:
    get:
      operationId: listUsers
      tags: [users]
      summary: List users
      parameters:
        - name: page
          in: query
          schema: { type: integer, default: 1, minimum: 1 }
        - name: per_page
          in: query
          schema: { type: integer, default: 20, maximum: 100 }
        - name: role
          in: query
          schema: { type: string, enum: [admin, member, viewer] }
      responses:
        '200':
          description: Paginated list of users
          headers:
            X-Total-Count: { schema: { type: integer } }
            Link: { schema: { type: string } }
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items: { $ref: '#/components/schemas/User' }
                  meta: { $ref: '#/components/schemas/PaginationMeta' }
        '401': { $ref: '#/components/responses/Unauthorized' }

    post:
      operationId: createUser
      tags: [users]
      summary: Create a user
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/CreateUserRequest' }
      responses:
        '201':
          description: User created
          headers:
            Location:
              schema: { type: string, format: uri }
              example: /v1/users/usr_01HX5RKP
          content:
            application/json:
              schema: { $ref: '#/components/schemas/User' }
        '400': { $ref: '#/components/responses/ValidationError' }
        '409': { $ref: '#/components/responses/Conflict' }

components:
  schemas:
    User:
      type: object
      required: [id, email, role, created_at]
      properties:
        id:
          type: string
          pattern: '^usr_[0-9A-Z]{8,}$'
          example: usr_01HX5RKPQ
        email:
          type: string
          format: email
        role:
          type: string
          enum: [admin, member, viewer]
        name:
          type: string
          maxLength: 255
        created_at:
          type: string
          format: date-time

    CreateUserRequest:
      type: object
      required: [email, password, role]
      properties:
        email: { type: string, format: email }
        password: { type: string, minLength: 10, writeOnly: true }
        role: { type: string, enum: [member, viewer] }
        name: { type: string, maxLength: 255 }

    PaginationMeta:
      type: object
      properties:
        total: { type: integer }
        page: { type: integer }
        per_page: { type: integer }
        total_pages: { type: integer }

    Error:
      type: object
      required: [code, message]
      properties:
        code: { type: string }
        message: { type: string }
        details:
          type: array
          items:
            type: object
            properties:
              field: { type: string }
              message: { type: string }

  responses:
    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema: { $ref: '#/components/schemas/Error' }
          example: { code: unauthorized, message: "Bearer token required" }

    ValidationError:
      description: Request validation failed
      content:
        application/json:
          schema: { $ref: '#/components/schemas/Error' }
          example:
            code: validation_error
            message: "Request validation failed"
            details:
              - field: email
                message: "Must be a valid email address"

    Conflict:
      description: Resource conflict
      content:
        application/json:
          schema: { $ref: '#/components/schemas/Error' }

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - bearerAuth: []
```

### 5. Versioning Strategy

| Strategy | Pros | Cons | Use When |
|----------|------|------|---------|
| URL path `/v1/` | Simple, explicit, cacheable | Duplicate routes | Public APIs, long-lived |
| Header `Accept: application/vnd.api+json;version=2` | Clean URLs | Complex routing | Internal APIs |
| Query param `?version=2` | Easy to test | Pollutes URLs | Avoid |

**Recommended for public APIs**: URL path versioning (`/v1/`, `/v2/`).

Deprecation flow:
1. Announce deprecation with `Sunset` header and date
2. Keep old version running for ≥ 6 months after `Sunset`
3. Return `Deprecation: true` header on deprecated endpoints

### 6. Authentication Patterns

```yaml
# JWT Bearer (most common)
Authorization: Bearer eyJhbGciOiJSUzI1NiJ9...

# API Key (service-to-service)
X-API-Key: sk_live_abc123

# OAuth 2.0 scopes
scope: users:read users:write orders:read
```

### 7. Rate Limiting Headers
```
X-RateLimit-Limit: 1000         # requests per window
X-RateLimit-Remaining: 743      # remaining in current window
X-RateLimit-Reset: 1705315200   # Unix timestamp when window resets
Retry-After: 30                 # seconds (on 429 response)
```

---

## Tools & Resources

- **OpenAPI spec**: https://spec.openapis.org/oas/v3.1.0
- **Swagger Editor**: https://editor.swagger.io/
- **Redoc**: https://redocly.com/
- **Stoplight Studio** (visual OpenAPI editor): https://stoplight.io/studio
- **Prism** (mock server from OpenAPI spec): https://stoplight.io/open-source/prism
- **spectral** (OpenAPI linter): https://stoplight.io/open-source/spectral

---

## Checklist

- [ ] Consumer requirements and domain entities identified
- [ ] API paradigm chosen (REST / GraphQL / gRPC)
- [ ] Resource names are plural nouns; no verbs in path (except action sub-resources)
- [ ] HTTP methods and status codes follow conventions
- [ ] OpenAPI 3.1 spec written with all required fields
- [ ] Request/response schemas defined in `components/schemas`
- [ ] Reusable error responses in `components/responses`
- [ ] Authentication scheme defined in `securitySchemes`
- [ ] Pagination strategy defined (cursor or page-based)
- [ ] Rate limiting headers documented
- [ ] Versioning strategy decided and applied
- [ ] Spec validated with `spectral lint openapi.yml`
- [ ] Mock server generated for consumer testing (`npx @stoplight/prism-cli mock openapi.yml`)
