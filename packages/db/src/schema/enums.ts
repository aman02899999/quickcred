import { pgEnum } from "drizzle-orm/pg-core";

export const integrationMode = pgEnum("integration_mode", ["mock", "sandbox", "live"]);

export const lenderStatus = pgEnum("lender_status", ["onboarding", "active", "suspended", "terminated"]);

export const employmentType = pgEnum("employment_type", ["salaried", "self_employed", "other"]);

export const verificationType = pgEnum("verification_type", [
  "pan",
  "aadhaar_offline_xml",
  "aadhaar_digilocker",
  "aadhaar_ekyc_otp",
  "video_kyc",
  "ckyc",
  "document",
  "penny_drop",
  "reverse_penny_drop",
]);

export const verificationStatus = pgEnum("verification_status", [
  "initiated",
  "pending",
  "verified",
  "failed",
  "expired",
  "manual_review",
]);

export const consentPurpose = pgEnum("consent_purpose", [
  "terms_of_use",
  "privacy_notice",
  "kyc",
  "bureau_pull",
  "account_aggregator",
  "communications_sms",
  "communications_email",
  "communications_whatsapp",
  "marketing",
  "loan_agreement",
  "e_mandate",
]);

export const consentStatus = pgEnum("consent_status", ["granted", "withdrawn", "expired"]);

export const aaConsentStatus = pgEnum("aa_consent_status", [
  "created",
  "pending_user",
  "active",
  "rejected",
  "paused",
  "revoked",
  "expired",
  "data_ready",
  "data_fetch_failed",
]);

export const riskBand = pgEnum("risk_band", [
  "low",
  "medium",
  "high",
  "fraud_suspected",
  "affordability_failure",
]);

export const decisionOutcome = pgEnum("decision_outcome", ["approve", "refer", "decline"]);

export const repaymentType = pgEnum("repayment_type", ["bullet", "instalment"]);

export const applicationStatus = pgEnum("application_status", [
  "draft",
  "submitted",
  "otp_verified",
  "kyc_pending",
  "kyc_verified",
  "bank_verification_pending",
  "credit_check_pending",
  "underwriting_pending",
  "manual_review",
  "approved",
  "rejected",
  "offer_generated",
  "agreement_pending",
  "sanctioned",
  "disbursement_pending",
  "disbursed",
  "cancelled",
]);

export const offerStatus = pgEnum("offer_status", ["generated", "viewed", "accepted", "expired", "withdrawn"]);

export const loanAccountStatus = pgEnum("loan_account_status", [
  "active",
  "cooling_off",
  "overdue",
  "closed",
  "foreclosed",
  "cancelled_in_cooling_off",
  "written_off",
  "restructured",
]);

export const scheduleStatus = pgEnum("schedule_status", ["upcoming", "due", "partially_paid", "paid", "overdue", "waived"]);

export const documentType = pgEnum("document_type", [
  "kfs",
  "loan_agreement",
  "sanction_letter",
  "salary_slip",
  "bank_statement",
  "business_proof",
  "receipt",
  "noc",
  "closure_certificate",
  "kyc_document",
]);

export const disbursementStatus = pgEnum("disbursement_status", [
  "requested",
  "awaiting_checker",
  "approved",
  "submitted",
  "processing",
  "success",
  "failed",
  "reversed",
]);

export const repaymentStatus = pgEnum("repayment_status", ["initiated", "pending", "success", "failed", "refunded"]);

export const repaymentChannel = pgEnum("repayment_channel", ["upi_collect", "upi_intent", "payment_link", "nach", "upi_autopay", "netbanking", "manual"]);

export const allocationBucket = pgEnum("allocation_bucket", ["penal_charges", "fees", "interest", "principal"]);

export const mandateStatus = pgEnum("mandate_status", ["created", "pending_auth", "active", "paused", "revoked", "failed"]);

export const ledgerAccountType = pgEnum("ledger_account_type", ["asset", "liability", "income", "expense", "equity"]);

export const entryDirection = pgEnum("entry_direction", ["debit", "credit"]);

export const collectionsStage = pgEnum("collections_stage", ["dpd_1_30", "dpd_31_60", "dpd_61_90", "dpd_90_plus"]);

export const caseStatus = pgEnum("case_status", ["open", "in_progress", "promise_to_pay", "resolved", "escalated", "closed"]);

export const complaintStatus = pgEnum("complaint_status", ["received", "acknowledged", "in_progress", "resolved", "escalated_to_lender", "escalated_to_rbi_ombudsman", "closed"]);

export const notificationChannel = pgEnum("notification_channel", ["sms", "email", "whatsapp", "in_app", "push"]);

export const notificationStatus = pgEnum("notification_status", ["queued", "sent", "delivered", "failed", "suppressed"]);

export const actorType = pgEnum("actor_type", ["customer", "staff", "system", "provider"]);
