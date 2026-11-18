# System architecture (deliverable A: architecture assessment)

## 1. Assessment of the starting point

- **No existing codebase.** None of the owner's 13 GitHub repositories is a lending product, so QuickCred is a greenfield monorepo. Nothing existing gets overwritten.
- **The spec is a 12–18 month roadmap for a funded team, written as one prompt.** It asks for 16 deliverables: web, mobile, admin, super-admin, lender portal, LOS, LMS, ledger, underwriting and more. Done properly, this is the work of 6–10 engineers for a year. The plan below orders it so each phase leaves a working, demonstrable slice. Expect the later phases to be shaped by whichever lender you sign, so they shouldn't be over-built now.
- **The biggest architectural fact is regulatory:** QuickCred is an LSP. The lender owns the book, the money and the KYC/bureau/AA licences. The architecture therefore treats every external capability as a lender-scoped, swappable adapter, and treats QuickCred's ledger as a servicing mirror of the lender's book, not the book of record.

## 2. Shape: modular monolith

One NestJS API process, with hard module boundaries, one Postgres, Redis for queues. Split into services only when a module needs independent scaling or a separate compliance boundary (the ledger is the first candidate).

```
                ┌────────────── apps/web (Next.js) ──────────────┐
 Customers ───► │  public site · calculator · apply flow · loan  │
 Staff ───────► │  /admin · /super · /lender (role-gated)        │
                └───────────────────────┬────────────────────────┘
 Expo app (later) ──────────────────────┤  REST /v1, JWT
                                        ▼
 ┌──────────────────────────── apps/api (NestJS) ────────────────────────────┐
 │ auth  identity  consent  onboarding  banking(AA)  credit  fraud           │
 │ underwriting  products  los  offers/kfs  documents/esign                  │
 │ lms  payments(disb/repay)  ledger  collections  complaints  notifications │
 │ admin/rbac  audit  integrations(registry, webhooks)                       │
 │                                                                            │
 │ adapters/  pan · kyc · aa · bureau · esign · payout · pg · sms · email    │
 │            each: interface + MockAdapter (labelled) + LiveAdapter (later) │
 └──────┬──────────────────────┬───────────────────────┬─────────────────────┘
        ▼                      ▼                       ▼
   Postgres 16            Redis + BullMQ          S3 (SSE-KMS)   KMS   Secrets Manager
   (packages/db)          jobs: OTP, AA fetch,    documents       envelope keys
                          bureau, accrual, dunning,
                          recon, webhooks
```

### Module rules
1. A module owns its tables. Other modules call its service, never its tables.
2. Status changes go through a state machine (`los` for applications, `lms` for accounts) that writes an immutable event row in the same transaction.
3. Money is computed once, in `packages/finance` (Phase 4), using decimal arithmetic. Stored results are displayed, never recomputed in UI code.
4. Every adapter call records `mode` and `is_mock` on the resulting row. A mock result can never become a `verified` state outside `APP_ENV=local|staging` (enforced in the adapter registry).
5. Every write by staff produces an `audit_logs` row with a reason for critical actions.

## 3. Key flows

**Application → disbursement (happy path)**
OTP login → consents (T&C, privacy, KYC, bureau, AA) → PAN verify → KYC (lender's KUA via provider) → profile → AA consent + fetch → bank analysis → bureau pull (lender membership) → fraud score → underwriting decision (approve / refer to manual / decline, with reasons) → offer(s) priced by finance package, with APR ≤ product ceiling → KFS shown and acknowledged → e-sign agreement → sanction → maker raises payout from **lender account** to verified borrower account → checker approves → provider webhook (signed) → ledger posts → loan account `cooling_off` → `active`.

**Repayment**
Payment link / UPI intent / mandate under the **lender's** merchant account → signed webhook → idempotent repayment row → allocation waterfall (penal → fees → interest → principal, lender-configurable) → ledger → receipt → closure + NOC when principal and all dues are zero.

## 4. Tenancy
- `lenders` is the tenant. Every financial row carries `lender_id`.
- Customers are platform-level (`users`), because one borrower may apply to several lenders. Sharing a borrower's data with a second lender requires a fresh lender-specific consent row.
- Staff are either platform (`admin_users.lender_id IS NULL`) or lender-scoped.

## 5. Technology choices (from the spec, with notes)

| Area | Choice | Note |
|---|---|---|
| Web | Next.js 16 App Router, React 19, Tailwind 4, shadcn/ui | Admin and customer in one app, separated by route groups and middleware. Split later if needed |
| API | NestJS 11, REST, OpenAPI at `/docs` | URI versioning `/v1` |
| DB | Postgres 16 + Drizzle | SQL-first migrations, custom SQL for triggers |
| Jobs | Redis 7 + BullMQ | Phase 2 onwards |
| Mobile | Expo | After web flow is proven. No contacts, SMS, call-log or media permissions |
| Infra | AWS ap-south-1 / ap-south-2, Docker, GitHub Actions, OTel, Sentry, WAF | Data localisation |

## 6. What I'd push back on in the spec
- **"Separate financial ledger service"** now: I disagree. A separate deployable before there is one lender and one product adds distributed-transaction pain with no benefit. Here's what I'd do instead: keep it a module with its own tables and an append-only, DB-enforced balance invariant (done), and split it once volume or a lender's audit demands it. The risk in splitting now is payout/ledger inconsistency across two databases, which is exactly the bug class you can't afford.
- **Lender portal + super admin + admin as three UIs:** one admin app with role-scoped navigation covers all three until a lender asks for white-labelling.
- **Mobile app in parallel with web:** don't. It doubles UI work on a flow that will change once the lender's credit policy lands, and Play policy may block your shortest tenures anyway (COMPLIANCE_CHECKLIST §0.2).
