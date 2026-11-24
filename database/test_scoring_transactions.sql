-- Live integration test. This entire test is rolled back, including new rows.
-- Requires at least two active accounts in the same currency.
BEGIN;
DO $$
DECLARE
  a int; c int; b numeric; d numeric; curr text; t bigint; u bigint;
  actual numeric; row_tx record; rejected boolean := false;
BEGIN
  SELECT account_id,balance,currency::text INTO a,b,curr
  FROM public.accounts WHERE status='active' AND balance>=10 ORDER BY balance DESC LIMIT 1;
  IF a IS NULL THEN RAISE EXCEPTION 'Two active test accounts required'; END IF;
  SELECT account_id,balance INTO c,d
  FROM public.accounts WHERE status='active' AND currency::text=curr AND account_id<>a
  ORDER BY account_id LIMIT 1;
  IF c IS NULL THEN RAISE EXCEPTION 'Need a second active account in %',curr; END IF;

  -- Pending deposit does not change account balance.
  INSERT INTO public.transactions(to_account_id,transaction_type,amount,status)
  VALUES(a,'deposit',100,'pending') RETURNING transaction_id INTO t;
  SELECT balance INTO actual FROM public.accounts WHERE account_id=a;
  IF actual<>b THEN RAISE EXCEPTION 'Pending deposit changed balance'; END IF;

  UPDATE public.transactions SET status='completed' WHERE transaction_id=t;
  SELECT balance INTO actual FROM public.accounts WHERE account_id=a;
  IF actual<>b+100 THEN RAISE EXCEPTION 'Deposit failed'; END IF;
  SELECT * INTO row_tx FROM public.v_transaction_balances WHERE transaction_id=t;
  IF row_tx.to_balance_before<>b OR row_tx.to_balance_after<>b+100 THEN
    RAISE EXCEPTION 'Deposit snapshot wrong'; END IF;

  UPDATE public.transactions SET status='completed' WHERE transaction_id=t;
  SELECT balance INTO actual FROM public.accounts WHERE account_id=a;
  IF actual<>b+100 THEN RAISE EXCEPTION 'Duplicate completion changed balance'; END IF;

  -- Reject a completed deposit: exactly the monetary effect is reversed.
  UPDATE public.transactions SET status='failed' WHERE transaction_id=t;
  SELECT balance INTO actual FROM public.accounts WHERE account_id=a;
  IF actual<>b THEN RAISE EXCEPTION 'Deposit rejection failed to reverse'; END IF;
  SELECT * INTO row_tx FROM public.v_transaction_balances WHERE transaction_id=t;
  IF row_tx.to_balance_before<>b+100 OR row_tx.to_balance_after<>b THEN
    RAISE EXCEPTION 'Reversal snapshot wrong'; END IF;

  -- A transfer adjusts both balances; cancel returns both to their baseline.
  INSERT INTO public.transactions(from_account_id,to_account_id,transaction_type,amount,status)
  VALUES(a,c,'transfer',10,'completed') RETURNING transaction_id INTO u;
  IF (SELECT balance FROM public.accounts WHERE account_id=a)<>b-10
     OR (SELECT balance FROM public.accounts WHERE account_id=c)<>d+10 THEN
     RAISE EXCEPTION 'Transfer did not update both accounts'; END IF;
  UPDATE public.transactions SET status='cancelled' WHERE transaction_id=u;
  IF (SELECT balance FROM public.accounts WHERE account_id=a)<>b
     OR (SELECT balance FROM public.accounts WHERE account_id=c)<>d THEN
     RAISE EXCEPTION 'Transfer reversal did not restore balances'; END IF;

  -- Insufficient funds must reject the posting without changing balances.
  INSERT INTO public.transactions(from_account_id,transaction_type,amount,status)
  VALUES(a,'withdrawal',b+1,'pending') RETURNING transaction_id INTO u;
  BEGIN
    UPDATE public.transactions SET status='completed' WHERE transaction_id=u;
  EXCEPTION WHEN SQLSTATE 'P0001' THEN
    -- Trigger's rejected posting leaves transaction pending and balance intact.
    rejected := true;
  END;
  IF NOT rejected THEN RAISE EXCEPTION 'Overdraft should have been rejected'; END IF;
  IF (SELECT balance FROM public.accounts WHERE account_id=a)<>b
     OR (SELECT status FROM public.transactions WHERE transaction_id=u)<>'pending' THEN
    RAISE EXCEPTION 'Failed posting was not rolled back'; END IF;

  IF EXISTS(SELECT 1 FROM public.v_credit_scoring_normalized
            WHERE score NOT BETWEEN 0 AND 1) THEN
    RAISE EXCEPTION 'Normalized score outside 0..1'; END IF;
  RAISE NOTICE 'PASS: deposit, balances, idempotency, reversal, atomic transfer, insufficient funds, scoring';
END $$;
ROLLBACK;
