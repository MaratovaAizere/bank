--
-- PostgreSQL database dump
--

\restrict WoU2pGyp8di5sCUx7yeYnVJNnxE0b0XKeFDlerhxLoG1W44Q4B4KSoG3OFhHke2

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.7 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: account_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.account_status AS ENUM (
    'active',
    'frozen',
    'closed'
);


--
-- Name: account_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.account_type AS ENUM (
    'savings',
    'checking',
    'business'
);


--
-- Name: loan_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.loan_status AS ENUM (
    'pending',
    'approved',
    'active',
    'paid',
    'rejected'
);


--
-- Name: transaction_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.transaction_status AS ENUM (
    'pending',
    'completed',
    'failed',
    'cancelled'
);


--
-- Name: transaction_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.transaction_type AS ENUM (
    'deposit',
    'withdrawal',
    'transfer',
    'fee'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_holders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_holders (
    account_id integer NOT NULL,
    customer_id integer NOT NULL,
    ownership_percent numeric(5,2) DEFAULT 100 NOT NULL,
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT valid_ownership_percentage CHECK (((ownership_percent > (0)::numeric) AND (ownership_percent <= (100)::numeric)))
);


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    account_id integer NOT NULL,
    branch_id integer NOT NULL,
    account_number character varying(34) NOT NULL,
    account_type public.account_type NOT NULL,
    balance numeric(15,2) DEFAULT 0 NOT NULL,
    currency character(3) DEFAULT 'KZT'::bpchar NOT NULL,
    status public.account_status DEFAULT 'active'::public.account_status NOT NULL,
    opened_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_at timestamp without time zone,
    CONSTRAINT non_negative_balance CHECK ((balance >= (0)::numeric)),
    CONSTRAINT valid_closing_date CHECK (((closed_at IS NULL) OR (closed_at >= opened_at))),
    CONSTRAINT valid_currency CHECK ((currency = ANY (ARRAY['KZT'::bpchar, 'USD'::bpchar, 'EUR'::bpchar, 'GBP'::bpchar])))
);


--
-- Name: accounts_account_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_account_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_account_id_seq OWNED BY public.accounts.account_id;


--
-- Name: bank_shareholders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bank_shareholders (
    shareholder_id integer NOT NULL,
    full_name character varying(150) NOT NULL,
    holder_type character varying(20) NOT NULL,
    country character varying(60) NOT NULL,
    share_percent numeric(5,2) NOT NULL,
    shares_count bigint NOT NULL,
    acquired_at date NOT NULL,
    added_at timestamp without time zone DEFAULT now() NOT NULL,
    customer_id integer
);


--
-- Name: bank_shareholders_shareholder_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bank_shareholders_shareholder_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bank_shareholders_shareholder_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bank_shareholders_shareholder_id_seq OWNED BY public.bank_shareholders.shareholder_id;


--
-- Name: branches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branches (
    branch_id integer NOT NULL,
    branch_name character varying(100) NOT NULL,
    swift_code character varying(20) NOT NULL,
    city character varying(50) NOT NULL,
    address character varying(200) NOT NULL,
    phone character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: branches_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.branches_branch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: branches_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.branches_branch_id_seq OWNED BY public.branches.branch_id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    customer_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    national_id character varying(20) NOT NULL,
    date_of_birth date NOT NULL,
    phone character varying(20) NOT NULL,
    email character varying(100),
    address character varying(200),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT valid_date_of_birth CHECK ((date_of_birth < CURRENT_DATE))
);


--
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customers_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customers_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customers_customer_id_seq OWNED BY public.customers.customer_id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employees (
    employee_id integer NOT NULL,
    branch_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    "position" character varying(50) NOT NULL,
    salary numeric(12,2) NOT NULL,
    email character varying(100) NOT NULL,
    hire_date date NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT positive_employee_salary CHECK ((salary > (0)::numeric))
);


--
-- Name: employees_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employees_employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employees_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employees_employee_id_seq OWNED BY public.employees.employee_id;


--
-- Name: loan_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loan_payments (
    payment_id bigint NOT NULL,
    loan_id integer NOT NULL,
    account_id integer NOT NULL,
    amount numeric(15,2) NOT NULL,
    payment_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    payment_number integer NOT NULL,
    is_late boolean DEFAULT false NOT NULL,
    CONSTRAINT positive_payment_amount CHECK ((amount > (0)::numeric)),
    CONSTRAINT positive_payment_number CHECK ((payment_number > 0))
);


--
-- Name: loan_payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loan_payments_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_payments_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loan_payments_payment_id_seq OWNED BY public.loan_payments.payment_id;


--
-- Name: loans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loans (
    loan_id integer NOT NULL,
    customer_id integer NOT NULL,
    branch_id integer NOT NULL,
    approved_by integer,
    principal_amount numeric(15,2) NOT NULL,
    interest_rate numeric(5,2) NOT NULL,
    term_months integer NOT NULL,
    status public.loan_status DEFAULT 'pending'::public.loan_status NOT NULL,
    application_date date DEFAULT CURRENT_DATE NOT NULL,
    start_date date,
    end_date date,
    CONSTRAINT positive_loan_amount CHECK ((principal_amount > (0)::numeric)),
    CONSTRAINT positive_loan_term CHECK ((term_months > 0)),
    CONSTRAINT valid_interest_rate CHECK (((interest_rate >= (0)::numeric) AND (interest_rate <= (100)::numeric))),
    CONSTRAINT valid_loan_dates CHECK (((end_date IS NULL) OR (start_date IS NULL) OR (end_date > start_date)))
);


--
-- Name: loans_loan_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loans_loan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loans_loan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loans_loan_id_seq OWNED BY public.loans.loan_id;


--
-- Name: mv_branch_statistics; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_branch_statistics AS
 WITH account_totals AS (
         SELECT accounts.branch_id,
            (count(*))::integer AS account_count,
            (COALESCE(sum(
                CASE
                    WHEN ((accounts.currency)::text = 'KZT'::text) THEN accounts.balance
                    ELSE (0)::numeric
                END), (0)::numeric))::numeric(20,2) AS total_kzt
           FROM public.accounts
          GROUP BY accounts.branch_id
        ), loan_totals AS (
         SELECT loans.branch_id,
            (count(*))::integer AS loan_count
           FROM public.loans
          GROUP BY loans.branch_id
        )
 SELECT b.branch_id,
    b.branch_name,
    b.city,
    COALESCE(a.account_count, 0) AS account_count,
    COALESCE(l.loan_count, 0) AS loan_count,
    (COALESCE(a.total_kzt, (0)::numeric))::numeric(20,2) AS total_kzt
   FROM ((public.branches b
     LEFT JOIN account_totals a ON ((a.branch_id = b.branch_id)))
     LEFT JOIN loan_totals l ON ((l.branch_id = b.branch_id)))
  WITH NO DATA;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    transaction_id bigint NOT NULL,
    from_account_id integer,
    to_account_id integer,
    transaction_type public.transaction_type NOT NULL,
    amount numeric(15,2) NOT NULL,
    status public.transaction_status DEFAULT 'pending'::public.transaction_status NOT NULL,
    description character varying(250),
    transaction_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT different_transfer_accounts CHECK (((from_account_id IS NULL) OR (to_account_id IS NULL) OR (from_account_id <> to_account_id))),
    CONSTRAINT positive_transaction_amount CHECK ((amount > (0)::numeric)),
    CONSTRAINT transaction_has_account CHECK (((from_account_id IS NOT NULL) OR (to_account_id IS NOT NULL)))
);


--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transactions_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transactions_transaction_id_seq OWNED BY public.transactions.transaction_id;


--
-- Name: transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfers (
    transfer_id integer NOT NULL,
    transfer_type character varying(20) NOT NULL,
    from_account_id integer NOT NULL,
    to_account_id integer,
    currency character varying(10) NOT NULL,
    amount numeric(20,8) NOT NULL,
    fee numeric(20,8) DEFAULT 0 NOT NULL,
    network character varying(10),
    wallet_address character varying(80),
    tx_hash character varying(70),
    status character varying(12) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    completed_at timestamp without time zone
);


--
-- Name: transfers_transfer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transfers_transfer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transfers_transfer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transfers_transfer_id_seq OWNED BY public.transfers.transfer_id;


--
-- Name: v_active_loans; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_active_loans AS
 SELECT l.loan_id,
    l.customer_id,
    c.first_name,
    c.last_name,
    l.principal_amount,
    l.interest_rate,
    (l.status)::text AS status
   FROM (public.loans l
     JOIN public.customers c ON ((c.customer_id = l.customer_id)))
  WHERE ((l.status)::text = ANY (ARRAY['active'::text, 'approved'::text]));


--
-- Name: v_customer_accounts; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_customer_accounts AS
 SELECT c.customer_id,
    c.first_name,
    c.last_name,
    (count(DISTINCT a.account_id))::integer AS account_count,
    (COALESCE(sum(
        CASE
            WHEN ((a.currency)::text = 'KZT'::text) THEN ((a.balance * ah.ownership_percent) / 100.0)
            ELSE (0)::numeric
        END), (0)::numeric))::numeric(20,2) AS balance_kzt
   FROM ((public.customers c
     LEFT JOIN public.account_holders ah ON ((ah.customer_id = c.customer_id)))
     LEFT JOIN public.accounts a ON ((a.account_id = ah.account_id)))
  GROUP BY c.customer_id, c.first_name, c.last_name;


--
-- Name: v_customer_contacts_editable; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_customer_contacts_editable AS
 SELECT customer_id,
    first_name,
    last_name,
    phone,
    email
   FROM public.customers;


--
-- Name: v_customers_with_email; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_customers_with_email AS
 SELECT customer_id,
    first_name,
    last_name,
    phone,
    email
   FROM public.customers
  WHERE ((email IS NOT NULL) AND ((email)::text <> ''::text))
  WITH LOCAL CHECK OPTION;


--
-- Name: accounts account_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts ALTER COLUMN account_id SET DEFAULT nextval('public.accounts_account_id_seq'::regclass);


--
-- Name: bank_shareholders shareholder_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_shareholders ALTER COLUMN shareholder_id SET DEFAULT nextval('public.bank_shareholders_shareholder_id_seq'::regclass);


--
-- Name: branches branch_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches ALTER COLUMN branch_id SET DEFAULT nextval('public.branches_branch_id_seq'::regclass);


--
-- Name: customers customer_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers ALTER COLUMN customer_id SET DEFAULT nextval('public.customers_customer_id_seq'::regclass);


--
-- Name: employees employee_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees ALTER COLUMN employee_id SET DEFAULT nextval('public.employees_employee_id_seq'::regclass);


--
-- Name: loan_payments payment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments ALTER COLUMN payment_id SET DEFAULT nextval('public.loan_payments_payment_id_seq'::regclass);


--
-- Name: loans loan_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans ALTER COLUMN loan_id SET DEFAULT nextval('public.loans_loan_id_seq'::regclass);


--
-- Name: transactions transaction_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.transactions_transaction_id_seq'::regclass);


--
-- Name: transfers transfer_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers ALTER COLUMN transfer_id SET DEFAULT nextval('public.transfers_transfer_id_seq'::regclass);


--
-- Name: account_holders account_holders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_holders
    ADD CONSTRAINT account_holders_pkey PRIMARY KEY (account_id, customer_id);


--
-- Name: accounts accounts_account_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_account_number_key UNIQUE (account_number);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (account_id);


--
-- Name: bank_shareholders bank_shareholders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_shareholders
    ADD CONSTRAINT bank_shareholders_pkey PRIMARY KEY (shareholder_id);


--
-- Name: branches branches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_pkey PRIMARY KEY (branch_id);


--
-- Name: branches branches_swift_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_swift_code_key UNIQUE (swift_code);


--
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- Name: customers customers_national_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_national_id_key UNIQUE (national_id);


--
-- Name: customers customers_phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_phone_key UNIQUE (phone);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: employees employees_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_email_key UNIQUE (email);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- Name: loan_payments loan_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT loan_payments_pkey PRIMARY KEY (payment_id);


--
-- Name: loans loans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (loan_id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: transfers transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT transfers_pkey PRIMARY KEY (transfer_id);


--
-- Name: loan_payments uq_loan_payment_number; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT uq_loan_payment_number UNIQUE (loan_id, payment_number);


--
-- Name: idx_transactions_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_date ON public.transactions USING btree (transaction_date);


--
-- Name: idx_transactions_from_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_from_account ON public.transactions USING btree (from_account_id);


--
-- Name: idx_transactions_to_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_to_account ON public.transactions USING btree (to_account_id);


--
-- Name: mv_branch_statistics_branch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mv_branch_statistics_branch_id_idx ON public.mv_branch_statistics USING btree (branch_id);


--
-- Name: account_holders account_holders_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_holders
    ADD CONSTRAINT account_holders_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(account_id);


--
-- Name: account_holders account_holders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_holders
    ADD CONSTRAINT account_holders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: accounts accounts_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id);


--
-- Name: employees employees_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id);


--
-- Name: bank_shareholders fk_shareholders_customer; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_shareholders
    ADD CONSTRAINT fk_shareholders_customer FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: transfers fk_transfers_from_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT fk_transfers_from_account FOREIGN KEY (from_account_id) REFERENCES public.accounts(account_id);


--
-- Name: transfers fk_transfers_to_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT fk_transfers_to_account FOREIGN KEY (to_account_id) REFERENCES public.accounts(account_id);


--
-- Name: loan_payments loan_payments_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT loan_payments_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(account_id);


--
-- Name: loan_payments loan_payments_loan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT loan_payments_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES public.loans(loan_id);


--
-- Name: loans loans_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.employees(employee_id);


--
-- Name: loans loans_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id);


--
-- Name: loans loans_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: transactions transactions_from_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_from_account_id_fkey FOREIGN KEY (from_account_id) REFERENCES public.accounts(account_id);


--
-- Name: transactions transactions_to_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_to_account_id_fkey FOREIGN KEY (to_account_id) REFERENCES public.accounts(account_id);


--
-- PostgreSQL database dump complete
--

\unrestrict WoU2pGyp8di5sCUx7yeYnVJNnxE0b0XKeFDlerhxLoG1W44Q4B4KSoG3OFhHke2

