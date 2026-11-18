# Screen-by-screen UI plan (deliverable D)

Global rules for every customer screen:
- **Mobile-first at 360 px**, single column, sticky primary CTA at the bottom, 44 px touch targets, WCAG 2.1 AA contrast.
- **Lender name and RBI registration shown** wherever an offer, KFS or loan appears. While no lender is signed: "MOCK LENDER (demo)".
- **Demo banner** while `INTEGRATION_MODE=mock`. Mock results carry a "Mock result" badge.
- No "instant", "guaranteed" or "pre-approved" copy. Times are stated as "usually" only once measured.
- Every async step has loading, success, failure and retry states, plus a "save and continue later" path.
- Stepper on application screens: *Verify · Identity · Details · Bank · Offer · Sign · Receive*.

## Reference funnel notes
The reference site (tejasloan.com/apply/pan-mobile) is a JS-rendered app. Only its HTML head was retrievable from this environment, so this plan doesn't copy its layout. Its metadata leads with "Instant Approval" and "instant disbursal". QuickCred deliberately does the opposite: APR and total repayment first, lender identity up front.

## A. Public website
| ID | Screen | Purpose and key content | States / notes |
|---|---|---|---|
| P-1 | Home | Hero "Get Financial Support When You Need It.", subtext, Apply CTA, calculator (P-3 embedded), eligibility summary, How it works (4 steps), features, security and privacy, **lending partner disclosure block**, FAQ, support, footer with legal links + grievance officer | Partner block shows lender name, RBI reg no., link to lender's site and RBI DLA directory |
| P-2 | Loan products | Cards per configured product: tenure, amount range, representative APR example, fees | Data from `/v1/public/products`; "illustrative, final terms by lender" |
| P-3 | Calculator | Inputs: amount slider, tenure picker, rate, fee. Outputs: principal, interest, fee, GST, **net disbursement**, **total repayment**, **APR (shown as large as total repayment)**, due date, instalments | Server-computed via `/v1/public/calculator` so the numbers match the KFS exactly |
| P-4 | Eligibility explainer | What's checked, documents needed, who can apply (age, income, residency) | No result shown here (spec 5.4) |
| P-5 | How it works | Step detail including consent and data use | |
| P-6 | Security and privacy | Encryption, data in India, what we never access (contacts, photos, SMS) | |
| P-7 | FAQ | Fees, APR, cooling-off, foreclosure, grievance | |
| P-8 | Support / contact | Ticket form (creates complaint), phone, email, hours | |
| P-9 | Legal | Terms, Privacy notice (DPDP itemised), Fair Practices Code, Grievance policy, Sample KFS, Partner list | Counsel-drafted text required |

## B. Customer application
| ID | Screen | Content | API |
|---|---|---|---|
| C-1 | Mobile number | Phone input, T&C + privacy consent checkboxes (unticked by default), Send OTP | `POST /auth/otp/send` |
| C-2 | OTP | 6-digit input, countdown, resend after cooldown, attempts left | `POST /auth/otp/verify` |
| C-3 | Basic eligibility | Requested amount, tenure, monthly income, employment type, existing EMIs | `POST /applications` |
| C-4 | PAN | PAN, name as on PAN, DOB; consent for PAN verification | `POST /applications/:id/pan` |
| C-5 | KYC method | Choose DigiLocker / offline Aadhaar XML / V-CIP (lender-enabled methods only); masked display | `POST /applications/:id/kyc` → redirect |
| C-6 | KYC result | Verified / failed with reason / manual review | `GET /applications/:id` |
| C-7 | Personal details | Email, current + permanent address (same-as toggle), occupation, employer | `PATCH /applications/:id/profile` |
| C-8 | Income | Salaried: salary, employer, tenure, slip upload. Self-employed: business income, statements | `POST /applications/:id/documents` |
| C-9 | Bank account | Account no. (twice), IFSC lookup, holder name; penny-drop status | `POST /applications/:id/bank-accounts` |
| C-10 | Account Aggregator | Explain purpose, data range, retention; continue to AA → return; status polling | `POST /applications/:id/aa/consents` |
| C-11 | Assessment in progress | Steps: bureau, bank analysis, checks. Honest timing | `GET /applications/:id` |
| C-12 | Offer(s) | Per lender card: amount, tenure, APR, fees, GST, net disbursement, total repayment, due date. Comparison layout from day one (multi-lender rule) | `GET /applications/:id/offers` |
| C-13 | KFS | Standard KFS rendered + PDF download, language choice, acknowledgement checkbox | `GET /offers/:id/kfs` |
| C-14 | Agreement and e-sign | Agreement preview, consent, e-sign redirect | `POST /offers/:id/accept`, `POST /offers/:id/esign` |
| C-15 | Disbursement status | Pending lender authorization → processing → credited (UTR) / failed | `GET /loans/:id` |
| C-16 | Rejected / referred | Plain-language reason codes, what to do next, reapply-after date | |

## C. Customer loan dashboard
| ID | Screen | Content |
|---|---|---|
| L-1 | Home | Active loan card: outstanding, due date, Pay now; cooling-off banner with "Cancel loan" while in look-up period |
| L-2 | Loan detail | Principal, interest accrued, fees, schedule, payment history, lender details |
| L-3 | Pay | Amount options (due / full / custom), UPI intent / link, mandate status |
| L-4 | Receipts and documents | Receipts, KFS, agreement, NOC, closure certificate |
| L-5 | Foreclosure | Payoff quote valid until date, breakdown |
| L-6 | Support | Raise complaint, track ticket, escalation path to lender GRO and RBI Ombudsman |
| L-7 | Privacy centre | Consents list with withdraw, data export request, deletion request |

## D. Admin (one app, role-scoped nav)
| ID | Screen | Roles |
|---|---|---|
| A-1 | Login + MFA | all staff |
| A-2 | Dashboard: customers, applications by status, approvals, disbursement volume, outstanding, collections, overdue, delinquency, PAR, repayment success, fraud alerts | ops, lender_viewer (own lender) |
| A-3 | Applications list (filters, SLA chips) → detail with tabs: Summary, KYC, Bank, Bureau, Fraud, Decision, Documents, Notes, History | underwriter, ops |
| A-4 | Manual review queue: approve / reject / request docs with mandatory reason | underwriter |
| A-5 | Customers (masked PII; reveal is audited) | ops, support |
| A-6 | Disbursements: maker queue, checker queue, failures, retries | finance_maker, finance_checker |
| A-7 | Repayments and reconciliation | finance |
| A-8 | Collections: buckets, cases, contact log (window-enforced) | collections |
| A-9 | Complaints with SLA clock | support |
| A-10 | Reports + CSV export | ops, auditor |
| A-11 | Audit log viewer | auditor, super_admin |

## E. Super-admin
| ID | Screen |
|---|---|
| S-1 | Lenders: onboarding checklist (agreement ref, GRO, DLG, CIMS), status |
| S-2 | Products: versioned config, APR preview against ceiling, activate requires lender approval ref |
| S-3 | Providers: per lender, mode (mock/sandbox/live), secret ref, health; switching to live needs 2-person approval |
| S-4 | Webhook monitor and API health |
| S-5 | Staff, roles and permissions |
| S-6 | Risk analytics, compliance monitor (complaints ageing, consent withdrawals, DLG utilisation) |
| S-7 | System settings |

## Mobile (Expo, later)
Same C and L screens; native UPI intent; no device permissions beyond camera for KYC through the lender's provider SDK.
