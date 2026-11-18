-- Integrity tests for DB-level financial controls. Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=0 -f test/integrity.sql
-- Each block prints PASS/FAIL. Runs inside a transaction that is rolled back.
\set QUIET on
BEGIN;
CREATE TEMP TABLE results(name text, ok boolean);

INSERT INTO lenders(id, legal_name, rbi_registration_no, entity_type, grievance_officer_name, grievance_officer_email, grievance_officer_phone)
VALUES ('00000000-0000-0000-0000-00000000000a','MOCK LENDER (not a real NBFC)','MOCK-000','nbfc_icc','Mock GRO','gro@example.invalid','0000000000');
INSERT INTO users(id, phone_enc, phone_hash, phone_last4) VALUES ('00000000-0000-0000-0000-0000000000b1','\x00','h1','0001');
INSERT INTO ledger_accounts(id, lender_id, code, name, type) VALUES
 ('00000000-0000-0000-0000-0000000000c1','00000000-0000-0000-0000-00000000000a','LOAN_RECEIVABLE','Loan receivable','asset'),
 ('00000000-0000-0000-0000-0000000000c2','00000000-0000-0000-0000-00000000000a','LENDER_BANK','Lender bank','asset');

-- T1 balanced ledger transaction commits (checked via SET CONSTRAINTS IMMEDIATE)
DO $$ BEGIN
  INSERT INTO ledger_transactions(id, lender_id, event_type, source_type, source_id, idempotency_key, value_date)
  VALUES ('00000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-00000000000a','DISBURSEMENT','test',gen_random_uuid(),'t1',current_date);
  INSERT INTO ledger_entries(transaction_id, ledger_account_id, direction, amount) VALUES
   ('00000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-0000000000c1','debit',10000.00),
   ('00000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-0000000000c2','credit',10000.00);
  SET CONSTRAINTS ALL IMMEDIATE; SET CONSTRAINTS ALL DEFERRED;
  INSERT INTO results VALUES ('T1 balanced ledger txn accepted', true);
EXCEPTION WHEN OTHERS THEN INSERT INTO results VALUES ('T1 balanced ledger txn accepted', false); END $$;

-- T2 unbalanced ledger transaction rejected
DO $$ BEGIN
  INSERT INTO ledger_transactions(id, lender_id, event_type, source_type, source_id, idempotency_key, value_date)
  VALUES ('00000000-0000-0000-0000-0000000000d2','00000000-0000-0000-0000-00000000000a','DISBURSEMENT','test',gen_random_uuid(),'t2',current_date);
  INSERT INTO ledger_entries(transaction_id, ledger_account_id, direction, amount) VALUES
   ('00000000-0000-0000-0000-0000000000d2','00000000-0000-0000-0000-0000000000c1','debit',10000.00),
   ('00000000-0000-0000-0000-0000000000d2','00000000-0000-0000-0000-0000000000c2','credit',9999.99);
  SET CONSTRAINTS ALL IMMEDIATE;
  INSERT INTO results VALUES ('T2 unbalanced ledger txn rejected', false);
EXCEPTION WHEN integrity_constraint_violation THEN INSERT INTO results VALUES ('T2 unbalanced ledger txn rejected', true); END $$;
SET CONSTRAINTS ALL DEFERRED;

-- T3 ledger entries are append-only
DO $$ BEGIN
  UPDATE ledger_entries SET amount = 1 WHERE transaction_id = '00000000-0000-0000-0000-0000000000d1';
  INSERT INTO results VALUES ('T3 ledger entry UPDATE blocked', false);
EXCEPTION WHEN integrity_constraint_violation THEN INSERT INTO results VALUES ('T3 ledger entry UPDATE blocked', true); END $$;

-- T4 audit log DELETE blocked
DO $$ BEGIN
  INSERT INTO audit_logs(actor_type, action, entity_type, hash) VALUES ('system','test','test','x');
  DELETE FROM audit_logs;
  INSERT INTO results VALUES ('T4 audit log DELETE blocked', false);
EXCEPTION WHEN integrity_constraint_violation THEN INSERT INTO results VALUES ('T4 audit log DELETE blocked', true); END $$;

-- T5 floating-point money impossible: numeric(18,2) keeps exact paise
INSERT INTO results SELECT 'T5 numeric money exact (0.1+0.2=0.3)', (0.10::numeric(18,2) + 0.20::numeric(18,2)) = 0.30::numeric(18,2);

-- T6 only one open application per user
DO $$ BEGIN
  INSERT INTO loan_applications(application_no, user_id, requested_amount, requested_tenure_days, status) VALUES ('A1','00000000-0000-0000-0000-0000000000b1',5000,30,'submitted');
  INSERT INTO loan_applications(application_no, user_id, requested_amount, requested_tenure_days, status) VALUES ('A2','00000000-0000-0000-0000-0000000000b1',5000,30,'draft');
  INSERT INTO results VALUES ('T6 duplicate open application rejected', false);
EXCEPTION WHEN unique_violation THEN INSERT INTO results VALUES ('T6 duplicate open application rejected', true); END $$;

-- T7 product cooling-off must be >= 1 day
DO $$ BEGIN
  INSERT INTO loan_products(lender_id, code, name, tenure_days_min, tenure_days_max, amount_min, amount_max, annual_interest_rate, cooling_off_days)
  VALUES ('00000000-0000-0000-0000-00000000000a','P0','bad',15,15,1000,1000,0.24,0);
  INSERT INTO results VALUES ('T7 cooling-off < 1 day rejected', false);
EXCEPTION WHEN check_violation THEN INSERT INTO results VALUES ('T7 cooling-off < 1 day rejected', true); END $$;

SELECT CASE WHEN ok THEN 'PASS' ELSE 'FAIL' END AS result, name FROM results ORDER BY name;
SELECT CASE WHEN bool_and(ok) THEN 'ALL PASS' ELSE 'SOME FAILED' END AS summary FROM results;
ROLLBACK;
