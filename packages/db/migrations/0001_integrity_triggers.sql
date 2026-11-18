-- Integrity controls that Drizzle cannot express declaratively.

-- 1. Append-only tables: block UPDATE and DELETE.
CREATE OR REPLACE FUNCTION qc_block_mutation() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'table % is append-only (% blocked)', TG_TABLE_NAME, TG_OP
    USING ERRCODE = 'integrity_constraint_violation';
END;
$$ LANGUAGE plpgsql;
--> statement-breakpoint
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'audit_logs','consent_records','application_events','ledger_transactions','ledger_entries',
    'repayment_allocations','underwriting_decisions'
  ] LOOP
    IF to_regclass(t) IS NOT NULL THEN
      EXECUTE format('CREATE TRIGGER %I_append_only BEFORE UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE FUNCTION qc_block_mutation()', t, t);
    END IF;
  END LOOP;
END $$;
--> statement-breakpoint

-- 2. Offers: priced terms are immutable; only status/accepted_at/acceptance_consent_id/kfs_document_id may change.
CREATE OR REPLACE FUNCTION qc_offer_terms_guard() RETURNS trigger AS $$
BEGIN
  IF (NEW.principal, NEW.tenure_days, NEW.annual_interest_rate, NEW.interest_amount, NEW.processing_fee,
      NEW.gst_on_fees, NEW.other_charges, NEW.net_disbursement, NEW.total_repayment, NEW.apr, NEW.first_due_date)
     IS DISTINCT FROM
     (OLD.principal, OLD.tenure_days, OLD.annual_interest_rate, OLD.interest_amount, OLD.processing_fee,
      OLD.gst_on_fees, OLD.other_charges, OLD.net_disbursement, OLD.total_repayment, OLD.apr, OLD.first_due_date) THEN
    RAISE EXCEPTION 'loan offer terms are immutable; generate a new offer' USING ERRCODE = 'integrity_constraint_violation';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--> statement-breakpoint
CREATE TRIGGER loan_offers_terms_immutable BEFORE UPDATE ON loan_offers FOR EACH ROW EXECUTE FUNCTION qc_offer_terms_guard();
--> statement-breakpoint
CREATE TRIGGER loan_offers_no_delete BEFORE DELETE ON loan_offers FOR EACH ROW EXECUTE FUNCTION qc_block_mutation();
--> statement-breakpoint

-- 3. Double-entry: every ledger transaction must balance at COMMIT.
CREATE OR REPLACE FUNCTION qc_ledger_balanced() RETURNS trigger AS $$
DECLARE d numeric; c numeric; n int;
BEGIN
  SELECT COALESCE(SUM(amount) FILTER (WHERE direction = 'debit'), 0),
         COALESCE(SUM(amount) FILTER (WHERE direction = 'credit'), 0),
         COUNT(*)
    INTO d, c, n
    FROM ledger_entries WHERE transaction_id = NEW.transaction_id;
  IF n < 2 OR d <> c THEN
    RAISE EXCEPTION 'ledger transaction % unbalanced (debits %, credits %, entries %)', NEW.transaction_id, d, c, n
      USING ERRCODE = 'integrity_constraint_violation';
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
--> statement-breakpoint
CREATE CONSTRAINT TRIGGER ledger_entries_balanced
  AFTER INSERT ON ledger_entries DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION qc_ledger_balanced();
--> statement-breakpoint

-- 4. updated_at maintenance.
CREATE OR REPLACE FUNCTION qc_touch_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
--> statement-breakpoint
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE table_schema = 'public' AND column_name = 'updated_at' LOOP
    EXECUTE format('CREATE TRIGGER %I_touch BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION qc_touch_updated_at()', r.table_name, r.table_name);
  END LOOP;
END $$;
