# Korgaonkar Care AI

The advanced upgrade is documented in [UPGRADE.md](UPGRADE.md), including completed/pending features, operations APIs, roles, architecture and demo instructions. The earlier HealthSathi implementation notes below describe the preserved foundation; the upgrade status takes precedence.

# HealthSathi Goa — educational hospital service assistant

A professional educational portal for hospital navigation and simulated appointment booking. It runs on React/Vinext with Cloudflare Workers and D1 (SQLite), without paid AI APIs. The hosted Site remains private to its owner.

## What is implemented

| Feature | Behaviour |
| --- | --- |
| Doctor search and recommendation | Search by name or speciality; concept aliases such as skin specialist; filter by hospital and OPD weekday. Profiles show illustrative qualifications, languages and experience. |
| OPD schedules and slots | Server-backed doctor schedules and offered half-hour slots for the next 28 days; holidays and closed slots excluded. |
| Guided chatbot booking | Speciality → hospital → doctor → date/time → fictional patient name. Supports typed follow-ups and action buttons. |
| Booking lifecycle | Save a request with ID, view, atomically reschedule, cancel, or delete. Status is always awaiting hospital confirmation or cancelled; never falsely confirmed. |
| Double-booking prevention | SQLite partial unique index on active `bookings.slot_id`; validation and mutation are one SQL statement. Concurrent requests cannot reserve the same slot. Failed rescheduling retains the original slot. |
| Reminders | Opt-in appointment reminders plus one-time/daily/weekly user-entered appointment, prescribed-medication, test and follow-up reminders. In-app due notices and calendar alarms; no SMS, email or WhatsApp delivery. No drug or dose recommendation. |
| Report terminology | Authenticated, consent-gated comparison of fictional numeric values with user-supplied lab ranges; cited test definitions and questions for the clinician. Values are not stored. Not diagnosis, critical-value detection or clinical report interpretation. |
| Staff handover | Demo Reception/Billing/Nursing inbox, explicit consent for optional reviewed conversation excerpts, administrator replies, and user-controlled deletion. No real hospital staff receive these requests. |
| Facilities and navigation | Unconnected bed/ICU/MRI/CT/lab/pharmacy status; clearly labelled fictional floor routes, with an admin layout editor. No fabricated live availability or actual GMC floor directions. |
| Consultation fees | Editable illustrative INR fees; unconfigured fees are shown as unknown. The administrator can populate example fees for seeded demo profiles. No payments. |
| Hospital locator | Verified GMC location and links to the official Goa directory and map directions. No location collection, live distances or invented clinic addresses. |
| Service information | Official ORS registration, blood stock lookup, eSanjeevani, government scheme resources; lab and pharmacy guidance without medical recommendations. |
| Feedback | Signed-in users submit ratings/comments and delete their own feedback. |
| Administration | Server-side owner allowlist; edit demo doctors, schedules, department display names, individual slot availability and holidays; generate future slots; inspect aggregate analytics. |
| Accessibility | Native dialog keyboard focus, labelled inputs, screen-reader live chat, large text, high contrast, read aloud, optional voice transcription where browser-supported. |
| Data preservation | Earlier-version appointment requests are retained and accessible under My appointments → Earlier project requests. |

## AI and ML

- Supervised multinomial Naive Bayes: 96 labeled examples, 12 intents, Laplace smoothing and confidence thresholding.
- TF-IDF cosine retrieval and vocabulary coverage checks; unknown questions ask for clarification.
- Session-only context for department, hospital, doctor and displayed slots.
- Concept-expanded retrieval over eight curated official-source summaries, with citation links and verification dates. This is extractive RAG-style grounding, **not an LLM generator or neural embedding model**.
- Explainable doctor ranking by requested speciality/name, with hospital/day filtering; not clinical recommendations.
- Experimental English/Hindi/Konkani/Marathi service phrase normalization. Hindi/Konkani/Marathi are **not professionally reviewed**, and responses remain English. This is not a trained multilingual model. Konkani voice input is explicitly unavailable; other voice support depends on the browser.
- Deterministic emergency phrase routing to official Indian emergency guidance (112), independent of ML confidence. Not clinical triage and not guaranteed to detect every urgent phrase.
- Cautious service navigation for selected symptom phrases, including frequent headaches to General Medicine, with emergency-language overrides. Not clinical triage or a validated referral model.
- Opt-in aggregate daily intent counts, measured response-time samples and department inquiry counts. Analytics stores no transcript, user ID or session ID. Admin metrics include request demand, escalation counts and the separate fixed benchmark; usage and clarification rate are not represented as real-world accuracy. Older untimed events are excluded from timing averages. Authentication providers still process normal requests.

The fixed 24-phrase held-out demonstration set gives 24/24 top-1 matches and 22/24 correct accepted responses. It is small and hand-written, not evidence of real-world or clinical accuracy. Model scores are not calibrated probabilities.

## External systems — not connected

Real hospital acceptance/verification, live queues and waiting times, live blood/pharmacy stock, teleconsultation booking, SMS/email/WhatsApp delivery, real patient records, ABDM and ORS APIs are not connected. Official portal links are provided instead. ORS/eHospital/ABDM integrations require authorised access, implementation and security validation; no fake API integration or clinical confirmation is shown.

GMC is a real institution, but every doctor profile, qualification, OPD schedule and slot in this project is fictional. North Goa Learning Clinic and South Goa Learning Hospital are entirely fictional. Use fictional patient data only.

## Running locally

Requires Node 22.13+ and npm. The project was built using Node 22.23.4.

1. `npm install`
2. Create an ignored `.dev.vars` containing `ADMIN_EMAIL="seedy@sites.test"` for the starter's local mock identity.
3. `npm run build`
4. On a fresh local database, apply each migration once, in order:
   - `node --import ./scripts/sites-env.mjs ./node_modules/wrangler/bin/wrangler.js d1 execute DB --local --config dist/server/wrangler.json --persist-to .wrangler/state --file drizzle/0000_quiet_loki.sql`
   - `node --import ./scripts/sites-env.mjs ./node_modules/wrangler/bin/wrangler.js d1 execute DB --local --config dist/server/wrangler.json --persist-to .wrangler/state --file drizzle/0001_loud_weapon_omega.sql`
   - Apply `drizzle/0002_cool_gressill.sql` and then `drizzle/0003_bored_thena.sql` using the same D1 command above and their respective filenames.
5. `npm run dev`
6. Visit `/signin-with-chatgpt?return_to=/` on the printed local URL. The starter simulates local sign-in. The configured administrator's first directory load initializes illustrative hospital data; no schema changes occur at request time.

The hosted deployment uses a secret `ADMIN_EMAIL` matching the Site owner's authenticated email. No local mock identity is deployed. Signing in does not itself confer admin access. Never put service keys in client code.

## Validation

- `node node_modules/typescript/bin/tsc --noEmit`
- `node scripts/test-ml.mjs`
- `node scripts/test-hospital.mjs`
- With the local development server running: `node scripts/test-api.mjs` and `node scripts/test-support.mjs`

The local API test creates and removes QA records. It checks anonymous access rejection, origin enforcement, concurrent slot collision, atomic rescheduling, cancellation, holiday/slot blocking, feedback and input validation. Do not point it at production.

## Architecture

- `app/dashboard.tsx`: portal shell, guided chat, voice/accessibility controls.
- `app/patient-features.tsx`: doctor search, slot picker, appointment lifecycle and calendar export.
- `app/admin-panel.tsx`, `app/support-admin.tsx`: restricted demo administration, internal staff replies, sample layouts and analytics.
- `app/care-tools.tsx`, `app/clinical-support.ts`: report terminology, reminders, handover and facility UI; bounded service navigation and pure numeric comparison.
- `app/api/support/route.ts`: authenticated report processing, reminders, handovers and layouts.
- `app/services.tsx`: verified-source library, hospital locator, feedback.
- `app/ml.ts`: intent training corpus, classifier and evaluation.
- `app/knowledge.ts`: reviewed-for-source summaries, retrieval and experimental phrase normalization.
- `app/api/hospital/route.ts`: authenticated APIs and atomic bookings.
- `db/schema.ts`, `drizzle/`: schema and append-only migrations.

## Cost

No paid AI API, messaging provider, payment processor or custom domain is required. Local use is free. Hosting and D1 are provisioned through Sites and subject to account access/quotas; unlimited free hosting is not guaranteed. Cloudflare separately offers Workers and D1 free plans with quotas. A standalone Cloudflare deployment requires replacing Sites-managed authentication and configuring bindings; it is not a one-click independent deployment.

Official references checked 8 November 2026:
- https://ors.gov.in/faq.html
- https://www.mha.gov.in/emergency-response-support-system-erss
- https://www.goa.gov.in/department/goa-medical-college-and-hospital/
- https://nhm.goa.gov.in/health-centers-hospitals/
- https://eraktkosh.mohfw.gov.in/BLDAHIMS/bloodbank/stockAvailability.cnt
- https://esanjeevani.mohfw.gov.in/
- https://dhs.goa.gov.in/pages/details/Schemes/deen-dayal-swasthya-seva-yojana
- https://beneficiary.nha.gov.in/
- https://developers.cloudflare.com/workers/platform/pricing/
- https://developers.cloudflare.com/d1/platform/pricing/

Additional official clinical-information sources (checked 8 November 2026):
- https://medlineplus.gov/lab-tests/how-to-understand-your-lab-results/
- https://medlineplus.gov/lab-tests/complete-blood-count-cbc/
- https://medlineplus.gov/lab-tests/blood-glucose-test/
- https://medlineplus.gov/lab-tests/creatinine-test/
- https://www.nhs.uk/symptoms/headaches/

Report values remain only in request/response memory and the current browser state; they are not persisted by this application. This does not replace hospital patient verification or constitute a clinical deployment. Clear values or leave the page to discard the report-helper state.
