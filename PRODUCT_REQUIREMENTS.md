# Product requirements

The full master specification from the product owner (18 Nov 2026) is the requirements baseline. This file records **scope decisions** made against it; the detailed screen plan is in `docs/UI_SCREEN_PLAN.md`.

## Product
Short-term personal loans, ₹1,000–₹1,00,000 (illustrative), tenures configured per lender product. QuickCred operates as a Lending Service Provider for RBI-regulated lenders; the lender makes credit decisions, sanctions and disburses.

## Scope decisions (pending owner approval)
| Topic | Spec says | Recommendation | Why |
|---|---|---|---|
| Tenures | 15, 30, 45, 60, 75, 100 days | Engine supports any tenure; launch 75/100 everywhere, 30–60 web-only if lender approves; 15 days off | APR optics under KFS rules and Play Store's 60-day rule (COMPLIANCE_CHECKLIST §0.2) |
| Lender | "under an agreement with an RBI-regulated lender" | Build against a clearly labelled MOCK LENDER until one is signed | No live path is possible without it |
| Admin / super-admin / lender portal | three interfaces | One admin app, role-scoped | Same data, less UI to maintain |
| Ledger | separate service | Module with DB-enforced invariants, split later | Avoid cross-DB consistency bugs |
| Mobile | in parallel | After Phase 4 | Flow will change once credit policy lands |
| Underwriting weights | 25/20/20/15/10/10 | Use as labelled experimental defaults, configurable per lender policy version | Not validated credit policy (spec agrees) |

## Non-negotiables carried from the spec
No hidden fees; APR shown prominently; no contacts/call-log/gallery access; no biometrics stored; masked Aadhaar; no guaranteed/instant claims; no real KYC/bureau/money without lender authorization; every mock labelled; complete audit trail.
