import { boolean, index, integer, jsonb, pgTable, text, timestamp, uuid, varchar } from "drizzle-orm/pg-core";
import { createdOnly, encrypted, money, pk, rate } from "./common";
import { decisionOutcome, integrationMode, riskBand } from "./enums";
import { users } from "./identity";

/** Bureau pull, made under the lender's CIC membership with explicit borrower consent. */
export const creditReports = pgTable(
  "credit_reports",
  {
    id: pk(),
    userId: uuid("user_id").notNull().references(() => users.id),
    applicationId: uuid("application_id"),
    lenderId: uuid("lender_id").notNull(),
    bureau: varchar("bureau", { length: 16 }).notNull(), // cibil | experian | crif | equifax
    mode: integrationMode("mode").notNull(),
    isMock: boolean("is_mock").notNull(),
    consentRecordId: uuid("consent_record_id").notNull(),
    enquiryPurpose: varchar("enquiry_purpose", { length: 32 }).notNull().default("personal_loan"),
    reportEnc: encrypted("report_enc"),
    status: varchar("status", { length: 16 }).notNull(), // success | no_hit | failed
    pulledAt: timestamp("pulled_at", { withTimezone: true }).notNull().defaultNow(),
    purgeAfter: timestamp("purge_after", { withTimezone: true }),
    ...createdOnly,
  },
  (t) => [index("credit_reports_user_idx").on(t.userId), index("credit_reports_app_idx").on(t.applicationId)],
);

export const creditScores = pgTable(
  "credit_scores",
  {
    id: pk(),
    creditReportId: uuid("credit_report_id").notNull().references(() => creditReports.id),
    userId: uuid("user_id").notNull().references(() => users.id),
    score: integer("score"), // null on NTC / no-hit
    scoreModel: varchar("score_model", { length: 32 }),
    activeAccounts: integer("active_accounts"),
    totalOutstanding: money("total_outstanding"),
    monthlyObligation: money("monthly_obligation"),
    overdueAccounts: integer("overdue_accounts"),
    maxDpd12m: integer("max_dpd_12m"),
    enquiries30d: integer("enquiries_30d"),
    enquiries90d: integer("enquiries_90d"),
    writtenOffOrSettled: boolean("written_off_or_settled"),
    ...createdOnly,
  },
  (t) => [index("credit_scores_user_idx").on(t.userId)],
);

export const fraudAssessments = pgTable(
  "fraud_assessments",
  {
    id: pk(),
    applicationId: uuid("application_id").notNull(),
    userId: uuid("user_id").notNull().references(() => users.id),
    score: integer("score").notNull(), // 0 (clean) .. 100
    signals: jsonb("signals").notNull(), // [{code, weight, evidence}]
    hardStop: boolean("hard_stop").notNull().default(false),
    reviewedBy: uuid("reviewed_by"),
    reviewOutcome: varchar("review_outcome", { length: 24 }),
    engineVersion: varchar("engine_version", { length: 24 }).notNull(),
    ...createdOnly,
  },
  (t) => [index("fraud_app_idx").on(t.applicationId)],
);

/** Explainable decision record. Immutable; re-assessment writes a new row. */
export const underwritingDecisions = pgTable(
  "underwriting_decisions",
  {
    id: pk(),
    applicationId: uuid("application_id").notNull(),
    lenderId: uuid("lender_id").notNull(),
    policyVersion: varchar("policy_version", { length: 24 }).notNull(),
    componentScores: jsonb("component_scores").notNull(), // {credit_history:{weight,score,reasons}, ...}
    totalScore: integer("total_score").notNull(),
    riskBand: riskBand("risk_band").notNull(),
    outcome: decisionOutcome("outcome").notNull(),
    reasonCodes: jsonb("reason_codes").notNull(),
    maxEligibleAmount: money("max_eligible_amount"),
    foirComputed: rate("foir_computed"),
    decidedBy: varchar("decided_by", { length: 16 }).notNull(), // engine | staff
    staffUserId: uuid("staff_user_id"),
    overrideReason: text("override_reason"),
    ...createdOnly,
  },
  (t) => [index("uw_app_idx").on(t.applicationId)],
);
