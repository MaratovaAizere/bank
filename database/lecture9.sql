-- Lecture 9 for Northstar Bank (PostgreSQL 18).
-- Safe to run repeatedly: creates/replaces educational views and refreshes the
-- materialized view; does not delete or truncate any bank tables.
-- Run as postgres (the same PostgreSQL role that imported bank_database.sql).
-- These roles are NOLOGIN groups, not website accounts.

BEGIN;

-- 1. A regular VIEW is a named SELECT. Results always reflect current tables.
CREATE OR REPLACE VIEW public.v_customer_accounts AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT a.account_id)::integer AS account_count,
    COALESCE(SUM(
        CASE WHEN a.currency::text = 'KZT'
             THEN a.balance * ah.ownership_percent / 100.0
             ELSE 0 END
    ), 0)::numeric(20, 2) AS balance_kzt
FROM public.customers AS c
LEFT JOIN public.account_holders AS ah ON ah.customer_id = c.customer_id
LEFT JOIN public.accounts AS a ON a.account_id = ah.account_id
GROUP BY c.customer_id, c.first_name, c.last_name;

-- Another regular view using enum-safe comparisons (status::text).
CREATE OR REPLACE VIEW public.v_active_loans AS
SELECT
    l.loan_id,
    l.customer_id,
    c.first_name,
    c.last_name,
    l.principal_amount,
    l.interest_rate,
    l.status::text AS status
FROM public.loans AS l
JOIN public.customers AS c ON c.customer_id = l.customer_id
WHERE l.status::text IN ('active', 'approved');

-- 2. Updatable view: direct columns from one table (no JOIN or aggregation).
CREATE OR REPLACE VIEW public.v_customer_contacts_editable AS
SELECT customer_id, first_name, last_name, phone, email
FROM public.customers;

-- 3. CHECK OPTION demonstration: edits through this view must retain email.
CREATE OR REPLACE VIEW public.v_customers_with_email AS
SELECT customer_id, first_name, last_name, phone, email
FROM public.customers
WHERE email IS NOT NULL AND email <> ''
WITH LOCAL CHECK OPTION;

-- 4. Materialized view: a stored snapshot of branch metrics.
-- The CTEs aggregate separately, preventing double-counting across JOINs.
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_branch_statistics AS
WITH account_totals AS (
    SELECT branch_id,
           COUNT(*)::integer AS account_count,
           COALESCE(SUM(CASE WHEN currency::text = 'KZT' THEN balance ELSE 0 END), 0)::numeric(20,2) AS total_kzt
    FROM public.accounts
    GROUP BY branch_id
), loan_totals AS (
    SELECT branch_id, COUNT(*)::integer AS loan_count
    FROM public.loans
    GROUP BY branch_id
)
SELECT b.branch_id, b.branch_name, b.city,
       COALESCE(a.account_count, 0)::integer AS account_count,
       COALESCE(l.loan_count, 0)::integer AS loan_count,
       COALESCE(a.total_kzt, 0)::numeric(20,2) AS total_kzt
FROM public.branches AS b
LEFT JOIN account_totals AS a ON a.branch_id = b.branch_id
LEFT JOIN loan_totals AS l ON l.branch_id = b.branch_id
WITH DATA;

-- UNIQUE index is required for REFRESH ... CONCURRENTLY.
CREATE UNIQUE INDEX IF NOT EXISTS mv_branch_statistics_branch_id_idx
ON public.mv_branch_statistics (branch_id);

-- 5. Roles / groups: safe demo groups, not database LOGIN users.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bank_lecture9_reader') THEN
        CREATE ROLE bank_lecture9_reader NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bank_lecture9_analyst') THEN
        CREATE ROLE bank_lecture9_analyst NOLOGIN;
    END IF;
END $$;

GRANT USAGE ON SCHEMA public TO bank_lecture9_reader;
GRANT SELECT ON public.v_customer_accounts,
                public.v_active_loans,
                public.v_customer_contacts_editable,
                public.v_customers_with_email,
                public.mv_branch_statistics
TO bank_lecture9_reader;
GRANT bank_lecture9_reader TO bank_lecture9_analyst;

COMMIT;

-- A second run updates the materialized data WITHOUT changing its definition.
REFRESH MATERIALIZED VIEW public.mv_branch_statistics;
