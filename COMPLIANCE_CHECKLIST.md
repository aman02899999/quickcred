# Regulatory gap assessment and compliance checklist (deliverable G, part 1)

> Status: pre-Phase 1, 18 Nov 2026. This is an engineering reading of Indian lending regulation, **not legal advice**.
> Every item marked ⚠️ needs sign-off from a fintech lawyer and the partner lender's compliance team before go-live.
> Confidence tags: **[Certain]** = verified in this repo or by computation; **[Likely]** = strong recollection of the regulation, verify the exact clause; **[Guessing]** = inference.

## 0. The five problems to solve before code matters

These are business and legal blockers. No amount of engineering removes them.

### 0.1 There is no lender. Without one, QuickCred cannot lend a rupee.
- **[Likely]** Under the RBI (Digital Lending) Directions, 2025, an LSP only sources, services and provides technology. Credit decision, sanction, disbursement from the lender's own account, KFS issuance and grievance ownership sit with the Regulated Entity (RE).
- **[Likely]** The alternative, your own NBFC-ICC registration, needs Net Owned Fund on a glide path to ₹10 crore (by March 2027), plus 12–24 months of RBI process. Not a near-term path.
- **What the code does about it:** `lenders.lsp_agreement_ref` is null today, and the API refuses to boot any provider in `live` mode without `LENDER_AUTHORIZATION_REF` + `APP_ENV=production` (`apps/api/src/config/integration-mode.ts`, 5 tests). **[Certain]**
- **What you must do:** sign at least one NBFC/bank partner. Their credit policy, pricing ceiling, KYC (KUA licence), bureau membership, AA FIU registration and payout accounts are all things QuickCred *borrows*. Until then this is a demo.

### 0.2 15-day tenures make the APR look predatory, by arithmetic.
The KFS rules (RBI circular of April 2024, in force from 1 Oct 2024, carried into the 2025 Directions) **[Likely]** require the APR to include *all* charges collected from the borrower: interest, processing fee, GST on fees, and any third-party charges. A flat fee spread over 15 days annualises brutally.

Computed in this repo (₹10,000 principal, bullet repayment, fee deducted upfront with 18% GST, nominal APR = IRR × 365/days) **[Certain about the arithmetic; Likely about the exact RBI annualisation convention]**:

| Interest p.a. | Processing fee | 15 days | 30 days | 60 days | 100 days |
|---|---|---|---|---|---|
| 24% | 2% + GST | **83.4%** | 54.0% | 39.3% | 33.4% |
| 24% | 5% + GST | **178.1%** | 101.8% | 63.6% | 48.4% |
| 36% | 2% + GST | **95.7%** | 66.3% | 51.6% | 45.7% |
| 365% (1%/day, the payday norm) | 2% + GST | **432.6%** | 403.2% | 388.5% | 382.6% |

So even a "cheap" 24% loan shows an 83% APR at 15 days, because the ₹236 fee+GST dominates ₹99 of interest.

- **Why it matters:** RBI does not cap NBFC rates, but **[Likely]** requires a board-approved interest-rate model and has taken supervisory action against lenders for usurious pricing. Partner lenders have their own APR ceilings, and a 15-day product will hit them first. App stores (Google Play's personal-loan policy) **[Likely]** also prohibits personal loans that require full repayment in **60 days or less**, and in India requires the app to be on the RBI's DLA list. That rule alone would keep the 15, 30, 45 *and* 60-day products out of the Android app. Only 75 and 100 days survive on Play; the website is not bound by it.
- **I disagree with leading on 15-day products** because the APR disclosure makes them unmarketable, Play policy may reject them, and partner lenders will push back. **Here's what I'd do instead:** make 75–100 days the default (the only tenures that clear Play policy), keep 30–60 days web-only and only if the lender approves and the APR stays inside their ceiling, and drop the processing fee to a small flat amount for short tenures. **The risk in your approach** is a KFS that shows 100%+ APR on the first screen, which kills conversion and invites regulator and press attention.
- **What the code does:** `loan_products.apr_ceiling` blocks any offer above the lender's board-approved APR (enforced in the Phase 4 offer service). The calculator will show APR first, not buried.

### 0.3 DLG/FLDG has hard limits. Don't plan a model that depends on more.
- **[Likely]** Default Loss Guarantee from an LSP is capped at **5% of the disbursed portfolio** it covers, must be in the form of cash deposit, FD with lien, or bank guarantee, needs a written contract, and the LSP must be a company incorporated under the Companies Act. DLG cannot be invoked beyond 120 days overdue.
- **[Likely]** The 2025 Directions carried forward the 2023 DLG guidelines largely unchanged.
- **Implication:** lenders will price for the risk above 5%. If your unit economics assume the lender takes near-zero risk because you guarantee it, they don't work.
- **Code:** `lenders.dlg_arrangement` records type, cover %, instrument and validity, and Phase 5 reports track DLG utilisation per lender.

### 0.4 Multi-lender display rules apply as soon as you sign a second lender.
- **[Likely]** The 2025 Directions require an LSP working with several REs to show the borrower all offers from lenders willing to lend, with an unbiased, consistent display (lender name, amount, tenure, APR, monthly repayment, penal charges), and no dark patterns pushing one lender.
- **Code:** offers are per-lender rows (`loan_offers.lender_id`). The offer screen (D-12) is designed as a comparison list from day one.

### 0.5 "QuickCred" naming and the reference site.
- **[Guessing]** Several Indian lending apps and NBFCs use "Quick Credit" / "QuickCredit" names. Run a trademark search (Class 36) and check the RBI's DLA directory before spending on the brand.
- The reference site's page metadata advertises "Instant Approval" and "instant disbursal" **[Certain, from its HTML head]**. Its rendered body couldn't be inspected from this environment (JS app, and the browser tunnel was refused). Do not copy that positioning. The spec already forbids unsubstantiated "instant/guaranteed" claims.

## 1. Regulation-by-regulation checklist

Legend: ✅ designed/implemented in this repo · 🟡 designed, built in a later phase · ⚠️ needs a lender/legal decision · ❌ gap

### RBI (Digital Lending) Directions, 2025 [Likely, verify clause numbers]
| # | Requirement | Status | Where |
|---|---|---|---|
| DL-1 | Disbursement directly from RE's bank account to borrower's account. No LSP pass-through or pool account | ✅ schema / 🟡 code | `disbursements.source_account_ref` is the lender account; there is no QuickCred pool account in the ledger chart |
| DL-2 | Repayments directly into RE's account (or RE's escrow), not LSP | 🟡 | Phase 4 payment-link creation under lender's PG merchant |
| DL-3 | LSP fees paid by the RE, never charged to borrower | 🟡 | No LSP fee field on borrower side by design |
| DL-4 | KFS before contract, standard format, with APR and all charges | 🟡 Phase 4 | `loan_offers` stores the KFS snapshot; terms immutable by trigger ✅ |
| DL-5 | Charges not in KFS cannot be levied without consent | ✅ schema | `loan_offers` terms immutable (trigger test) |
| DL-6 | Cooling-off/look-up period ≥ 1 day. Exit by paying principal + proportionate APR, no penalty | ✅ schema / 🟡 code | `loan_products.cooling_off_days >= 1` CHECK (test T7); `loan_account_status.cancelled_in_cooling_off` |
| DL-7 | Data collection need-based, with explicit consent, purpose-specific; no access to files, media, contacts, call logs, telephony | ✅ policy | No such permissions in web/mobile; `consent_records` per purpose |
| DL-8 | Borrower can deny/revoke consent and request deletion | 🟡 Phase 2 | append-only `consent_records` with `withdrawn` rows |
| DL-9 | Data stored only on servers in India | ⚠️ infra | AWS ap-south-1/ap-south-2 only (DEPLOYMENT_GUIDE) |
| DL-10 | No biometric data stored by LSP | ✅ | no column exists for it |
| DL-11 | Grievance redressal officer for LSP and lender, displayed on site/app | 🟡 Phase 1 | `lenders.grievance_officer_*`; footer component |
| DL-12 | Unresolved complaint in 30 days → RBI Integrated Ombudsman | ✅ schema | `complaints.resolution_due_at` |
| DL-13 | Lender name shown upfront on every screen where an offer appears | 🟡 Phase 1/4 | design rule in UI plan |
| DL-14 | Recovery agent details shared with borrower in advance | 🟡 Phase 5 | `collections_cases.recovery_agency_ref` |
| DL-15 | No automatic credit-limit increase without explicit consent | ✅ by scope | no revolving limits in scope |
| DL-16 | RE reports DLAs to RBI CIMS; DLA appears in RBI's public directory | ⚠️ lender | `lenders.cims_dla_reported` |
| DL-17 | Multi-lender unbiased offer display | 🟡 Phase 4 | see 0.4 |
| DL-18 | Credit information of LSP-sourced loans reported to CICs by RE | ⚠️ lender | lender's job; we export data |
| DL-19 | DLG ≤ 5% and in permitted forms | ⚠️ commercial | see 0.3 |

### KFS and pricing [Likely]
| # | Requirement | Status |
|---|---|---|
| KFS-1 | APR computed by IRR over actual cash flows, including fees, GST, third-party charges | 🟡 Phase 4, finance package with independent reference tests |
| KFS-2 | KFS in a language the borrower understands; acknowledgement recorded | 🟡 `consent_records.language`, `notice_hash` |
| KFS-3 | Penal charges, not penal interest; not capitalised (RBI penal-charges circular, Jan 2024) | ✅ schema: separate `penal_outstanding`, `penal_charge_per_day` |
| KFS-4 | Repayment schedule annex for instalment products | 🟡 `loan_offers.schedule_preview` |
| KFS-5 | GST at 18% on fees only; interest exempt | ✅ schema default `gst_rate=0.18` on fees |

### KYC / AML [Likely]
| # | Requirement | Status |
|---|---|---|
| KYC-1 | Aadhaar e-KYC only via an entity authorised as KUA/sub-KUA. The **lender's** licence, not QuickCred's | ⚠️ lender |
| KYC-2 | Offline Aadhaar XML / DigiLocker allowed with masked number | 🟡 mock adapter Phase 2 |
| KYC-3 | Store only last-4 Aadhaar digits; full number only in an Aadhaar Data Vault if legally required | ✅ schema has `aadhaar_last4` + `aadhaar_vault_ref` only |
| KYC-4 | V-CIP per KYC Master Direction (live, in India, geo-tagged, auditor-recorded) | 🟡 provider via lender |
| KYC-5 | CKYC search/upload | ⚠️ lender |
| KYC-6 | PMLA: STR/CTR reporting to FIU-IND is the RE's obligation; LSP flags suspicious patterns | 🟡 fraud engine Phase 3 |

### Credit bureau [Likely]
| # | Requirement | Status |
|---|---|---|
| CIC-1 | Only CIC members (the lender) may pull reports; LSP calls under the lender's membership | ⚠️ lender, `credit_reports.lender_id NOT NULL` ✅ |
| CIC-2 | Explicit borrower consent per pull | ✅ `credit_reports.consent_record_id NOT NULL` |
| CIC-3 | No adverse decision solely on one score; reasons recorded | ✅ `underwriting_decisions.reason_codes`, component scores |

### Account Aggregator [Likely]
| # | Requirement | Status |
|---|---|---|
| AA-1 | FIU must be a regulated entity: the lender is FIU, QuickCred is its TSP | ⚠️ lender `AA_FIU_ID` |
| AA-2 | Consent artefact purpose/duration minimal; data deleted when purpose served | ✅ `aa_sessions.purge_after` |

### DPDP Act 2023 and DPDP Rules 2025 [Likely]
| # | Requirement | Status |
|---|---|---|
| DP-1 | Notice + free, specific, informed consent per purpose; itemised notice | ✅ consent model |
| DP-2 | Withdrawal as easy as giving consent | 🟡 Phase 2 UI |
| DP-3 | Erasure when purpose ends, subject to legal retention (RBI/PMLA: 5+ years after relationship ends **[Likely]**) | 🟡 retention job Phase 6 |
| DP-4 | Breach notification to Data Protection Board and affected users | 🟡 incident runbook (SECURITY_POLICY) |
| DP-5 | Most Rules obligations phase in ~18 months after Nov 2025 notification **[Likely]** → mid-2027 | plan for compliance at launch anyway |

### Other
| # | Requirement | Status |
|---|---|---|
| OT-1 | CERT-In: report incidents within 6 hours; keep ICT logs 180 days in India **[Likely]** | 🟡 SECURITY_POLICY |
| OT-2 | TRAI DLT registration for SMS headers/templates | ⚠️ `notifications.dlt_template_id` |
| OT-3 | Fair Practices Code: no harassment, calls only 08:00–19:00 **[Likely]**, no contact with borrower's contacts | 🟡 Phase 5 contact-window enforcement; `contact_attempts_today` |
| OT-4 | Play Store personal-loan policy: declaration, lender disclosure, no loans repayable in ≤ 60 days | ⚠️ blocks 15–60 day products in the Android app (see 0.2) |
| OT-5 | Foreclosure: disclose any prepayment charge in KFS; cooling-off exit always free | 🟡 Phase 4 |

## 2. What I need you (or a lawyer) to decide

1. Which lender you're talking to, and whether they hold KUA, CIC membership, an AA FIU registration and a PG/payout setup we can integrate with.
2. Whether 15/30/45-day products stay in scope given 0.2. My recommendation: build the engine for any tenure, but launch with 75/100 days everywhere and 30–60 days on web only if the lender's APR ceiling allows.
3. The DLG commitment, if any, and its cap.
4. Grievance officer names and contact for QuickCred as LSP.
