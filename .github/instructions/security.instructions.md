---
applyTo: "**"
---

# Security Standards

These rules apply to every file in every project. There are no exceptions.

## Secrets and Credentials
- Never hardcode secrets, API keys, tokens, passwords, or connection strings in source code.
- Store all secrets in environment variables or a secrets manager (Azure Key Vault, AWS Secrets
  Manager, HashiCorp Vault, GitHub Actions secrets).
- Reject any PR that adds a credential to the repository, even in a comment or test fixture.
- Rotate any secret that was accidentally committed, regardless of how briefly it was exposed.

## Input Validation
- Validate and sanitize all input at every trust boundary (HTTP request, file upload, IPC, CLI arg).
- Prefer allowlists (accept known-good patterns) over denylists (reject known-bad patterns).
- Reject input that fails validation with a descriptive 400/422 error — do not silently strip it.
- Validate on the server side; client-side validation is UX only, never a security control.

## SQL and Query Safety
- Use parameterized queries or an ORM for all database interactions.
- Never concatenate user-supplied values into a SQL string.
- Apply the principle of least privilege: the DB user for the application should only have the
  permissions it actually needs (SELECT, INSERT — not DROP TABLE).

## Output Encoding and XSS
- Encode output before rendering in HTML, JavaScript, CSS, or URL contexts.
- Use framework-provided escaping (React JSX, Django templates, Razor) rather than manual encoding.
- Set `Content-Security-Policy`, `X-Content-Type-Options`, and `X-Frame-Options` headers.

## Transport Security
- Use HTTPS/TLS for all external HTTP calls; never disable certificate verification.
- Enforce HTTPS at the load balancer or middleware layer; redirect HTTP → HTTPS.
- Use current TLS versions (1.2 minimum, prefer 1.3); disable older protocols and weak ciphers.

## Authentication and Authorization
- Apply authentication middleware before any business logic in route/handler definitions.
- Enforce authorization checks on every request — do not rely on UI hiding protected features.
- Apply the principle of least privilege for service accounts, IAM roles, and DB users.
- Implement rate limiting on all public-facing endpoints to mitigate brute-force and abuse.

## Logging and Observability
- Log security-relevant events: auth attempts, permission denials, input validation failures.
- Never log sensitive data: passwords, tokens, full credit card numbers, PII (names, emails,
  SSNs) should be masked or omitted from log output.
- Ensure log entries include a request/correlation ID to enable tracing across services.

## Dependencies
- Pin dependency versions and review changes via Dependabot or Renovate.
- Run a software-composition analysis (SCA) scan in CI to detect known CVEs.
- Do not import packages with no legitimate use case for the project.
