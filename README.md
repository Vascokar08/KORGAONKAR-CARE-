# Korgaonkar Care AI

Korgaonkar Care AI is an educational hospital service chatbot built for the Natural Language Processing and Applications Lab. It demonstrates role-aware chatbot navigation, doctor discovery, appointment requests, hospital service guidance, staff operations, reminders, feedback collection, and database-backed workflows using fictional records.

This project is a demonstration system. It is not connected to real patient records, hospital acceptance systems, live queues, pharmacy stock, or clinical decision-making.

## Objectives

- Provide a simple chatbot entry point for Patient Mode and Staff Mode.
- Demonstrate NLP-based intent recognition and source-backed hospital information.
- Help patients find a doctor, choose a department, and request a demo appointment.
- Demonstrate staff workflows for resources, doctor workspace, appointment decisions, reports, reminders, support, and feedback.
- Keep appointment and operational changes validated by the server and database.
- Make the project understandable, testable, and suitable for academic demonstration.

## Chatbot modes

The Care Assistant opens with two chatbot options: **Patient** and **Staff**. The Return Home action resets the conversation and returns to this mode-selection screen without a page refresh.

### Patient Mode

- Find a dermatologist or another department through the chatbot.
- Open **Doctor & OPD** to search doctors by name, speciality, hospital, and weekday.
- View illustrative consultation timing, availability, profile information, and fees where configured.
- Use **Book a Visit** to select a doctor, date, and available time slot.
- View booking IDs and manage demo appointments, including rescheduling and cancellation.
- Use care reminders and submit feedback.
- Reports are intentionally hidden from Patient Mode in this demonstration.

### Staff Mode

- Review hospital resources and fictional capacity records.
- Open the Doctor Workspace to view upcoming demo appointments.
- Accept or decline appointments awaiting hospital confirmation.
- Open Reports & Terms, Care Reminders, Staff Support, and Feedback.
- Use role-controlled staff operations backed by server-side permission checks.

All appointment decisions are clearly labelled as demonstration actions. They do not confirm a real hospital appointment.

## NLP and machine-learning techniques

- Text normalization and intent routing for common hospital-service questions.
- A small supervised intent classifier using labelled examples and Naive Bayes-style probability estimates.
- TF-IDF cosine retrieval over a curated collection of official healthcare information.
- Concept expansion for phrases such as “skin specialist” and “dermatologist.”
- Deterministic emergency-language routing that directs users to emergency help instead of diagnosing.
- Session context for the selected department, hospital, doctor, and displayed slots.
- Optional browser speech recognition and text-to-speech; availability depends on the browser.

No generative AI API is required. The model and retrieval outputs are educational, bounded, and not clinical diagnoses.

## Technology stack

| Layer | Technology | Purpose |
| --- | --- | --- |
| Interface | React 19, TypeScript, Vite/Vinext | Responsive chatbot and dashboards |
| Styling | CSS, Lucide React | Healthcare-themed layout and icons |
| NLP | TypeScript intent routing, Naive Bayes-style classifier, TF-IDF retrieval | Intent recognition and source-backed responses |
| Patient workflows | React components and typed API calls | Doctor search, slots, booking, cancellation, rescheduling |
| Staff workflows | React operations components and server routes | Resources, doctor workspace, appointment decisions, support |
| Database | Supabase/Postgres for Netlify; Cloudflare D1 for the original local target | Fictional doctors, schedules, bookings, resources, feedback, and audit records |
| Validation | TypeScript, Vite production build, database integration tests | Regression and deployment checks |

## Appointment workflow

1. The patient selects Patient Mode and chooses Doctor & OPD or Book a Visit.
2. The chatbot or directory filters doctors and displays available demo schedules.
3. The patient selects a doctor, date, and offered time slot.
4. The booking form collects fictional patient details and consent fields.
5. The server validates the slot and prevents active double bookings.
6. A booking ID is displayed after the database confirms the request.
7. The request remains awaiting hospital confirmation until an authorised Staff Workspace user accepts or declines it.
8. Patients can view, reschedule, or cancel their own demo requests.

## Feedback and navigation

The chatbot provides a Give Feedback action after role selection and after relevant responses. The Feedback page supports educational ratings, comments, complaints, and improvement suggestions. The reusable Home action returns to the Patient/Staff chatbot selection and clears only the current conversation state.

## Project structure

```text
app/
  dashboard.tsx             Main chatbot shell, modes, navigation, and chat actions
  patient-features.tsx      Doctor directory, booking dialog, and patient bookings
  operations.tsx            Resources, queue tools, and staff workspace
  care-tools.tsx            Reports, reminders, staff support, and facility tools
  services.tsx              Feedback, official information, and hospital locator
  chat.ts                   Intent response logic and conversation context
  knowledge.ts              Curated documents and TF-IDF retrieval
  ml.ts                     Local classifier and evaluation data
  api/hospital/route.ts     Doctor, slot, booking, feedback, and analytics APIs
  api/operations/route.ts   Staff resources, queues, roles, and appointment decisions
db/                         Database schema and migrations
netlify/runtime/            Netlify API adapter and Supabase/Postgres connection
scripts/                    Build and integration-test helpers
public/                     Static assets
README.md                   This project guide
```

## Run locally

Requirements: Node.js 22.13 or newer and npm.

```bash
npm install
npm run dev
```

For the Netlify bundle:

```bash
npm run build:netlify
```

The hosted deployment requires Supabase/Postgres configuration through Netlify environment variables. Never commit database passwords, service keys, or private tokens. Use fictional patient data only.

## Validation commands

```bash
npx tsc --noEmit
npm run build:netlify
node scripts/test-netlify.mjs
```

The integration test covers schema setup, fixtures, appointment conflicts, ownership, rescheduling failure behavior, analytics, staff restrictions, and transaction rollback.

## Screenshots

Add current screenshots to the report or project presentation using these suggested captions:

- **Figure 1:** Care Assistant chatbot with Patient and Staff options.
- **Figure 2:** Patient Mode Doctor & OPD directory and Book a Visit flow.
- **Figure 3:** Staff Workspace with Accept and Decline appointment actions.
- **Figure 4:** Feedback form and staff support workflow.

## Limitations and future enhancements

The project uses fictional doctors, schedules, patients, and resource values. It does not provide diagnosis, live queue data, medical-record access, live hospital acceptance, pharmacy inventory, SMS, email, WhatsApp, or real insurance processing. Staff permissions are demonstration permissions and require deployment-specific authentication configuration.

Future work could connect an authorised hospital scheduling system, add audited patient authentication, integrate a verified multilingual model, add accessibility-tested voice services, and conduct independent NLP evaluation with a larger reviewed dataset.

## Deployment

The educational deployment is available at [korgaonkar-care-ai.netlify.app](https://korgaonkar-care-ai.netlify.app). The GitHub repository is [Vascokar08/KORGAONKAR-CARE-](https://github.com/Vascokar08/KORGAONKAR-CARE-).

