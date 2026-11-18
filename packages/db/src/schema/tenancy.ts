import { boolean, index, integer, jsonb, pgTable, text, uniqueIndex, uuid, varchar, check } from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { money, pk, rate, softDelete, timestamps } from "./common";
import { lenderStatus, repaymentType } from "./enums";

/** Regulated entities (banks/NBFCs). Every financial row carries lender_id for isolation. */
export const lenders = pgTable(
  "lenders",
  {
    id: pk(),
    legalName: text("legal_name").notNull(),
    brandName: text("brand_name"),
    rbiRegistrationNo: varchar("rbi_registration_no", { length: 64 }).notNull(),
    entityType: varchar("entity_type", { length: 32 }).notNull(), // bank | nbfc_icc | nbfc_mfi | ...
    status: lenderStatus("status").notNull().default("onboarding"),
    grievanceOfficerName: text("grievance_officer_name").notNull(),
    grievanceOfficerEmail: text("grievance_officer_email").notNull(),
    grievanceOfficerPhone: varchar("grievance_officer_phone", { length: 20 }).notNull(),
    nodalOfficerDetails: jsonb("nodal_officer_details"),
    lspAgreementRef: text("lsp_agreement_ref"), // null => no live paths for this lender
    dlgArrangement: jsonb("dlg_arrangement"), // {type, coverPct<=5, instrument, validTill}
    cimsDlaReported: boolean("cims_dla_reported").notNull().default(false),
    ...timestamps,
    ...softDelete,
  },
  (t) => [uniqueIndex("lenders_rbi_reg_uq").on(t.rbiRegistrationNo)],
);

/** Lender-owned loan products. Pricing here is configuration, not credit policy approval. */
export const loanProducts = pgTable(
  "loan_products",
  {
    id: pk(),
    lenderId: uuid("lender_id").notNull().references(() => lenders.id),
    code: varchar("code", { length: 40 }).notNull(),
    name: text("name").notNull(),
    repaymentType: repaymentType("repayment_type").notNull().default("bullet"),
    tenureDaysMin: integer("tenure_days_min").notNull(),
    tenureDaysMax: integer("tenure_days_max").notNull(),
    amountMin: money("amount_min").notNull(),
    amountMax: money("amount_max").notNull(),
    annualInterestRate: rate("annual_interest_rate").notNull(),
    processingFeeRate: rate("processing_fee_rate").notNull().default("0"),
    processingFeeFlat: money("processing_fee_flat").notNull().default("0"),
    gstRate: rate("gst_rate").notNull().default("0.18"),
    penalChargePerDay: money("penal_charge_per_day").notNull().default("0"),
    coolingOffDays: integer("cooling_off_days").notNull().default(3),
    instalmentFrequencyDays: integer("instalment_frequency_days"),
    aprCeiling: rate("apr_ceiling"), // board-approved max APR; offers above are blocked
    version: integer("version").notNull().default(1),
    isActive: boolean("is_active").notNull().default(false),
    approvedByLenderRef: text("approved_by_lender_ref"),
    ...timestamps,
  },
  (t) => [
    uniqueIndex("loan_products_lender_code_ver_uq").on(t.lenderId, t.code, t.version),
    index("loan_products_lender_idx").on(t.lenderId),
    check("loan_products_tenure_chk", sql`${t.tenureDaysMin} > 0 AND ${t.tenureDaysMax} >= ${t.tenureDaysMin}`),
    check("loan_products_amount_chk", sql`${t.amountMin} > 0 AND ${t.amountMax} >= ${t.amountMin}`),
    check("loan_products_cooling_off_chk", sql`${t.coolingOffDays} >= 1`),
  ],
);
