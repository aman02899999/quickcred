import { boolean, check, date, index, integer, jsonb, pgTable, text, timestamp, uniqueIndex, uuid, varchar } from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { createdOnly, money, pk, rate, timestamps } from "./common";
import {
  actorType,
  allocationBucket,
  applicationStatus,
  disbursementStatus,
  documentType,
  integrationMode,
  loanAccountStatus,
  mandateStatus,
  offerStatus,
  repaymentChannel,
  repaymentStatus,
  scheduleStatus,
} from "./enums";
import { users } from "./identity";
import { bankAccounts } from "./banking";
import { lenders, loanProducts } from "./tenancy";

// ---------------------------------------------------------------- LOS

export const loanApplications = pgTable(
  "loan_applications",
  {
    id: pk(),
    applicationNo: varchar("application_no", { length: 24 }).notNull(),
    userId: uuid("user_id").notNull().references(() => users.id),
    lenderId: uuid("lender_id").references(() => lenders.id), // set once routed to a lender
    productId: uuid("product_id").references(() => loanProducts.id),
    status: applicationStatus("status").notNull().default("draft"),
    requestedAmount: money("requested_amount").notNull(),
    requestedTenureDays: integer("requested_tenure_days").notNull(),
    declaredMonthlyIncome: money("declared_monthly_income"),
    declaredExistingEmi: money("declared_existing_emi"),
    purpose: varchar("purpose", { length: 40 }),
    assignedTo: uuid("assigned_to"),
    slaDueAt: timestamp("sla_due_at", { withTimezone: true }),
    submittedAt: timestamp("submitted_at", { withTimezone: true }),
    decidedAt: timestamp("decided_at", { withTimezone: true }),
    rejectionReasonCodes: jsonb("rejection_reason_codes"),
    version: integer("version").notNull().default(1), // optimistic locking for state machine
    ...timestamps,
  },
  (t) => [
    uniqueIndex("loan_apps_no_uq").on(t.applicationNo),
    index("loan_apps_user_idx").on(t.userId),
    index("loan_apps_lender_status_idx").on(t.lenderId, t.status),
    index("loan_apps_assigned_idx").on(t.assignedTo, t.status),
    // one in-flight application per user (duplicate-application control)
    uniqueIndex("loan_apps_one_open_per_user_uq")
      .on(t.userId)
      .where(sql`status NOT IN ('rejected','cancelled','disbursed')`),
    check("loan_apps_amount_chk", sql`${t.requestedAmount} > 0`),
  ],
);

/** Immutable status history = application audit trail. */
export const applicationEvents = pgTable(
  "application_events",
  {
    id: pk(),
    applicationId: uuid("application_id").notNull().references(() => loanApplications.id),
    fromStatus: applicationStatus("from_status"),
    toStatus: applicationStatus("to_status").notNull(),
    actorType: actorType("actor_type").notNull(),
    actorId: uuid("actor_id"),
    note: text("note"),
    metadata: jsonb("metadata"),
    ...createdOnly,
  },
  (t) => [index("app_events_app_idx").on(t.applicationId, t.createdAt)],
);

/**
 * Offer = the priced terms + KFS snapshot. Immutable once generated; a re-price is a new offer.
 * All amounts are computed by the finance package and stored, never recomputed for display.
 */
export const loanOffers = pgTable(
  "loan_offers",
  {
    id: pk(),
    applicationId: uuid("application_id").notNull().references(() => loanApplications.id),
    lenderId: uuid("lender_id").notNull().references(() => lenders.id),
    productId: uuid("product_id").notNull().references(() => loanProducts.id),
    status: offerStatus("status").notNull().default("generated"),
    principal: money("principal").notNull(),
    tenureDays: integer("tenure_days").notNull(),
    annualInterestRate: rate("annual_interest_rate").notNull(),
    interestAmount: money("interest_amount").notNull(),
    processingFee: money("processing_fee").notNull(),
    gstOnFees: money("gst_on_fees").notNull(),
    otherCharges: money("other_charges").notNull().default("0"),
    netDisbursement: money("net_disbursement").notNull(),
    totalRepayment: money("total_repayment").notNull(),
    apr: rate("apr").notNull(),
    firstDueDate: date("first_due_date").notNull(),
    schedulePreview: jsonb("schedule_preview").notNull(),
    kfsVersion: varchar("kfs_version", { length: 24 }).notNull(),
    kfsDocumentId: uuid("kfs_document_id"),
    validUntil: timestamp("valid_until", { withTimezone: true }).notNull(),
    acceptedAt: timestamp("accepted_at", { withTimezone: true }),
    acceptanceConsentId: uuid("acceptance_consent_id"),
    ...createdOnly,
  },
  (t) => [
    index("loan_offers_app_idx").on(t.applicationId),
    check(
      "loan_offers_math_chk",
      sql`${t.netDisbursement} = ${t.principal} - ${t.processingFee} - ${t.gstOnFees} - ${t.otherCharges}`,
    ),
  ],
);

export const loanDocuments = pgTable(
  "loan_documents",
  {
    id: pk(),
    userId: uuid("user_id").notNull().references(() => users.id),
    applicationId: uuid("application_id").references(() => loanApplications.id),
    loanAccountId: uuid("loan_account_id"),
    type: documentType("type").notNull(),
    storageKey: text("storage_key").notNull(), // S3 key, SSE-KMS, ap-south-1
    sha256: varchar("sha256", { length: 64 }).notNull(),
    mimeType: varchar("mime_type", { length: 64 }).notNull(),
    sizeBytes: integer("size_bytes").notNull(),
    templateVersion: varchar("template_version", { length: 24 }),
    eSignProvider: varchar("esign_provider", { length: 32 }),
    eSignRef: text("esign_ref"),
    eSignedAt: timestamp("esigned_at", { withTimezone: true }),
    isMockSigned: boolean("is_mock_signed").notNull().default(false),
    tamperFlags: jsonb("tamper_flags"),
    ...createdOnly,
  },
  (t) => [index("loan_docs_app_idx").on(t.applicationId), index("loan_docs_account_idx").on(t.loanAccountId)],
);

// ---------------------------------------------------------------- LMS

export const loanAccounts = pgTable(
  "loan_accounts",
  {
    id: pk(),
    loanNo: varchar("loan_no", { length: 24 }).notNull(),
    lenderId: uuid("lender_id").notNull().references(() => lenders.id),
    userId: uuid("user_id").notNull().references(() => users.id),
    applicationId: uuid("application_id").notNull().references(() => loanApplications.id),
    offerId: uuid("offer_id").notNull().references(() => loanOffers.id),
    status: loanAccountStatus("status").notNull().default("cooling_off"),
    principal: money("principal").notNull(),
    annualInterestRate: rate("annual_interest_rate").notNull(),
    apr: rate("apr").notNull(),
    disbursedOn: date("disbursed_on"),
    maturityDate: date("maturity_date").notNull(),
    coolingOffEndsAt: timestamp("cooling_off_ends_at", { withTimezone: true }),
    // Balances are a cache of the ledger, rebuilt nightly and checked in reconciliation.
    principalOutstanding: money("principal_outstanding").notNull(),
    interestAccrued: money("interest_accrued").notNull().default("0"),
    feesOutstanding: money("fees_outstanding").notNull().default("0"),
    penalOutstanding: money("penal_outstanding").notNull().default("0"),
    dpd: integer("dpd").notNull().default(0),
    closedAt: timestamp("closed_at", { withTimezone: true }),
    version: integer("version").notNull().default(1),
    ...timestamps,
  },
  (t) => [
    uniqueIndex("loan_accounts_no_uq").on(t.loanNo),
    uniqueIndex("loan_accounts_app_uq").on(t.applicationId),
    index("loan_accounts_lender_status_idx").on(t.lenderId, t.status),
    index("loan_accounts_user_idx").on(t.userId),
    index("loan_accounts_dpd_idx").on(t.dpd).where(sql`dpd > 0`),
  ],
);

export const loanSchedules = pgTable(
  "loan_schedules",
  {
    id: pk(),
    loanAccountId: uuid("loan_account_id").notNull().references(() => loanAccounts.id),
    instalmentNo: integer("instalment_no").notNull(),
    dueDate: date("due_date").notNull(),
    principalDue: money("principal_due").notNull(),
    interestDue: money("interest_due").notNull(),
    feesDue: money("fees_due").notNull().default("0"),
    totalDue: money("total_due").notNull(),
    paidAmount: money("paid_amount").notNull().default("0"),
    status: scheduleStatus("status").notNull().default("upcoming"),
    ...timestamps,
  },
  (t) => [
    uniqueIndex("loan_schedules_acct_no_uq").on(t.loanAccountId, t.instalmentNo),
    index("loan_schedules_due_idx").on(t.dueDate, t.status),
  ],
);

/** Lender-to-borrower payout. Maker-checker + idempotency enforced in DB. */
export const disbursements = pgTable(
  "disbursements",
  {
    id: pk(),
    loanAccountId: uuid("loan_account_id").notNull().references(() => loanAccounts.id),
    lenderId: uuid("lender_id").notNull().references(() => lenders.id),
    beneficiaryAccountId: uuid("beneficiary_account_id").notNull().references(() => bankAccounts.id),
    amount: money("amount").notNull(),
    status: disbursementStatus("status").notNull().default("requested"),
    idempotencyKey: varchar("idempotency_key", { length: 80 }).notNull(),
    provider: varchar("provider", { length: 32 }).notNull(),
    mode: integrationMode("mode").notNull(),
    isMock: boolean("is_mock").notNull(),
    sourceAccountRef: text("source_account_ref").notNull(), // lender's account, never a QuickCred pool
    makerId: uuid("maker_id").notNull(),
    checkerId: uuid("checker_id"),
    providerRef: text("provider_ref"),
    utr: varchar("utr", { length: 40 }),
    failureReason: text("failure_reason"),
    attempts: integer("attempts").notNull().default(0),
    submittedAt: timestamp("submitted_at", { withTimezone: true }),
    completedAt: timestamp("completed_at", { withTimezone: true }),
    ...timestamps,
  },
  (t) => [
    uniqueIndex("disb_idem_uq").on(t.idempotencyKey),
    // at most one non-failed payout per loan account
    uniqueIndex("disb_one_live_per_loan_uq").on(t.loanAccountId).where(sql`status NOT IN ('failed','reversed')`),
    check("disb_maker_checker_chk", sql`${t.checkerId} IS NULL OR ${t.checkerId} <> ${t.makerId}`),
    check("disb_amount_chk", sql`${t.amount} > 0`),
  ],
);

export const repayments = pgTable(
  "repayments",
  {
    id: pk(),
    loanAccountId: uuid("loan_account_id").notNull().references(() => loanAccounts.id),
    lenderId: uuid("lender_id").notNull().references(() => lenders.id),
    amount: money("amount").notNull(),
    channel: repaymentChannel("channel").notNull(),
    status: repaymentStatus("status").notNull().default("initiated"),
    idempotencyKey: varchar("idempotency_key", { length: 80 }).notNull(),
    provider: varchar("provider", { length: 32 }).notNull(),
    mode: integrationMode("mode").notNull(),
    isMock: boolean("is_mock").notNull(),
    providerRef: text("provider_ref"),
    utr: varchar("utr", { length: 40 }),
    paidAt: timestamp("paid_at", { withTimezone: true }),
    receiptDocumentId: uuid("receipt_document_id"),
    ...timestamps,
  },
  (t) => [
    uniqueIndex("repay_idem_uq").on(t.idempotencyKey),
    uniqueIndex("repay_provider_ref_uq").on(t.provider, t.providerRef),
    index("repay_account_idx").on(t.loanAccountId),
    check("repay_amount_chk", sql`${t.amount} > 0`),
  ],
);

/** Allocation waterfall result, immutable. Order is lender-configured, default penal→fees→interest→principal. */
export const repaymentAllocations = pgTable(
  "repayment_allocations",
  {
    id: pk(),
    repaymentId: uuid("repayment_id").notNull().references(() => repayments.id),
    scheduleId: uuid("schedule_id").references(() => loanSchedules.id),
    bucket: allocationBucket("bucket").notNull(),
    amount: money("amount").notNull(),
    ...createdOnly,
  },
  (t) => [index("repay_alloc_repay_idx").on(t.repaymentId)],
);

export const mandates = pgTable(
  "mandates",
  {
    id: pk(),
    userId: uuid("user_id").notNull().references(() => users.id),
    loanAccountId: uuid("loan_account_id").references(() => loanAccounts.id),
    bankAccountId: uuid("bank_account_id").notNull().references(() => bankAccounts.id),
    type: varchar("type", { length: 16 }).notNull(), // enach | upi_autopay
    provider: varchar("provider", { length: 32 }).notNull(),
    mode: integrationMode("mode").notNull(),
    isMock: boolean("is_mock").notNull(),
    maxAmount: money("max_amount").notNull(),
    status: mandateStatus("status").notNull().default("created"),
    umrn: varchar("umrn", { length: 40 }),
    validUntil: date("valid_until"),
    consentRecordId: uuid("consent_record_id").notNull(),
    ...timestamps,
  },
  (t) => [index("mandates_account_idx").on(t.loanAccountId)],
);
