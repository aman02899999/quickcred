import { boolean, index, inet, integer, jsonb, pgTable, text, timestamp, uniqueIndex, uuid, varchar } from "drizzle-orm/pg-core";
import { createdOnly, encrypted, pk, softDelete, timestamps } from "./common";
import { integrationMode, consentPurpose, consentStatus, employmentType, verificationStatus, verificationType } from "./enums";

/**
 * Customers. Phone stored encrypted + HMAC blind index for lookup/dedupe.
 * Plain phone/PAN/Aadhaar never touch these columns.
 */
export const users = pgTable(
  "users",
  {
    id: pk(),
    phoneEnc: encrypted("phone_enc").notNull(),
    phoneHash: varchar("phone_hash", { length: 64 }).notNull(),
    phoneLast4: varchar("phone_last4", { length: 4 }).notNull(),
    status: varchar("status", { length: 24 }).notNull().default("active"), // active | blocked | erased
    lastLoginAt: timestamp("last_login_at", { withTimezone: true }),
    ...timestamps,
    ...softDelete,
  },
  (t) => [uniqueIndex("users_phone_hash_uq").on(t.phoneHash)],
);

export const userProfiles = pgTable(
  "user_profiles",
  {
    id: pk(),
    userId: uuid("user_id").notNull().references(() => users.id),
    fullNameEnc: encrypted("full_name_enc"),
    dobEnc: encrypted("dob_enc"),
    emailEnc: encrypted("email_enc"),
    panEnc: encrypted("pan_enc"),
    panHash: varchar("pan_hash", { length: 64 }), // duplicate-applicant detection
    panLast4: varchar("pan_last4", { length: 4 }),
    aadhaarLast4: varchar("aadhaar_last4", { length: 4 }), // only masked digits, ever
    aadhaarVaultRef: text("aadhaar_vault_ref"), // reference token if the lender's vault holds it
    currentAddressEnc: encrypted("current_address_enc"),
    permanentAddressEnc: encrypted("permanent_address_enc"),
    employmentType: employmentType("employment_type"),
    occupation: text("occupation"),
    employerName: text("employer_name"),
    monthlyIncomeDeclared: varchar("monthly_income_declared", { length: 24 }), // declared, unverified; numeric string
    ...timestamps,
  },
  (t) => [uniqueIndex("user_profiles_user_uq").on(t.userId), uniqueIndex("user_profiles_pan_hash_uq").on(t.panHash)],
);

export const otpChallenges = pgTable(
  "otp_challenges",
  {
    id: pk(),
    phoneHash: varchar("phone_hash", { length: 64 }).notNull(),
    codeHash: varchar("code_hash", { length: 128 }).notNull(), // argon2/HMAC, never plaintext
    purpose: varchar("purpose", { length: 24 }).notNull().default("login"),
    attempts: integer("attempts").notNull().default(0),
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
    consumedAt: timestamp("consumed_at", { withTimezone: true }),
    ip: inet("ip"),
    deviceId: uuid("device_id"),
    ...createdOnly,
  },
  (t) => [index("otp_phone_created_idx").on(t.phoneHash, t.createdAt)],
);

export const devices = pgTable(
  "devices",
  {
    id: pk(),
    userId: uuid("user_id").references(() => users.id),
    fingerprintHash: varchar("fingerprint_hash", { length: 64 }).notNull(),
    platform: varchar("platform", { length: 16 }).notNull(), // web | android | ios
    userAgent: text("user_agent"),
    riskFlags: jsonb("risk_flags"),
    firstSeenAt: timestamp("first_seen_at", { withTimezone: true }).notNull().defaultNow(),
    lastSeenAt: timestamp("last_seen_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index("devices_fp_idx").on(t.fingerprintHash), index("devices_user_idx").on(t.userId)],
);

export const userSessions = pgTable(
  "user_sessions",
  {
    id: pk(),
    userId: uuid("user_id").notNull().references(() => users.id),
    deviceId: uuid("device_id").references(() => devices.id),
    refreshTokenHash: varchar("refresh_token_hash", { length: 128 }).notNull(),
    ip: inet("ip"),
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
    revokedAt: timestamp("revoked_at", { withTimezone: true }),
    ...createdOnly,
  },
  (t) => [uniqueIndex("user_sessions_refresh_uq").on(t.refreshTokenHash), index("user_sessions_user_idx").on(t.userId)],
);

/** One row per verification attempt. Provider raw response is encrypted; is_mock is non-nullable. */
export const identityVerifications = pgTable(
  "identity_verifications",
  {
    id: pk(),
    userId: uuid("user_id").notNull().references(() => users.id),
    applicationId: uuid("application_id"),
    type: verificationType("type").notNull(),
    status: verificationStatus("status").notNull().default("initiated"),
    provider: varchar("provider", { length: 40 }).notNull(),
    mode: integrationMode("mode").notNull(),
    isMock: boolean("is_mock").notNull(),
    providerRef: text("provider_ref"),
    nameMatchScore: integer("name_match_score"), // 0-100
    dobMatched: boolean("dob_matched"),
    failureReason: text("failure_reason"),
    responseEnc: encrypted("response_enc"),
    verifiedAt: timestamp("verified_at", { withTimezone: true }),
    expiresAt: timestamp("expires_at", { withTimezone: true }),
    ...timestamps,
  },
  (t) => [index("idv_user_type_idx").on(t.userId, t.type), index("idv_application_idx").on(t.applicationId)],
);

/** Append-only consent log. Withdrawal is a new row, not an update. */
export const consentRecords = pgTable(
  "consent_records",
  {
    id: pk(),
    userId: uuid("user_id").notNull().references(() => users.id),
    lenderId: uuid("lender_id"),
    applicationId: uuid("application_id"),
    purpose: consentPurpose("purpose").notNull(),
    status: consentStatus("status").notNull(),
    noticeVersion: varchar("notice_version", { length: 32 }).notNull(),
    noticeHash: varchar("notice_hash", { length: 64 }).notNull(), // sha256 of exact text shown
    language: varchar("language", { length: 8 }).notNull().default("en"),
    ip: inet("ip"),
    deviceId: uuid("device_id"),
    expiresAt: timestamp("expires_at", { withTimezone: true }),
    ...createdOnly,
  },
  (t) => [index("consent_user_purpose_idx").on(t.userId, t.purpose, t.createdAt)],
);

