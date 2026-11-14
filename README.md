# Northstar Bank: React → API → PostgreSQL

All ten existing screens now load database rows and send additions/edits/deletions to the API. English database enums are translated into Russian labels. Browser demo data has been removed.

## Local setup (Windows)

1. Install Node.js 22 or newer. Keep PostgreSQL running.
2. Extract this project and open its folder in VS Code.
3. Copy `.env.example` to `.env`. Set PGDATABASE to your actual database name, PGUSER and PGPASSWORD to your PostgreSQL login. Never upload `.env` to GitHub.
4. Generate an API token:

   ```powershell
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```

   Paste it into API_TOKEN in `.env`. This is separate from your PostgreSQL password.
5. In the terminal run:

   ```powershell
   npm ci
   npm run server
   ```

6. In a second terminal in the same folder run:

   ```powershell
   npm run dev -- --host 127.0.0.1
   ```

7. Open http://localhost:5173 and enter API_TOKEN. If Vite selects a different port, free port 5173 or update FRONTEND_ORIGINS accordingly.
8. Add a test customer, then check in pgAdmin:

   ```sql
   SELECT * FROM public.customers ORDER BY customer_id DESC;
   ```

   Refresh the browser and verify the record remains.

## SQL import, only if needed

If your database already contains these tables, do not import again. Configure that database in `.env`.

For a separate new database use PostgreSQL 18 terminal tools. Your uploaded SQL file contains COPY FROM stdin and psql commands; do not paste it into pgAdmin Query Tool.

```powershell
createdb -U postgres bank_project
psql -X -v ON_ERROR_STOP=1 -U postgres -d bank_project -f "C:\path\bank_database(1).sql"
```

Set PGDATABASE=bank_project afterward. On Windows, executables are commonly in `C:\Program Files\PostgreSQL\18\bin`; use full paths if commands are not found. The dump expects a postgres role and was exported from PostgreSQL 18.3. The SQL dump is not included in this archive: use your existing file.

## Connect the published GitHub Pages website

The steps above connect your LOCAL copy. They do not change the published website.

1. Host the backend on a Node server with access to PostgreSQL. Install using `npm ci`; start using `node server/index.js`.
2. Set server environment variables API_TOKEN, PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD (or DATABASE_URL), HOST=0.0.0.0, and the host-assigned PORT. Use verified TLS if the database provider requires it.
3. Include `https://maratovaaizere.github.io` in FRONTEND_ORIGINS. The backend needs an HTTPS address. A remote server cannot access PostgreSQL on your laptop using localhost.
4. Upload the changed project files to your existing bank-frontend repository. Exclude `.env`, node_modules, dist and SQL dumps.
5. In repository Settings → Secrets and variables → Actions → Variables, create VITE_API_URL containing the HTTPS backend URL without `/api`. This URL is public: it must not contain passwords or tokens.
6. Re-run the Publish website workflow. It now passes VITE_API_URL into the build.
7. Open your GitHub Pages site and enter API_TOKEN.

## Scope and checks

This application is intended for local development and demonstration. Inserting transactions, transfers or loan payments records rows; it does not debit or credit balances or execute payments. PostgreSQL constraints remain authoritative. The existing ownership-total check is a frontend convenience, not a concurrency-safe database rule.

The shared API token gives full table access and is kept in sessionStorage. Use coursework/test data. Individual user accounts, roles, audit logging and production banking rules are not implemented.

`npm test` checks enum translation, authentication, CORS and invalid requests. `npm run build -- --base=/bank-frontend/` checks the frontend build. These tests do not establish connectivity to your PostgreSQL instance; complete the test-record step with your own credentials.

## Credit scoring + SQL JOIN

The **Кредитный скоринг** sidebar page calls authenticated `GET /api/credit-scoring`.
PostgreSQL `LEFT JOIN` combines customers with aggregated loans, loan payments, and account holders/accounts (`JOIN`). Aggregation before joining prevents multiplying payment and balance records. Balances count only KZT and are weighted by ownership percentage. The provisional internal score (300–850) considers late payments, loan history, active loans, accounts, and KZT balance. This is **not** a validated credit bureau score and must not be used for real lending decisions. No schema migration is required.

## Banking analytics and access management

The sidebar contains **«Аналитика и доступ»**, an operational dashboard with three sections:

- **Клиенты и счета**: account balances, current loans, and editable contact information.
- **Филиальная сеть**: account and loan counts plus KZT balances. A manual refresh updates the stored summary.
- **Роли и доступ**: read-only database roles, login and administrative privileges, and group memberships.

The roles section uses `GET /api/bank-access/roles`. It loads separately from reports, so it stays accessible even if reporting views have not been initialized. No PDF, lecture reference, or training UI is included.

### PostgreSQL setup

Keep the existing bank data and your existing `.env` unchanged. Back up the project before replacing its files.

For the account and branch reporting sections, apply the idempotent migration once:

```bash
psql -U postgres -h localhost -p 5432 -d bank_database -v ON_ERROR_STOP=1 -f database/bank_analytics.sql
```

It creates the required views and materialized summary (without deleting any existing customer records). It creates two NOLOGIN reporting groups and, if the earlier groups are present, renames them to `bank_reporting_reader` and `bank_reporting_analyst`, preserving their permissions and memberships. If the role names already exist, the migration does not rename them again. Use the actual database name from `PGDATABASE` if it is different.

Open two VS Code terminals in `bank-frontend`:

```bash
npm run server
```

```bash
npm run dev
```

Visit `http://localhost:5173` (or the port reported by Vite), open **«Аналитика и доступ»**, then select a section card.

### PostgreSQL objects

- `v_customer_accounts`: dynamically combines customer, ownership, and account data for total balances.
- `v_active_loans`: filters the current loan portfolio with enum-safe comparisons.
- `v_customer_contacts_editable`: supports limited edits to email/phone via the authenticated API.
- `v_customers_with_email`: restricts updates through this particular view to contacts with an email.
- `mv_branch_statistics`: stores aggregated branch results, refreshed via its unique index.
- `pg_roles`: the API only reads role attributes. Granting permissions is intentionally not exposed to the website.

**Security note:** This is an administrative demo with one shared API token rather than individual user logins. Do not expose it publicly with real banking information or a PostgreSQL superuser account.
