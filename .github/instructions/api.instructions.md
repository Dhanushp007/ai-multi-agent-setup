---
applyTo: "**/api/**,**/routes/**,**/controllers/**,**/handlers/**"
---

# API Coding Standards

## HTTP Status Codes
Use the correct status code for every response — do not return 200 for errors.

| Code | When to use |
|------|-------------|
| 200  | Successful GET, PUT, PATCH |
| 201  | Resource created (POST) |
| 204  | Success with no body (DELETE) |
| 400  | Malformed request syntax |
| 401  | Missing or invalid authentication |
| 403  | Authenticated but not authorized |
| 404  | Resource not found |
| 409  | Conflict (duplicate, optimistic lock) |
| 422  | Validation error (well-formed but semantically invalid) |
| 429  | Rate limit exceeded |
| 500  | Unexpected server error |

## Error Responses
- Always return a structured error body — never a plain string or an empty body.
- Minimum shape: `{ "error": { "code": "VALIDATION_ERROR", "message": "..." } }`.
- Add a `details` array for field-level validation errors.
- Never expose internal stack traces, query text, or file paths in production responses.
- Include the request ID in every error response for support tracing.

## Request Validation
- Validate every request body, query parameter, and path parameter with a schema library
  (Zod, Pydantic, FluentValidation, Joi).
- Return 422 with field-level error details when validation fails.
- Reject unknown fields (strip-or-reject, not silently pass through).

## Tracing and Observability
- Accept `X-Request-ID` from callers; generate one if absent.
- Include the request ID in every response header and in all log lines for that request.
- Log request method, path, status code, and duration at INFO level for every request.

## Pagination
- All list endpoints must support pagination — never return unbounded collections.
- Prefer cursor-based pagination over offset/limit for large or frequently-updated datasets.
- Response shape: `{ "data": [...], "pagination": { "nextCursor": "...", "hasMore": true } }`.
- Default page size should be reasonable (20–50); document and enforce a maximum (e.g., 100).

## Versioning
- Version APIs via the URL path: `/api/v1/`, `/api/v2/`.
- Never make breaking changes to an existing version — add a new version instead.
- Deprecate old versions with a `Sunset` response header and a migration timeline.

## Documentation
- Document every endpoint with OpenAPI 3.x annotations or JSDoc `@openapi` comments.
- Keep generated docs (`openapi.yaml` / `swagger.json`) in source control and regenerate in CI.
- Document authentication requirements, rate limits, and error codes per endpoint.

## Auth Middleware
- Register authentication and authorization middleware before route handlers — never inline auth
  checks inside business logic.
- Use a centralized policy/permission system; do not scatter `if (user.role === "admin")` checks.

## Security
- Apply rate limiting at the router level for all public endpoints.
- Set `Cache-Control: no-store` on endpoints that return sensitive or personalized data.
- See `security.instructions.md` for input validation, SQL safety, and secrets rules that
  also apply here.
