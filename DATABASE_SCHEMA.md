# Database schema (deliverable C)

Source of truth: `packages/db/src/schema/*.ts` (Drizzle) → `packages/db/migrations/0000_init.sql` (generated) + `0001_integrity_triggers.sql` (hand-written).
Verified on 18 Nov 2026: both migrations applied cleanly to PostgreSQL 16, creating **42 tables**, and `packages/db/test/integrity.sql` passes **7/7**.

## Conventions
| Rule | Implementation |
|---|---|
| UUID ids | `gen_random_uuid()` defaults on every table |
| Money | `NUMERIC(18,2)` INR, never float. Rates `NUMERIC(12,8)` as fractions (0.24 = 24% p.a.) |
| Sensitive data | `*_enc BYTEA` envelope-encrypted; `*_hash` HMAC blind index for lookup/dedupe; `*_last4` for display |
| Aadhaar | Only `aadhaar_last4` and an optional vault reference token. No full number, no biometrics |
| Tenancy | `lender_id` on every financial row; indexes lead with `lender_id` where queried by lender |
| Mock vs live | Every provider-derived row has `mode` + `is_mock NOT NULL` |
| Immutability | Append-only tables blocked from UPDATE/DELETE by trigger; corrections are new rows (reversals) |
| Soft delete | Only on `lenders`, `users`, `admin_users`. Never on financial or audit rows |
| Optimistic locking | `version` on `loan_applications`, `loan_accounts` |

## Tables by domain

### Tenancy and products
- **lenders**: regulated entity, RBI registration, grievance officer, `lsp_agreement_ref` (null ⇒ no live paths), `dlg_arrangement`, `cims_dla_reported`.
- **loan_products**: per lender, versioned. Tenure/amount ranges, rate, fee (rate + flat), GST rate, penal charge, `cooling_off_days ≥ 1` (CHECK), `apr_ceiling`.

### Identity and consent
- **users**: phone (enc + hash unique + last4), status.
- **user_profiles**: encrypted name/DOB/email/PAN/addresses; `pan_hash` UNIQUE ⇒ duplicate-PAN detection at DB level.
- **otp_challenges**: hashed code, attempts, expiry, IP/device for abuse detection.
- **devices**, **user_sessions** (refresh token hashed, revocable).
- **identity_verifications**: one row per PAN/KYC/V-CIP/penny-drop attempt, name-match score, encrypted provider response.
- **consent_records** (append-only): purpose, granted/withdrawn, notice version + SHA-256 of exact text shown, language.

### Banking (AA)
- **bank_accounts**: encrypted number + hash; unique per user; non-unique index on hash to flag one account used by many users.
- **aa_sessions**: consent handle/id, status lifecycle, FI types, date range, `purge_after` retention.
- **bank_transactions**: normalised, narration encrypted, derived category.
- **bank_analyses**: salary, EMI, bounces, balances, feature JSON, engine version.

### Credit, fraud, decisions
- **credit_reports**: `lender_id NOT NULL` (pulled under lender's CIC membership), `consent_record_id NOT NULL`, encrypted report, `purge_after`.
- **credit_scores**: parsed summary (score nullable for NTC, DPD, enquiries, obligations).
- **fraud_assessments**: score, signals JSON, hard-stop, reviewer.
- **underwriting_decisions** (append-only): policy version, component scores, risk band, outcome, reason codes, override reason.

### LOS
- **loan_applications**: 17-state enum exactly as spec Part 10; partial unique index allows **one open application per user**; SLA + assignment.
- **application_events** (append-only): full status history with actor.
- **loan_offers**: priced terms + KFS reference; CHECK `net = principal − fee − GST − other`; terms immutable by trigger; DELETE blocked.
- **loan_documents**: S3 key, SHA-256, e-sign metadata, `is_mock_signed`, tamper flags.

### LMS and payments
- **loan_accounts**: balances are a ledger cache; status includes `cooling_off`, `cancelled_in_cooling_off`; DPD.
- **loan_schedules**: per instalment (bullet = 1 row).
- **disbursements**: idempotency key UNIQUE; **at most one non-failed payout per loan** (partial unique); **maker ≠ checker** (CHECK); `source_account_ref` = lender account.
- **repayments**: idempotency key UNIQUE; (provider, provider_ref) UNIQUE against webhook replays.
- **repayment_allocations** (append-only): waterfall result per bucket.
- **mandates**: e-NACH / UPI AutoPay with consent reference.

### Ledger
- **ledger_accounts** (chart per lender, optional per-loan sub-ledger), **ledger_transactions** (append-only, idempotent, reversal pointer), **ledger_entries** (append-only, amount > 0).
- **Deferred constraint trigger** rejects any transaction whose debits ≠ credits or with fewer than 2 entries, at COMMIT.

### Operations
- **admin_users**, **roles**, **permissions** (`is_critical`), **role_permissions**, **admin_user_roles** (lender-scoped).
- **audit_logs** (append-only, hash-chained `prev_hash`/`hash`).
- **collections_cases**, **complaints** (`resolution_due_at` for the 30-day ombudsman clock).
- **api_integrations** (mode, `secret_ref` pointer only, live approval fields), **webhook_events** (unique per provider event, signature result, encrypted payload), **idempotency_keys**, **notifications** (DLT template id, `is_mock`).

## Spec table list vs. delivered
All 32 tables named in spec Part 16 exist. Added because the spec's list can't enforce its own requirements without them: `lenders`, `otp_challenges`, `devices`, `bank_analyses`, `underwriting_decisions`, `application_events`, `ledger_transactions`, `role_permissions`, `admin_user_roles`, `idempotency_keys` (10 tables, 42 total).

## Integrity tests (packages/db/test/integrity.sql)
| Test | Result |
|---|---|
| T1 balanced ledger transaction accepted | PASS |
| T2 unbalanced transaction rejected at commit | PASS |
| T3 ledger entry UPDATE blocked | PASS |
| T4 audit log DELETE blocked | PASS |
| T5 numeric money exact (0.10 + 0.20 = 0.30) | PASS |
| T6 second open application for same user rejected | PASS |
| T7 product with cooling-off < 1 day rejected | PASS |

## Known schema decisions to revisit
- Postgres RLS policies for lender isolation (Phase 6).
- Partitioning `bank_transactions`, `audit_logs`, `ledger_entries` by month once volume warrants.
- Retention/purge jobs driven by `purge_after` (Phase 6), subject to RBI/PMLA retention minimums.
