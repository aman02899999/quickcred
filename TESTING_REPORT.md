# Testing report

## Phase 0 (18 Nov 2026)

| Suite | Command | Result |
|---|---|---|
| Typecheck (api, web, db) | `pnpm -r typecheck` | ✅ pass, 0 errors |
| API unit: integration-mode boot guard | `pnpm --filter @quickcred/api test` | ✅ 5/5 pass |
| DB migrations on PostgreSQL 16 | `pnpm db:migrate` | ✅ 2 migrations applied, 42 tables |
| DB integrity controls | `psql "$DATABASE_URL" -f packages/db/test/integrity.sql` | ✅ 7/7 pass |
| API boot + health | `node apps/api/dist/main.js` → `GET /v1/health` | ✅ 200, all providers `mock`; `/docs` 200 |
| API refuses live payout | `PAYOUT_MODE=live node apps/api/dist/main.js` | ✅ exits with "PAYOUT_MODE=live refused" |
| Web production build | `pnpm --filter @quickcred/web build` | ✅ static `/` built |

**Failed:** none. **Not yet tested (nothing to test yet):** OTP, KYC, consent flows, bank ingestion, credit assessment, interest/APR/GST/schedules, disbursement, repayment, foreclosure, access control, webhooks, and E2E. Each lands with its phase. Financial calculations will be checked against an independent Python `decimal` reference (the same method used for the APR table in COMPLIANCE_CHECKLIST §0.2).
