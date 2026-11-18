import { boolean, index, inet, integer, jsonb, pgTable, primaryKey, text, timestamp, uniqueIndex, uuid, varchar } from "drizzle-orm/pg-core";
import { createdOnly, encrypted, pk, softDelete, timestamps } from "./common";
import { actorType, caseStatus, collectionsStage, complaintStatus, integrationMode, notificationChannel, notificationStatus } from "./enums";
import { users } from "./identity";
import { loanAccounts } from "./lending";
import { lenders } from "./tenancy";

// ------------------------------------------------------------ Staff & RBAC

export const adminUsers = pgTable(
  "admin_users",
  {
    id: pk(),
    email: varchar("email", { length: 254 }).notNull(),
    fullName: text("full_name").notNull(),
    lenderId: uuid("lender_id").references(() => lenders.id), // null = QuickCred platform staff
    passwordHash: text("password_hash"), // argon2id; null when SSO-only
    mfaSecretEnc: encrypted("mfa_secret_enc"),
    mfaEnabled: boolean("mfa_enabled").notNull().default(false),
    isActive: boolean("is_active").notNull().default(true),
    lastLoginAt: timestamp("last_login_at", { withTimezone: true }),
    ...timestamps,
    ...softDelete,
  },
  (t) => [uniqueIndex("admin_users_email_uq").on(t.email)],
);

export const roles = pgTable(
  "roles",
  {
    id: pk(),
    code: varchar("code", { length: 48 }).notNull(), // super_admin | ops_admin | underwriter | finance_maker | finance_checker | collections_agent | support | auditor | lender_viewer
    name: text("name").notNull(),
    scope: varchar("scope", { length: 16 }).notNull(), // platform | lender
    ...timestamps,
  },
  (t) => [uniqueIndex("roles_code_uq").on(t.code)],
);

export const permissions = pgTable(
  "permissions",
  {
    id: pk(),
    code: varchar("code", { length: 64 }).notNull(), // e.g. application.decide, disbursement.approve
    description: text("description").notNull(),
    isCritical: boolean("is_critical").notNull().default(false), // requires MFA step-up + audit reason
  },
  (t) => [uniqueIndex("permissions_code_uq").on(t.code)],
);

export const rolePermissions = pgTable(
  "role_permissions",
  {
    roleId: uuid("role_id").notNull().references(() => roles.id),
    permissionId: uuid("permission_id").notNull().references(() => permissions.id),
  },
  (t) => [primaryKey({ columns: [t.roleId, t.permissionId] })],
);

export const adminUserRoles = pgTable(
  "admin_user_roles",
  {
    adminUserId: uuid("admin_user_id").notNull().references(() => adminUsers.id),
    roleId: uuid("role_id").notNull().references(() => roles.id),
    lenderId: uuid("lender_id").references(() => lenders.id),
  },
  (t) => [primaryKey({ columns: [t.adminUserId, t.roleId] })],
);

// ------------------------------------------------------------ Audit

/** Append-only, hash-chained. UPDATE/DELETE blocked by trigger. */
export const auditLogs = pgTable(
  "audit_logs",
  {
    id: pk(),
    actorType: actorType("actor_type").notNull(),
    actorId: uuid("actor_id"),
    lenderId: uuid("lender_id"),
    action: varchar("action", { length: 80 }).notNull(),
    entityType: varchar("entity_type", { length: 48 }).notNull(),
    entityId: uuid("entity_id"),
    before: jsonb("before"), // PII-redacted
    after: jsonb("after"), // PII-redacted
    reason: text("reason"),
    ip: inet("ip"),
    requestId: varchar("request_id", { length: 64 }),
    prevHash: varchar("prev_hash", { length: 64 }),
    hash: varchar("hash", { length: 64 }).notNull(),
    ...createdOnly,
  },
  (t) => [index("audit_entity_idx").on(t.entityType, t.entityId), index("audit_actor_idx").on(t.actorId, t.createdAt)],
);

// ------------------------------------------------------------ Collections & complaints

export const collectionsCases = pgTable(
  "collections_cases",
  {
    id: pk(),
    loanAccountId: uuid("loan_account_id").notNull().references(() => loanAccounts.id),
    lenderId: uuid("lender_id").notNull().references(() => lenders.id),
    stage: collectionsStage("stage").notNull(),
    status: caseStatus("status").notNull().default("open"),
    assignedTo: uuid("assigned_to"),
    recoveryAgencyRef: text("recovery_agency_ref"), // must be lender-empanelled; disclosed to borrower
    promiseToPayDate: timestamp("promise_to_pay_date", { withTimezone: true }),
    contactAttemptsToday: integer("contact_attempts_today").notNull().default(0),
    notes: jsonb("notes"),
    ...timestamps,
  },
  (t) => [index("collections_lender_stage_idx").on(t.lenderId, t.stage, t.status)],
);

export const complaints = pgTable(
  "complaints",
  {
    id: pk(),
    ticketNo: varchar("ticket_no", { length: 24 }).notNull(),
    userId: uuid("user_id").references(() => users.id),
    lenderId: uuid("lender_id").references(() => lenders.id),
    loanAccountId: uuid("loan_account_id"),
    category: varchar("category", { length: 40 }).notNull(),
    description: text("description").notNull(),
    status: complaintStatus("status").notNull().default("received"),
    assignedTo: uuid("assigned_to"),
    acknowledgedAt: timestamp("acknowledged_at", { withTimezone: true }),
    resolutionDueAt: timestamp("resolution_due_at", { withTimezone: true }).notNull(), // 30-day RBI escalation clock
    resolvedAt: timestamp("resolved_at", { withTimezone: true }),
    resolution: text("resolution"),
    ...timestamps,
  },
  (t) => [uniqueIndex("complaints_ticket_uq").on(t.ticketNo), index("complaints_status_idx").on(t.status, t.resolutionDueAt)],
);

// ------------------------------------------------------------ Integrations

export const apiIntegrations = pgTable(
  "api_integrations",
  {
    id: pk(),
    lenderId: uuid("lender_id").references(() => lenders.id),
    category: varchar("category", { length: 24 }).notNull(), // pan | kyc | aa | bureau | esign | payout | pg | sms ...
    provider: varchar("provider", { length: 40 }).notNull(),
    mode: integrationMode("mode").notNull().default("mock"),
    secretRef: text("secret_ref"), // pointer into AWS Secrets Manager; never the secret
    config: jsonb("config"),
    isEnabled: boolean("is_enabled").notNull().default(false),
    lastHealthAt: timestamp("last_health_at", { withTimezone: true }),
    lastHealthOk: boolean("last_health_ok"),
    liveApprovedBy: uuid("live_approved_by"),
    liveApprovedAt: timestamp("live_approved_at", { withTimezone: true }),
    ...timestamps,
  },
  (t) => [uniqueIndex("api_integrations_scope_uq").on(t.lenderId, t.category, t.provider)],
);

export const webhookEvents = pgTable(
  "webhook_events",
  {
    id: pk(),
    provider: varchar("provider", { length: 40 }).notNull(),
    eventType: varchar("event_type", { length: 64 }).notNull(),
    providerEventId: varchar("provider_event_id", { length: 128 }).notNull(),
    signatureValid: boolean("signature_valid").notNull(),
    payloadEnc: encrypted("payload_enc").notNull(),
    processedAt: timestamp("processed_at", { withTimezone: true }),
    processingError: text("processing_error"),
    attempts: integer("attempts").notNull().default(0),
    ...createdOnly,
  },
  (t) => [uniqueIndex("webhook_provider_event_uq").on(t.provider, t.providerEventId)],
);

export const idempotencyKeys = pgTable(
  "idempotency_keys",
  {
    key: varchar("key", { length: 80 }).primaryKey(),
    scope: varchar("scope", { length: 48 }).notNull(),
    requestHash: varchar("request_hash", { length: 64 }).notNull(),
    responseStatus: integer("response_status"),
    responseBody: jsonb("response_body"),
    lockedUntil: timestamp("locked_until", { withTimezone: true }),
    ...createdOnly,
  },
);

export const notifications = pgTable(
  "notifications",
  {
    id: pk(),
    userId: uuid("user_id").references(() => users.id),
    loanAccountId: uuid("loan_account_id"),
    channel: notificationChannel("channel").notNull(),
    templateCode: varchar("template_code", { length: 64 }).notNull(),
    dltTemplateId: varchar("dlt_template_id", { length: 40 }),
    status: notificationStatus("status").notNull().default("queued"),
    isMock: boolean("is_mock").notNull(),
    payload: jsonb("payload"),
    providerRef: text("provider_ref"),
    scheduledFor: timestamp("scheduled_for", { withTimezone: true }),
    sentAt: timestamp("sent_at", { withTimezone: true }),
    failureReason: text("failure_reason"),
    ...createdOnly,
  },
  (t) => [index("notifications_user_idx").on(t.userId, t.createdAt), index("notifications_status_idx").on(t.status, t.scheduledFor)],
);
