CREATE TYPE "public"."aa_consent_status" AS ENUM('created', 'pending_user', 'active', 'rejected', 'paused', 'revoked', 'expired', 'data_ready', 'data_fetch_failed');--> statement-breakpoint
CREATE TYPE "public"."actor_type" AS ENUM('customer', 'staff', 'system', 'provider');--> statement-breakpoint
CREATE TYPE "public"."allocation_bucket" AS ENUM('penal_charges', 'fees', 'interest', 'principal');--> statement-breakpoint
CREATE TYPE "public"."application_status" AS ENUM('draft', 'submitted', 'otp_verified', 'kyc_pending', 'kyc_verified', 'bank_verification_pending', 'credit_check_pending', 'underwriting_pending', 'manual_review', 'approved', 'rejected', 'offer_generated', 'agreement_pending', 'sanctioned', 'disbursement_pending', 'disbursed', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."case_status" AS ENUM('open', 'in_progress', 'promise_to_pay', 'resolved', 'escalated', 'closed');--> statement-breakpoint
CREATE TYPE "public"."collections_stage" AS ENUM('dpd_1_30', 'dpd_31_60', 'dpd_61_90', 'dpd_90_plus');--> statement-breakpoint
CREATE TYPE "public"."complaint_status" AS ENUM('received', 'acknowledged', 'in_progress', 'resolved', 'escalated_to_lender', 'escalated_to_rbi_ombudsman', 'closed');--> statement-breakpoint
CREATE TYPE "public"."consent_purpose" AS ENUM('terms_of_use', 'privacy_notice', 'kyc', 'bureau_pull', 'account_aggregator', 'communications_sms', 'communications_email', 'communications_whatsapp', 'marketing', 'loan_agreement', 'e_mandate');--> statement-breakpoint
CREATE TYPE "public"."consent_status" AS ENUM('granted', 'withdrawn', 'expired');--> statement-breakpoint
CREATE TYPE "public"."decision_outcome" AS ENUM('approve', 'refer', 'decline');--> statement-breakpoint
CREATE TYPE "public"."disbursement_status" AS ENUM('requested', 'awaiting_checker', 'approved', 'submitted', 'processing', 'success', 'failed', 'reversed');--> statement-breakpoint
CREATE TYPE "public"."document_type" AS ENUM('kfs', 'loan_agreement', 'sanction_letter', 'salary_slip', 'bank_statement', 'business_proof', 'receipt', 'noc', 'closure_certificate', 'kyc_document');--> statement-breakpoint
CREATE TYPE "public"."employment_type" AS ENUM('salaried', 'self_employed', 'other');--> statement-breakpoint
CREATE TYPE "public"."entry_direction" AS ENUM('debit', 'credit');--> statement-breakpoint
CREATE TYPE "public"."integration_mode" AS ENUM('mock', 'sandbox', 'live');--> statement-breakpoint
CREATE TYPE "public"."ledger_account_type" AS ENUM('asset', 'liability', 'income', 'expense', 'equity');--> statement-breakpoint
CREATE TYPE "public"."lender_status" AS ENUM('onboarding', 'active', 'suspended', 'terminated');--> statement-breakpoint
CREATE TYPE "public"."loan_account_status" AS ENUM('active', 'cooling_off', 'overdue', 'closed', 'foreclosed', 'cancelled_in_cooling_off', 'written_off', 'restructured');--> statement-breakpoint
CREATE TYPE "public"."mandate_status" AS ENUM('created', 'pending_auth', 'active', 'paused', 'revoked', 'failed');--> statement-breakpoint
CREATE TYPE "public"."notification_channel" AS ENUM('sms', 'email', 'whatsapp', 'in_app', 'push');--> statement-breakpoint
CREATE TYPE "public"."notification_status" AS ENUM('queued', 'sent', 'delivered', 'failed', 'suppressed');--> statement-breakpoint
CREATE TYPE "public"."offer_status" AS ENUM('generated', 'viewed', 'accepted', 'expired', 'withdrawn');--> statement-breakpoint
CREATE TYPE "public"."repayment_channel" AS ENUM('upi_collect', 'upi_intent', 'payment_link', 'nach', 'upi_autopay', 'netbanking', 'manual');--> statement-breakpoint
CREATE TYPE "public"."repayment_status" AS ENUM('initiated', 'pending', 'success', 'failed', 'refunded');--> statement-breakpoint
CREATE TYPE "public"."repayment_type" AS ENUM('bullet', 'instalment');--> statement-breakpoint
CREATE TYPE "public"."risk_band" AS ENUM('low', 'medium', 'high', 'fraud_suspected', 'affordability_failure');--> statement-breakpoint
CREATE TYPE "public"."schedule_status" AS ENUM('upcoming', 'due', 'partially_paid', 'paid', 'overdue', 'waived');--> statement-breakpoint
CREATE TYPE "public"."verification_status" AS ENUM('initiated', 'pending', 'verified', 'failed', 'expired', 'manual_review');--> statement-breakpoint
CREATE TYPE "public"."verification_type" AS ENUM('pan', 'aadhaar_offline_xml', 'aadhaar_digilocker', 'aadhaar_ekyc_otp', 'video_kyc', 'ckyc', 'document', 'penny_drop', 'reverse_penny_drop');--> statement-breakpoint
CREATE TABLE "lenders" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"legal_name" text NOT NULL,
	"brand_name" text,
	"rbi_registration_no" varchar(64) NOT NULL,
	"entity_type" varchar(32) NOT NULL,
	"status" "lender_status" DEFAULT 'onboarding' NOT NULL,
	"grievance_officer_name" text NOT NULL,
	"grievance_officer_email" text NOT NULL,
	"grievance_officer_phone" varchar(20) NOT NULL,
	"nodal_officer_details" jsonb,
	"lsp_agreement_ref" text,
	"dlg_arrangement" jsonb,
	"cims_dla_reported" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "loan_products" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"lender_id" uuid NOT NULL,
	"code" varchar(40) NOT NULL,
	"name" text NOT NULL,
	"repayment_type" "repayment_type" DEFAULT 'bullet' NOT NULL,
	"tenure_days_min" integer NOT NULL,
	"tenure_days_max" integer NOT NULL,
	"amount_min" numeric(18, 2) NOT NULL,
	"amount_max" numeric(18, 2) NOT NULL,
	"annual_interest_rate" numeric(12, 8) NOT NULL,
	"processing_fee_rate" numeric(12, 8) DEFAULT '0' NOT NULL,
	"processing_fee_flat" numeric(18, 2) DEFAULT '0' NOT NULL,
	"gst_rate" numeric(12, 8) DEFAULT '0.18' NOT NULL,
	"penal_charge_per_day" numeric(18, 2) DEFAULT '0' NOT NULL,
	"cooling_off_days" integer DEFAULT 3 NOT NULL,
	"instalment_frequency_days" integer,
	"apr_ceiling" numeric(12, 8),
	"version" integer DEFAULT 1 NOT NULL,
	"is_active" boolean DEFAULT false NOT NULL,
	"approved_by_lender_ref" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "loan_products_tenure_chk" CHECK ("loan_products"."tenure_days_min" > 0 AND "loan_products"."tenure_days_max" >= "loan_products"."tenure_days_min"),
	CONSTRAINT "loan_products_amount_chk" CHECK ("loan_products"."amount_min" > 0 AND "loan_products"."amount_max" >= "loan_products"."amount_min"),
	CONSTRAINT "loan_products_cooling_off_chk" CHECK ("loan_products"."cooling_off_days" >= 1)
);
--> statement-breakpoint
CREATE TABLE "consent_records" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"lender_id" uuid,
	"application_id" uuid,
	"purpose" "consent_purpose" NOT NULL,
	"status" "consent_status" NOT NULL,
	"notice_version" varchar(32) NOT NULL,
	"notice_hash" varchar(64) NOT NULL,
	"language" varchar(8) DEFAULT 'en' NOT NULL,
	"ip" "inet",
	"device_id" uuid,
	"expires_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "devices" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"fingerprint_hash" varchar(64) NOT NULL,
	"platform" varchar(16) NOT NULL,
	"user_agent" text,
	"risk_flags" jsonb,
	"first_seen_at" timestamp with time zone DEFAULT now() NOT NULL,
	"last_seen_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "identity_verifications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"application_id" uuid,
	"type" "verification_type" NOT NULL,
	"status" "verification_status" DEFAULT 'initiated' NOT NULL,
	"provider" varchar(40) NOT NULL,
	"mode" "integration_mode" NOT NULL,
	"is_mock" boolean NOT NULL,
	"provider_ref" text,
	"name_match_score" integer,
	"dob_matched" boolean,
	"failure_reason" text,
	"response_enc" "bytea",
	"verified_at" timestamp with time zone,
	"expires_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "otp_challenges" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"phone_hash" varchar(64) NOT NULL,
	"code_hash" varchar(128) NOT NULL,
	"purpose" varchar(24) DEFAULT 'login' NOT NULL,
	"attempts" integer DEFAULT 0 NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"consumed_at" timestamp with time zone,
	"ip" "inet",
	"device_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_profiles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"full_name_enc" "bytea",
	"dob_enc" "bytea",
	"email_enc" "bytea",
	"pan_enc" "bytea",
	"pan_hash" varchar(64),
	"pan_last4" varchar(4),
	"aadhaar_last4" varchar(4),
	"aadhaar_vault_ref" text,
	"current_address_enc" "bytea",
	"permanent_address_enc" "bytea",
	"employment_type" "employment_type",
	"occupation" text,
	"employer_name" text,
	"monthly_income_declared" varchar(24),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"device_id" uuid,
	"refresh_token_hash" varchar(128) NOT NULL,
	"ip" "inet",
	"expires_at" timestamp with time zone NOT NULL,
	"revoked_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"phone_enc" "bytea" NOT NULL,
	"phone_hash" varchar(64) NOT NULL,
	"phone_last4" varchar(4) NOT NULL,
	"status" varchar(24) DEFAULT 'active' NOT NULL,
	"last_login_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "aa_sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"application_id" uuid,
	"lender_id" uuid,
	"provider" varchar(40) NOT NULL,
	"mode" "integration_mode" NOT NULL,
	"is_mock" boolean NOT NULL,
	"consent_handle" text,
	"consent_id" text,
	"status" "aa_consent_status" DEFAULT 'created' NOT NULL,
	"fi_types" jsonb NOT NULL,
	"data_range_from" date,
	"data_range_to" date,
	"consent_expires_at" timestamp with time zone,
	"data_fetched_at" timestamp with time zone,
	"purge_after" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "bank_accounts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"account_number_enc" "bytea" NOT NULL,
	"account_number_hash" varchar(64) NOT NULL,
	"account_last4" varchar(4) NOT NULL,
	"ifsc" varchar(11) NOT NULL,
	"bank_name" text,
	"holder_name_at_bank" text,
	"name_match_score" integer,
	"verification_status" "verification_status" DEFAULT 'initiated' NOT NULL,
	"verification_method" varchar(32),
	"is_mock_verified" boolean DEFAULT false NOT NULL,
	"is_primary" boolean DEFAULT false NOT NULL,
	"verified_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "bank_analyses" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"aa_session_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"months_covered" integer NOT NULL,
	"avg_monthly_credit" numeric(18, 2),
	"avg_monthly_debit" numeric(18, 2),
	"avg_balance" numeric(18, 2),
	"detected_salary" numeric(18, 2),
	"salary_regularity_score" integer,
	"detected_emi_total" numeric(18, 2),
	"bounce_count" integer,
	"features" jsonb NOT NULL,
	"engine_version" varchar(24) NOT NULL,
	"is_mock" boolean NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "bank_transactions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"aa_session_id" uuid,
	"bank_account_id" uuid,
	"user_id" uuid NOT NULL,
	"txn_date" date NOT NULL,
	"amount" numeric(18, 2) NOT NULL,
	"direction" varchar(6) NOT NULL,
	"balance_after" numeric(18, 2),
	"mode" varchar(16),
	"narration_enc" "bytea",
	"category" varchar(32),
	"provider_txn_id" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "credit_reports" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"application_id" uuid,
	"lender_id" uuid NOT NULL,
	"bureau" varchar(16) NOT NULL,
	"mode" "integration_mode" NOT NULL,
	"is_mock" boolean NOT NULL,
	"consent_record_id" uuid NOT NULL,
	"enquiry_purpose" varchar(32) DEFAULT 'personal_loan' NOT NULL,
	"report_enc" "bytea",
	"status" varchar(16) NOT NULL,
	"pulled_at" timestamp with time zone DEFAULT now() NOT NULL,
	"purge_after" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "credit_scores" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"credit_report_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"score" integer,
	"score_model" varchar(32),
	"active_accounts" integer,
	"total_outstanding" numeric(18, 2),
	"monthly_obligation" numeric(18, 2),
	"overdue_accounts" integer,
	"max_dpd_12m" integer,
	"enquiries_30d" integer,
	"enquiries_90d" integer,
	"written_off_or_settled" boolean,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fraud_assessments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"application_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"score" integer NOT NULL,
	"signals" jsonb NOT NULL,
	"hard_stop" boolean DEFAULT false NOT NULL,
	"reviewed_by" uuid,
	"review_outcome" varchar(24),
	"engine_version" varchar(24) NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "underwriting_decisions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"application_id" uuid NOT NULL,
	"lender_id" uuid NOT NULL,
	"policy_version" varchar(24) NOT NULL,
	"component_scores" jsonb NOT NULL,
	"total_score" integer NOT NULL,
	"risk_band" "risk_band" NOT NULL,
	"outcome" "decision_outcome" NOT NULL,
	"reason_codes" jsonb NOT NULL,
	"max_eligible_amount" numeric(18, 2),
	"foir_computed" numeric(12, 8),
	"decided_by" varchar(16) NOT NULL,
	"staff_user_id" uuid,
	"override_reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "application_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"application_id" uuid NOT NULL,
	"from_status" "application_status",
	"to_status" "application_status" NOT NULL,
	"actor_type" "actor_type" NOT NULL,
	"actor_id" uuid,
	"note" text,
	"metadata" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "disbursements" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"loan_account_id" uuid NOT NULL,
	"lender_id" uuid NOT NULL,
	"beneficiary_account_id" uuid NOT NULL,
	"amount" numeric(18, 2) NOT NULL,
	"status" "disbursement_status" DEFAULT 'requested' NOT NULL,
	"idempotency_key" varchar(80) NOT NULL,
	"provider" varchar(32) NOT NULL,
	"mode" "integration_mode" NOT NULL,
	"is_mock" boolean NOT NULL,
	"source_account_ref" text NOT NULL,
	"maker_id" uuid NOT NULL,
	"checker_id" uuid,
	"provider_ref" text,
	"utr" varchar(40),
	"failure_reason" text,
	"attempts" integer DEFAULT 0 NOT NULL,
	"submitted_at" timestamp with time zone,
	"completed_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "disb_maker_checker_chk" CHECK ("disbursements"."checker_id" IS NULL OR "disbursements"."checker_id" <> "disbursements"."maker_id"),
	CONSTRAINT "disb_amount_chk" CHECK ("disbursements"."amount" > 0)
);
--> statement-breakpoint
CREATE TABLE "loan_accounts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"loan_no" varchar(24) NOT NULL,
	"lender_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"application_id" uuid NOT NULL,
	"offer_id" uuid NOT NULL,
	"status" "loan_account_status" DEFAULT 'cooling_off' NOT NULL,
	"principal" numeric(18, 2) NOT NULL,
	"annual_interest_rate" numeric(12, 8) NOT NULL,
	"apr" numeric(12, 8) NOT NULL,
	"disbursed_on" date,
	"maturity_date" date NOT NULL,
	"cooling_off_ends_at" timestamp with time zone,
	"principal_outstanding" numeric(18, 2) NOT NULL,
	"interest_accrued" numeric(18, 2) DEFAULT '0' NOT NULL,
	"fees_outstanding" numeric(18, 2) DEFAULT '0' NOT NULL,
	"penal_outstanding" numeric(18, 2) DEFAULT '0' NOT NULL,
	"dpd" integer DEFAULT 0 NOT NULL,
	"closed_at" timestamp with time zone,
	"version" integer DEFAULT 1 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "loan_applications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"application_no" varchar(24) NOT NULL,
	"user_id" uuid NOT NULL,
	"lender_id" uuid,
	"product_id" uuid,
	"status" "application_status" DEFAULT 'draft' NOT NULL,
	"requested_amount" numeric(18, 2) NOT NULL,
	"requested_tenure_days" integer NOT NULL,
	"declared_monthly_income" numeric(18, 2),
	"declared_existing_emi" numeric(18, 2),
	"purpose" varchar(40),
	"assigned_to" uuid,
	"sla_due_at" timestamp with time zone,
	"submitted_at" timestamp with time zone,
	"decided_at" timestamp with time zone,
	"rejection_reason_codes" jsonb,
	"version" integer DEFAULT 1 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "loan_apps_amount_chk" CHECK ("loan_applications"."requested_amount" > 0)
);
--> statement-breakpoint
CREATE TABLE "loan_documents" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"application_id" uuid,
	"loan_account_id" uuid,
	"type" "document_type" NOT NULL,
	"storage_key" text NOT NULL,
	"sha256" varchar(64) NOT NULL,
	"mime_type" varchar(64) NOT NULL,
	"size_bytes" integer NOT NULL,
	"template_version" varchar(24),
	"esign_provider" varchar(32),
	"esign_ref" text,
	"esigned_at" timestamp with time zone,
	"is_mock_signed" boolean DEFAULT false NOT NULL,
	"tamper_flags" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "loan_offers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"application_id" uuid NOT NULL,
	"lender_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"status" "offer_status" DEFAULT 'generated' NOT NULL,
	"principal" numeric(18, 2) NOT NULL,
	"tenure_days" integer NOT NULL,
	"annual_interest_rate" numeric(12, 8) NOT NULL,
	"interest_amount" numeric(18, 2) NOT NULL,
	"processing_fee" numeric(18, 2) NOT NULL,
	"gst_on_fees" numeric(18, 2) NOT NULL,
	"other_charges" numeric(18, 2) DEFAULT '0' NOT NULL,
	"net_disbursement" numeric(18, 2) NOT NULL,
	"total_repayment" numeric(18, 2) NOT NULL,
	"apr" numeric(12, 8) NOT NULL,
	"first_due_date" date NOT NULL,
	"schedule_preview" jsonb NOT NULL,
	"kfs_version" varchar(24) NOT NULL,
	"kfs_document_id" uuid,
	"valid_until" timestamp with time zone NOT NULL,
	"accepted_at" timestamp with time zone,
	"acceptance_consent_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "loan_offers_math_chk" CHECK ("loan_offers"."net_disbursement" = "loan_offers"."principal" - "loan_offers"."processing_fee" - "loan_offers"."gst_on_fees" - "loan_offers"."other_charges")
);
--> statement-breakpoint
CREATE TABLE "loan_schedules" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"loan_account_id" uuid NOT NULL,
	"instalment_no" integer NOT NULL,
	"due_date" date NOT NULL,
	"principal_due" numeric(18, 2) NOT NULL,
	"interest_due" numeric(18, 2) NOT NULL,
	"fees_due" numeric(18, 2) DEFAULT '0' NOT NULL,
	"total_due" numeric(18, 2) NOT NULL,
	"paid_amount" numeric(18, 2) DEFAULT '0' NOT NULL,
	"status" "schedule_status" DEFAULT 'upcoming' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "mandates" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"loan_account_id" uuid,
	"bank_account_id" uuid NOT NULL,
	"type" varchar(16) NOT NULL,
	"provider" varchar(32) NOT NULL,
	"mode" "integration_mode" NOT NULL,
	"is_mock" boolean NOT NULL,
	"max_amount" numeric(18, 2) NOT NULL,
	"status" "mandate_status" DEFAULT 'created' NOT NULL,
	"umrn" varchar(40),
	"valid_until" date,
	"consent_record_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "repayment_allocations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"repayment_id" uuid NOT NULL,
	"schedule_id" uuid,
	"bucket" "allocation_bucket" NOT NULL,
	"amount" numeric(18, 2) NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "repayments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"loan_account_id" uuid NOT NULL,
	"lender_id" uuid NOT NULL,
	"amount" numeric(18, 2) NOT NULL,
	"channel" "repayment_channel" NOT NULL,
	"status" "repayment_status" DEFAULT 'initiated' NOT NULL,
	"idempotency_key" varchar(80) NOT NULL,
	"provider" varchar(32) NOT NULL,
	"mode" "integration_mode" NOT NULL,
	"is_mock" boolean NOT NULL,
	"provider_ref" text,
	"utr" varchar(40),
	"paid_at" timestamp with time zone,
	"receipt_document_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "repay_amount_chk" CHECK ("repayments"."amount" > 0)
);
--> statement-breakpoint
CREATE TABLE "ledger_accounts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"lender_id" uuid NOT NULL,
	"code" varchar(64) NOT NULL,
	"name" text NOT NULL,
	"type" "ledger_account_type" NOT NULL,
	"loan_account_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ledger_entries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"transaction_id" uuid NOT NULL,
	"ledger_account_id" uuid NOT NULL,
	"direction" "entry_direction" NOT NULL,
	"amount" numeric(18, 2) NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "ledger_entries_positive_chk" CHECK ("ledger_entries"."amount" > 0)
);
--> statement-breakpoint
CREATE TABLE "ledger_transactions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"lender_id" uuid NOT NULL,
	"event_type" varchar(40) NOT NULL,
	"source_type" varchar(32) NOT NULL,
	"source_id" uuid NOT NULL,
	"idempotency_key" varchar(80) NOT NULL,
	"value_date" date NOT NULL,
	"reverses_transaction_id" uuid,
	"metadata" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "admin_user_roles" (
	"admin_user_id" uuid NOT NULL,
	"role_id" uuid NOT NULL,
	"lender_id" uuid,
	CONSTRAINT "admin_user_roles_admin_user_id_role_id_pk" PRIMARY KEY("admin_user_id","role_id")
);
--> statement-breakpoint
CREATE TABLE "admin_users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" varchar(254) NOT NULL,
	"full_name" text NOT NULL,
	"lender_id" uuid,
	"password_hash" text,
	"mfa_secret_enc" "bytea",
	"mfa_enabled" boolean DEFAULT false NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"last_login_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "api_integrations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"lender_id" uuid,
	"category" varchar(24) NOT NULL,
	"provider" varchar(40) NOT NULL,
	"mode" "integration_mode" DEFAULT 'mock' NOT NULL,
	"secret_ref" text,
	"config" jsonb,
	"is_enabled" boolean DEFAULT false NOT NULL,
	"last_health_at" timestamp with time zone,
	"last_health_ok" boolean,
	"live_approved_by" uuid,
	"live_approved_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "audit_logs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"actor_type" "actor_type" NOT NULL,
	"actor_id" uuid,
	"lender_id" uuid,
	"action" varchar(80) NOT NULL,
	"entity_type" varchar(48) NOT NULL,
	"entity_id" uuid,
	"before" jsonb,
	"after" jsonb,
	"reason" text,
	"ip" "inet",
	"request_id" varchar(64),
	"prev_hash" varchar(64),
	"hash" varchar(64) NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "collections_cases" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"loan_account_id" uuid NOT NULL,
	"lender_id" uuid NOT NULL,
	"stage" "collections_stage" NOT NULL,
	"status" "case_status" DEFAULT 'open' NOT NULL,
	"assigned_to" uuid,
	"recovery_agency_ref" text,
	"promise_to_pay_date" timestamp with time zone,
	"contact_attempts_today" integer DEFAULT 0 NOT NULL,
	"notes" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "complaints" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"ticket_no" varchar(24) NOT NULL,
	"user_id" uuid,
	"lender_id" uuid,
	"loan_account_id" uuid,
	"category" varchar(40) NOT NULL,
	"description" text NOT NULL,
	"status" "complaint_status" DEFAULT 'received' NOT NULL,
	"assigned_to" uuid,
	"acknowledged_at" timestamp with time zone,
	"resolution_due_at" timestamp with time zone NOT NULL,
	"resolved_at" timestamp with time zone,
	"resolution" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "idempotency_keys" (
	"key" varchar(80) PRIMARY KEY NOT NULL,
	"scope" varchar(48) NOT NULL,
	"request_hash" varchar(64) NOT NULL,
	"response_status" integer,
	"response_body" jsonb,
	"locked_until" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "notifications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"loan_account_id" uuid,
	"channel" "notification_channel" NOT NULL,
	"template_code" varchar(64) NOT NULL,
	"dlt_template_id" varchar(40),
	"status" "notification_status" DEFAULT 'queued' NOT NULL,
	"is_mock" boolean NOT NULL,
	"payload" jsonb,
	"provider_ref" text,
	"scheduled_for" timestamp with time zone,
	"sent_at" timestamp with time zone,
	"failure_reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "permissions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" varchar(64) NOT NULL,
	"description" text NOT NULL,
	"is_critical" boolean DEFAULT false NOT NULL
);
--> statement-breakpoint
CREATE TABLE "role_permissions" (
	"role_id" uuid NOT NULL,
	"permission_id" uuid NOT NULL,
	CONSTRAINT "role_permissions_role_id_permission_id_pk" PRIMARY KEY("role_id","permission_id")
);
--> statement-breakpoint
CREATE TABLE "roles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" varchar(48) NOT NULL,
	"name" text NOT NULL,
	"scope" varchar(16) NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "webhook_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"provider" varchar(40) NOT NULL,
	"event_type" varchar(64) NOT NULL,
	"provider_event_id" varchar(128) NOT NULL,
	"signature_valid" boolean NOT NULL,
	"payload_enc" "bytea" NOT NULL,
	"processed_at" timestamp with time zone,
	"processing_error" text,
	"attempts" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "loan_products" ADD CONSTRAINT "loan_products_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "consent_records" ADD CONSTRAINT "consent_records_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "devices" ADD CONSTRAINT "devices_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "identity_verifications" ADD CONSTRAINT "identity_verifications_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_profiles" ADD CONSTRAINT "user_profiles_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_sessions" ADD CONSTRAINT "user_sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_sessions" ADD CONSTRAINT "user_sessions_device_id_devices_id_fk" FOREIGN KEY ("device_id") REFERENCES "public"."devices"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "aa_sessions" ADD CONSTRAINT "aa_sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bank_accounts" ADD CONSTRAINT "bank_accounts_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bank_analyses" ADD CONSTRAINT "bank_analyses_aa_session_id_aa_sessions_id_fk" FOREIGN KEY ("aa_session_id") REFERENCES "public"."aa_sessions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bank_analyses" ADD CONSTRAINT "bank_analyses_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bank_transactions" ADD CONSTRAINT "bank_transactions_aa_session_id_aa_sessions_id_fk" FOREIGN KEY ("aa_session_id") REFERENCES "public"."aa_sessions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bank_transactions" ADD CONSTRAINT "bank_transactions_bank_account_id_bank_accounts_id_fk" FOREIGN KEY ("bank_account_id") REFERENCES "public"."bank_accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bank_transactions" ADD CONSTRAINT "bank_transactions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "credit_reports" ADD CONSTRAINT "credit_reports_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "credit_scores" ADD CONSTRAINT "credit_scores_credit_report_id_credit_reports_id_fk" FOREIGN KEY ("credit_report_id") REFERENCES "public"."credit_reports"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "credit_scores" ADD CONSTRAINT "credit_scores_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fraud_assessments" ADD CONSTRAINT "fraud_assessments_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "application_events" ADD CONSTRAINT "application_events_application_id_loan_applications_id_fk" FOREIGN KEY ("application_id") REFERENCES "public"."loan_applications"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "disbursements" ADD CONSTRAINT "disbursements_loan_account_id_loan_accounts_id_fk" FOREIGN KEY ("loan_account_id") REFERENCES "public"."loan_accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "disbursements" ADD CONSTRAINT "disbursements_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "disbursements" ADD CONSTRAINT "disbursements_beneficiary_account_id_bank_accounts_id_fk" FOREIGN KEY ("beneficiary_account_id") REFERENCES "public"."bank_accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_accounts" ADD CONSTRAINT "loan_accounts_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_accounts" ADD CONSTRAINT "loan_accounts_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_accounts" ADD CONSTRAINT "loan_accounts_application_id_loan_applications_id_fk" FOREIGN KEY ("application_id") REFERENCES "public"."loan_applications"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_accounts" ADD CONSTRAINT "loan_accounts_offer_id_loan_offers_id_fk" FOREIGN KEY ("offer_id") REFERENCES "public"."loan_offers"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_applications" ADD CONSTRAINT "loan_applications_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_applications" ADD CONSTRAINT "loan_applications_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_applications" ADD CONSTRAINT "loan_applications_product_id_loan_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."loan_products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_documents" ADD CONSTRAINT "loan_documents_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_documents" ADD CONSTRAINT "loan_documents_application_id_loan_applications_id_fk" FOREIGN KEY ("application_id") REFERENCES "public"."loan_applications"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_offers" ADD CONSTRAINT "loan_offers_application_id_loan_applications_id_fk" FOREIGN KEY ("application_id") REFERENCES "public"."loan_applications"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_offers" ADD CONSTRAINT "loan_offers_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_offers" ADD CONSTRAINT "loan_offers_product_id_loan_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."loan_products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loan_schedules" ADD CONSTRAINT "loan_schedules_loan_account_id_loan_accounts_id_fk" FOREIGN KEY ("loan_account_id") REFERENCES "public"."loan_accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "mandates" ADD CONSTRAINT "mandates_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "mandates" ADD CONSTRAINT "mandates_loan_account_id_loan_accounts_id_fk" FOREIGN KEY ("loan_account_id") REFERENCES "public"."loan_accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "mandates" ADD CONSTRAINT "mandates_bank_account_id_bank_accounts_id_fk" FOREIGN KEY ("bank_account_id") REFERENCES "public"."bank_accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "repayment_allocations" ADD CONSTRAINT "repayment_allocations_repayment_id_repayments_id_fk" FOREIGN KEY ("repayment_id") REFERENCES "public"."repayments"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "repayment_allocations" ADD CONSTRAINT "repayment_allocations_schedule_id_loan_schedules_id_fk" FOREIGN KEY ("schedule_id") REFERENCES "public"."loan_schedules"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "repayments" ADD CONSTRAINT "repayments_loan_account_id_loan_accounts_id_fk" FOREIGN KEY ("loan_account_id") REFERENCES "public"."loan_accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "repayments" ADD CONSTRAINT "repayments_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ledger_accounts" ADD CONSTRAINT "ledger_accounts_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ledger_entries" ADD CONSTRAINT "ledger_entries_transaction_id_ledger_transactions_id_fk" FOREIGN KEY ("transaction_id") REFERENCES "public"."ledger_transactions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ledger_entries" ADD CONSTRAINT "ledger_entries_ledger_account_id_ledger_accounts_id_fk" FOREIGN KEY ("ledger_account_id") REFERENCES "public"."ledger_accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ledger_transactions" ADD CONSTRAINT "ledger_transactions_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "admin_user_roles" ADD CONSTRAINT "admin_user_roles_admin_user_id_admin_users_id_fk" FOREIGN KEY ("admin_user_id") REFERENCES "public"."admin_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "admin_user_roles" ADD CONSTRAINT "admin_user_roles_role_id_roles_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "admin_user_roles" ADD CONSTRAINT "admin_user_roles_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "admin_users" ADD CONSTRAINT "admin_users_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "api_integrations" ADD CONSTRAINT "api_integrations_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "collections_cases" ADD CONSTRAINT "collections_cases_loan_account_id_loan_accounts_id_fk" FOREIGN KEY ("loan_account_id") REFERENCES "public"."loan_accounts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "collections_cases" ADD CONSTRAINT "collections_cases_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "complaints" ADD CONSTRAINT "complaints_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "complaints" ADD CONSTRAINT "complaints_lender_id_lenders_id_fk" FOREIGN KEY ("lender_id") REFERENCES "public"."lenders"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_role_id_roles_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_permission_id_permissions_id_fk" FOREIGN KEY ("permission_id") REFERENCES "public"."permissions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "lenders_rbi_reg_uq" ON "lenders" USING btree ("rbi_registration_no");--> statement-breakpoint
CREATE UNIQUE INDEX "loan_products_lender_code_ver_uq" ON "loan_products" USING btree ("lender_id","code","version");--> statement-breakpoint
CREATE INDEX "loan_products_lender_idx" ON "loan_products" USING btree ("lender_id");--> statement-breakpoint
CREATE INDEX "consent_user_purpose_idx" ON "consent_records" USING btree ("user_id","purpose","created_at");--> statement-breakpoint
CREATE INDEX "devices_fp_idx" ON "devices" USING btree ("fingerprint_hash");--> statement-breakpoint
CREATE INDEX "devices_user_idx" ON "devices" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idv_user_type_idx" ON "identity_verifications" USING btree ("user_id","type");--> statement-breakpoint
CREATE INDEX "idv_application_idx" ON "identity_verifications" USING btree ("application_id");--> statement-breakpoint
CREATE INDEX "otp_phone_created_idx" ON "otp_challenges" USING btree ("phone_hash","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "user_profiles_user_uq" ON "user_profiles" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "user_profiles_pan_hash_uq" ON "user_profiles" USING btree ("pan_hash");--> statement-breakpoint
CREATE UNIQUE INDEX "user_sessions_refresh_uq" ON "user_sessions" USING btree ("refresh_token_hash");--> statement-breakpoint
CREATE INDEX "user_sessions_user_idx" ON "user_sessions" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "users_phone_hash_uq" ON "users" USING btree ("phone_hash");--> statement-breakpoint
CREATE INDEX "aa_user_idx" ON "aa_sessions" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "aa_consent_handle_uq" ON "aa_sessions" USING btree ("consent_handle");--> statement-breakpoint
CREATE UNIQUE INDEX "bank_accounts_user_acct_uq" ON "bank_accounts" USING btree ("user_id","account_number_hash");--> statement-breakpoint
CREATE INDEX "bank_accounts_acct_hash_idx" ON "bank_accounts" USING btree ("account_number_hash");--> statement-breakpoint
CREATE INDEX "bank_analyses_user_idx" ON "bank_analyses" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "bank_txn_user_date_idx" ON "bank_transactions" USING btree ("user_id","txn_date");--> statement-breakpoint
CREATE INDEX "bank_txn_session_idx" ON "bank_transactions" USING btree ("aa_session_id");--> statement-breakpoint
CREATE INDEX "credit_reports_user_idx" ON "credit_reports" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "credit_reports_app_idx" ON "credit_reports" USING btree ("application_id");--> statement-breakpoint
CREATE INDEX "credit_scores_user_idx" ON "credit_scores" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "fraud_app_idx" ON "fraud_assessments" USING btree ("application_id");--> statement-breakpoint
CREATE INDEX "uw_app_idx" ON "underwriting_decisions" USING btree ("application_id");--> statement-breakpoint
CREATE INDEX "app_events_app_idx" ON "application_events" USING btree ("application_id","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "disb_idem_uq" ON "disbursements" USING btree ("idempotency_key");--> statement-breakpoint
CREATE UNIQUE INDEX "disb_one_live_per_loan_uq" ON "disbursements" USING btree ("loan_account_id") WHERE status NOT IN ('failed','reversed');--> statement-breakpoint
CREATE UNIQUE INDEX "loan_accounts_no_uq" ON "loan_accounts" USING btree ("loan_no");--> statement-breakpoint
CREATE UNIQUE INDEX "loan_accounts_app_uq" ON "loan_accounts" USING btree ("application_id");--> statement-breakpoint
CREATE INDEX "loan_accounts_lender_status_idx" ON "loan_accounts" USING btree ("lender_id","status");--> statement-breakpoint
CREATE INDEX "loan_accounts_user_idx" ON "loan_accounts" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "loan_accounts_dpd_idx" ON "loan_accounts" USING btree ("dpd") WHERE dpd > 0;--> statement-breakpoint
CREATE UNIQUE INDEX "loan_apps_no_uq" ON "loan_applications" USING btree ("application_no");--> statement-breakpoint
CREATE INDEX "loan_apps_user_idx" ON "loan_applications" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "loan_apps_lender_status_idx" ON "loan_applications" USING btree ("lender_id","status");--> statement-breakpoint
CREATE INDEX "loan_apps_assigned_idx" ON "loan_applications" USING btree ("assigned_to","status");--> statement-breakpoint
CREATE UNIQUE INDEX "loan_apps_one_open_per_user_uq" ON "loan_applications" USING btree ("user_id") WHERE status NOT IN ('rejected','cancelled','disbursed');--> statement-breakpoint
CREATE INDEX "loan_docs_app_idx" ON "loan_documents" USING btree ("application_id");--> statement-breakpoint
CREATE INDEX "loan_docs_account_idx" ON "loan_documents" USING btree ("loan_account_id");--> statement-breakpoint
CREATE INDEX "loan_offers_app_idx" ON "loan_offers" USING btree ("application_id");--> statement-breakpoint
CREATE UNIQUE INDEX "loan_schedules_acct_no_uq" ON "loan_schedules" USING btree ("loan_account_id","instalment_no");--> statement-breakpoint
CREATE INDEX "loan_schedules_due_idx" ON "loan_schedules" USING btree ("due_date","status");--> statement-breakpoint
CREATE INDEX "mandates_account_idx" ON "mandates" USING btree ("loan_account_id");--> statement-breakpoint
CREATE INDEX "repay_alloc_repay_idx" ON "repayment_allocations" USING btree ("repayment_id");--> statement-breakpoint
CREATE UNIQUE INDEX "repay_idem_uq" ON "repayments" USING btree ("idempotency_key");--> statement-breakpoint
CREATE UNIQUE INDEX "repay_provider_ref_uq" ON "repayments" USING btree ("provider","provider_ref");--> statement-breakpoint
CREATE INDEX "repay_account_idx" ON "repayments" USING btree ("loan_account_id");--> statement-breakpoint
CREATE UNIQUE INDEX "ledger_accounts_lender_code_uq" ON "ledger_accounts" USING btree ("lender_id","code");--> statement-breakpoint
CREATE INDEX "ledger_entries_txn_idx" ON "ledger_entries" USING btree ("transaction_id");--> statement-breakpoint
CREATE INDEX "ledger_entries_account_idx" ON "ledger_entries" USING btree ("ledger_account_id");--> statement-breakpoint
CREATE UNIQUE INDEX "ledger_txn_idem_uq" ON "ledger_transactions" USING btree ("idempotency_key");--> statement-breakpoint
CREATE INDEX "ledger_txn_source_idx" ON "ledger_transactions" USING btree ("source_type","source_id");--> statement-breakpoint
CREATE UNIQUE INDEX "admin_users_email_uq" ON "admin_users" USING btree ("email");--> statement-breakpoint
CREATE UNIQUE INDEX "api_integrations_scope_uq" ON "api_integrations" USING btree ("lender_id","category","provider");--> statement-breakpoint
CREATE INDEX "audit_entity_idx" ON "audit_logs" USING btree ("entity_type","entity_id");--> statement-breakpoint
CREATE INDEX "audit_actor_idx" ON "audit_logs" USING btree ("actor_id","created_at");--> statement-breakpoint
CREATE INDEX "collections_lender_stage_idx" ON "collections_cases" USING btree ("lender_id","stage","status");--> statement-breakpoint
CREATE UNIQUE INDEX "complaints_ticket_uq" ON "complaints" USING btree ("ticket_no");--> statement-breakpoint
CREATE INDEX "complaints_status_idx" ON "complaints" USING btree ("status","resolution_due_at");--> statement-breakpoint
CREATE INDEX "notifications_user_idx" ON "notifications" USING btree ("user_id","created_at");--> statement-breakpoint
CREATE INDEX "notifications_status_idx" ON "notifications" USING btree ("status","scheduled_for");--> statement-breakpoint
CREATE UNIQUE INDEX "permissions_code_uq" ON "permissions" USING btree ("code");--> statement-breakpoint
CREATE UNIQUE INDEX "roles_code_uq" ON "roles" USING btree ("code");--> statement-breakpoint
CREATE UNIQUE INDEX "webhook_provider_event_uq" ON "webhook_events" USING btree ("provider","provider_event_id");