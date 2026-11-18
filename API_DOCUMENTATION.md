# API contract (deliverable E)

Base URL `/v1`. JSON. Live OpenAPI at `GET /docs` (only `/v1/health` is implemented in Phase 0; everything else below is the contract each phase implements).

## Conventions
- **Auth:** customer `Authorization: Bearer <access JWT>` (15 min) + refresh. Staff: same, with `amr` claim requiring MFA; critical actions need a step-up token (`X-Step-Up`).
- **Idempotency:** every POST that creates money movement, offers or applications requires `Idempotency-Key` (UUID). Same key + same body ⇒ same response; same key + different body ⇒ `409`.
- **Money:** strings with 2 decimals (`"10000.00"`), never JSON numbers. Rates as strings (`"0.24000000"`).
- **Errors:** RFC 7807 `application/problem+json` with `code` (e.g. `OTP_EXPIRED`, `APR_ABOVE_CEILING`, `LIVE_MODE_REFUSED`).
- **Mock marking:** any response derived from a mock adapter includes `"isMock": true`.
- **Pagination:** cursor-based `?cursor=&limit=`.
- **Tenancy:** lender-scoped staff only see rows for their `lender_id`; enforced server-side.

## Public
| Method | Path | Purpose | Phase |
|---|---|---|---|
| GET | `/health` | Liveness + integration modes | ✅ 0 |
| GET | `/public/products` | Active products (illustrative terms) | 1 |
| POST | `/public/calculator` | `{amount, tenureDays, annualRate?, feeRate?}` → full KFS-style breakdown incl. APR | 1 |
| GET | `/public/lenders` | Partner disclosures (name, RBI reg, GRO) | 1 |
| POST | `/public/support` | Create support ticket / complaint | 1 |

## Customer auth
| Method | Path | Body → Response | Phase |
|---|---|---|---|
| POST | `/auth/otp/send` | `{phone, consents:[{purpose, noticeVersion}]}` → `{challengeId, resendAfterSec}`; 429 on limits | 2 |
| POST | `/auth/otp/verify` | `{challengeId, code, deviceFingerprint}` → `{accessToken, refreshToken, user}` | 2 |
| POST | `/auth/refresh` | `{refreshToken}` → rotated tokens | 2 |
| POST | `/auth/logout` | revoke session | 2 |

## Applications (customer)
| Method | Path | Purpose | Phase |
|---|---|---|---|
| POST | `/applications` | create draft `{requestedAmount, requestedTenureDays, declaredMonthlyIncome, employmentType, declaredExistingEmi}` | 2 |
| GET | `/applications/:id` | status, next required step, checklist | 2 |
| POST | `/applications/:id/pan` | `{pan, nameOnPan, dob}` → verification result | 2 |
| POST | `/applications/:id/kyc` | `{method}` → `{redirectUrl}` or `{status}` | 2 |
| PATCH | `/applications/:id/profile` | personal details | 2 |
| POST | `/applications/:id/documents` | presigned upload request → `{uploadUrl, documentId}` | 2 |
| POST | `/applications/:id/bank-accounts` | `{accountNumber, ifsc}` → penny-drop result | 2 |
| POST | `/applications/:id/aa/consents` | start AA → `{redirectUrl, consentHandle}` | 3 |
| POST | `/applications/:id/submit` | lock inputs, start assessment jobs | 3 |
| GET | `/applications/:id/offers` | list offers (multi-lender) | 4 |
| POST | `/applications/:id/cancel` | cancel before sanction | 2 |

## Offers and loans (customer)
| Method | Path | Purpose | Phase |
|---|---|---|---|
| GET | `/offers/:id/kfs` | KFS JSON + PDF link | 4 |
| POST | `/offers/:id/accept` | `{kfsAcknowledged:true, language}` | 4 |
| POST | `/offers/:id/esign` | start e-sign → redirect | 4 |
| GET | `/loans` / `/loans/:id` | dashboard data, schedule, history | 4 |
| POST | `/loans/:id/payments` | create payment intent `{amount}` (Idempotency-Key) | 4 |
| GET | `/loans/:id/foreclosure-quote` | payoff breakdown | 4 |
| POST | `/loans/:id/cooling-off-cancel` | exit in look-up period | 4 |
| GET | `/loans/:id/documents` | receipts, KFS, NOC | 4 |
| GET/POST | `/me/consents` | list / withdraw | 2 |
| POST | `/me/data-requests` | export or erasure request | 6 |

## Staff / admin (`/admin/*`)
| Method | Path | Permission | Phase |
|---|---|---|---|
| POST | `/admin/auth/login`, `/admin/auth/mfa/verify` | | 1 |
| GET | `/admin/dashboard/metrics` | `dashboard.view` | 5 |
| GET | `/admin/applications` · `/:id` | `application.view` | 3 |
| POST | `/admin/applications/:id/assign` | `application.assign` | 3 |
| POST | `/admin/applications/:id/decision` | `application.decide` (critical) `{outcome, reasonCodes, note}` | 3 |
| POST | `/admin/applications/:id/notes` | `application.note` | 3 |
| POST | `/admin/disbursements` | `disbursement.create` (maker) | 4 |
| POST | `/admin/disbursements/:id/approve` | `disbursement.approve` (critical, checker ≠ maker) | 4 |
| GET | `/admin/repayments`, `/admin/reconciliation/runs` | `finance.view` | 4 |
| GET/POST | `/admin/collections/cases…` | `collections.*` | 5 |
| GET/PATCH | `/admin/complaints…` | `complaint.*` | 5 |
| GET | `/admin/audit-logs` | `audit.view` | 1 |
| CRUD | `/admin/lenders`, `/admin/products`, `/admin/providers`, `/admin/staff`, `/admin/roles` | super-admin (critical) | 1/5 |
| POST | `/admin/customers/:id/reveal` | `pii.reveal` (audited, reason required) | 5 |

## Webhooks (inbound, `/webhooks/:provider`)
- Verify HMAC signature with provider secret + timestamp tolerance (5 min) **before** parsing business fields.
- Insert `webhook_events` with unique `(provider, provider_event_id)`; duplicates return 200 without reprocessing.
- Processing happens in a BullMQ job; the HTTP handler only verifies, stores and acks.
- Providers: `aa`, `kyc`, `esign`, `payout`, `pg`, `mandate`.
