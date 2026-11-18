import { check, date, index, pgTable, text, uniqueIndex, uuid, varchar, jsonb } from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { createdOnly, money, pk, timestamps } from "./common";
import { entryDirection, ledgerAccountType } from "./enums";
import { lenders } from "./tenancy";

/**
 * Double-entry ledger, per lender book. QuickCred records the lender's book as a
 * servicing agent; the lender's own core system remains the book of record.
 */
export const ledgerAccounts = pgTable(
  "ledger_accounts",
  {
    id: pk(),
    lenderId: uuid("lender_id").notNull().references(() => lenders.id),
    code: varchar("code", { length: 64 }).notNull(), // e.g. LOAN_PRINCIPAL_RECEIVABLE, or per-loan sub-account
    name: text("name").notNull(),
    type: ledgerAccountType("type").notNull(),
    loanAccountId: uuid("loan_account_id"), // set for per-loan sub-ledgers
    ...timestamps,
  },
  (t) => [uniqueIndex("ledger_accounts_lender_code_uq").on(t.lenderId, t.code)],
);

/** A balanced group of entries. sum(debits) = sum(credits) enforced by deferred trigger (migration 0001). */
export const ledgerTransactions = pgTable(
  "ledger_transactions",
  {
    id: pk(),
    lenderId: uuid("lender_id").notNull().references(() => lenders.id),
    eventType: varchar("event_type", { length: 40 }).notNull(), // DISBURSEMENT | INTEREST_ACCRUAL | REPAYMENT | REVERSAL ...
    sourceType: varchar("source_type", { length: 32 }).notNull(),
    sourceId: uuid("source_id").notNull(),
    idempotencyKey: varchar("idempotency_key", { length: 80 }).notNull(),
    valueDate: date("value_date").notNull(),
    reversesTransactionId: uuid("reverses_transaction_id"),
    metadata: jsonb("metadata"),
    ...createdOnly,
  },
  (t) => [uniqueIndex("ledger_txn_idem_uq").on(t.idempotencyKey), index("ledger_txn_source_idx").on(t.sourceType, t.sourceId)],
);

export const ledgerEntries = pgTable(
  "ledger_entries",
  {
    id: pk(),
    transactionId: uuid("transaction_id").notNull().references(() => ledgerTransactions.id),
    ledgerAccountId: uuid("ledger_account_id").notNull().references(() => ledgerAccounts.id),
    direction: entryDirection("direction").notNull(),
    amount: money("amount").notNull(),
    ...createdOnly,
  },
  (t) => [
    index("ledger_entries_txn_idx").on(t.transactionId),
    index("ledger_entries_account_idx").on(t.ledgerAccountId),
    check("ledger_entries_positive_chk", sql`${t.amount} > 0`),
  ],
);
