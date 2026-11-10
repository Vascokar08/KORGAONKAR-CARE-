# Netlify deployment

The Netlify target uses React + Vite, Node serverless functions, and Supabase Postgres and verified-email authentication. The original Sites/Cloudflare target remains available with `npm run build`.

1. Create a Supabase **Free** project. Disable automatic table exposure and enable automatic row-level security.
2. Run `netlify/migrations/001_initial.sql` once using the project's SQL editor. It creates a private `care` schema, foreign keys, unique booking/queue constraints and fictional fixtures. No patient data is migrated from the separate Sites deployment.
3. Set these Netlify environment variables, never commit their values:
   - `DATABASE_URL`: Supabase transaction-pooler connection URL, using TLS (`sslmode=require`). The password can be omitted from this URL and supplied separately below.
   - `PGPASSWORD`: database password, stored as a Netlify secret in the Production context. Never expose it in browser code or commit it. Free Legacy plans limit scope controls; keep untrusted deploy approval enabled.
   - `SUPABASE_URL`: project API URL.
   - `SUPABASE_ANON_KEY`: public publishable/anon API key. This is intentionally sent to the client; never use a service-role key here.
   - `ADMIN_EMAIL`: verified email of the demo administrator.
   - `PUBLIC_DEMO_ADMIN`: optional safety switch. It defaults to public demo admin mode for this fictional deployment; set it to `false` before using any real patient data. Public mode uses a shared demo identity.
4. Import the GitHub repository in Netlify. Build: `npm run build:netlify`; publish: `netlify-dist`; Node 22. `netlify.toml` configures functions and SPA routing.
5. Set the Supabase Auth Site URL and allowed redirect URL to the deployed Netlify HTTPS origin. Email verification must remain enabled. Register and confirm the administrator account using the exact `ADMIN_EMAIL`.
6. Verify `/api/health`, the doctor directory, sign-in, booking conflict protection and staff restrictions.

Public visitors can explore the chatbot and doctor directory. This project is configured as a public educational demo, so the homepage does not show a sign-in option and the admin dashboard uses a shared fictional demo identity. Do not store real patient information while `PUBLIC_DEMO_ADMIN=true`; turn it off before any real deployment. Incoming Sites identity headers are ignored on Netlify. All SQL uses bound parameters, and batch writes use database transactions. The private schema is inaccessible through the browser Data API.

Free plans have quotas; Supabase free projects can pause when inactive. This is an educational demonstration, not a clinical system. Use fictional records. Existing Sites sign-ins and records are separate; the Netlify earlier-requests list is empty. No paid AI API is needed.

Local verification: `node scripts/prepare-postgres.mjs`, `node scripts/test-netlify.mjs`, `npm run build:netlify`. The test database is an isolated in-memory Postgres engine; no production data is used.

