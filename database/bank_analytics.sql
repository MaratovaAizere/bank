-- Northstar Bank: analytics and access management (PostgreSQL).
-- Re-runnable migration: creates reporting views and read-only group roles.
-- Does not delete rows or change banking transactions.
-- Run with a database administrator role.

BEGIN;

-- Customer account summary.
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

-- Current credit portfolio with enum-safe comparisons.
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

-- Client contact information.
CREATE OR REPLACE VIEW public.v_customer_contacts_editable AS
SELECT customer_id, first_name, last_name, phone, email
FROM public.customers;

-- Contact validation: clients returned by this view must keep an email.
CREATE OR REPLACE VIEW public.v_customers_with_email AS
SELECT customer_id, first_name, last_name, phone, email
FROM public.customers
WHERE email IS NOT NULL AND email <> ''
WITH LOCAL CHECK OPTION;

-- Aggregated branch KPIs.
-- Aggregate accounts and loans separately to avoid double-counting.
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

-- Read-only reporting groups; NOLOGIN means they cannot sign in directly.
DO $$
BEGIN
    -- If the previous reporting groups exist, preserve their OIDs, grants,
    -- and memberships while giving them neutral business names.
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bank_lecture9_reader')
       AND NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bank_reporting_reader') THEN
        EXECUTE 'ALTER ROLE bank_lecture9_reader RENAME TO bank_reporting_reader';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bank_lecture9_analyst')
       AND NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bank_reporting_analyst') THEN
        EXECUTE 'ALTER ROLE bank_lecture9_analyst RENAME TO bank_reporting_analyst';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bank_reporting_reader') THEN
        EXECUTE 'CREATE ROLE bank_reporting_reader NOLOGIN';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bank_reporting_analyst') THEN
        EXECUTE 'CREATE ROLE bank_reporting_analyst NOLOGIN';
    END IF;
END $$;

GRANT USAGE ON SCHEMA public TO bank_reporting_reader;
GRANT SELECT ON public.v_customer_accounts,
                public.v_active_loans,
                public.v_customer_contacts_editable,
                public.v_customers_with_email,
                public.mv_branch_statistics
TO bank_reporting_reader;
GRANT bank_reporting_reader TO bank_reporting_analyst;

COMMIT;

-- Refresh the stored branch totals.
REFRESH MATERIALIZED VIEW public.mv_branch_statistics;
