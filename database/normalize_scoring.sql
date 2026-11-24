-- Optional standalone normalization refresh. The full upgrade also creates this view.
BEGIN;
CREATE OR REPLACE VIEW public.v_credit_scoring_normalized AS
SELECT customer_id, first_name, last_name, loan_count, open_loans,
       payment_count, late_count, account_count, kzt_balance,
       ROUND((score::numeric - 300) / 550, 1) AS score,
       reasons, risk, score::int AS raw_score
FROM public.v_credit_scoring;
COMMIT;
