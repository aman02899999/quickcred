# QuickCred

Digital lending platform for short-term personal loans in India, built to operate as a **Lending Service Provider (LSP)** for RBI-regulated lenders.

> ⚠️ **Demo / development build.** No lender partner is connected. Every external provider (PAN, KYC, Account Aggregator, credit bureau, e-sign, payouts, payments) is a clearly labelled mock. The API refuses to start any provider in live mode without a lender authorization reference. No real loans, KYC checks or money movement happen here.

## Status
**Phase 0 complete** (assessment, skeleton, schema). Phase 1 awaits owner approval. See [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md).

## Repository layout
```
apps/web      Next.js 16 customer site + admin (Tailwind 4)
apps/api      NestJS 11 REST API (OpenAPI at /docs)
apps/mobile   Expo app (placeholder, built after Phase 4)
packages/db   Drizzle schema, SQL migrations, DB integrity tests
docs/         UI screen plan
```

## Docs
| Doc | Content |
|---|---|
| [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) | A. Architecture assessment |
| [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md) | B. Implementation plan |
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | C. Database schema |
| [docs/UI_SCREEN_PLAN.md](docs/UI_SCREEN_PLAN.md) | D. Screen-by-screen UI plan |
| [API_DOCUMENTATION.md](API_DOCUMENTATION.md) | E. API contract |
| [PROVIDER_INTEGRATIONS.md](PROVIDER_INTEGRATIONS.md) | F. Integration strategy |
| [COMPLIANCE_CHECKLIST.md](COMPLIANCE_CHECKLIST.md) · [SECURITY_POLICY.md](SECURITY_POLICY.md) | G. Regulatory and security gap assessment |
| [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) | Scope decisions |
| [TESTING_REPORT.md](TESTING_REPORT.md) · [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Test results, setup |

## Quick start
See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#local-development-works-today).
