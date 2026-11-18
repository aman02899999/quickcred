# Security policy and security gap assessment (deliverable G, part 2)

Status: pre-Phase 1. ✅ = in the repo now, 🟡 = designed, built in the named phase, ❌ = open gap.

## 1. Threat model, top risks for an Indian lending app

| Threat | Likely vector | Control | Status |
|---|---|---|---|
| Synthetic / stolen identity loans | Bought PAN+Aadhaar, SIM swap, mule accounts | PAN↔bank name match, same-account-across-users index, device fingerprint, velocity limits, AA salary detection | ✅ schema indexes · 🟡 Phase 3 engine |
| Payout to wrong/mule account | Beneficiary changed after verification | Payout only to `bank_accounts.verification_status=verified` owned by applicant; maker-checker; one live payout per loan | ✅ DB constraints (`disb_one_live_per_loan_uq`, maker≠checker CHECK) |
| Double disbursement | Retries, webhook replays | Idempotency keys (unique), provider event id unique, partial unique index | ✅ schema |
| OTP abuse / SMS pumping | Bots hitting send-OTP | Per-phone + per-IP + per-device rate limits, resend cooldown, captcha after N | 🟡 Phase 2 |
| PII breach | SQL injection, leaked backups, insider | Field-level envelope encryption (KMS), blind indexes for lookup, RBAC, audit log, encrypted backups | ✅ schema (`*_enc` bytea, `*_hash`) · 🟡 crypto service Phase 1 |
| Ledger tampering | Insider edits balances | Append-only ledger + balance trigger, hash-chained audit log, nightly ledger↔account reconciliation | ✅ triggers (tests T1–T4) |
| Webhook forgery | Fake "payment success" | HMAC signature verification, timestamp window, source IP allowlist, store `signature_valid` | 🟡 Phase 4 |
| Secret leakage to browser | NEXT_PUBLIC misuse | Secrets only server-side; CI grep fails build on `NEXT_PUBLIC_*KEY|SECRET` | 🟡 Phase 1 CI |
| Accidental real KYC / money movement | Mis-set env var | Boot guard refuses `live` without lender authorization + production | ✅ `integration-mode.ts` + 5 tests |
| Staff account takeover | Phishing | MFA mandatory for staff, step-up MFA on critical permissions, session timeout 15 min idle | 🟡 Phase 1 |

## 2. Controls by layer

**Identity and access**
- Customers: phone OTP (hashed with HMAC, 5-min TTL, 5 attempts, 30-s resend cooldown, 5 sends/hour). Short-lived access JWT (15 min) + rotating refresh token stored hashed (`user_sessions.refresh_token_hash`), revocable per device.
- Staff: email + password (argon2id) + TOTP MFA, or SSO later. RBAC via `roles`/`permissions`; lender-scoped staff can only see their `lender_id` rows (enforced in a repository layer and, Phase 6, Postgres RLS).
- Critical permissions (`permissions.is_critical`): disbursement approval, product pricing edits, provider credential changes, manual credit override. They need MFA step-up and a written reason, and they land in `audit_logs`.

**Data protection**
- Envelope encryption: per-record data key encrypted by AWS KMS CMK in ap-south-1. Columns: phone, PAN, name, DOB, email, addresses, account number, provider payloads, bank narrations.
- Blind indexes (HMAC with a pepper held in Secrets Manager) for phone, PAN and account number, so duplicate detection works without decrypting.
- Aadhaar: last 4 digits only. No biometrics, ever. No raw XML retained after verification.
- Logs: PII-redacting logger; `audit_logs.before/after` store redacted diffs.

**Application**
- Validation at both edges (zod on web, class-validator/zod on API). Parameterised queries via Drizzle.
- Security headers on web ✅ (HSTS, nosniff, frame DENY, Permissions-Policy denying camera/mic/geo/contacts by default).
- CORS allowlist from env ✅. CSRF protection for cookie-based staff sessions.
- File uploads: MIME sniffing, size caps, AV scan, stored in S3 with SSE-KMS, served via short-lived signed URLs.

**Infrastructure** (Phase 6)
- AWS ap-south-1 primary, ap-south-2 DR. Private subnets for DB/Redis, WAF + rate rules at the edge, TLS 1.2+.
- Encrypted RDS snapshots, PITR, quarterly restore drill.
- OpenTelemetry traces, Sentry with PII scrubbing, 180-day log retention in India (CERT-In).

## 3. Incident response (summary)
1. Detect (alerts, Sentry, WAF, user report) → incident commander assigned.
2. Contain within 1 hour; preserve logs.
3. **Report to CERT-In within 6 hours** of noticing a reportable incident **[Likely]**; notify partner lender immediately (they carry RBI reporting).
4. DPDP: notify the Data Protection Board and affected users per the Rules.
5. Post-mortem within 5 business days.

## 4. Open security gaps (honest list)
- ❌ No crypto service, auth, or rate limiting yet. Those are Phase 1 and 2.
- ❌ No CI pipeline yet (Phase 1 adds lint, typecheck, unit tests, DB integrity tests, secret scan, dependency audit).
- ❌ No pen test / VAPT. Lenders will demand a CERT-In-empanelled auditor's report before integration. Budget for it in Phase 6.
- ❌ Postgres RLS for tenant isolation not yet designed in SQL. Application-layer scoping comes first.

## Reporting a vulnerability
Email security@<your-domain> (to be set up). Do not open public issues for security bugs.
