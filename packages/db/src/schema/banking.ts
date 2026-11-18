import { boolean, date, index, integer, jsonb, pgTable, text, timestamp, uniqueIndex, uuid, varchar } from "drizzle-orm/pg-core";
import { createdOnly, encrypted, money, pk, timestamps } from "./common";
import { aaConsentStatus, integrationMode, verificationStatus } from "./enums";
import { users } from "./identity";

export const bankAccounts = pgTable(
  "bank_accounts",
  {
    id: pk(),
    userId: uuid("user_id").notNull().references(() => users.id),
    accountNumberEnc: encrypted("account_number_enc").notNull(),
    accountNumberHash: varchar("account_number_hash", { length: 64 }).notNull(), // HMAC(ifsc+acct)
    accountLast4: varchar("account_last4", { length: 4 }).notNull(),
    ifsc: varchar("ifsc", { length: 11 }).notNull(),
    bankName: text("bank_name"),
    holderNameAtBank: text("holder_name_at_bank"), // from penny drop / AA
    nameMatchScore: integer("name_match_score"),
    verificationStatus: verificationStatus("verification_status").notNull().default("initiated"),
    verificationMethod: varchar("verification_method", { length: 32 }), // penny_drop | reverse_penny_drop | aa
    isMockVerified: boolean("is_mock_verified").notNull().default(false),
    isPrimary: boolean("is_primary").notNull().default(false),
    verifiedAt: timestamp("verified_at", { withTimezone: true }),
    ...timestamps,
  },
  (t) => [
    uniqueIndex("bank_accounts_user_acct_uq").on(t.userId, t.accountNumberHash),
    index("bank_accounts_acct_hash_idx").on(t.accountNumberHash), // same account across users = fraud signal
  ],
);

/** Account Aggregator consent + fetch lifecycle. The FIU is the lender, not QuickCred. */
export const aaSessions = pgTable(
  "aa_sessions",
  {
    id: pk(),
    userId: uuid("user_id").notNull().references(() => users.id),
    applicationId: uuid("application_id"),
    lenderId: uuid("lender_id"),
    provider: varchar("provider", { length: 40 }).notNull(),
    mode: integrationMode("mode").notNull(),
    isMock: boolean("is_mock").notNull(),
    consentHandle: text("consent_handle"),
    consentId: text("consent_id"),
    status: aaConsentStatus("status").notNull().default("created"),
    fiTypes: jsonb("fi_types").notNull(), // ["DEPOSIT"]
    dataRangeFrom: date("data_range_from"),
    dataRangeTo: date("data_range_to"),
    consentExpiresAt: timestamp("consent_expires_at", { withTimezone: true }),
    dataFetchedAt: timestamp("data_fetched_at", { withTimezone: true }),
    purgeAfter: timestamp("purge_after", { withTimezone: true }), // retention clock
    ...timestamps,
  },
  (t) => [index("aa_user_idx").on(t.userId), uniqueIndex("aa_consent_handle_uq").on(t.consentHandle)],
);

/** Normalised transactions from AA/statement. Narration encrypted; category derived. */
export const bankTransactions = pgTable(
  "bank_transactions",
  {
    id: pk(),
    aaSessionId: uuid("aa_session_id").references(() => aaSessions.id),
    bankAccountId: uuid("bank_account_id").references(() => bankAccounts.id),
    userId: uuid("user_id").notNull().references(() => users.id),
    txnDate: date("txn_date").notNull(),
    amount: money("amount").notNull(),
    direction: varchar("direction", { length: 6 }).notNull(), // credit | debit
    balanceAfter: money("balance_after"),
    mode: varchar("mode", { length: 16 }), // UPI | NEFT | IMPS | ACH | CASH ...
    narrationEnc: encrypted("narration_enc"),
    category: varchar("category", { length: 32 }), // salary | emi | bounce | transfer | ...
    providerTxnId: text("provider_txn_id"),
    ...createdOnly,
  },
  (t) => [index("bank_txn_user_date_idx").on(t.userId, t.txnDate), index("bank_txn_session_idx").on(t.aaSessionId)],
);

/** Derived cash-flow features, one row per analysis run. Inputs to underwriting. */
export const bankAnalyses = pgTable(
  "bank_analyses",
  {
    id: pk(),
    aaSessionId: uuid("aa_session_id").notNull().references(() => aaSessions.id),
    userId: uuid("user_id").notNull().references(() => users.id),
    monthsCovered: integer("months_covered").notNull(),
    avgMonthlyCredit: money("avg_monthly_credit"),
    avgMonthlyDebit: money("avg_monthly_debit"),
    avgBalance: money("avg_balance"),
    detectedSalary: money("detected_salary"),
    salaryRegularityScore: integer("salary_regularity_score"),
    detectedEmiTotal: money("detected_emi_total"),
    bounceCount: integer("bounce_count"),
    features: jsonb("features").notNull(),
    engineVersion: varchar("engine_version", { length: 24 }).notNull(),
    isMock: boolean("is_mock").notNull(),
    ...createdOnly,
  },
  (t) => [index("bank_analyses_user_idx").on(t.userId)],
);
