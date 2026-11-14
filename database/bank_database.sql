--
-- PostgreSQL database dump
--

\restrict 6NyOiWeKX1WFi8pf941qQYXBbenyyK1FlDhYm38gWI8FWfrtY33ghBcP7XEb9sF

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3 (Homebrew)

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
-- Name: account_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.account_status AS ENUM (
    'active',
    'frozen',
    'closed'
);


ALTER TYPE public.account_status OWNER TO postgres;

--
-- Name: account_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.account_type AS ENUM (
    'savings',
    'checking',
    'business'
);


ALTER TYPE public.account_type OWNER TO postgres;

--
-- Name: loan_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.loan_status AS ENUM (
    'pending',
    'approved',
    'active',
    'paid',
    'rejected'
);


ALTER TYPE public.loan_status OWNER TO postgres;

--
-- Name: transaction_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transaction_status AS ENUM (
    'pending',
    'completed',
    'failed',
    'cancelled'
);


ALTER TYPE public.transaction_status OWNER TO postgres;

--
-- Name: transaction_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transaction_type AS ENUM (
    'deposit',
    'withdrawal',
    'transfer',
    'fee'
);


ALTER TYPE public.transaction_type OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_holders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account_holders (
    account_id integer NOT NULL,
    customer_id integer NOT NULL,
    ownership_percent numeric(5,2) DEFAULT 100 NOT NULL,
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT valid_ownership_percentage CHECK (((ownership_percent > (0)::numeric) AND (ownership_percent <= (100)::numeric)))
);


ALTER TABLE public.account_holders OWNER TO postgres;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.accounts OWNER TO postgres;

--
-- Name: accounts_account_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.accounts_account_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.accounts_account_id_seq OWNER TO postgres;

--
-- Name: accounts_account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.accounts_account_id_seq OWNED BY public.accounts.account_id;


--
-- Name: bank_shareholders; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.bank_shareholders OWNER TO postgres;

--
-- Name: bank_shareholders_shareholder_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bank_shareholders_shareholder_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bank_shareholders_shareholder_id_seq OWNER TO postgres;

--
-- Name: bank_shareholders_shareholder_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bank_shareholders_shareholder_id_seq OWNED BY public.bank_shareholders.shareholder_id;


--
-- Name: branches; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.branches OWNER TO postgres;

--
-- Name: branches_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.branches_branch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.branches_branch_id_seq OWNER TO postgres;

--
-- Name: branches_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.branches_branch_id_seq OWNED BY public.branches.branch_id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.customers OWNER TO postgres;

--
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customers_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customers_customer_id_seq OWNER TO postgres;

--
-- Name: customers_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customers_customer_id_seq OWNED BY public.customers.customer_id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.employees OWNER TO postgres;

--
-- Name: employees_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employees_employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employees_employee_id_seq OWNER TO postgres;

--
-- Name: employees_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employees_employee_id_seq OWNED BY public.employees.employee_id;


--
-- Name: loan_payments; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.loan_payments OWNER TO postgres;

--
-- Name: loan_payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.loan_payments_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.loan_payments_payment_id_seq OWNER TO postgres;

--
-- Name: loan_payments_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.loan_payments_payment_id_seq OWNED BY public.loan_payments.payment_id;


--
-- Name: loans; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.loans OWNER TO postgres;

--
-- Name: loans_loan_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.loans_loan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.loans_loan_id_seq OWNER TO postgres;

--
-- Name: loans_loan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.loans_loan_id_seq OWNED BY public.loans.loan_id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.transactions OWNER TO postgres;

--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transactions_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transactions_transaction_id_seq OWNER TO postgres;

--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transactions_transaction_id_seq OWNED BY public.transactions.transaction_id;


--
-- Name: transfers; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.transfers OWNER TO postgres;

--
-- Name: transfers_transfer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transfers_transfer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transfers_transfer_id_seq OWNER TO postgres;

--
-- Name: transfers_transfer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transfers_transfer_id_seq OWNED BY public.transfers.transfer_id;


--
-- Name: accounts account_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts ALTER COLUMN account_id SET DEFAULT nextval('public.accounts_account_id_seq'::regclass);


--
-- Name: bank_shareholders shareholder_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_shareholders ALTER COLUMN shareholder_id SET DEFAULT nextval('public.bank_shareholders_shareholder_id_seq'::regclass);


--
-- Name: branches branch_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branches ALTER COLUMN branch_id SET DEFAULT nextval('public.branches_branch_id_seq'::regclass);


--
-- Name: customers customer_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers ALTER COLUMN customer_id SET DEFAULT nextval('public.customers_customer_id_seq'::regclass);


--
-- Name: employees employee_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees ALTER COLUMN employee_id SET DEFAULT nextval('public.employees_employee_id_seq'::regclass);


--
-- Name: loan_payments payment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_payments ALTER COLUMN payment_id SET DEFAULT nextval('public.loan_payments_payment_id_seq'::regclass);


--
-- Name: loans loan_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loans ALTER COLUMN loan_id SET DEFAULT nextval('public.loans_loan_id_seq'::regclass);


--
-- Name: transactions transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.transactions_transaction_id_seq'::regclass);


--
-- Name: transfers transfer_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfers ALTER COLUMN transfer_id SET DEFAULT nextval('public.transfers_transfer_id_seq'::regclass);


--
-- Data for Name: account_holders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.account_holders (account_id, customer_id, ownership_percent, added_at) FROM stdin;
1	1	100.00	2026-09-23 10:13:51.777571
2	1	100.00	2026-09-23 10:13:51.777571
3	2	100.00	2026-09-23 10:13:51.777571
4	3	60.00	2026-09-23 10:13:51.777571
4	4	40.00	2026-09-23 10:13:51.777571
5	5	100.00	2026-09-23 10:13:51.777571
101	100	100.00	2026-09-29 10:29:22.150398
100	99	100.00	2026-09-29 10:29:22.150398
99	98	100.00	2026-09-29 10:29:22.150398
98	97	100.00	2026-09-29 10:29:22.150398
97	96	100.00	2026-09-29 10:29:22.150398
96	95	100.00	2026-09-29 10:29:22.150398
95	94	100.00	2026-09-29 10:29:22.150398
94	93	100.00	2026-09-29 10:29:22.150398
93	92	100.00	2026-09-29 10:29:22.150398
92	91	100.00	2026-09-29 10:29:22.150398
91	90	100.00	2026-09-29 10:29:22.150398
90	89	100.00	2026-09-29 10:29:22.150398
89	88	100.00	2026-09-29 10:29:22.150398
88	87	100.00	2026-09-29 10:29:22.150398
87	86	100.00	2026-09-29 10:29:22.150398
86	85	100.00	2026-09-29 10:29:22.150398
85	84	100.00	2026-09-29 10:29:22.150398
84	83	100.00	2026-09-29 10:29:22.150398
83	82	100.00	2026-09-29 10:29:22.150398
82	81	100.00	2026-09-29 10:29:22.150398
81	80	100.00	2026-09-29 10:29:22.150398
80	79	100.00	2026-09-29 10:29:22.150398
79	78	100.00	2026-09-29 10:29:22.150398
78	77	100.00	2026-09-29 10:29:22.150398
77	76	100.00	2026-09-29 10:29:22.150398
76	75	100.00	2026-09-29 10:29:22.150398
75	74	100.00	2026-09-29 10:29:22.150398
74	73	100.00	2026-09-29 10:29:22.150398
73	72	100.00	2026-09-29 10:29:22.150398
72	71	100.00	2026-09-29 10:29:22.150398
71	70	100.00	2026-09-29 10:29:22.150398
70	69	100.00	2026-09-29 10:29:22.150398
69	68	100.00	2026-09-29 10:29:22.150398
68	67	100.00	2026-09-29 10:29:22.150398
67	66	100.00	2026-09-29 10:29:22.150398
66	65	100.00	2026-09-29 10:29:22.150398
65	64	100.00	2026-09-29 10:29:22.150398
64	63	100.00	2026-09-29 10:29:22.150398
63	62	100.00	2026-09-29 10:29:22.150398
62	61	100.00	2026-09-29 10:29:22.150398
61	60	100.00	2026-09-29 10:29:22.150398
60	59	100.00	2026-09-29 10:29:22.150398
59	58	100.00	2026-09-29 10:29:22.150398
58	57	100.00	2026-09-29 10:29:22.150398
57	56	100.00	2026-09-29 10:29:22.150398
56	55	100.00	2026-09-29 10:29:22.150398
55	54	100.00	2026-09-29 10:29:22.150398
54	53	100.00	2026-09-29 10:29:22.150398
53	52	100.00	2026-09-29 10:29:22.150398
52	51	100.00	2026-09-29 10:29:22.150398
51	50	100.00	2026-09-29 10:29:22.150398
50	49	100.00	2026-09-29 10:29:22.150398
49	48	100.00	2026-09-29 10:29:22.150398
48	47	100.00	2026-09-29 10:29:22.150398
47	46	100.00	2026-09-29 10:29:22.150398
46	45	100.00	2026-09-29 10:29:22.150398
45	44	100.00	2026-09-29 10:29:22.150398
44	43	100.00	2026-09-29 10:29:22.150398
43	42	100.00	2026-09-29 10:29:22.150398
42	41	100.00	2026-09-29 10:29:22.150398
41	40	100.00	2026-09-29 10:29:22.150398
40	39	100.00	2026-09-29 10:29:22.150398
39	38	100.00	2026-09-29 10:29:22.150398
38	37	100.00	2026-09-29 10:29:22.150398
37	36	100.00	2026-09-29 10:29:22.150398
36	35	100.00	2026-09-29 10:29:22.150398
35	34	100.00	2026-09-29 10:29:22.150398
34	33	100.00	2026-09-29 10:29:22.150398
33	32	100.00	2026-09-29 10:29:22.150398
32	31	100.00	2026-09-29 10:29:22.150398
31	30	100.00	2026-09-29 10:29:22.150398
30	29	100.00	2026-09-29 10:29:22.150398
29	28	100.00	2026-09-29 10:29:22.150398
28	27	100.00	2026-09-29 10:29:22.150398
27	26	100.00	2026-09-29 10:29:22.150398
26	25	100.00	2026-09-29 10:29:22.150398
25	24	100.00	2026-09-29 10:29:22.150398
24	23	100.00	2026-09-29 10:29:22.150398
23	22	100.00	2026-09-29 10:29:22.150398
22	21	100.00	2026-09-29 10:29:22.150398
21	20	100.00	2026-09-29 10:29:22.150398
20	19	100.00	2026-09-29 10:29:22.150398
19	18	100.00	2026-09-29 10:29:22.150398
18	17	100.00	2026-09-29 10:29:22.150398
17	16	100.00	2026-09-29 10:29:22.150398
16	15	100.00	2026-09-29 10:29:22.150398
15	14	100.00	2026-09-29 10:29:22.150398
14	13	100.00	2026-09-29 10:29:22.150398
13	12	100.00	2026-09-29 10:29:22.150398
12	11	100.00	2026-09-29 10:29:22.150398
11	10	100.00	2026-09-29 10:29:22.150398
10	9	100.00	2026-09-29 10:29:22.150398
9	8	100.00	2026-09-29 10:29:22.150398
8	7	100.00	2026-09-29 10:29:22.150398
7	6	100.00	2026-09-29 10:29:22.150398
\.


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.accounts (account_id, branch_id, account_number, account_type, balance, currency, status, opened_at, closed_at) FROM stdin;
1	1	KZ001BANK0000000001	checking	150000.00	KZT	active	2022-01-10 00:00:00	\N
2	1	KZ001BANK0000000002	savings	500000.00	KZT	active	2022-02-14 00:00:00	\N
3	2	KZ002BANK0000000003	checking	75000.00	USD	active	2022-03-20 00:00:00	\N
4	3	KZ003BANK0000000004	business	1200000.00	KZT	active	2022-04-05 00:00:00	\N
5	4	KZ004BANK0000000005	savings	32000.00	EUR	frozen	2022-05-11 00:00:00	\N
6	5	KZ005BANK0000000006	checking	0.00	KZT	closed	2021-12-01 00:00:00	\N
7	2	KZ172083017272057760	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
8	21	KZ670990179180860160	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
9	1	KZ946934908444563456	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
10	6	KZ228367222990141888	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
11	43	KZ554429126216331904	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
12	23	KZ269869946545419520	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
13	89	KZ616470677071217664	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
14	52	KZ217825491924108480	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
15	75	KZ124893233263729808	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
16	72	KZ151951922002736096	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
17	76	KZ478833182704924352	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
18	100	KZ958699035021661568	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
19	45	KZ000006560381471176	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
20	77	KZ934054724433648384	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
21	41	KZ484587764883227328	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
22	83	KZ774016658586915968	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
23	41	KZ627594588757218944	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
24	79	KZ689217502711561472	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
25	46	KZ447791549391634688	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
26	69	KZ584413135420416512	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
27	27	KZ195895258709235744	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
28	25	KZ299089232754068608	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
29	89	KZ406833899641291904	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
30	1	KZ726715389267372800	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
31	80	KZ251114280250658304	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
32	17	KZ031965829873381368	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
33	65	KZ194684213141599552	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
34	73	KZ470197104471801600	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
35	93	KZ741182012979260288	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
36	59	KZ732975335469888512	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
37	16	KZ916609794905177472	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
38	93	KZ405870834796561856	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
39	100	KZ791696726178957312	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
40	14	KZ663953879697209728	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
41	26	KZ458206013763115840	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
42	43	KZ059732724200764808	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
43	61	KZ006443784833298993	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
44	82	KZ686764025951110528	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
45	54	KZ193424689903327616	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
46	35	KZ757058530544175104	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
47	46	KZ774009969822029696	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
48	63	KZ453887243799161920	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
49	59	KZ436001512996488704	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
50	69	KZ842819309812167424	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
51	73	KZ717300309616745856	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
52	14	KZ002317408995183179	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
53	92	KZ658511575761154560	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
54	79	KZ631065729310157824	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
55	20	KZ936384422346258944	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
56	31	KZ642086494285977472	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
57	42	KZ186832808346611104	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
58	63	KZ726548113775451648	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
59	31	KZ814826196538416640	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
60	9	KZ714264939844499840	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
61	60	KZ784335092440611200	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
62	43	KZ321919647985148736	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
63	18	KZ248146789277208672	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
64	21	KZ691746427417438080	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
65	99	KZ258486045099973984	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
66	47	KZ873822108672754688	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
67	18	KZ470152994030361472	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
68	17	KZ165372665618043648	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
69	79	KZ664255872346023936	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
70	29	KZ092014974619449184	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
71	15	KZ289163808591011968	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
72	96	KZ796887258556244096	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
73	47	KZ916363557174358912	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
74	34	KZ366234583796930304	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
75	95	KZ425216070748992704	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
76	20	KZ211601963065713312	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
77	36	KZ047820139278391680	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
78	69	KZ954746242691166848	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
79	5	KZ002721766536289083	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
80	67	KZ171113546776828768	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
81	12	KZ597203645148651776	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
82	97	KZ173416285803163584	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
83	3	KZ103099510320347808	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
84	57	KZ541305268678838208	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
85	93	KZ920160876596110464	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
86	3	KZ833694680987089152	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
87	27	KZ117262494659821744	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
88	65	KZ582103428470449408	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
89	62	KZ323624342384124288	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
90	26	KZ661417801935363200	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
91	68	KZ156193100905496640	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
92	1	KZ494485425995386368	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
93	73	KZ032069385214981592	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
94	3	KZ263829360053045472	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
95	98	KZ328651264275068544	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
96	65	KZ394542054379456000	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
97	92	KZ993041153831450752	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
98	58	KZ781944617353589504	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
99	93	KZ433733028852778560	savings	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
100	64	KZ601412495276522496	business	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
101	85	KZ752287505709934976	checking	0.00	KZT	active	2026-09-29 10:29:22.150398	\N
\.


--
-- Data for Name: bank_shareholders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bank_shareholders (shareholder_id, full_name, holder_type, country, share_percent, shares_count, acquired_at, added_at, customer_id) FROM stdin;
1	Nomad Capital Holding	company	Kazakhstan	18.50	185000	2012-03-15	2026-09-29 10:38:19.670054	\N
2	Aidar Nurlanovich Sadykov	individual	Kazakhstan	12.00	120000	2012-03-15	2026-09-29 10:38:19.670054	\N
3	Samruk Investment Fund	state	Kazakhstan	10.00	100000	2013-06-01	2026-09-29 10:38:19.670054	\N
4	Eurasia Growth Partners	fund	Luxembourg	8.00	80000	2015-09-20	2026-09-29 10:38:19.670054	\N
5	Dana Erlanovna Kasymova	individual	Kazakhstan	7.00	70000	2014-01-10	2026-09-29 10:38:19.670054	\N
6	Silk Road Ventures	fund	UAE	6.00	60000	2016-04-12	2026-09-29 10:38:19.670054	\N
7	Timur Bolatovich Akhmetov	individual	Kazakhstan	5.00	50000	2013-11-05	2026-09-29 10:38:19.670054	\N
8	Altyn Asyl Trust	company	Kazakhstan	4.50	45000	2017-02-28	2026-09-29 10:38:19.670054	\N
9	Central Asia Investments Ltd	company	Cyprus	4.00	40000	2018-07-19	2026-09-29 10:38:19.670054	\N
10	Marat Serikovich Zhunusov	individual	Kazakhstan	3.50	35000	2014-08-22	2026-09-29 10:38:19.670054	\N
11	Baiterek Development	state	Kazakhstan	3.00	30000	2019-05-30	2026-09-29 10:38:19.670054	\N
12	Anna Viktorovna Petrova	individual	Russia	2.50	25000	2016-10-03	2026-09-29 10:38:19.670054	\N
13	Global Emerging Markets Fund	fund	United Kingdom	2.50	25000	2019-12-11	2026-09-29 10:38:19.670054	\N
14	Kairat Mukhtarovich Omarov	individual	Kazakhstan	2.00	20000	2015-03-17	2026-09-29 10:38:19.670054	\N
15	Steppe Wealth Management	company	Kazakhstan	2.00	20000	2020-01-24	2026-09-29 10:38:19.670054	\N
16	Li Wei	individual	China	1.50	15000	2020-06-08	2026-09-29 10:38:19.670054	\N
17	Bosphorus Capital	company	Turkey	1.50	15000	2017-09-14	2026-09-29 10:38:19.670054	\N
18	Aigerim Kanatovna Bekova	individual	Kazakhstan	1.20	12000	2018-04-02	2026-09-29 10:38:19.670054	\N
19	Tengri Pension Fund	fund	Kazakhstan	1.20	12000	2021-03-09	2026-09-29 10:38:19.670054	\N
20	Daniel Hoffmann	individual	Germany	1.00	10000	2019-08-27	2026-09-29 10:38:19.670054	\N
21	Almaty Employees Association	company	Kazakhstan	1.00	10000	2021-11-15	2026-09-29 10:38:19.670054	\N
22	Yerlan Amanovich Tokhtarov	individual	Kazakhstan	0.80	8000	2022-02-21	2026-09-29 10:38:19.670054	\N
23	Sofia Marchetti	individual	Italy	0.60	6000	2022-05-16	2026-09-29 10:38:19.670054	\N
24	Nurlan Bakhytovich Iskakov	individual	Kazakhstan	0.40	4000	2023-01-30	2026-09-29 10:38:19.670054	\N
25	Zarina Ruslanovna Mustafina	individual	Kazakhstan	0.30	3000	2023-09-12	2026-09-29 10:38:19.670054	\N
\.


--
-- Data for Name: branches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.branches (branch_id, branch_name, swift_code, city, address, phone, created_at) FROM stdin;
1	Almaty Central	KZBAALKZALM1	Almaty	 Abay Ave 1	+7 727 250 0001	2026-09-23 10:13:51.689655
2	Astana Main	KZBAALKZAST1	Astana	Mangilik El 10	+7 717 220 0002	2026-09-23 10:13:51.689655
3	Shymkent Branch 	KZBAALKZSHY1	Shymkent	Tauke Khan 25	+7 777 233 0003	2026-09-23 10:13:51.689655
4	Karaganda Branch	KZBAALKAR1	Karaganda	Bukhar Zhyrau 8 	+7 721 244 0004	2026-09-23 10:13:51.689655
5	Aktobe Branch	KZBAALAKT1	Aktobe	Abilkayyr Khan 3 	+7 707 777 0007	2026-09-23 10:13:51.689655
6	Branch Astana #1	swift_code_1_ab57	Aktobe	Abay ave. 63	+77018244195	2026-09-29 10:29:22.150398
7	Branch Semey #2	swift_code_2_ee4d	Aktobe	Abay ave. 166	+77012242070	2026-09-29 10:29:22.150398
8	Branch Atyrau #3	swift_code_3_8412	Almaty	Abay ave. 44	+77017083194	2026-09-29 10:29:22.150398
9	Branch Karaganda #4	swift_code_4_97b7	Taraz	Abay ave. 130	+77015083889	2026-09-29 10:29:22.150398
10	Branch Atyrau #5	swift_code_5_75b0	Pavlodar	Abay ave. 173	+77010118072	2026-09-29 10:29:22.150398
11	Branch Semey #6	swift_code_6_1477	Karaganda	Abay ave. 17	+77010189195	2026-09-29 10:29:22.150398
12	Branch Shymkent #7	swift_code_7_74e8	Taraz	Abay ave. 162	+77018182459	2026-09-29 10:29:22.150398
13	Branch Karaganda #8	swift_code_8_04f5	Aktobe	Abay ave. 153	+77013420585	2026-09-29 10:29:22.150398
14	Branch Astana #9	swift_code_9_efc3	Karaganda	Abay ave. 106	+77019224489	2026-09-29 10:29:22.150398
15	Branch Shymkent #10	swift_code_10_c8ed	Almaty	Abay ave. 11	+77013248308	2026-09-29 10:29:22.150398
16	Branch Almaty #11	swift_code_11_d06a	Semey	Abay ave. 131	+77014337755	2026-09-29 10:29:22.150398
17	Branch Kostanay #12	swift_code_12_8c6d	Atyrau	Abay ave. 42	+77011728069	2026-09-29 10:29:22.150398
18	Branch Atyrau #13	swift_code_13_9d03	Taraz	Abay ave. 88	+77019330381	2026-09-29 10:29:22.150398
19	Branch Almaty #14	swift_code_14_f954	Shymkent	Abay ave. 2	+77018074082	2026-09-29 10:29:22.150398
20	Branch Astana #15	swift_code_15_cf4a	Kostanay	Abay ave. 170	+77019859133	2026-09-29 10:29:22.150398
21	Branch Aktobe #16	swift_code_16_97f0	Kostanay	Abay ave. 30	+77014915506	2026-09-29 10:29:22.150398
22	Branch Astana #17	swift_code_17_d196	Shymkent	Abay ave. 124	+77012351053	2026-09-29 10:29:22.150398
23	Branch Pavlodar #18	swift_code_18_45d1	Aktobe	Abay ave. 112	+77012642003	2026-09-29 10:29:22.150398
24	Branch Kostanay #19	swift_code_19_f672	Atyrau	Abay ave. 84	+77014721337	2026-09-29 10:29:22.150398
25	Branch Taraz #20	swift_code_20_605c	Astana	Abay ave. 162	+77012542951	2026-09-29 10:29:22.150398
26	Branch Almaty #21	swift_code_21_d275	Taraz	Abay ave. 151	+77012804904	2026-09-29 10:29:22.150398
27	Branch Astana #22	swift_code_22_7146	Taraz	Abay ave. 143	+77019108989	2026-09-29 10:29:22.150398
28	Branch Semey #23	swift_code_23_904c	Aktobe	Abay ave. 32	+77017141304	2026-09-29 10:29:22.150398
29	Branch Shymkent #24	swift_code_24_b4cf	Kostanay	Abay ave. 120	+77019559516	2026-09-29 10:29:22.150398
30	Branch Taraz #25	swift_code_25_85e9	Astana	Abay ave. 196	+77010101720	2026-09-29 10:29:22.150398
31	Branch Aktobe #26	swift_code_26_bfb1	Aktobe	Abay ave. 187	+77015708226	2026-09-29 10:29:22.150398
32	Branch Kostanay #27	swift_code_27_384f	Atyrau	Abay ave. 112	+77014201326	2026-09-29 10:29:22.150398
33	Branch Aktobe #28	swift_code_28_d9f1	Astana	Abay ave. 113	+77011600785	2026-09-29 10:29:22.150398
34	Branch Taraz #29	swift_code_29_5761	Astana	Abay ave. 195	+77019053757	2026-09-29 10:29:22.150398
35	Branch Taraz #30	swift_code_30_2b81	Aktobe	Abay ave. 121	+77013198085	2026-09-29 10:29:22.150398
36	Branch Shymkent #31	swift_code_31_a983	Karaganda	Abay ave. 141	+77016936620	2026-09-29 10:29:22.150398
37	Branch Semey #32	swift_code_32_f209	Karaganda	Abay ave. 26	+77014230297	2026-09-29 10:29:22.150398
38	Branch Kostanay #33	swift_code_33_ea6f	Atyrau	Abay ave. 8	+77012965274	2026-09-29 10:29:22.150398
39	Branch Karaganda #34	swift_code_34_2a2c	Pavlodar	Abay ave. 161	+77017582644	2026-09-29 10:29:22.150398
40	Branch Karaganda #35	swift_code_35_b293	Almaty	Abay ave. 142	+77019821168	2026-09-29 10:29:22.150398
41	Branch Astana #36	swift_code_36_4990	Astana	Abay ave. 169	+77013644655	2026-09-29 10:29:22.150398
42	Branch Aktobe #37	swift_code_37_50c3	Atyrau	Abay ave. 143	+77015288723	2026-09-29 10:29:22.150398
43	Branch Almaty #38	swift_code_38_2962	Taraz	Abay ave. 109	+77014108687	2026-09-29 10:29:22.150398
44	Branch Almaty #39	swift_code_39_2a9a	Atyrau	Abay ave. 167	+77015058872	2026-09-29 10:29:22.150398
45	Branch Taraz #40	swift_code_40_624b	Semey	Abay ave. 160	+77012913538	2026-09-29 10:29:22.150398
46	Branch Shymkent #41	swift_code_41_7904	Shymkent	Abay ave. 125	+77019995593	2026-09-29 10:29:22.150398
47	Branch Aktobe #42	swift_code_42_ec15	Aktobe	Abay ave. 10	+77018572877	2026-09-29 10:29:22.150398
48	Branch Atyrau #43	swift_code_43_0430	Karaganda	Abay ave. 88	+77012566079	2026-09-29 10:29:22.150398
49	Branch Karaganda #44	swift_code_44_0952	Astana	Abay ave. 86	+77014214906	2026-09-29 10:29:22.150398
50	Branch Pavlodar #45	swift_code_45_ed54	Atyrau	Abay ave. 118	+77012969975	2026-09-29 10:29:22.150398
51	Branch Karaganda #46	swift_code_46_97f1	Taraz	Abay ave. 164	+77014011745	2026-09-29 10:29:22.150398
52	Branch Taraz #47	swift_code_47_3b1b	Atyrau	Abay ave. 45	+77015269121	2026-09-29 10:29:22.150398
53	Branch Astana #48	swift_code_48_aed6	Aktobe	Abay ave. 68	+77011414832	2026-09-29 10:29:22.150398
54	Branch Karaganda #49	swift_code_49_7809	Semey	Abay ave. 11	+77016740905	2026-09-29 10:29:22.150398
55	Branch Taraz #50	swift_code_50_60a8	Kostanay	Abay ave. 50	+77019887681	2026-09-29 10:29:22.150398
56	Branch Pavlodar #51	swift_code_51_1d2a	Almaty	Abay ave. 16	+77019409754	2026-09-29 10:29:22.150398
57	Branch Semey #52	swift_code_52_e789	Karaganda	Abay ave. 195	+77018345456	2026-09-29 10:29:22.150398
58	Branch Pavlodar #53	swift_code_53_e460	Pavlodar	Abay ave. 30	+77010492245	2026-09-29 10:29:22.150398
59	Branch Semey #54	swift_code_54_f66c	Semey	Abay ave. 173	+77017944633	2026-09-29 10:29:22.150398
60	Branch Semey #55	swift_code_55_a8ee	Semey	Abay ave. 38	+77012210931	2026-09-29 10:29:22.150398
61	Branch Almaty #56	swift_code_56_693b	Karaganda	Abay ave. 176	+77015752248	2026-09-29 10:29:22.150398
62	Branch Astana #57	swift_code_57_bc27	Atyrau	Abay ave. 149	+77010708107	2026-09-29 10:29:22.150398
63	Branch Aktobe #58	swift_code_58_c1f2	Almaty	Abay ave. 106	+77013234950	2026-09-29 10:29:22.150398
64	Branch Kostanay #59	swift_code_59_7576	Kostanay	Abay ave. 95	+77014990049	2026-09-29 10:29:22.150398
65	Branch Astana #60	swift_code_60_4847	Astana	Abay ave. 110	+77014796414	2026-09-29 10:29:22.150398
66	Branch Kostanay #61	swift_code_61_5f7c	Aktobe	Abay ave. 14	+77015680776	2026-09-29 10:29:22.150398
67	Branch Taraz #62	swift_code_62_839f	Taraz	Abay ave. 4	+77016774702	2026-09-29 10:29:22.150398
68	Branch Aktobe #63	swift_code_63_01a6	Astana	Abay ave. 2	+77019332515	2026-09-29 10:29:22.150398
69	Branch Atyrau #64	swift_code_64_a87e	Atyrau	Abay ave. 31	+77019906710	2026-09-29 10:29:22.150398
70	Branch Pavlodar #65	swift_code_65_142c	Atyrau	Abay ave. 51	+77011807752	2026-09-29 10:29:22.150398
71	Branch Taraz #66	swift_code_66_c617	Karaganda	Abay ave. 21	+77018010635	2026-09-29 10:29:22.150398
72	Branch Pavlodar #67	swift_code_67_12fc	Astana	Abay ave. 153	+77015104595	2026-09-29 10:29:22.150398
73	Branch Atyrau #68	swift_code_68_1e8d	Almaty	Abay ave. 37	+77013413569	2026-09-29 10:29:22.150398
74	Branch Aktobe #69	swift_code_69_acd6	Aktobe	Abay ave. 192	+77011230983	2026-09-29 10:29:22.150398
75	Branch Almaty #70	swift_code_70_83bf	Karaganda	Abay ave. 1	+77010663990	2026-09-29 10:29:22.150398
76	Branch Atyrau #71	swift_code_71_e2c3	Karaganda	Abay ave. 22	+77013022356	2026-09-29 10:29:22.150398
77	Branch Kostanay #72	swift_code_72_0d68	Shymkent	Abay ave. 41	+77012008807	2026-09-29 10:29:22.150398
78	Branch Semey #73	swift_code_73_c2e0	Taraz	Abay ave. 92	+77018943327	2026-09-29 10:29:22.150398
79	Branch Astana #74	swift_code_74_a4ed	Semey	Abay ave. 58	+77017890586	2026-09-29 10:29:22.150398
80	Branch Aktobe #75	swift_code_75_8920	Semey	Abay ave. 62	+77010365083	2026-09-29 10:29:22.150398
81	Branch Almaty #76	swift_code_76_b295	Taraz	Abay ave. 9	+77015381952	2026-09-29 10:29:22.150398
82	Branch Shymkent #77	swift_code_77_b20e	Atyrau	Abay ave. 168	+77014663924	2026-09-29 10:29:22.150398
83	Branch Aktobe #78	swift_code_78_393c	Taraz	Abay ave. 164	+77014171205	2026-09-29 10:29:22.150398
84	Branch Semey #79	swift_code_79_cbff	Astana	Abay ave. 29	+77012768140	2026-09-29 10:29:22.150398
85	Branch Pavlodar #80	swift_code_80_0043	Karaganda	Abay ave. 172	+77013530480	2026-09-29 10:29:22.150398
86	Branch Karaganda #81	swift_code_81_7189	Semey	Abay ave. 84	+77013703604	2026-09-29 10:29:22.150398
87	Branch Almaty #82	swift_code_82_b9aa	Semey	Abay ave. 191	+77015102001	2026-09-29 10:29:22.150398
88	Branch Atyrau #83	swift_code_83_717d	Taraz	Abay ave. 39	+77019145950	2026-09-29 10:29:22.150398
89	Branch Pavlodar #84	swift_code_84_5bd6	Shymkent	Abay ave. 110	+77018850007	2026-09-29 10:29:22.150398
90	Branch Shymkent #85	swift_code_85_a71a	Aktobe	Abay ave. 123	+77015989854	2026-09-29 10:29:22.150398
91	Branch Pavlodar #86	swift_code_86_9ff7	Aktobe	Abay ave. 74	+77015312482	2026-09-29 10:29:22.150398
92	Branch Atyrau #87	swift_code_87_36ff	Astana	Abay ave. 148	+77014992857	2026-09-29 10:29:22.150398
93	Branch Almaty #88	swift_code_88_f55f	Aktobe	Abay ave. 110	+77015513178	2026-09-29 10:29:22.150398
94	Branch Almaty #89	swift_code_89_bdf7	Kostanay	Abay ave. 186	+77018714533	2026-09-29 10:29:22.150398
95	Branch Kostanay #90	swift_code_90_1b39	Astana	Abay ave. 33	+77011349282	2026-09-29 10:29:22.150398
96	Branch Kostanay #91	swift_code_91_a699	Aktobe	Abay ave. 64	+77013137586	2026-09-29 10:29:22.150398
97	Branch Semey #92	swift_code_92_dd45	Astana	Abay ave. 82	+77015976810	2026-09-29 10:29:22.150398
98	Branch Kostanay #93	swift_code_93_e561	Astana	Abay ave. 72	+77010685808	2026-09-29 10:29:22.150398
99	Branch Taraz #94	swift_code_94_a38c	Pavlodar	Abay ave. 39	+77011000183	2026-09-29 10:29:22.150398
100	Branch Taraz #95	swift_code_95_dc19	Atyrau	Abay ave. 64	+77014527650	2026-09-29 10:29:22.150398
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customers (customer_id, first_name, last_name, national_id, date_of_birth, phone, email, address, created_at) FROM stdin;
1	Асхат 	Иванов	990101300123	1999-01-01	+7 701 000 0001	ashat.evanov@emaple.com	Almaty, Dostyk 12	2026-09-23 10:13:51.720759
2	Айгерим	Смагулова	950512400456	1995-02-15	+7 775 202 0009	 aigerymsmagulova@example.com	Astana , Turan 5	2026-09-23 10:13:51.720759
3	Ерлан	Ким	880723500789	1988-07-23	+7 701 000 0008	erlank@example.com	Karaganda, Lenina 20	2026-09-23 10:13:51.720759
4	Динара	Ахметова	021115600321	1988-07-23	+7 701 000 2222	dina@example.com	Shymkent, Baytursynov 7 	2026-09-23 10:13:51.720759
5	Руслан	Жунусов	760209700654	1976-02-09	+7 701 000 0005	marat.zh@example.com	Aktobe, Moldagulova 15	2026-09-23 10:13:51.720759
6	Kamila	Rakhimov	916290284243	1996-02-11	+77010359689	user1_8a1a90@example.com	Abay ave. 82	2026-09-29 10:29:22.150398
7	Marat	Seitkali	825803100220	1959-07-15	+77010639487	user2_cca206@example.com	Abay ave. 115	2026-09-29 10:29:22.150398
8	Gulnara	Kasymova	664272529037	1977-10-01	+77011056082	user3_b78493@example.com	Abay ave. 61	2026-09-29 10:29:22.150398
9	Aigerim	Mustafina	263451970649	1989-12-03	+77019570942	user4_33e1a9@example.com	Abay ave. 4	2026-09-29 10:29:22.150398
10	Ruslan	Tleuov	701305766421	1988-07-23	+77015218123	user5_1b8d15@example.com	Abay ave. 103	2026-09-29 10:29:22.150398
11	Zarina	Iskakov	987116366200	1984-11-09	+77013660721	user6_9d0f72@example.com	Abay ave. 86	2026-09-29 10:29:22.150398
12	Aliya	Baimukhanov	139543932333	1981-11-07	+77010165996	user7_0c99a7@example.com	Abay ave. 195	2026-09-29 10:29:22.150398
13	Dana	Smagulova	038960453923	1989-05-24	+77015521355	user8_bf3f9b@example.com	Abay ave. 159	2026-09-29 10:29:22.150398
14	Aidar	Omarov	908830819003	1981-06-09	+77017120723	user9_b281ff@example.com	Abay ave. 137	2026-09-29 10:29:22.150398
15	Dana	Tokhtarov	327726433388	1976-01-06	+77018692533	user10_e8ff53@example.com	Abay ave. 66	2026-09-29 10:29:22.150398
16	Ruslan	Sadykov	175694421315	1969-04-17	+77019319221	user11_d7c775@example.com	Abay ave. 136	2026-09-29 10:29:22.150398
17	Daniyar	Smagulova	566643899335	1987-06-03	+77017645446	user12_185ef0@example.com	Abay ave. 119	2026-09-29 10:29:22.150398
18	Aidar	Tleuov	948383184645	1990-05-03	+77016132006	user13_dbc00e@example.com	Abay ave. 136	2026-09-29 10:29:22.150398
19	Assel	Ospanova	496690537082	2005-08-04	+77015766254	user14_53e454@example.com	Abay ave. 103	2026-09-29 10:29:22.150398
20	Yerlan	Iskakov	366248487410	1999-08-26	+77014115187	user15_b16191@example.com	Abay ave. 80	2026-09-29 10:29:22.150398
21	Aidar	Dosmukhambetov	021890007890	1997-11-27	+77011329867	user16_da4c4e@example.com	Abay ave. 54	2026-09-29 10:29:22.150398
22	Aigerim	Akhmetov	272269792085	1983-06-26	+77010260589	user17_f5c750@example.com	Abay ave. 135	2026-09-29 10:29:22.150398
23	Dias	Bekova	150643867808	1967-12-06	+77016042368	user18_4ab2ac@example.com	Abay ave. 50	2026-09-29 10:29:22.150398
24	Aigerim	Tokhtarov	310059822973	1993-05-25	+77011095027	user19_5608da@example.com	Abay ave. 174	2026-09-29 10:29:22.150398
25	Dana	Bekova	976243192746	1960-05-07	+77016486894	user20_e30c24@example.com	Abay ave. 67	2026-09-29 10:29:22.150398
26	Arman	Akhmetov	766245301131	1973-08-03	+77018684799	user21_fabbce@example.com	Abay ave. 88	2026-09-29 10:29:22.150398
27	Assel	Baimukhanov	096784643624	1969-09-16	+77017827634	user22_1d9424@example.com	Abay ave. 170	2026-09-29 10:29:22.150398
28	Arman	Yesenova	663559804827	2005-02-13	+77016621219	user23_b95ce3@example.com	Abay ave. 21	2026-09-29 10:29:22.150398
29	Ruslan	Seitkali	618941212829	1967-05-26	+77013957210	user24_c171e6@example.com	Abay ave. 106	2026-09-29 10:29:22.150398
30	Assel	Smagulova	351497093375	1976-12-10	+77019631315	user25_2e19f0@example.com	Abay ave. 147	2026-09-29 10:29:22.150398
31	Timur	Smagulova	489150051007	2003-03-20	+77015071125	user26_955c84@example.com	Abay ave. 41	2026-09-29 10:29:22.150398
32	Saltanat	Bekova	878040613006	1983-07-04	+77010055597	user27_bbad0f@example.com	Abay ave. 49	2026-09-29 10:29:22.150398
33	Ainur	Dosmukhambetov	367379610428	1986-11-05	+77014641712	user28_e4e62a@example.com	Abay ave. 161	2026-09-29 10:29:22.150398
34	Aidar	Abenov	615339019514	1973-09-12	+77017890051	user29_a43e31@example.com	Abay ave. 135	2026-09-29 10:29:22.150398
35	Madina	Mustafina	759611756871	1996-08-24	+77012250970	user30_fea198@example.com	Abay ave. 82	2026-09-29 10:29:22.150398
36	Aidar	Mustafina	094838137179	1998-03-07	+77010821610	user31_a68fff@example.com	Abay ave. 74	2026-09-29 10:29:22.150398
37	Madina	Tokhtarov	956331358992	1999-11-10	+77014579929	user32_087677@example.com	Abay ave. 128	2026-09-29 10:29:22.150398
38	Arman	Bekova	897271245882	2008-03-11	+77016423146	user33_f4915d@example.com	Abay ave. 172	2026-09-29 10:29:22.150398
39	Timur	Bekova	466695971993	1988-07-18	+77014174671	user34_678885@example.com	Abay ave. 47	2026-09-29 10:29:22.150398
40	Bauyrzhan	Ospanova	051308306575	2003-01-27	+77010198140	user35_35ea23@example.com	Abay ave. 111	2026-09-29 10:29:22.150398
41	Aigerim	Yesenova	913517144359	1963-01-10	+77017177405	user36_a41c1f@example.com	Abay ave. 88	2026-09-29 10:29:22.150398
42	Timur	Akhmetov	842478473145	1990-09-01	+77017934987	user37_209f00@example.com	Abay ave. 23	2026-09-29 10:29:22.150398
43	Saltanat	Mustafina	049661129844	1979-09-12	+77012122380	user38_8cb2a9@example.com	Abay ave. 199	2026-09-29 10:29:22.150398
44	Bauyrzhan	Baimukhanov	055173278484	1993-05-06	+77017578098	user39_83d798@example.com	Abay ave. 174	2026-09-29 10:29:22.150398
45	Assel	Omarov	343070338665	1991-06-27	+77011177237	user40_684e9f@example.com	Abay ave. 17	2026-09-29 10:29:22.150398
46	Bauyrzhan	Bekova	984728838300	1959-12-04	+77010958253	user41_60213e@example.com	Abay ave. 127	2026-09-29 10:29:22.150398
47	Kamila	Sadykov	986985123658	1982-09-08	+77014471672	user42_afc052@example.com	Abay ave. 25	2026-09-29 10:29:22.150398
48	Aigerim	Zhunusov	468628399591	1966-04-23	+77010905464	user43_e3a9c4@example.com	Abay ave. 172	2026-09-29 10:29:22.150398
49	Bauyrzhan	Ospanova	511295249788	2007-02-25	+77019228147	user44_3621f4@example.com	Abay ave. 72	2026-09-29 10:29:22.150398
50	Saltanat	Sadykov	598055344815	1973-10-27	+77017325706	user45_1beb9d@example.com	Abay ave. 104	2026-09-29 10:29:22.150398
51	Aigerim	Mustafina	722983110386	1962-07-06	+77014574083	user46_018afa@example.com	Abay ave. 91	2026-09-29 10:29:22.150398
52	Ainur	Seitkali	978770703129	1965-03-24	+77017588979	user47_dc8092@example.com	Abay ave. 191	2026-09-29 10:29:22.150398
53	Daniyar	Ospanova	921059365900	2006-10-03	+77019112471	user48_fc260e@example.com	Abay ave. 28	2026-09-29 10:29:22.150398
54	Arman	Sadykov	811852552633	1968-11-27	+77014522256	user49_32b8ad@example.com	Abay ave. 116	2026-09-29 10:29:22.150398
55	Zarina	Mustafina	299439234830	1990-06-13	+77015977721	user50_f059d2@example.com	Abay ave. 30	2026-09-29 10:29:22.150398
56	Ruslan	Tokhtarov	176177564514	1960-08-31	+77016645363	user51_d69a8c@example.com	Abay ave. 132	2026-09-29 10:29:22.150398
57	Aigerim	Akhmetov	444170358963	1961-08-22	+77010004016	user52_d13d44@example.com	Abay ave. 70	2026-09-29 10:29:22.150398
58	Aidar	Smagulova	929519460530	1984-10-21	+77010327034	user53_ae2042@example.com	Abay ave. 190	2026-09-29 10:29:22.150398
59	Assel	Rakhimov	028223140811	1985-10-08	+77014481744	user54_740cd7@example.com	Abay ave. 62	2026-09-29 10:29:22.150398
60	Dana	Nurgaliyev	009781258575	1991-08-17	+77016193057	user55_82c93e@example.com	Abay ave. 136	2026-09-29 10:29:22.150398
61	Ruslan	Abenov	469513543278	1961-02-04	+77011583319	user56_1963a9@example.com	Abay ave. 170	2026-09-29 10:29:22.150398
62	Zarina	Tokhtarov	554825983478	2004-08-18	+77011792334	user57_aadba3@example.com	Abay ave. 79	2026-09-29 10:29:22.150398
63	Dana	Yesenova	733951960156	1987-04-15	+77011959383	user58_5fb8ed@example.com	Abay ave. 128	2026-09-29 10:29:22.150398
64	Dana	Ospanova	486611781703	1986-01-09	+77018072902	user59_bd0bf8@example.com	Abay ave. 39	2026-09-29 10:29:22.150398
65	Zarina	Sadykov	866508912597	1984-04-09	+77013049651	user60_23ce60@example.com	Abay ave. 151	2026-09-29 10:29:22.150398
66	Madina	Rakhimov	589582735431	1990-07-31	+77012272832	user61_a6d580@example.com	Abay ave. 154	2026-09-29 10:29:22.150398
67	Saltanat	Abenov	389562831585	2002-05-21	+77011000902	user62_b5f2d7@example.com	Abay ave. 47	2026-09-29 10:29:22.150398
68	Aigerim	Smagulova	897508018425	2005-10-25	+77016376724	user63_25f83c@example.com	Abay ave. 181	2026-09-29 10:29:22.150398
69	Ruslan	Mustafina	928043972576	1966-08-14	+77018329992	user64_453d40@example.com	Abay ave. 163	2026-09-29 10:29:22.150398
70	Zarina	Kenzhebayev	601171957170	1965-06-10	+77011589810	user65_b1f657@example.com	Abay ave. 93	2026-09-29 10:29:22.150398
71	Aliya	Mustafina	577105361846	1979-06-20	+77017640046	user66_fb4fb7@example.com	Abay ave. 8	2026-09-29 10:29:22.150398
72	Zarina	Kasymova	647210703917	1981-10-12	+77012674051	user67_50963c@example.com	Abay ave. 115	2026-09-29 10:29:22.150398
73	Aidar	Akhmetov	757548815436	1987-07-17	+77010133309	user68_b1ab93@example.com	Abay ave. 182	2026-09-29 10:29:22.150398
74	Nurlan	Akhmetov	012077920548	1999-10-21	+77014295547	user69_133c1c@example.com	Abay ave. 9	2026-09-29 10:29:22.150398
75	Madina	Smagulova	218600319835	2003-11-22	+77018211803	user70_826f47@example.com	Abay ave. 186	2026-09-29 10:29:22.150398
76	Bauyrzhan	Dosmukhambetov	831433083707	1971-02-22	+77010962438	user71_edf5d3@example.com	Abay ave. 199	2026-09-29 10:29:22.150398
77	Aigerim	Nurgaliyev	826070556077	2001-04-09	+77016477065	user72_f92451@example.com	Abay ave. 122	2026-09-29 10:29:22.150398
78	Aigerim	Abenov	073230724487	1965-01-21	+77010006698	user73_6f5324@example.com	Abay ave. 34	2026-09-29 10:29:22.150398
79	Madina	Ospanova	042701349972	1961-02-06	+77018717418	user74_7fcfc5@example.com	Abay ave. 182	2026-09-29 10:29:22.150398
80	Ainur	Dosmukhambetov	817638435225	1966-08-23	+77015461757	user75_094e60@example.com	Abay ave. 22	2026-09-29 10:29:22.150398
81	Nurlan	Seitkali	473852819433	1962-07-22	+77016264178	user76_35b6d8@example.com	Abay ave. 68	2026-09-29 10:29:22.150398
82	Dias	Baimukhanov	519188962068	1964-02-02	+77011057196	user77_cb702c@example.com	Abay ave. 11	2026-09-29 10:29:22.150398
83	Ainur	Omarov	633774549725	1970-06-13	+77012106388	user78_b62a26@example.com	Abay ave. 151	2026-09-29 10:29:22.150398
84	Bauyrzhan	Yesenova	214429717892	1965-05-17	+77010032954	user79_17d02b@example.com	Abay ave. 119	2026-09-29 10:29:22.150398
85	Gulnara	Bekova	811481831736	1968-01-07	+77014523322	user80_23c20f@example.com	Abay ave. 122	2026-09-29 10:29:22.150398
86	Saltanat	Dosmukhambetov	241888249622	1998-12-27	+77013572662	user81_9982f6@example.com	Abay ave. 148	2026-09-29 10:29:22.150398
87	Nurlan	Rakhimov	236204239713	1992-01-02	+77012288894	user82_eb4f18@example.com	Abay ave. 9	2026-09-29 10:29:22.150398
88	Aigerim	Abenov	327119999595	1996-01-31	+77015604618	user83_4a3b68@example.com	Abay ave. 102	2026-09-29 10:29:22.150398
89	Madina	Sadykov	528638741028	1964-05-01	+77011475105	user84_a3ed4e@example.com	Abay ave. 70	2026-09-29 10:29:22.150398
90	Aigerim	Tleuov	781246812630	1982-08-31	+77013898196	user85_858ad7@example.com	Abay ave. 33	2026-09-29 10:29:22.150398
91	Marat	Bekova	520793069854	1988-09-29	+77016350478	user86_428485@example.com	Abay ave. 168	2026-09-29 10:29:22.150398
92	Kamila	Seitkali	078590534660	2003-05-20	+77012786026	user87_43b216@example.com	Abay ave. 150	2026-09-29 10:29:22.150398
93	Daniyar	Kasymova	983463174061	2008-02-05	+77013764148	user88_ade624@example.com	Abay ave. 76	2026-09-29 10:29:22.150398
94	Madina	Mustafina	763062001412	1967-07-31	+77013013582	user89_e01c5e@example.com	Abay ave. 27	2026-09-29 10:29:22.150398
95	Nurlan	Omarov	223760256799	1984-03-01	+77014784571	user90_ae67fc@example.com	Abay ave. 177	2026-09-29 10:29:22.150398
96	Bauyrzhan	Dosmukhambetov	946594168186	1970-03-08	+77012172474	user91_c3c27c@example.com	Abay ave. 19	2026-09-29 10:29:22.150398
97	Timur	Dosmukhambetov	769490204473	1977-03-05	+77017876587	user92_67495e@example.com	Abay ave. 33	2026-09-29 10:29:22.150398
98	Dias	Zhunusov	188044804698	1982-05-10	+77012810733	user93_35c4b9@example.com	Abay ave. 42	2026-09-29 10:29:22.150398
99	Daniyar	Ospanova	837222154462	1996-07-24	+77015487823	user94_494de9@example.com	Abay ave. 168	2026-09-29 10:29:22.150398
100	Nurlan	Baimukhanov	348988650860	1962-05-16	+77014077990	user95_e2b74e@example.com	Abay ave. 61	2026-09-29 10:29:22.150398
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employees (employee_id, branch_id, first_name, last_name, "position", salary, email, hire_date, is_active) FROM stdin;
1	1	Нурлан	Беков	Branch Manager	450000.00	nurlan.bekov@bank.kz	2018-03-01	t
2	1	Сауле	Тохтарова	Loan Officer	280000.00	saule.tokhtarova@bank.kz	2020-06-15	t
3	2	Тимур	Ержанов	Teller	180000.00	timur.erzhanov@bank.kz	2021-09-10	t
4	3	Гульнара	Оспанова	Loan Officer	260000.00	gulnara.ospanova@bank.kz	2019-01-20	t
5	4	Бекзат	Сериков	Branch Manager	430000.00	bekzat.serikov@bank.kz	2017-11-05	t
6	70	Dana	Seitkali	Compliance Officer	863633.33	user1_eb4220@example.com	2018-10-17	t
7	9	Saltanat	Yesenova	Compliance Officer	994581.33	user2_911a0d@example.com	2022-08-27	t
8	81	Bauyrzhan	Kenzhebayev	Compliance Officer	661662.00	user3_9f4d3b@example.com	2018-09-02	t
9	70	Kamila	Rakhimov	Customer Manager	587920.94	user4_b5e7cf@example.com	2023-10-12	t
10	50	Timur	Seitkali	Analyst	290261.61	user5_49269c@example.com	2018-06-19	t
11	8	Ruslan	Bekova	Teller	288763.90	user6_d62a16@example.com	2026-06-20	t
12	43	Marat	Tleuov	Loan Officer	872861.50	user7_cd6c4b@example.com	2022-04-29	t
13	83	Arman	Dosmukhambetov	Branch Manager	314906.68	user8_d576d3@example.com	2021-10-23	t
14	96	Zarina	Dosmukhambetov	Teller	261994.35	user9_b2b22b@example.com	2025-02-06	t
15	60	Madina	Akhmetov	Analyst	874311.93	user10_6c6f12@example.com	2017-08-09	t
16	35	Ainur	Mustafina	Loan Officer	863128.05	user11_a8ba90@example.com	2019-01-28	t
17	64	Timur	Yesenova	Branch Manager	938385.73	user12_d3242d@example.com	2024-02-05	t
18	57	Aigerim	Dosmukhambetov	Analyst	555379.78	user13_05736a@example.com	2022-03-31	t
19	88	Dana	Bekova	Accountant	353987.51	user14_547628@example.com	2020-07-24	t
20	75	Daniyar	Ospanova	Branch Manager	771131.88	user15_ae9265@example.com	2024-09-19	t
21	46	Madina	Abenov	Cashier	396405.32	user16_4fe29e@example.com	2016-12-08	t
22	12	Ainur	Dosmukhambetov	Accountant	291056.26	user17_c0a82e@example.com	2018-05-31	t
23	11	Timur	Omarov	Accountant	605892.84	user18_3a2b93@example.com	2018-01-04	t
24	59	Gulnara	Iskakov	Cashier	923068.66	user19_d7c65c@example.com	2016-11-04	t
25	97	Madina	Sadykov	Analyst	369202.87	user20_9dbe3c@example.com	2023-11-03	t
26	61	Dana	Ospanova	Customer Manager	970598.38	user21_5fc277@example.com	2019-06-13	t
27	87	Aliya	Kasymova	Analyst	974066.75	user22_cd0417@example.com	2020-09-30	t
28	53	Timur	Nurgaliyev	Customer Manager	255332.97	user23_c9f520@example.com	2020-08-05	t
29	2	Nurlan	Kenzhebayev	Teller	603329.79	user24_62202d@example.com	2024-03-12	t
30	18	Daniyar	Rakhimov	Teller	659111.98	user25_c0f597@example.com	2022-05-18	t
31	45	Arman	Dosmukhambetov	Teller	300585.64	user26_b77861@example.com	2021-11-16	t
32	17	Dias	Dosmukhambetov	Customer Manager	720876.38	user27_10ec49@example.com	2016-10-16	t
33	15	Aigerim	Mustafina	Teller	273939.45	user28_6e3e1b@example.com	2024-02-01	t
34	4	Yerlan	Tleuov	Loan Officer	641838.41	user29_98b1c0@example.com	2023-02-02	t
35	64	Daniyar	Iskakov	Accountant	539161.90	user30_6b89f0@example.com	2024-04-15	t
36	82	Aidar	Kenzhebayev	Customer Manager	254922.43	user31_765c4c@example.com	2020-07-31	t
37	89	Yerlan	Omarov	Loan Officer	991183.09	user32_a0709b@example.com	2020-06-04	t
38	2	Yerlan	Rakhimov	Analyst	952988.09	user33_9e931e@example.com	2020-01-29	t
39	16	Marat	Smagulova	Customer Manager	786661.12	user34_25848c@example.com	2023-11-23	t
40	97	Saltanat	Smagulova	Compliance Officer	469390.45	user35_fd63f2@example.com	2021-06-12	t
41	31	Daniyar	Seitkali	Loan Officer	483184.55	user36_58f42a@example.com	2024-09-17	t
42	26	Gulnara	Kasymova	Analyst	725019.74	user37_34314a@example.com	2024-03-23	t
43	62	Kamila	Seitkali	Cashier	763821.23	user38_7478f2@example.com	2018-11-01	t
44	80	Zarina	Baimukhanov	Teller	426712.32	user39_f8abc2@example.com	2019-08-15	t
45	95	Aidar	Ospanova	Analyst	288689.38	user40_11eeb9@example.com	2025-01-14	t
46	73	Arman	Dosmukhambetov	Accountant	902126.95	user41_3f2c4b@example.com	2018-02-01	t
47	23	Gulnara	Sadykov	Customer Manager	443241.11	user42_91618d@example.com	2017-09-22	t
48	48	Madina	Bekova	Accountant	612487.68	user43_daa87c@example.com	2018-11-16	t
49	31	Yerlan	Iskakov	Branch Manager	610131.22	user44_18b803@example.com	2021-11-05	t
50	94	Aigerim	Ospanova	Loan Officer	733217.25	user45_b8c12c@example.com	2018-02-22	t
51	37	Timur	Kasymova	Compliance Officer	931261.09	user46_ee20bc@example.com	2020-04-04	t
52	55	Aliya	Bekova	Loan Officer	305165.52	user47_c38af5@example.com	2021-02-08	t
53	46	Ainur	Abenov	Branch Manager	659762.40	user48_b23f5f@example.com	2016-11-30	t
54	47	Nurlan	Tleuov	Analyst	648952.81	user49_475c74@example.com	2019-08-31	t
55	16	Aigerim	Zhunusov	Accountant	497221.42	user50_47c08b@example.com	2018-09-20	t
56	28	Aigerim	Rakhimov	Teller	610860.99	user51_e5b99f@example.com	2021-05-29	t
57	17	Arman	Sadykov	Customer Manager	519621.88	user52_621b71@example.com	2024-10-10	t
58	68	Arman	Rakhimov	Loan Officer	519130.44	user53_e8e48a@example.com	2018-01-27	t
59	60	Aidar	Akhmetov	Customer Manager	410656.86	user54_5b0141@example.com	2019-01-17	t
60	6	Aigerim	Rakhimov	Teller	307517.47	user55_6caa3c@example.com	2020-01-28	t
61	82	Dana	Omarov	Loan Officer	249375.65	user56_7686ed@example.com	2026-03-20	t
62	72	Saltanat	Tokhtarov	Cashier	968737.42	user57_161417@example.com	2023-10-20	t
63	70	Marat	Bekova	Teller	391354.41	user58_9e6e7c@example.com	2025-07-17	t
64	64	Dana	Nurgaliyev	Analyst	838864.73	user59_bf2344@example.com	2017-04-13	t
65	45	Assel	Omarov	Customer Manager	520584.14	user60_761055@example.com	2025-10-10	t
66	16	Gulnara	Yesenova	Compliance Officer	848477.54	user61_a64d10@example.com	2024-03-29	t
67	11	Dana	Sadykov	Customer Manager	754038.27	user62_c731b9@example.com	2024-09-09	t
68	42	Dana	Nurgaliyev	Teller	614125.89	user63_985187@example.com	2024-08-09	t
69	42	Bauyrzhan	Kenzhebayev	Analyst	248126.70	user64_5d5b3a@example.com	2024-11-15	t
70	63	Dana	Rakhimov	Cashier	913163.83	user65_1e6454@example.com	2019-02-11	t
71	94	Timur	Ospanova	Customer Manager	317761.02	user66_4f8853@example.com	2024-10-05	t
72	1	Assel	Iskakov	Loan Officer	532465.10	user67_812c85@example.com	2024-07-05	t
73	47	Yerlan	Tleuov	Teller	671758.59	user68_9c34a7@example.com	2019-03-09	t
74	4	Dias	Tleuov	Loan Officer	956541.98	user69_245fde@example.com	2020-01-30	t
75	7	Bauyrzhan	Ospanova	Branch Manager	515989.13	user70_f12167@example.com	2018-01-09	t
76	62	Yerlan	Yesenova	Loan Officer	795643.89	user71_ecae6e@example.com	2017-03-18	t
77	60	Gulnara	Dosmukhambetov	Cashier	806780.67	user72_c548c9@example.com	2023-11-13	t
78	86	Madina	Rakhimov	Compliance Officer	521539.20	user73_5f851c@example.com	2021-01-08	t
79	78	Zarina	Yesenova	Cashier	935870.62	user74_43a2dc@example.com	2023-06-21	t
80	95	Ainur	Seitkali	Cashier	554995.45	user75_59c614@example.com	2023-03-18	t
81	82	Ruslan	Akhmetov	Compliance Officer	261833.89	user76_181848@example.com	2025-03-18	t
82	77	Marat	Omarov	Customer Manager	452187.01	user77_5a3d46@example.com	2026-03-16	t
83	1	Aidar	Tokhtarov	Branch Manager	402772.39	user78_9f2125@example.com	2024-12-04	t
84	51	Dana	Abenov	Compliance Officer	960799.28	user79_acd7d8@example.com	2024-08-18	t
85	29	Nurlan	Ospanova	Branch Manager	364384.57	user80_6a14be@example.com	2026-07-22	t
86	69	Dias	Sadykov	Loan Officer	961417.56	user81_cac256@example.com	2017-04-18	t
87	73	Ainur	Nurgaliyev	Customer Manager	448633.39	user82_938576@example.com	2017-10-25	t
88	52	Aidar	Smagulova	Compliance Officer	944902.19	user83_1e0e64@example.com	2024-05-07	t
89	49	Marat	Rakhimov	Analyst	849388.43	user84_5fd815@example.com	2017-05-03	t
90	53	Zarina	Zhunusov	Teller	339323.18	user85_394b18@example.com	2022-05-06	t
91	20	Kamila	Kenzhebayev	Teller	245341.68	user86_85ecd5@example.com	2026-03-18	t
92	45	Arman	Mustafina	Cashier	588258.77	user87_7a4927@example.com	2020-12-09	t
93	35	Zarina	Bekova	Analyst	849292.91	user88_a975e6@example.com	2019-11-14	t
94	95	Assel	Seitkali	Cashier	467999.17	user89_636722@example.com	2019-07-05	t
95	3	Aliya	Iskakov	Analyst	757131.12	user90_f82462@example.com	2019-03-15	t
96	88	Aliya	Smagulova	Cashier	463845.10	user91_209708@example.com	2023-09-17	t
97	12	Aigerim	Seitkali	Analyst	828387.16	user92_4abaef@example.com	2019-05-20	t
98	22	Saltanat	Zhunusov	Branch Manager	633331.93	user93_2f3864@example.com	2023-01-12	t
99	17	Dana	Dosmukhambetov	Compliance Officer	878865.06	user94_64edbf@example.com	2025-02-22	t
100	63	Assel	Yesenova	Customer Manager	324217.44	user95_ed9ea7@example.com	2025-04-11	t
\.


--
-- Data for Name: loan_payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.loan_payments (payment_id, loan_id, account_id, amount, payment_date, payment_number, is_late) FROM stdin;
1	1	1	48500.00	2026-09-23 10:13:51.827601	1	f
2	1	1	48500.00	2026-09-23 10:13:51.827601	2	f
3	3	4	68500.00	2026-09-23 10:13:51.827601	1	f
4	3	4	68500.00	2026-09-23 10:13:51.827601	2	t
5	5	1	45500.00	2026-09-23 10:13:51.827601	17	f
6	5	1	45500.00	2026-09-23 10:13:51.827601	18	f
7	59	50	289006.74	2026-09-29 10:29:22.150398	83	f
8	87	72	457984.63	2026-09-29 10:29:22.150398	57	f
9	61	97	130440.07	2026-09-29 10:29:22.150398	73	f
10	70	61	87886.82	2026-09-29 10:29:22.150398	75	f
11	63	23	303230.52	2026-09-29 10:29:22.150398	62	f
12	189	59	177942.24	2026-09-29 10:29:22.150398	24	f
13	159	9	204143.67	2026-09-29 10:29:22.150398	74	f
14	9	77	86077.79	2026-09-29 10:29:22.150398	78	f
15	181	18	481907.33	2026-09-29 10:29:22.150398	26	f
16	4	85	61270.28	2026-09-29 10:29:22.150398	29	f
17	11	74	173162.88	2026-09-29 10:29:22.150398	52	f
18	21	93	427835.77	2026-09-29 10:29:22.150398	76	f
19	183	33	320519.69	2026-09-29 10:29:22.150398	2	f
20	21	62	199726.69	2026-09-29 10:29:22.150398	56	f
21	140	67	432868.10	2026-09-29 10:29:22.150398	47	f
22	186	91	157392.23	2026-09-29 10:29:22.150398	72	f
23	92	95	107355.11	2026-09-29 10:29:22.150398	78	f
24	76	79	487521.57	2026-09-29 10:29:22.150398	54	f
25	95	8	92223.52	2026-09-29 10:29:22.150398	30	f
26	59	3	20351.01	2026-09-29 10:29:22.150398	50	f
27	121	63	213834.53	2026-09-29 10:29:22.150398	26	f
28	73	73	314158.72	2026-09-29 10:29:22.150398	71	f
29	77	74	394458.13	2026-09-29 10:29:22.150398	19	f
30	89	26	448035.42	2026-09-29 10:29:22.150398	46	f
31	9	24	357360.04	2026-09-29 10:29:22.150398	74	f
32	5	30	51469.62	2026-09-29 10:29:22.150398	2	f
33	4	26	335281.86	2026-09-29 10:29:22.150398	9	f
34	72	2	60266.11	2026-09-29 10:29:22.150398	50	f
35	134	29	250203.59	2026-09-29 10:29:22.150398	15	f
36	153	87	193652.83	2026-09-29 10:29:22.150398	53	f
37	105	51	93682.31	2026-09-29 10:29:22.150398	41	f
38	108	29	437663.48	2026-09-29 10:29:22.150398	80	f
39	162	66	259527.00	2026-09-29 10:29:22.150398	83	f
40	153	27	14828.59	2026-09-29 10:29:22.150398	33	f
41	52	97	499017.80	2026-09-29 10:29:22.150398	92	f
42	89	22	418536.08	2026-09-29 10:29:22.150398	93	f
43	126	87	284807.68	2026-09-29 10:29:22.150398	68	f
44	30	80	213849.49	2026-09-29 10:29:22.150398	44	f
45	30	18	327964.74	2026-09-29 10:29:22.150398	86	f
46	129	6	338651.18	2026-09-29 10:29:22.150398	96	f
47	151	5	93546.22	2026-09-29 10:29:22.150398	45	f
48	73	95	269168.66	2026-09-29 10:29:22.150398	58	f
49	129	60	293099.29	2026-09-29 10:29:22.150398	59	f
50	162	100	97104.48	2026-09-29 10:29:22.150398	68	f
51	101	94	227777.86	2026-09-29 10:29:22.150398	22	f
52	102	89	82034.82	2026-09-29 10:29:22.150398	66	f
53	83	60	64514.25	2026-09-29 10:29:22.150398	50	f
54	2	21	429762.43	2026-09-29 10:29:22.150398	64	f
55	109	41	339236.13	2026-09-29 10:29:22.150398	4	f
56	127	65	70470.86	2026-09-29 10:29:22.150398	50	f
57	29	7	186762.90	2026-09-29 10:29:22.150398	34	f
58	183	15	481848.46	2026-09-29 10:29:22.150398	25	f
59	72	78	40351.49	2026-09-29 10:29:22.150398	47	f
60	70	42	7064.42	2026-09-29 10:29:22.150398	98	f
61	95	100	398882.33	2026-09-29 10:29:22.150398	20	f
62	90	33	221971.65	2026-09-29 10:29:22.150398	63	f
63	154	84	339344.58	2026-09-29 10:29:22.150398	80	f
64	58	68	253423.10	2026-09-29 10:29:22.150398	21	f
65	2	6	181239.20	2026-09-29 10:29:22.150398	38	f
66	108	21	490872.17	2026-09-29 10:29:22.150398	31	f
67	93	14	120843.02	2026-09-29 10:29:22.150398	83	f
68	101	31	169528.22	2026-09-29 10:29:22.150398	47	f
69	153	10	176194.98	2026-09-29 10:29:22.150398	32	f
70	86	64	98957.56	2026-09-29 10:29:22.150398	58	f
71	190	15	326914.82	2026-09-29 10:29:22.150398	24	f
72	39	69	18151.06	2026-09-29 10:29:22.150398	19	f
73	162	56	354428.42	2026-09-29 10:29:22.150398	53	f
74	142	15	437511.81	2026-09-29 10:29:22.150398	78	f
75	76	8	330712.89	2026-09-29 10:29:22.150398	49	f
76	110	9	153227.55	2026-09-29 10:29:22.150398	90	f
77	95	61	277023.93	2026-09-29 10:29:22.150398	8	f
78	9	24	17700.25	2026-09-29 10:29:22.150398	35	f
79	142	19	448894.21	2026-09-29 10:29:22.150398	10	f
80	67	59	480081.62	2026-09-29 10:29:22.150398	69	f
81	35	87	307116.28	2026-09-29 10:29:22.150398	46	f
82	109	38	52645.97	2026-09-29 10:29:22.150398	80	f
83	110	56	453592.99	2026-09-29 10:29:22.150398	99	f
84	123	82	436737.15	2026-09-29 10:29:22.150398	74	f
85	39	61	37489.21	2026-09-29 10:29:22.150398	49	f
86	95	93	69758.62	2026-09-29 10:29:22.150398	87	f
87	58	97	178996.35	2026-09-29 10:29:22.150398	16	f
88	34	71	154002.71	2026-09-29 10:29:22.150398	23	f
89	57	95	482262.09	2026-09-29 10:29:22.150398	4	f
90	81	51	319075.74	2026-09-29 10:29:22.150398	67	f
91	34	87	97473.23	2026-09-29 10:29:22.150398	48	f
92	43	11	33896.92	2026-09-29 10:29:22.150398	55	f
93	72	10	271226.38	2026-09-29 10:29:22.150398	7	f
94	28	99	490919.98	2026-09-29 10:29:22.150398	34	f
95	61	39	244927.31	2026-09-29 10:29:22.150398	40	f
96	153	81	458993.55	2026-09-29 10:29:22.150398	86	f
97	174	52	334926.87	2026-09-29 10:29:22.150398	48	f
98	154	54	397225.57	2026-09-29 10:29:22.150398	75	f
99	135	36	199940.48	2026-09-29 10:29:22.150398	47	f
100	46	59	255124.92	2026-09-29 10:29:22.150398	35	f
101	60	75	322749.37	2026-09-29 10:29:22.150398	54	f
\.


--
-- Data for Name: loans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.loans (loan_id, customer_id, branch_id, approved_by, principal_amount, interest_rate, term_months, status, application_date, start_date, end_date) FROM stdin;
1	1	1	2	1000000.00	14.50	24	active	2023-01-15	2023-02-01	2025-02-01
2	2	2	\N	500000.00	12.00	12	pending	2024-05-10	\N	\N
3	3	3	4	20000000.00	15.00	36	active	2022-08-20	2022-09-01	2025-09-01
4	4	4	\N	300000.00	13.25	6	rejected	2024-02-01	\N	\N
5	5	1	2	750000.00	11.75	18	paid	2021-03-05	2021-04-01	2022-10-01
9	81	46	13	254776.98	8.41	57	pending	2026-09-29	2022-10-10	2023-01-08
11	27	44	86	212014.50	10.96	16	pending	2026-09-29	2023-07-03	2026-04-25
19	41	12	59	402126.67	17.72	51	pending	2026-09-29	2022-09-27	2026-02-05
21	52	24	21	391524.28	16.04	23	pending	2026-09-29	2023-10-24	2024-11-06
24	40	40	15	380786.12	9.54	12	pending	2026-09-29	2025-04-04	2026-07-26
26	44	51	41	476531.76	7.05	22	pending	2026-09-29	2024-11-27	2026-05-19
27	8	5	7	61321.80	5.70	56	pending	2026-09-29	2023-06-11	2025-06-08
28	16	26	41	252234.32	6.36	6	pending	2026-09-29	2024-03-31	2026-08-30
29	5	10	54	275571.25	11.88	27	pending	2026-09-29	2023-07-27	2024-02-08
30	50	30	92	494728.69	13.67	57	pending	2026-09-29	2023-10-10	2026-09-02
31	35	21	13	228084.17	4.67	21	pending	2026-09-29	2023-01-23	2025-02-17
34	80	18	12	401321.49	11.38	21	pending	2026-09-29	2023-05-14	2025-12-30
35	91	32	99	58354.89	7.84	53	pending	2026-09-29	2023-02-11	2023-03-10
39	22	66	15	236215.69	17.27	35	pending	2026-09-29	2024-12-28	2025-07-17
40	24	8	91	120485.82	13.62	28	pending	2026-09-29	2024-02-26	2025-12-25
43	55	7	70	487933.30	15.30	13	pending	2026-09-29	2026-03-15	2026-07-18
44	9	94	26	391567.79	15.41	13	pending	2026-09-29	2023-07-28	2025-08-05
45	53	52	68	49543.18	17.64	9	pending	2026-09-29	2026-01-06	2026-07-13
46	26	23	64	49862.92	5.67	39	pending	2026-09-29	2025-03-10	2025-09-08
51	85	27	13	240356.24	3.74	34	pending	2026-09-29	2025-02-15	2026-07-12
52	39	61	7	418348.97	6.20	50	pending	2026-09-29	2023-05-07	2025-05-30
56	3	43	39	166640.95	11.50	15	pending	2026-09-29	2024-09-27	2025-03-08
57	14	30	98	33582.95	6.70	9	pending	2026-09-29	2022-11-04	2025-01-11
58	74	9	95	214891.11	15.07	48	pending	2026-09-29	2022-12-18	2024-10-22
59	44	73	9	345671.78	12.10	11	pending	2026-09-29	2024-01-03	2026-06-19
60	15	31	35	380387.34	15.66	18	pending	2026-09-29	2022-12-23	2024-06-01
61	83	23	6	473392.64	15.70	50	pending	2026-09-29	2025-01-13	2025-10-11
63	72	5	85	55183.04	5.46	41	pending	2026-09-29	2025-07-20	2025-12-14
65	20	47	72	183003.72	14.39	48	pending	2026-09-29	2024-03-05	2026-07-03
67	52	24	28	154314.51	8.28	13	pending	2026-09-29	2023-06-15	2025-02-14
70	82	6	31	433609.47	7.32	50	pending	2026-09-29	2024-02-26	2024-12-09
71	31	57	26	296057.98	3.14	34	pending	2026-09-29	2022-12-16	2026-05-16
72	88	29	29	247315.99	18.75	30	pending	2026-09-29	2023-05-09	2024-07-03
73	89	77	57	147969.98	6.61	9	pending	2026-09-29	2024-02-10	2024-07-14
75	92	27	26	462962.95	16.02	26	pending	2026-09-29	2025-01-25	2026-03-10
76	98	54	12	169728.39	9.97	48	pending	2026-09-29	2023-02-15	2026-05-12
77	99	64	26	71450.41	10.55	42	pending	2026-09-29	2022-11-11	2024-06-26
79	29	8	41	218392.05	8.24	41	pending	2026-09-29	2023-06-15	2024-04-17
80	32	55	68	53101.49	8.40	24	pending	2026-09-29	2025-01-14	2026-04-08
81	69	92	31	460193.40	4.29	49	pending	2026-09-29	2022-11-07	2024-10-19
83	20	35	56	362162.35	19.11	47	pending	2026-09-29	2023-04-22	2025-03-02
86	26	5	18	281301.53	14.43	49	pending	2026-09-29	2025-07-19	2026-04-10
87	69	19	56	19263.26	11.94	48	pending	2026-09-29	2025-09-06	2025-09-14
89	95	51	93	85658.49	16.27	6	pending	2026-09-29	2023-10-04	2025-02-08
90	7	52	37	401144.02	14.05	23	pending	2026-09-29	2023-08-31	2023-12-20
92	73	94	29	394718.29	16.76	57	pending	2026-09-29	2023-09-01	2024-06-25
93	55	89	12	310359.03	14.01	13	pending	2026-09-29	2022-09-27	2026-02-10
94	68	30	90	419564.80	6.48	36	pending	2026-09-29	2024-04-30	2025-09-16
95	19	11	9	266839.09	3.47	9	pending	2026-09-29	2025-09-18	2026-09-02
98	92	71	47	153783.28	10.45	24	pending	2026-09-29	2023-10-21	2024-07-29
100	85	91	70	497358.63	13.36	58	pending	2026-09-29	2024-10-18	2026-08-23
101	30	52	85	395490.90	11.42	45	pending	2026-09-29	2024-07-08	2024-07-18
102	38	35	50	382110.61	16.00	37	pending	2026-09-29	2023-03-23	2025-08-16
104	40	86	97	268342.64	16.42	55	pending	2026-09-29	2025-04-29	2026-04-30
105	87	47	13	187165.47	10.48	31	pending	2026-09-29	2025-02-26	2026-01-17
106	68	81	14	359578.98	12.81	38	pending	2026-09-29	2022-09-17	2024-09-06
107	12	82	91	256984.41	3.83	47	pending	2026-09-29	2022-08-27	2023-10-27
108	12	45	95	188893.34	5.80	32	pending	2026-09-29	2024-04-09	2025-12-06
109	84	56	39	464863.87	13.56	25	pending	2026-09-29	2023-01-01	2025-06-29
110	86	22	100	42744.03	19.30	17	pending	2026-09-29	2023-10-04	2026-08-25
111	84	80	48	282664.89	11.39	13	pending	2026-09-29	2023-04-03	2024-10-07
117	51	62	26	185872.12	9.76	20	pending	2026-09-29	2023-03-01	2024-04-14
119	31	76	76	235294.55	15.77	27	pending	2026-09-29	2024-05-12	2025-04-06
121	78	77	11	11193.13	16.62	45	pending	2026-09-29	2025-04-22	2025-12-09
123	38	18	48	473872.99	18.46	32	pending	2026-09-29	2022-10-26	2025-08-18
126	89	10	38	64339.61	4.33	48	pending	2026-09-29	2023-11-02	2023-12-31
127	81	16	73	365974.18	10.61	54	pending	2026-09-29	2023-09-07	2025-11-14
128	64	93	83	458470.55	10.64	16	pending	2026-09-29	2023-06-27	2025-05-12
129	93	2	3	252536.13	18.54	42	pending	2026-09-29	2024-07-07	2025-12-07
133	54	78	21	280140.20	12.28	53	pending	2026-09-29	2025-03-08	2026-02-03
134	67	68	33	23045.88	13.35	19	pending	2026-09-29	2024-03-25	2024-07-07
135	14	94	83	311672.02	9.82	7	pending	2026-09-29	2023-12-29	2026-06-22
138	72	17	82	31478.25	12.45	51	pending	2026-09-29	2024-02-10	2026-06-04
140	97	53	13	480194.11	6.67	29	pending	2026-09-29	2024-11-18	2026-03-15
142	90	24	23	354649.08	3.33	9	pending	2026-09-29	2023-06-12	2023-08-09
149	9	40	69	328634.33	16.15	6	pending	2026-09-29	2023-02-07	2024-03-14
151	4	29	13	61422.74	15.32	26	pending	2026-09-29	2023-01-16	2024-12-26
153	88	77	23	11529.04	15.83	22	pending	2026-09-29	2023-03-13	2024-08-26
154	73	45	88	162359.60	4.96	41	pending	2026-09-29	2024-11-11	2026-02-01
158	26	91	20	118692.54	15.29	36	pending	2026-09-29	2025-09-27	2026-01-18
159	52	9	91	30892.27	17.69	52	pending	2026-09-29	2025-04-23	2026-01-25
162	7	29	64	456742.61	18.64	23	pending	2026-09-29	2022-09-24	2026-07-22
165	34	89	31	88855.25	5.91	7	pending	2026-09-29	2025-06-03	2026-06-13
171	46	59	79	65679.28	10.44	16	pending	2026-09-29	2025-02-01	2025-03-27
172	95	48	47	6029.56	16.35	28	pending	2026-09-29	2024-07-15	2026-09-23
174	29	66	8	223705.83	11.41	7	pending	2026-09-29	2023-09-09	2025-12-25
175	45	32	68	500010.01	19.40	47	pending	2026-09-29	2024-05-22	2026-05-02
179	81	51	73	203542.64	14.32	55	pending	2026-09-29	2024-10-05	2026-02-26
181	44	21	95	215221.91	18.17	43	pending	2026-09-29	2025-01-21	2025-09-27
183	48	73	87	241134.87	11.46	14	pending	2026-09-29	2023-05-21	2024-05-16
185	2	77	74	71140.66	4.65	34	pending	2026-09-29	2023-01-13	2025-01-13
186	48	44	81	441524.66	11.65	56	pending	2026-09-29	2023-08-06	2024-07-12
189	47	1	29	177409.12	4.46	23	pending	2026-09-29	2023-07-14	2024-10-10
190	28	32	37	479527.55	13.28	44	pending	2026-09-29	2022-12-25	2023-12-05
192	74	33	19	51413.68	8.21	42	pending	2026-09-29	2023-02-26	2024-03-17
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transactions (transaction_id, from_account_id, to_account_id, transaction_type, amount, status, description, transaction_date) FROM stdin;
1	\N	1	deposit	50000.00	completed	Пополнение через кассу	2026-09-23 10:13:51.795675
2	1	2	transfer	20000.00	completed	Перевод на накопительный счет	2026-09-23 10:13:51.795675
3	2	\N	withdrawal	15000.00	completed	Cнятие в банкомате	2026-09-23 10:13:51.795675
4	3	4	transfer	5000.00	pending	Оплата поставщику	2026-09-23 10:13:51.795675
5	\N	4	deposit	300000.00	completed	Пополнение бизнес-счета	2026-09-23 10:13:51.795675
6	4	\N	fee	500.00	completed	Комиссия за обслуживание	2026-09-23 10:13:51.795675
7	21	82	withdrawal	490827.66	pending	description_1_4a2f	2026-09-29 10:29:22.150398
8	56	64	transfer	291251.94	pending	description_2_be78	2026-09-29 10:29:22.150398
9	101	8	fee	440151.93	pending	description_3_0524	2026-09-29 10:29:22.150398
10	44	100	fee	170916.25	pending	description_4_1870	2026-09-29 10:29:22.150398
11	43	100	withdrawal	29765.62	pending	description_5_ed11	2026-09-29 10:29:22.150398
12	94	72	fee	93285.78	pending	description_6_2f84	2026-09-29 10:29:22.150398
13	61	51	fee	366385.45	pending	description_7_25f5	2026-09-29 10:29:22.150398
14	49	38	fee	34393.74	pending	description_8_f8ff	2026-09-29 10:29:22.150398
15	4	82	transfer	238406.26	pending	description_9_213c	2026-09-29 10:29:22.150398
16	65	61	transfer	225133.53	pending	description_10_eb86	2026-09-29 10:29:22.150398
17	12	29	withdrawal	19524.13	pending	description_11_9902	2026-09-29 10:29:22.150398
18	20	67	transfer	479519.92	pending	description_12_d661	2026-09-29 10:29:22.150398
19	95	63	withdrawal	160163.20	pending	description_13_5dbc	2026-09-29 10:29:22.150398
20	47	27	transfer	39074.86	pending	description_14_6bfe	2026-09-29 10:29:22.150398
21	26	45	transfer	207647.71	pending	description_15_8315	2026-09-29 10:29:22.150398
22	67	46	transfer	267853.88	pending	description_16_e414	2026-09-29 10:29:22.150398
23	60	2	withdrawal	302472.65	pending	description_17_992f	2026-09-29 10:29:22.150398
24	94	63	withdrawal	295080.43	pending	description_18_3adf	2026-09-29 10:29:22.150398
25	71	43	withdrawal	155455.22	pending	description_19_4174	2026-09-29 10:29:22.150398
26	77	60	transfer	49283.81	pending	description_20_a973	2026-09-29 10:29:22.150398
27	72	54	transfer	199651.26	pending	description_21_fdfb	2026-09-29 10:29:22.150398
28	70	35	deposit	464238.79	pending	description_22_987b	2026-09-29 10:29:22.150398
29	44	73	fee	8432.86	pending	description_23_3b8b	2026-09-29 10:29:22.150398
30	72	101	withdrawal	5778.71	pending	description_24_094a	2026-09-29 10:29:22.150398
31	97	24	fee	138402.17	pending	description_25_3cf3	2026-09-29 10:29:22.150398
32	16	85	fee	237452.76	pending	description_26_ea8f	2026-09-29 10:29:22.150398
33	67	64	fee	22501.48	pending	description_27_9c62	2026-09-29 10:29:22.150398
34	98	4	transfer	305302.96	pending	description_28_0e29	2026-09-29 10:29:22.150398
35	12	64	fee	110155.22	pending	description_29_da35	2026-09-29 10:29:22.150398
36	79	78	transfer	407172.40	pending	description_30_73a8	2026-09-29 10:29:22.150398
37	78	34	deposit	163519.50	pending	description_31_f025	2026-09-29 10:29:22.150398
38	29	12	withdrawal	334086.72	pending	description_32_7568	2026-09-29 10:29:22.150398
39	65	95	deposit	136351.46	pending	description_33_4cd2	2026-09-29 10:29:22.150398
40	12	69	deposit	352700.68	pending	description_34_5b1b	2026-09-29 10:29:22.150398
41	95	34	transfer	402807.09	pending	description_35_ecec	2026-09-29 10:29:22.150398
42	39	72	deposit	255824.73	pending	description_36_bc8e	2026-09-29 10:29:22.150398
43	73	62	withdrawal	131359.51	pending	description_37_8f01	2026-09-29 10:29:22.150398
44	84	17	transfer	357131.63	pending	description_38_34a6	2026-09-29 10:29:22.150398
45	93	100	deposit	437434.18	pending	description_39_afe6	2026-09-29 10:29:22.150398
46	61	63	transfer	254205.57	pending	description_40_5199	2026-09-29 10:29:22.150398
47	20	36	fee	86178.73	pending	description_41_7f11	2026-09-29 10:29:22.150398
48	100	22	transfer	135536.25	pending	description_42_6bbb	2026-09-29 10:29:22.150398
49	82	38	deposit	269976.15	pending	description_43_7598	2026-09-29 10:29:22.150398
50	100	22	withdrawal	345854.77	pending	description_44_613c	2026-09-29 10:29:22.150398
51	36	43	deposit	436894.85	pending	description_45_1e17	2026-09-29 10:29:22.150398
52	95	19	withdrawal	211457.02	pending	description_46_09b1	2026-09-29 10:29:22.150398
53	22	8	fee	500015.99	pending	description_47_634b	2026-09-29 10:29:22.150398
54	57	8	transfer	166523.03	pending	description_48_8201	2026-09-29 10:29:22.150398
55	81	44	fee	143617.97	pending	description_49_fe5f	2026-09-29 10:29:22.150398
56	60	71	deposit	433439.09	pending	description_50_5bb7	2026-09-29 10:29:22.150398
57	19	61	fee	386656.31	pending	description_51_bc62	2026-09-29 10:29:22.150398
58	2	87	deposit	489633.42	pending	description_52_d6cb	2026-09-29 10:29:22.150398
59	11	101	transfer	215437.12	pending	description_53_cea9	2026-09-29 10:29:22.150398
60	75	50	fee	312339.36	pending	description_54_3101	2026-09-29 10:29:22.150398
61	50	70	deposit	19112.62	pending	description_55_284b	2026-09-29 10:29:22.150398
62	101	51	deposit	161565.63	pending	description_56_aa3a	2026-09-29 10:29:22.150398
63	97	67	fee	451836.90	pending	description_57_b236	2026-09-29 10:29:22.150398
64	16	17	transfer	177058.45	pending	description_58_d741	2026-09-29 10:29:22.150398
65	63	1	transfer	160411.26	pending	description_59_2c18	2026-09-29 10:29:22.150398
66	58	77	withdrawal	105787.45	pending	description_60_0f86	2026-09-29 10:29:22.150398
67	62	1	fee	90401.62	pending	description_61_6d55	2026-09-29 10:29:22.150398
68	100	62	transfer	99915.62	pending	description_62_eab6	2026-09-29 10:29:22.150398
69	91	43	withdrawal	267473.11	pending	description_63_c25d	2026-09-29 10:29:22.150398
70	100	88	fee	124011.96	pending	description_64_80ca	2026-09-29 10:29:22.150398
71	56	66	transfer	471478.72	pending	description_65_3d8e	2026-09-29 10:29:22.150398
72	12	48	deposit	398587.36	pending	description_66_40b5	2026-09-29 10:29:22.150398
73	48	46	withdrawal	110990.92	pending	description_67_079b	2026-09-29 10:29:22.150398
74	6	8	deposit	298285.19	pending	description_68_fd09	2026-09-29 10:29:22.150398
75	41	92	deposit	357045.85	pending	description_69_82b4	2026-09-29 10:29:22.150398
76	71	81	transfer	421369.38	pending	description_70_81d8	2026-09-29 10:29:22.150398
77	85	24	deposit	118435.59	pending	description_71_d0a7	2026-09-29 10:29:22.150398
78	4	45	deposit	287062.02	pending	description_72_ffa8	2026-09-29 10:29:22.150398
79	85	32	fee	364276.30	pending	description_73_0b8d	2026-09-29 10:29:22.150398
80	50	9	withdrawal	82180.29	pending	description_74_57ee	2026-09-29 10:29:22.150398
81	98	84	transfer	212769.37	pending	description_75_ae2a	2026-09-29 10:29:22.150398
82	16	89	deposit	14168.16	pending	description_76_b28e	2026-09-29 10:29:22.150398
83	44	16	withdrawal	182222.37	pending	description_77_bf8b	2026-09-29 10:29:22.150398
84	43	76	transfer	285271.03	pending	description_78_c74f	2026-09-29 10:29:22.150398
85	6	7	withdrawal	444998.88	pending	description_79_b2ff	2026-09-29 10:29:22.150398
86	35	4	fee	385654.97	pending	description_80_28aa	2026-09-29 10:29:22.150398
87	88	20	transfer	25486.11	pending	description_81_bb72	2026-09-29 10:29:22.150398
88	46	78	fee	24257.23	pending	description_82_4018	2026-09-29 10:29:22.150398
89	48	64	fee	189803.94	pending	description_83_dcf8	2026-09-29 10:29:22.150398
90	53	43	transfer	320944.23	pending	description_84_1f8b	2026-09-29 10:29:22.150398
91	100	53	transfer	134857.70	pending	description_85_a6e0	2026-09-29 10:29:22.150398
92	29	101	withdrawal	277303.74	pending	description_86_116a	2026-09-29 10:29:22.150398
93	48	66	withdrawal	281278.63	pending	description_87_c7a0	2026-09-29 10:29:22.150398
94	46	66	withdrawal	422975.72	pending	description_88_6aa4	2026-09-29 10:29:22.150398
95	69	17	withdrawal	95764.12	pending	description_89_bf8c	2026-09-29 10:29:22.150398
96	44	31	fee	343835.61	pending	description_90_643c	2026-09-29 10:29:22.150398
97	52	49	transfer	284365.54	pending	description_91_7c78	2026-09-29 10:29:22.150398
98	39	41	withdrawal	319178.60	pending	description_92_e46b	2026-09-29 10:29:22.150398
99	83	95	fee	490241.03	pending	description_93_2c92	2026-09-29 10:29:22.150398
100	5	94	transfer	436676.85	pending	description_94_4a5b	2026-09-29 10:29:22.150398
101	78	30	transfer	226293.41	pending	description_95_a480	2026-09-29 10:29:22.150398
\.


--
-- Data for Name: transfers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transfers (transfer_id, transfer_type, from_account_id, to_account_id, currency, amount, fee, network, wallet_address, tx_hash, status, created_at, completed_at) FROM stdin;
1	crypto_withdrawal	3	\N	TON	2884.18665003	14.42093325	TON	0x9069cec247f576e68aa42fedcfee9fba	a7b52849a8a03e2ed29142764c089e05f401adeb39db1043e9d1269369729fac	completed	2026-05-05 16:33:26.253888	2026-05-05 16:43:16.120487
2	internal	63	9	EUR	255147.58000000	0.00000000	\N	\N	\N	pending	2026-09-01 16:17:45.500474	\N
3	internal	52	61	KZT	384545.17000000	0.00000000	\N	\N	\N	cancelled	2026-06-20 09:22:02.709763	\N
4	internal	2	18	KZT	380275.42000000	0.00000000	\N	\N	\N	pending	2026-08-30 18:25:13.449138	\N
5	internal	8	66	KZT	417991.31000000	0.00000000	\N	\N	\N	completed	2026-07-10 03:19:23.544731	2026-07-10 03:36:11.590791
6	crypto_withdrawal	87	\N	TON	262.12353641	1.31061768	TON	0x24977e71541d46feee84d28cc45078e3	b0d3069183c8152b7c696a2327ffea71ab5dfaf3eb366a6d2c64a3c3e6e86d31	completed	2026-07-23 01:41:43.005805	2026-07-23 01:59:23.062894
7	internal	94	18	EUR	154190.09000000	0.00000000	\N	\N	\N	completed	2026-08-04 15:46:33.792845	2026-08-04 15:47:11.677125
8	crypto_withdrawal	65	\N	ETH	7.05772954	0.03528865	ERC20	0xf414652f78d25b47b5679af1278b1c7d	06592a33166de40b90d72f00640afe921c40f8271b09cc5373e3df1b5ae2a84f	completed	2026-06-20 02:21:51.352877	2026-06-20 02:40:40.198462
9	crypto_withdrawal	59	\N	ETH	9.00514892	0.04502574	ERC20	0x9abd676d9951cbd6756653c9d0f7a488	\N	pending	2026-09-09 08:58:53.351192	\N
10	crypto_withdrawal	20	\N	TON	2967.54181704	14.83770909	TON	0x8477b68454b935f2c31e1175e8cbc286	\N	cancelled	2026-06-09 23:47:52.153433	\N
11	crypto_withdrawal	21	\N	BTC	0.24543677	0.00122718	BTC	0xeeceda7350281f4a5b1d2e6356dd4407	2842af9e107c8d80ac230a2e295645db43efb1ec4f0903239eb3b0628f654b34	completed	2026-07-25 20:58:52.843761	2026-07-25 21:07:16.462874
12	crypto_withdrawal	48	\N	BTC	0.34733965	0.00173670	BTC	0xd9bce2a423693855c09031e399d342f7	b8b3172b4ab9c216b185f44d90e638ef906c595b95d1c5af5d805d492a68494b	completed	2026-08-08 06:38:50.046786	2026-08-08 06:53:33.219884
13	internal	18	22	USD	261014.26000000	0.00000000	\N	\N	\N	completed	2026-09-13 19:41:57.237833	2026-09-13 19:43:34.282673
14	internal	52	35	KZT	457168.03000000	0.00000000	\N	\N	\N	completed	2026-08-05 15:09:31.174286	2026-08-05 15:09:44.236417
15	internal	69	41	KZT	387243.33000000	0.00000000	\N	\N	\N	pending	2026-06-10 21:37:39.760394	\N
16	internal	87	82	EUR	464667.74000000	0.00000000	\N	\N	\N	failed	2026-07-11 06:22:47.440537	\N
17	internal	7	29	USD	209868.27000000	0.00000000	\N	\N	\N	cancelled	2026-08-08 10:37:19.178398	\N
18	internal	65	30	KZT	258630.49000000	0.00000000	\N	\N	\N	failed	2026-06-09 05:14:17.459383	\N
19	crypto_withdrawal	19	\N	TON	1259.08366337	6.29541832	TON	0xd8a7f39cc7c0258255ffc54b457caca3	238a8566edecd69a10532e03d5d2f51c122b66aab5b3259c5eacbf347f42aeb1	completed	2026-05-24 04:21:33.644941	2026-05-24 04:24:53.993983
20	internal	19	97	KZT	446306.96000000	0.00000000	\N	\N	\N	completed	2026-07-25 03:57:55.654514	2026-07-25 04:16:19.413794
21	internal	75	53	EUR	225579.59000000	0.00000000	\N	\N	\N	completed	2026-07-24 17:25:39.068975	2026-07-24 17:49:14.506118
22	internal	45	63	USD	356637.99000000	0.00000000	\N	\N	\N	pending	2026-08-22 04:02:44.144355	\N
23	crypto_withdrawal	71	\N	BTC	0.31760186	0.00158801	BTC	0xc678794abdf90059268aec3c99010d03	\N	cancelled	2026-09-12 00:23:32.783022	\N
24	crypto_withdrawal	24	\N	BTC	0.49041565	0.00245208	BTC	0x921a9e64fd489e9171593a60653eec47	8abca1372e5650b5109261aec00591a27dd46dc85c1a120769c78b62cada2692	completed	2026-06-26 16:24:40.800602	2026-06-26 16:52:29.555558
25	crypto_withdrawal	43	\N	USDT	8191.37211153	40.95686056	TRC20	0xd137f537b6196bbcd57206992d50f961	8567570e88e313d70e8833d473bcf1c232dabc21335acfc5f6d63967a8325594	completed	2026-04-24 15:37:21.17566	2026-04-24 15:50:12.95528
26	internal	45	9	KZT	493566.41000000	0.00000000	\N	\N	\N	completed	2026-04-28 06:51:50.267778	2026-04-28 07:13:47.628188
27	internal	62	9	EUR	450077.95000000	0.00000000	\N	\N	\N	pending	2026-05-04 20:31:01.680004	\N
28	crypto_withdrawal	88	\N	USDT	8097.17417960	40.48587090	TRC20	0x3d760f879d3e2ee951d8fb7eb2987f1e	bf160efe7f9b043d7070bc7dca3837073f8b5b7807649412172ba3ff1ff957e7	completed	2026-09-10 22:35:24.21845	2026-09-10 23:03:50.908758
29	crypto_withdrawal	27	\N	USDT	19607.21303776	98.03606519	TRC20	0xeeb9be71f5f68d1c12492c5984409c16	\N	pending	2026-05-25 03:34:23.517437	\N
30	crypto_withdrawal	99	\N	TON	697.88306293	3.48941531	TON	0xa8b73190507263b204be9bb091894845	9cb2bfcfa01abd433680e07b52794567d923b00c16cf88202f745233e587da17	completed	2026-05-27 18:46:58.705754	2026-05-27 19:09:17.546399
31	crypto_withdrawal	101	\N	USDT	10515.60477561	52.57802388	TRC20	0xc9b6523fc5d68dec88ae6b91bad025f8	4bdc5e9461450b418f2c9e112306352c82c224bfe156602f47366b7f3fbcdfcb	completed	2026-04-13 06:49:30.031995	2026-04-13 06:50:25.445284
32	internal	59	8	USD	133844.94000000	0.00000000	\N	\N	\N	failed	2026-05-28 17:00:10.232133	\N
33	internal	4	89	KZT	320386.27000000	0.00000000	\N	\N	\N	completed	2026-08-24 14:46:48.896591	2026-08-24 14:47:37.052814
34	internal	58	93	USD	128530.97000000	0.00000000	\N	\N	\N	completed	2026-07-24 01:05:56.189801	2026-07-24 01:13:16.601185
35	internal	3	16	EUR	105556.72000000	0.00000000	\N	\N	\N	completed	2026-04-02 19:27:39.586962	2026-04-02 19:44:47.702795
36	crypto_withdrawal	96	\N	USDT	12831.00962814	64.15504814	TRC20	0x36d4bcddb2754dfe0296d430d45e9039	959965d4b11b5c713abf5875b67349407472170aba8de91fc42d34fed7d2330a	completed	2026-08-01 21:46:57.881	2026-08-01 22:07:33.26934
37	internal	78	20	KZT	192883.85000000	0.00000000	\N	\N	\N	completed	2026-07-27 19:35:49.06046	2026-07-27 19:40:48.420304
38	crypto_withdrawal	14	\N	USDT	15929.67064212	79.64835321	TRC20	0x9f70a657444d8fdacf4e573b5f92231d	61827c068abdd6bc69f5908038fad6a23fbbe7cf8e817919db7cbffba7a29c27	completed	2026-05-06 08:37:48.745242	2026-05-06 09:04:30.775547
39	internal	23	98	KZT	35829.97000000	0.00000000	\N	\N	\N	completed	2026-07-04 08:04:36.483608	2026-07-04 08:32:29.097771
40	crypto_withdrawal	84	\N	ETH	8.37343056	0.04186715	ERC20	0xe3ffe5cd9eae73414d5bfea427b2ca0a	\N	failed	2026-09-15 04:38:54.484647	\N
41	crypto_withdrawal	47	\N	TON	58.02584737	0.29012924	TON	0x87b944cc59cf0eb466f18a702bb84915	f42876b5e82694666d7f9ade1727b5aa879bd0b588d53b317d9fb942fa993ea4	completed	2026-06-19 00:01:44.863797	2026-06-19 00:08:16.715602
42	internal	2	12	KZT	141892.92000000	0.00000000	\N	\N	\N	pending	2026-04-05 18:12:07.803485	\N
43	crypto_withdrawal	10	\N	USDT	13933.85642246	69.66928211	TRC20	0x4ac848fb8b79a9181a9d7c7ff8147592	554d12beb7e5e2f56dd7e9f2b7437ef573966d2e0f184ca28dbbdc58d328899b	completed	2026-05-17 10:16:58.928815	2026-05-17 10:40:35.073945
44	crypto_withdrawal	21	\N	USDT	13991.73256102	69.95866281	TRC20	0x08206c66197f0617258919dc60d2ae5c	3df1c6f4acaf4cb7a50c15c908480e3dd8213b9af7075e953c2bdf96a951b540	completed	2026-04-23 19:43:16.274447	2026-04-23 19:50:14.443479
45	internal	35	46	EUR	252839.92000000	0.00000000	\N	\N	\N	completed	2026-04-09 04:39:16.480177	2026-04-09 05:00:19.848676
46	internal	62	88	KZT	2346.31000000	0.00000000	\N	\N	\N	completed	2026-04-16 01:10:48.560321	2026-04-16 01:20:45.002603
47	internal	97	53	KZT	426652.39000000	0.00000000	\N	\N	\N	completed	2026-05-18 10:42:39.577153	2026-05-18 10:43:06.273845
48	internal	23	9	EUR	12707.33000000	0.00000000	\N	\N	\N	completed	2026-05-20 07:27:54.39917	2026-05-20 07:37:59.584867
49	crypto_withdrawal	88	\N	USDT	1240.40177394	6.20200887	TRC20	0x4288245be7ae7f3e6a79b795a81baf4a	a5116c7097a61abc38c0c63311afac3bcb0b85c6f5aed7ade3da1374155c590d	completed	2026-09-07 21:47:54.473999	2026-09-07 21:51:53.416847
50	internal	89	14	USD	271914.90000000	0.00000000	\N	\N	\N	failed	2026-08-08 07:57:17.619139	\N
51	crypto_withdrawal	28	\N	USDT	10903.30657404	54.51653287	TRC20	0xdd9ed6cc417aef9f95f0edc21a78b197	6f2ee187f84cda1493a96b53e7ad84f4051735b7e5373febcbe7b16391f8a477	completed	2026-08-24 04:57:05.281185	2026-08-24 05:12:17.85306
52	internal	16	47	KZT	261725.71000000	0.00000000	\N	\N	\N	completed	2026-07-25 13:09:11.213756	2026-07-25 13:19:36.69357
53	internal	82	29	KZT	159577.94000000	0.00000000	\N	\N	\N	completed	2026-08-03 17:19:06.339377	2026-08-03 17:37:27.667001
54	internal	43	77	KZT	201812.67000000	0.00000000	\N	\N	\N	completed	2026-04-15 21:37:17.868017	2026-04-15 21:51:36.70564
55	internal	3	16	KZT	337588.46000000	0.00000000	\N	\N	\N	completed	2026-07-04 09:22:39.725447	2026-07-04 09:47:09.732581
56	crypto_withdrawal	9	\N	USDT	17034.66704337	85.17333522	TRC20	0xe8a82106594887bcacbbafe02e650f35	3a228fddb3272d7d3b3acbc779786e04f044b61cf15500629be02d19d50bc4dd	completed	2026-08-30 00:13:13.899892	2026-08-30 00:37:54.895248
57	internal	19	15	KZT	28847.47000000	0.00000000	\N	\N	\N	completed	2026-05-09 11:23:28.818648	2026-05-09 11:38:47.977235
58	crypto_withdrawal	69	\N	USDT	9617.20576841	48.08602884	TRC20	0xc56d76ec3938649a4c1a24a1441eae6a	\N	pending	2026-06-15 09:43:15.977185	\N
59	internal	82	42	KZT	274800.71000000	0.00000000	\N	\N	\N	completed	2026-04-27 10:27:36.359881	2026-04-27 10:37:20.654639
60	crypto_withdrawal	23	\N	USDT	9798.32138587	48.99160693	TRC20	0xd46daf2c0681e9d5ba3719a54fd1cbe1	\N	cancelled	2026-05-14 14:22:45.488065	\N
61	internal	60	61	USD	482422.89000000	0.00000000	\N	\N	\N	completed	2026-08-10 12:38:11.157897	2026-08-10 13:00:13.515191
62	internal	15	77	USD	64894.46000000	0.00000000	\N	\N	\N	failed	2026-06-27 08:47:16.410292	\N
63	crypto_withdrawal	51	\N	USDT	12160.56179370	60.80280897	TRC20	0x5814fb87651b9e597839a99716557a53	0a7aa50e07c826d914ea11c707ffd550f6f39b56a5f6d6406c09fa7b457cdcf0	completed	2026-07-28 22:22:00.989887	2026-07-28 22:28:38.649755
64	internal	76	50	USD	180537.57000000	0.00000000	\N	\N	\N	cancelled	2026-06-29 10:17:50.696457	\N
65	internal	57	79	KZT	366111.93000000	0.00000000	\N	\N	\N	completed	2026-09-27 22:47:32.719313	2026-09-27 22:58:57.286017
66	internal	25	78	KZT	213070.77000000	0.00000000	\N	\N	\N	completed	2026-08-26 18:34:20.117521	2026-08-26 18:59:02.104865
67	crypto_withdrawal	37	\N	USDT	11065.59505020	55.32797525	TRC20	0xcaabc9e0036cf3305bda1c0de4456cee	d7ced5ea3e3030f7218d8362d06ae51bbccdde79871df67b2f16cfa9f1351fe1	completed	2026-07-24 15:11:28.037088	2026-07-24 15:29:38.068777
68	internal	25	82	KZT	202942.00000000	0.00000000	\N	\N	\N	pending	2026-05-09 09:01:18.063754	\N
69	internal	44	68	KZT	151092.66000000	0.00000000	\N	\N	\N	completed	2026-05-21 03:08:26.883345	2026-05-21 03:18:13.512735
70	internal	99	23	EUR	199591.77000000	0.00000000	\N	\N	\N	completed	2026-06-27 14:34:50.936419	2026-06-27 15:02:23.48026
71	internal	67	78	KZT	195129.32000000	0.00000000	\N	\N	\N	completed	2026-07-25 18:42:54.084189	2026-07-25 19:02:35.276485
72	internal	89	86	USD	182750.22000000	0.00000000	\N	\N	\N	completed	2026-04-28 13:42:26.519649	2026-04-28 14:07:59.934162
73	internal	84	36	KZT	36029.82000000	0.00000000	\N	\N	\N	completed	2026-08-23 07:48:05.950456	2026-08-23 08:09:38.637647
74	internal	91	85	USD	102357.13000000	0.00000000	\N	\N	\N	completed	2026-08-04 09:40:24.721687	2026-08-04 10:03:20.711547
75	internal	32	8	KZT	418544.35000000	0.00000000	\N	\N	\N	cancelled	2026-05-06 21:57:06.159178	\N
76	crypto_withdrawal	1	\N	ETH	3.48970588	0.01744853	ERC20	0x945a7ef1cd7945c33284195533af5203	8308b3607195a8a69ac424a3d934b8b815dfaf0df7286d04ffc953073cbb3519	completed	2026-07-10 16:25:24.875686	2026-07-10 16:40:35.407756
77	internal	5	7	KZT	84794.26000000	0.00000000	\N	\N	\N	cancelled	2026-04-14 12:31:01.605523	\N
78	internal	37	90	USD	251988.42000000	0.00000000	\N	\N	\N	completed	2026-06-03 04:50:51.540893	2026-06-03 04:57:44.849505
79	internal	73	33	KZT	409776.64000000	0.00000000	\N	\N	\N	pending	2026-06-25 20:38:15.594918	\N
80	internal	36	45	EUR	38706.64000000	0.00000000	\N	\N	\N	cancelled	2026-06-12 21:28:01.240466	\N
81	crypto_withdrawal	48	\N	USDT	16301.98924541	81.50994623	TRC20	0xeff294a0449ec7b11c9ec5a3ced81e9c	dd90d5828f9da7650a59e59dd7b88963cd7453edb0cda7ba496a20e54fe7d418	completed	2026-09-26 09:11:17.615149	2026-09-26 09:20:14.766577
82	crypto_withdrawal	87	\N	BTC	0.02564998	0.00012825	BTC	0x865cf5e3d871d8fc8d34e89f0ea53670	3951fc2e6bbd4357f5cca052d73b0cfd4afcf111594aea0c9f99e57d4686a7a4	completed	2026-09-18 18:12:04.606409	2026-09-18 18:40:55.292524
83	internal	72	63	KZT	300724.46000000	0.00000000	\N	\N	\N	cancelled	2026-05-26 08:29:33.17704	\N
84	internal	18	86	EUR	271744.19000000	0.00000000	\N	\N	\N	completed	2026-08-01 13:51:03.243911	2026-08-01 14:10:47.975623
85	crypto_withdrawal	9	\N	ETH	3.49137260	0.01745686	ERC20	0x0caef1c1d4fb987f8c3b1cc760d71300	\N	pending	2026-04-23 16:11:24.524357	\N
86	crypto_withdrawal	88	\N	BTC	0.23614837	0.00118074	BTC	0x23f9b526454b2a76965df0449d7489e0	\N	cancelled	2026-08-05 04:05:29.214862	\N
87	internal	75	70	EUR	163568.82000000	0.00000000	\N	\N	\N	completed	2026-05-31 09:37:37.088924	2026-05-31 09:40:24.626332
88	internal	25	34	KZT	271859.51000000	0.00000000	\N	\N	\N	cancelled	2026-05-14 20:53:43.564896	\N
89	internal	100	89	EUR	68308.54000000	0.00000000	\N	\N	\N	completed	2026-07-17 15:38:39.019001	2026-07-17 15:51:11.91713
90	internal	53	13	EUR	162076.16000000	0.00000000	\N	\N	\N	pending	2026-05-07 19:17:04.571938	\N
91	internal	29	58	KZT	342489.47000000	0.00000000	\N	\N	\N	completed	2026-04-08 02:54:20.284241	2026-04-08 03:21:24.905773
92	internal	1	58	KZT	166389.03000000	0.00000000	\N	\N	\N	completed	2026-08-29 11:20:13.02809	2026-08-29 11:24:39.578897
93	internal	39	45	EUR	357261.62000000	0.00000000	\N	\N	\N	completed	2026-06-02 11:39:01.983116	2026-06-02 12:04:19.973956
94	internal	10	49	KZT	167107.27000000	0.00000000	\N	\N	\N	failed	2026-06-30 21:21:03.655923	\N
95	crypto_withdrawal	47	\N	BTC	0.23825026	0.00119125	BTC	0x4638c6940d0e9e3aee438681e8da3900	\N	pending	2026-08-18 16:13:18.227217	\N
96	crypto_withdrawal	58	\N	USDT	8243.91568802	41.21957844	TRC20	0x8d28cb9642d0a8c4576c6932c94a9dae	\N	pending	2026-05-27 02:43:59.643081	\N
97	crypto_withdrawal	77	\N	TON	1050.98118848	5.25490594	TON	0xb4a8d85c392f4b70571f807ba3b0449e	92bae9dc12d828e1956531213a0501b3eb09c4a8acca0c759eaea32a2e12b408	completed	2026-05-10 11:08:37.955472	2026-05-10 11:28:17.208911
98	crypto_withdrawal	97	\N	BTC	0.05720627	0.00028603	BTC	0xb7244408666e33febb9ea784afdd3dd6	\N	failed	2026-05-17 16:41:24.00211	\N
99	internal	55	60	KZT	317966.36000000	0.00000000	\N	\N	\N	completed	2026-06-07 01:02:26.228578	2026-06-07 01:12:56.288039
100	internal	21	45	KZT	69110.60000000	0.00000000	\N	\N	\N	completed	2026-07-17 20:47:07.637859	2026-07-17 20:55:22.870875
\.


--
-- Name: accounts_account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.accounts_account_id_seq', 101, true);


--
-- Name: bank_shareholders_shareholder_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bank_shareholders_shareholder_id_seq', 25, true);


--
-- Name: branches_branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.branches_branch_id_seq', 100, true);


--
-- Name: customers_customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customers_customer_id_seq', 100, true);


--
-- Name: employees_employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employees_employee_id_seq', 100, true);


--
-- Name: loan_payments_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.loan_payments_payment_id_seq', 101, true);


--
-- Name: loans_loan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.loans_loan_id_seq', 192, true);


--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transactions_transaction_id_seq', 101, true);


--
-- Name: transfers_transfer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transfers_transfer_id_seq', 100, true);


--
-- Name: account_holders account_holders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_holders
    ADD CONSTRAINT account_holders_pkey PRIMARY KEY (account_id, customer_id);


--
-- Name: accounts accounts_account_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_account_number_key UNIQUE (account_number);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (account_id);


--
-- Name: bank_shareholders bank_shareholders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_shareholders
    ADD CONSTRAINT bank_shareholders_pkey PRIMARY KEY (shareholder_id);


--
-- Name: branches branches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_pkey PRIMARY KEY (branch_id);


--
-- Name: branches branches_swift_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_swift_code_key UNIQUE (swift_code);


--
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- Name: customers customers_national_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_national_id_key UNIQUE (national_id);


--
-- Name: customers customers_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_phone_key UNIQUE (phone);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: employees employees_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_email_key UNIQUE (email);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- Name: loan_payments loan_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT loan_payments_pkey PRIMARY KEY (payment_id);


--
-- Name: loans loans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (loan_id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: transfers transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT transfers_pkey PRIMARY KEY (transfer_id);


--
-- Name: loan_payments uq_loan_payment_number; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT uq_loan_payment_number UNIQUE (loan_id, payment_number);


--
-- Name: idx_transactions_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transactions_date ON public.transactions USING btree (transaction_date);


--
-- Name: idx_transactions_from_account; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transactions_from_account ON public.transactions USING btree (from_account_id);


--
-- Name: idx_transactions_to_account; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transactions_to_account ON public.transactions USING btree (to_account_id);


--
-- Name: account_holders account_holders_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_holders
    ADD CONSTRAINT account_holders_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(account_id);


--
-- Name: account_holders account_holders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account_holders
    ADD CONSTRAINT account_holders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: accounts accounts_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id);


--
-- Name: employees employees_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id);


--
-- Name: bank_shareholders fk_shareholders_customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_shareholders
    ADD CONSTRAINT fk_shareholders_customer FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: transfers fk_transfers_from_account; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT fk_transfers_from_account FOREIGN KEY (from_account_id) REFERENCES public.accounts(account_id);


--
-- Name: transfers fk_transfers_to_account; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT fk_transfers_to_account FOREIGN KEY (to_account_id) REFERENCES public.accounts(account_id);


--
-- Name: loan_payments loan_payments_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT loan_payments_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(account_id);


--
-- Name: loan_payments loan_payments_loan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_payments
    ADD CONSTRAINT loan_payments_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES public.loans(loan_id);


--
-- Name: loans loans_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.employees(employee_id);


--
-- Name: loans loans_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id);


--
-- Name: loans loans_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: transactions transactions_from_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_from_account_id_fkey FOREIGN KEY (from_account_id) REFERENCES public.accounts(account_id);


--
-- Name: transactions transactions_to_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_to_account_id_fkey FOREIGN KEY (to_account_id) REFERENCES public.accounts(account_id);


--
-- PostgreSQL database dump complete
--

\unrestrict 6NyOiWeKX1WFi8pf941qQYXBbenyyK1FlDhYm38gWI8FWfrtY33ghBcP7XEb9sF

