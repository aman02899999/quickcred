import { customType, numeric, timestamp, uuid } from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

/**
 * Money is NUMERIC(18,2) in INR. Never float. Drizzle returns it as a string;
 * the finance package converts to a decimal type, never to JS number.
 */
export const money = (name: string) => numeric(name, { precision: 18, scale: 2 });

/** Rates as fractions, e.g. 0.240000 = 24% p.a. Six dp covers bps-level pricing. */
export const rate = (name: string) => numeric(name, { precision: 12, scale: 8 });

/** Envelope-encrypted payload: {keyId, iv, ciphertext, tag} serialised, stored as bytea. */
export const encrypted = customType<{ data: Buffer; driverData: Buffer }>({
  dataType() {
    return "bytea";
  },
});

export const pk = () => uuid("id").primaryKey().default(sql`gen_random_uuid()`);

export const timestamps = {
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
};

/** Soft delete: only on non-financial, non-audit rows. */
export const softDelete = {
  deletedAt: timestamp("deleted_at", { withTimezone: true }),
};

/** Immutable rows get created_at only, and a DB trigger blocks UPDATE/DELETE (see migrations/0001). */
export const createdOnly = {
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
};
