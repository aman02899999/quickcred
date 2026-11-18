# Implementation plan and roadmap (deliverable B)

Rule from the product owner: one phase at a time, a working app after every phase, a PR per phase, approval before the next phase starts. Each phase ends with the report format from spec Part 21 (what was built, files, DB changes, endpoints, tests run/passed/failed, outstanding dependencies, security issues, next phase).

Estimates are for one senior full-stack engineer working with Claude, in calendar weeks. **[Guessing]**, so treat them as ordering, not commitments.

## Phase 0: Assessment and skeleton ✅ (this PR)
- Monorepo: `apps/web`, `apps/api`, `apps/mobile` (placeholder), `packages/db`.
- Full DB schema (42 tables) + integrity triggers, applied to Postgres 16, 7/7 integrity tests passing.
- API boots with `/v1/health` and `/docs`; live-provider boot guard with 5 unit tests.
- Web builds; demo banner; security headers.
- Docs A–G.

## Phase 1: Foundation (≈ 3 weeks)
Exit criteria: a stranger can open the site, read honest product info, use a calculator labelled *illustrative*, and staff can log in to an empty admin with MFA.
1. Tooling: ESLint/Prettier, GitHub Actions CI (typecheck, unit, DB integrity SQL, `next build`, secret scan, `pnpm audit`), Dockerfiles.
2. `packages/finance` (pulled forward from Phase 4 because the calculator needs it): decimal money, interest, fee + GST, IRR-based APR, schedule generator. Tested against an independent reference implementation (Python `decimal`) and the worked examples in COMPLIANCE_CHECKLIST §0.2.
3. Design system: tokens (navy/royal/teal palette), shadcn/ui setup, form controls, cards, tables, badges, modals, toasts, stepper, calculator widget, upload dropzone, light/dark for dashboards.
4. Public website: home, products, calculator, eligibility explainer, how it works, security, lender disclosures, FAQ, support, legal pages (terms, privacy, grievance, fair practices, KFS sample).
5. Crypto service: KMS envelope encryption (local key in dev), blind index HMAC.
6. Staff auth: admin users, argon2id, TOTP MFA, RBAC guard, seed roles/permissions, audit-log writer with hash chain.
7. Seed: one **MOCK LENDER** (clearly labelled), its products, and staff users.

## Phase 2: Customer application (≈ 4 weeks)
Exit: a customer can sign up with mock OTP, consent, verify PAN (mock), complete KYC (mock), add profile and bank account, upload documents, and see application status.
- OTP service (Redis rate limits, mock SMS adapter that shows the code only in local/staging).
- Customer sessions, device fingerprinting.
- Consent service + UI (grant/withdraw).
- Adapters: PAN mock, KYC mock (offline XML/DigiLocker shape), penny-drop mock.
- Application state machine `draft → … → kyc_verified → bank_verification_pending`.
- Document uploads to S3 (MinIO locally).

## Phase 3: Financial integrations (≈ 4 weeks)
- AA adapter interface + mock FIP data generator (labelled `MOCK FIP`), consent lifecycle, data fetch job.
- Bank-statement analysis engine (salary, EMI, bounce, balances) with fixture-based tests.
- Bureau adapter + mock reports covering thin-file, clean, delinquent, high-enquiry.
- Fraud engine: rules from spec Part 9, scored, explainable.
- Underwriting engine: weighted components (spec Part 8 defaults, labelled experimental), affordability/FOIR, risk bands, approve/refer/decline, manual review queue.

## Phase 4: Lending operations (≈ 5 weeks)
- Products admin, offer generation (APR ceiling enforced), KFS PDF, agreement PDF, e-sign mock.
- Sanction, maker-checker disbursement to mock payout (labelled), webhook verification, ledger posting.
- LMS: accrual job, schedules, repayments (mock PG), allocation waterfall, partial/full/foreclosure, cooling-off cancellation, receipts, NOC.
- Reconciliation job (ledger ↔ account balances ↔ provider statements).

## Phase 5: Admin and analytics (≈ 4 weeks)
- Admin dashboard metrics, application/KYC/underwriting/disbursement/repayment modules.
- Super-admin: lenders, products, providers (mode switch with approval), webhook monitor, API health.
- Lender-scoped views (same app, role-gated).
- Collections: DPD buckets, case assignment, contact-window enforcement, dunning via notifications.
- Complaints with 30-day escalation clock.

## Phase 6: Production readiness (≈ 4 weeks + lender-dependent)
- E2E (Playwright) for the full journey, load tests (k6), RLS for tenant isolation, backups/restore drill, OTel/Sentry, Terraform for AWS ap-south-1, WAF, VAPT by a CERT-In-empanelled auditor, UAT with lender, **live adapter work per signed provider**.

## Mobile
After Phase 4, once the web flow is stable. Expo app reusing the API. Android build ships only tenures that clear Play policy.

## Dependencies outside engineering (blockers for going live, not for building)
| Dependency | Needed by | Owner |
|---|---|---|
| Signed lender partner (NBFC/bank) | Phase 6 live, ideally by Phase 3 for credit policy | Aman |
| Lender's credit policy and pricing ceiling | Phase 3 underwriting calibration | Lender |
| Provider contracts (KYC, AA TSP, bureau via lender, e-sign, PG/payout) | Phase 6 | Aman + lender |
| Domain, DLT SMS registration, email domain | Phase 2 live OTP | Aman |
| Legal pages drafted by counsel | Phase 1 content (placeholders are marked) | Aman |
