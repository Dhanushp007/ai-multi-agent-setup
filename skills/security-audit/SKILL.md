---
name: security-audit
description: Use this skill when asked to perform a security audit, find vulnerabilities, scan for secrets, check dependencies for CVEs, or review code for OWASP Top 10 issues — automatically selected for "security review", "find vulnerabilities", or "is this code safe".
license: MIT
---

# Security Audit

## When to Use This Skill

- Pre-release security audit of a codebase or PR
- Investigating a potential vulnerability report
- Scanning for leaked secrets or credentials
- Reviewing third-party dependency risk
- OWASP Top 10 compliance assessment
- Producing a security findings report for stakeholders

---

## Process

### 1. Define the Audit Scope

Clarify before starting:
- **Target**: specific files, a PR diff, or an entire repo?
- **Depth**: quick scan (SAST patterns + deps) or full audit (threat modelling)?
- **Standards**: OWASP Top 10, CWE, PCI-DSS, SOC 2, GDPR?

### 2. Secret & Credential Scanning

Search for hardcoded secrets before anything else — these are immediate, zero-effort exploits:

```powershell
# Common secret patterns
Select-String -Path . -Recurse -Pattern `
  "(api[_-]?key|secret|password|token|private[_-]?key)\s*[:=]\s*['\`"][^'\`"]{8,}" `
  -Include "*.js","*.ts","*.py","*.cs","*.go","*.env","*.yml","*.json"
```

Check for:
- Hardcoded passwords/tokens/keys in source
- `.env` files committed to the repo (`git log --all --full-history -- "**/.env"`)
- AWS/GCP/Azure credentials (`AKIA`, `AIza`, `-----BEGIN RSA`)
- JWT secrets or private keys

**If found**: flag as `[CRITICAL]` and recommend immediate rotation. Do NOT include the value in the report.

### 3. Dependency Vulnerability Scan

#### Node.js
```bash
npm audit --audit-level=moderate
npx better-npm-audit audit
```

#### Python
```bash
pip-audit --desc
safety check --full-report
```

#### .NET
```bash
dotnet list package --vulnerable --include-transitive
```

#### All stacks (via GitHub)
```
get_repository_security_alerts(owner, repo)
list_dependabot_alerts(owner, repo, state: "open")
```

For each finding, look up the CVE:
- NVD: https://nvd.nist.gov/vuln/detail/CVE-XXXX-XXXXX
- Note CVSS v3 base score and vector string
- Check if a fixed version exists

### 4. OWASP Top 10 Checklist

Work through each category systematically:

#### A01 — Broken Access Control
- [ ] Authorization checked on every sensitive endpoint (not just authentication)
- [ ] Direct object references validated against the requesting user's permissions
- [ ] Admin/internal routes protected behind role checks
- [ ] CORS policy is restrictive (`*` only for truly public APIs)

#### A02 — Cryptographic Failures
- [ ] Passwords hashed with bcrypt/argon2/scrypt (not MD5/SHA1/SHA256)
- [ ] Sensitive data encrypted at rest (PII, payment info, health data)
- [ ] TLS 1.2+ enforced; no SSLv3/TLS 1.0
- [ ] Secrets not stored in localStorage or URL parameters

#### A03 — Injection
- [ ] All DB queries parameterized (no string concatenation)
- [ ] ORM used correctly (raw queries audited)
- [ ] `eval()`, `exec()`, `shell_exec()` absent or heavily guarded
- [ ] HTML output escaped to prevent XSS (`innerHTML` assignments audited)
- [ ] XML/JSON parsers protected against XXE

#### A04 — Insecure Design
- [ ] Rate limiting on authentication endpoints
- [ ] Account lockout after N failed logins
- [ ] Password reset tokens single-use and short-lived

#### A05 — Security Misconfiguration
- [ ] Default credentials changed
- [ ] Debug endpoints/stack traces disabled in production
- [ ] Security headers present: `CSP`, `HSTS`, `X-Frame-Options`, `X-Content-Type-Options`
- [ ] Directory listing disabled

#### A06 — Vulnerable & Outdated Components
- [ ] Dependency audit clean (see step 3)
- [ ] Base Docker images up to date
- [ ] No EOL runtime versions (Node 16, Python 3.8, .NET 6)

#### A07 — Identification & Authentication Failures
- [ ] Session tokens are cryptographically random (≥128 bits)
- [ ] Sessions invalidated on logout
- [ ] Multi-factor authentication available for privileged accounts
- [ ] JWT `alg: none` attack mitigated; algorithm explicitly validated

#### A08 — Software & Data Integrity Failures
- [ ] Third-party scripts loaded with SRI hashes
- [ ] CI/CD pipeline cannot be modified by untrusted actors
- [ ] Serialized objects validated before deserialization

#### A09 — Security Logging & Monitoring Failures
- [ ] Auth events (login, logout, failure) logged with IP + timestamp
- [ ] Logs do not contain passwords, tokens, or PII
- [ ] Alerting on repeated failures

#### A10 — Server-Side Request Forgery (SSRF)
- [ ] User-supplied URLs validated against an allowlist before fetching
- [ ] Cloud metadata endpoint (`169.254.169.254`) blocked
- [ ] Redirects followed only to trusted domains

### 5. SAST Pattern Scanning

Run static analysis:

```bash
# JavaScript/TypeScript
npx eslint --plugin security .

# Python
bandit -r . -ll

# .NET
dotnet tool run security-scan

# Generic (Semgrep)
semgrep --config=p/owasp-top-ten .
semgrep --config=p/secrets .
```

### 6. Severity Scoring

Rate each finding using CVSS v3:

| Severity | CVSS Score | SLA to Fix |
|----------|-----------|------------|
| Critical | 9.0 – 10.0 | Immediate (block release) |
| High | 7.0 – 8.9 | 24–72 hours |
| Medium | 4.0 – 6.9 | Next sprint |
| Low | 0.1 – 3.9 | Backlog |
| Informational | 0.0 | No action required |

### 7. Write the Report

Structure findings as:

```markdown
## Finding: <Short Title>
- **Severity**: Critical / High / Medium / Low
- **CVSS Score**: X.X (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H)
- **CWE**: CWE-89 (SQL Injection)
- **Location**: `src/users/search.ts:47`
- **Description**: <What the vulnerability is>
- **Impact**: <What an attacker can do>
- **Remediation**: <Specific fix with code example>
- **References**: CVE-XXXX-XXXXX, https://cwe.mitre.org/data/definitions/89.html
```

---

## Tools & Resources

- **GitHub MCP**: `list_dependabot_alerts`, `get_repository_security_alerts`, `get_code_scanning_alerts`
- **NVD CVE database**: https://nvd.nist.gov/
- **OWASP Top 10**: https://owasp.org/Top10/
- **CWE list**: https://cwe.mitre.org/
- **Semgrep rules**: https://semgrep.dev/r
- **Have I Been Pwned API**: https://haveibeenpwned.com/API/v3

---

## Templates / Examples

### Critical Finding — Hardcoded Secret
```markdown
## Finding: Hardcoded AWS Access Key
- **Severity**: Critical
- **CVSS Score**: 10.0
- **CWE**: CWE-798 (Use of Hard-coded Credentials)
- **Location**: `config/aws.js:12`
- **Description**: An AWS access key ID and secret are committed in plaintext.
- **Impact**: Full AWS account takeover; data exfiltration; resource abuse.
- **Remediation**: Rotate the key immediately. Use environment variables or
  AWS IAM roles. Add `*.env` and `config/secrets.*` to `.gitignore`.
- **References**: CWE-798
```

---

## Checklist

- [ ] Scope defined (files, depth, standards)
- [ ] Secret scan complete — no hardcoded credentials
- [ ] Dependency audit run — all CVEs triaged
- [ ] OWASP A01 (Access Control) reviewed
- [ ] OWASP A02 (Crypto) reviewed
- [ ] OWASP A03 (Injection) reviewed
- [ ] OWASP A04–A10 reviewed
- [ ] SAST tool run and output triaged
- [ ] Each finding rated with CVSS severity
- [ ] Report written with remediation for every finding
- [ ] Critical/High findings communicated to owner before report is filed
