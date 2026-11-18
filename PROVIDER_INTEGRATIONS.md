# Provider integration strategy (deliverable F)

## Principle
Core loan logic never imports a vendor SDK. Each capability is a TypeScript interface; implementations are registered per lender in `api_integrations`. **Today every implementation is a mock.** No provider in this repo has been tested with real credentials, so none may be described as "working".

```
capability interface  ──►  MockXAdapter    (labelled, deterministic fixtures, local/staging only)
                      ──►  SandboxXAdapter (vendor sandbox creds, staging)
                      ──►  LiveXAdapter    (lender-authorised, production only)
```

### Safety rails (enforced in code)
1. **Boot guard** ✅ `apps/api/src/config/integration-mode.ts`: any `*_MODE=live` throws unless `INTEGRATION_MODE=live`, `APP_ENV=production` and `LENDER_AUTHORIZATION_REF` are set. 5 unit tests.
2. **Row marking** ✅ schema: every provider-derived row stores `mode` + `is_mock`. Phase 2 adds a check that `is_mock=true` rows can't satisfy a sanction in production.
3. **Mock labelling:** mock adapters return names like `MOCK USER`, PANs in the `ZZZPZ` test range, provider refs prefixed `MOCK-`, and UI shows a "Mock result" badge.
4. **No fabricated success in live paths:** if a live provider is down, the step fails with a retry. It never falls back to mock.
5. **Secrets:** only `secret_ref` pointers in DB; values in AWS Secrets Manager; never in browser bundles.

## Capability map

| Capability | Interface methods | Candidate providers | Licence holder (who must contract) | Mock behaviour |
|---|---|---|---|---|
| SMS OTP | `send(phone, templateId, vars)` | MSG91, Gupshup, Kaleyra | QuickCred (DLT-registered) | Logs code; returns it in API response only when `APP_ENV=local` |
| PAN verify | `verify(pan, name, dob)` → status, nameMatch, dobMatch | NSDL/Protean via Karza, Signzy, Digio, IDfy | QuickCred or lender | Fixture table: valid / name mismatch / invalid / provider error |
| KYC | `start(method)` → redirect; `fetchResult(ref)` | DigiLocker (via provider), offline XML, V-CIP (IDfy, Signzy, HyperVerge) | **Lender** (KUA/sub-KUA; V-CIP by RE) | Simulated redirect page with outcome picker, labelled MOCK |
| Penny drop | `verifyAccount(acct, ifsc)` → holder name | Cashfree, Razorpay, Decentro | Lender's PA or QuickCred | Deterministic names from fixtures |
| Account Aggregator | `createConsent`, `consentStatus`, `fetchFI`, `revoke` | Finvu, OneMoney, CAMSfinserv (AAs); FinBox, Perfios (TSP/analytics) | **Lender as FIU**; QuickCred as TSP | Generated statements per persona (salaried-stable, gig-irregular, bouncing), labelled `MOCK FIP` |
| Statement analysis | internal engine (Phase 3); optional vendor `analyse(statement)` | in-house; Perfios / FinBox as optional | n/a | n/a |
| Bureau | `pull(applicant, consentId)` → report | CIBIL, Experian, CRIF, Equifax | **Lender** (CIC member) | Personas: thin-file/NTC, clean 780, delinquent 600, high-enquiry |
| e-Sign | `createRequest(doc)`, `status` | Aadhaar e-Sign via Digio, Leegality, SignDesk | Lender or QuickCred | Signature page labelled MOCK, stamps `is_mock_signed` |
| Payout | `createPayout(beneficiary, amount, idemKey)`, webhook | Lender's bank API, Cashfree/RazorpayX **on lender's account** | **Lender** | State machine with configurable success/failure/delay; never touches a bank |
| Collections PG | `createPaymentLink`, `upiIntent`, webhook | Razorpay, Cashfree, PayU **under lender merchant id** | **Lender** | Simulated payment page |
| Mandates | `createMandate`, `status`, `debit` | NPCI e-NACH / UPI AutoPay via PG | Lender | Simulated authorise/revoke |
| Email | `send` | SES (ap-south-1) | QuickCred | Writes to local mailbox (Mailpit) |
| WhatsApp | `sendTemplate` | Gupshup, Meta Cloud API | QuickCred, opt-in consent | Logged only |

## Going live, per provider (checklist)
1. Signed lender agreement covering the capability; lender names QuickCred as its LSP/TSP.
2. Provider contract (often in the lender's name), sandbox credentials → `SandboxXAdapter` passes contract tests.
3. Security review of the provider (data location in India, SOC2/ISO, DPA).
4. Live credentials stored in Secrets Manager by a super-admin; `api_integrations.mode=live` set via two-person approval.
5. Controlled pilot with lender's staff accounts, reconciled end to end, before any public traffic.
6. Only then update this doc's status column from "mock" to "certified on <date>".

## Current status
| Capability | Status |
|---|---|
| All | **Mock only. Not built yet.** Adapter interfaces start in Phase 2 (PAN, KYC, penny drop, SMS) and Phase 3 (AA, bureau). |
