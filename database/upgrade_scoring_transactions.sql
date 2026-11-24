-- Northstar Bank / PostgreSQL upgrade: business views and atomic balance posting.
-- Safe to rerun on an existing bank_database. Does NOT replay imported history.
-- Run ONCE per upgrade after a database backup, with ON_ERROR_STOP=1.
BEGIN;

-- 1) Credit scoring calculated in the database, not in API JavaScript.
-- Independent aggregations avoid multiplying loans, payments and accounts.
CREATE OR REPLACE VIEW public.v_credit_scoring AS
WITH loan_stats AS (
  SELECT customer_id, COUNT(*)::int AS loan_count,
         COUNT(*) FILTER (WHERE status::text IN ('active','approved'))::int AS open_loans
  FROM public.loans GROUP BY customer_id
), payment_stats AS (
  SELECT l.customer_id, COUNT(*)::int AS payment_count,
         COUNT(*) FILTER (WHERE p.is_late IS TRUE)::int AS late_count
  FROM public.loans l
  JOIN public.loan_payments p ON p.loan_id=l.loan_id
  GROUP BY l.customer_id
), account_stats AS (
  SELECT ah.customer_id, COUNT(DISTINCT a.account_id)::int AS account_count,
         COALESCE(SUM(CASE WHEN a.currency::text='KZT'
                           THEN a.balance * ah.ownership_percent / 100.0 ELSE 0 END),0) AS kzt_balance
  FROM public.account_holders ah
  JOIN public.accounts a ON a.account_id=ah.account_id
  GROUP BY ah.customer_id
), stats AS (
  SELECT c.customer_id,c.first_name,c.last_name,
         COALESCE(ls.loan_count,0) AS loan_count,
         COALESCE(ls.open_loans,0) AS open_loans,
         COALESCE(ps.payment_count,0) AS payment_count,
         COALESCE(ps.late_count,0) AS late_count,
         COALESCE(ac.account_count,0) AS account_count,
         COALESCE(ac.kzt_balance,0) AS kzt_balance
  FROM public.customers c
  LEFT JOIN loan_stats ls ON ls.customer_id=c.customer_id
  LEFT JOIN payment_stats ps ON ps.customer_id=c.customer_id
  LEFT JOIN account_stats ac ON ac.customer_id=c.customer_id
), scored AS (
  SELECT stats.*,
         GREATEST(300,LEAST(850,
           550
           + CASE WHEN payment_count=0 THEN 0 WHEN late_count=0 THEN 110
                  ELSE -LEAST(220,ROUND(late_count::numeric/payment_count*220)::int) END
           + CASE WHEN loan_count>0 THEN 30 ELSE 0 END
           + CASE WHEN account_count>0 THEN 35 ELSE 0 END
           + CASE WHEN kzt_balance>=1000000 THEN 65 WHEN kzt_balance>=100000 THEN 30 ELSE 0 END
           - CASE WHEN open_loans>2 THEN 50 ELSE 0 END
         ))::int AS score,
         ARRAY_REMOVE(ARRAY[
            CASE WHEN payment_count=0 THEN 'Нет истории платежей'
                 WHEN late_count=0 THEN 'Платежи без просрочек'
                 ELSE late_count || ' просрочек из ' || payment_count || ' платежей' END,
            CASE WHEN loan_count>0 THEN 'Есть кредитная история' END,
            CASE WHEN account_count>0 THEN 'Есть банковский счёт' END,
            CASE WHEN kzt_balance>=1000000 THEN 'Баланс KZT от 1 млн'
                 WHEN kzt_balance>=100000 THEN 'Баланс KZT от 100 тыс.' END,
            CASE WHEN open_loans>2 THEN 'Более двух открытых кредитов' END
         ],NULL) AS reasons
  FROM stats
)
SELECT scored.*,
       CASE WHEN score>=700 THEN 'Низкий'
            WHEN score>=580 THEN 'Средний' ELSE 'Высокий' END AS risk
FROM scored;

-- Preserve the existing 0-1, one-decimal display, with risk based on raw score.
-- raw_score is appended so CREATE OR REPLACE works after older migration versions.
CREATE OR REPLACE VIEW public.v_credit_scoring_normalized AS
SELECT customer_id,first_name,last_name,loan_count,open_loans,
       payment_count,late_count,account_count,kzt_balance,
       ROUND((score::numeric-300)/550,1) AS score,
       reasons,risk,score::int AS raw_score
FROM public.v_credit_scoring;

-- Consolidated overview replaces five separate nested counting queries in API.
CREATE OR REPLACE VIEW public.v_bank_summary AS
SELECT (SELECT COUNT(*)::int FROM public.customers) AS customer_count,
       (SELECT COUNT(*)::int FROM public.accounts) AS account_count,
       (SELECT COUNT(*)::int FROM public.loans) AS loan_count,
       (SELECT COUNT(*)::int FROM public.branches) AS branch_count,
       (SELECT COALESCE(SUM(balance),0) FROM public.accounts WHERE currency::text='KZT') AS balance_kzt;

-- Imported account balances are already final balances: legacy transaction rows
-- remain unmanaged; their monetary movements must never be replayed.
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS balance_managed boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS from_balance_before numeric(15,2),
  ADD COLUMN IF NOT EXISTS from_balance_after numeric(15,2),
  ADD COLUMN IF NOT EXISTS to_balance_before numeric(15,2),
  ADD COLUMN IF NOT EXISTS to_balance_after numeric(15,2);

-- Consistent account-lock ordering makes simultaneous transfers safer.
-- The trigger runs in the same DB transaction as INSERT/UPDATE/DELETE.
CREATE OR REPLACE FUNCTION public.apply_transaction_balance()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  direction integer := 0;
  src public.accounts%ROWTYPE;
  dst public.accounts%ROWTYPE;
BEGIN
  IF TG_OP='DELETE' THEN
    IF OLD.status <> 'pending' THEN
      RAISE EXCEPTION 'Проведённые и отклонённые операции удалять нельзя: сохраните историю.';
    END IF;
    RETURN OLD;
  END IF;

  IF TG_OP='INSERT' THEN
    NEW.balance_managed := true;
    NEW.from_balance_before := NULL; NEW.from_balance_after := NULL;
    NEW.to_balance_before := NULL; NEW.to_balance_after := NULL;
  ELSE
    -- Client cannot forge or overwrite snapshots or legacy markers.
    NEW.balance_managed := OLD.balance_managed;
    NEW.from_balance_before := OLD.from_balance_before;
    NEW.from_balance_after := OLD.from_balance_after;
    NEW.to_balance_before := OLD.to_balance_before;
    NEW.to_balance_after := OLD.to_balance_after;

    IF OLD.status IN ('failed','cancelled') THEN
      IF NEW IS DISTINCT FROM OLD THEN
        RAISE EXCEPTION 'Отклонённая/отменённая операция неизменяема; создайте новую.';
      END IF;
      RETURN NEW;
    END IF;

    IF OLD.status='completed' THEN
      IF NOT OLD.balance_managed THEN
        RAISE EXCEPTION 'Историческая операция: исходные изменения балансов неизвестны.';
      END IF;
      IF ROW(NEW.from_account_id,NEW.to_account_id,NEW.amount,NEW.transaction_type)
        IS DISTINCT FROM ROW(OLD.from_account_id,OLD.to_account_id,OLD.amount,OLD.transaction_type) THEN
        RAISE EXCEPTION 'Нельзя изменять реквизиты проведённой транзакции.';
      END IF;
      IF NEW.status='completed' THEN RETURN NEW; END IF;
      IF NEW.status NOT IN ('failed','cancelled') THEN
        RAISE EXCEPTION 'Проведённую операцию можно только отменить или отклонить.';
      END IF;
      direction := -1;
    END IF;
  END IF;

  IF NOT (
    (NEW.transaction_type='deposit' AND NEW.from_account_id IS NULL AND NEW.to_account_id IS NOT NULL)
    OR (NEW.transaction_type IN ('withdrawal','fee') AND NEW.from_account_id IS NOT NULL AND NEW.to_account_id IS NULL)
    OR (NEW.transaction_type='transfer' AND NEW.from_account_id IS NOT NULL
        AND NEW.to_account_id IS NOT NULL AND NEW.from_account_id<>NEW.to_account_id)
  ) THEN
    RAISE EXCEPTION 'Указаны неверные счета для типа операции.';
  END IF;

  IF NEW.amount IS NULL OR NEW.amount<=0 THEN
    RAISE EXCEPTION 'Сумма операции должна быть положительной.';
  END IF;

  IF NEW.status='completed' AND direction=0 THEN
    direction := 1;
    NEW.balance_managed := true;
  END IF;
  -- pending, failed, cancelled are stored but do not move money.
  IF direction=0 THEN RETURN NEW; END IF;

  -- Lock both accounts in ID order; the SQL statement is rolled back on error.
  PERFORM account_id FROM public.accounts
  WHERE account_id IN (NEW.from_account_id, NEW.to_account_id)
  ORDER BY account_id FOR UPDATE;

  IF NEW.from_account_id IS NOT NULL THEN
    SELECT * INTO STRICT src FROM public.accounts WHERE account_id=NEW.from_account_id;
    IF direction=1 AND src.status<>'active' THEN
      RAISE EXCEPTION 'Счёт отправителя не активен.';
    END IF;
    IF src.balance - direction*NEW.amount < 0 THEN
      RAISE EXCEPTION 'Недостаточно средств на счёте отправителя.';
    END IF;
  END IF;
  IF NEW.to_account_id IS NOT NULL THEN
    SELECT * INTO STRICT dst FROM public.accounts WHERE account_id=NEW.to_account_id;
    IF direction=1 AND dst.status<>'active' THEN
      RAISE EXCEPTION 'Счёт получателя не активен.';
    END IF;
    IF dst.balance + direction*NEW.amount < 0 THEN
      RAISE EXCEPTION 'Невозможно откатить: на счёте получателя недостаточно средств.';
    END IF;
  END IF;
  IF NEW.transaction_type='transfer' AND src.currency<>dst.currency THEN
    RAISE EXCEPTION 'Перевод между разными валютами без конвертации запрещён.';
  END IF;

  IF NEW.from_account_id IS NOT NULL THEN
    NEW.from_balance_before:=src.balance;
    UPDATE public.accounts SET balance=balance-direction*NEW.amount
    WHERE account_id=NEW.from_account_id RETURNING balance INTO NEW.from_balance_after;
  END IF;
  IF NEW.to_account_id IS NOT NULL THEN
    NEW.to_balance_before:=dst.balance;
    UPDATE public.accounts SET balance=balance+direction*NEW.amount
    WHERE account_id=NEW.to_account_id RETURNING balance INTO NEW.to_balance_after;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS transaction_balance_trigger ON public.transactions;
CREATE TRIGGER transaction_balance_trigger
BEFORE INSERT OR UPDATE OR DELETE ON public.transactions
FOR EACH ROW EXECUTE FUNCTION public.apply_transaction_balance();

-- Read model for the UI, including balance before and after posting/reversal.
CREATE OR REPLACE VIEW public.v_transaction_balances AS
SELECT transaction_id,from_account_id,to_account_id,transaction_type,amount,
       status,description,transaction_date,
       from_balance_before,from_balance_after,to_balance_before,to_balance_after
FROM public.transactions;

-- Add helpful indexes for repeat aggregate queries (safe if index names absent).
CREATE INDEX IF NOT EXISTS idx_scoring_loans_customer ON public.loans(customer_id);
CREATE INDEX IF NOT EXISTS idx_scoring_payments_loan ON public.loan_payments(loan_id);
CREATE INDEX IF NOT EXISTS idx_scoring_holders_customer ON public.account_holders(customer_id);
COMMIT;
