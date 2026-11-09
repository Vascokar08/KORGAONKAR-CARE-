BEGIN;
CREATE SCHEMA IF NOT EXISTS care;
SET LOCAL search_path=care,public;
CREATE TABLE IF NOT EXISTS "appointments" (
	"id" text PRIMARY KEY NOT NULL,
	"owner" text NOT NULL,
	"name" text NOT NULL,
	"department" text NOT NULL,
	"date" text NOT NULL,
	"time" text NOT NULL,
	"created_at" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "bookings" (
	"id" text PRIMARY KEY NOT NULL,
	"owner" text NOT NULL,
	"name" text NOT NULL,
	"slot_id" text NOT NULL,
	"status" text DEFAULT 'awaiting_hospital_confirmation' NOT NULL,
	"reminder" integer DEFAULT 0 NOT NULL,
	"created_at" text NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "one_active_booking_per_slot" ON "bookings" ("slot_id") WHERE "bookings"."status" != 'cancelled';
CREATE TABLE IF NOT EXISTS "departments" (
	"id" text PRIMARY KEY NOT NULL,
	"hospital_id" text NOT NULL,
	"name" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "doctors" (
	"id" text PRIMARY KEY NOT NULL,
	"hospital_id" text NOT NULL,
	"department_id" text NOT NULL,
	"name" text NOT NULL,
	"speciality" text NOT NULL,
	"qualification" text NOT NULL,
	"experience" integer NOT NULL,
	"languages" text NOT NULL,
	"active" integer DEFAULT 1 NOT NULL

);

CREATE TABLE IF NOT EXISTS "feedback" (
	"id" text PRIMARY KEY NOT NULL,
	"owner" text NOT NULL,
	"rating" integer NOT NULL,
	"topic" text NOT NULL,
	"comment" text NOT NULL,
	"created_at" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "holidays" (
	"id" text PRIMARY KEY NOT NULL,
	"hospital_id" text NOT NULL,
	"date" text NOT NULL,
	"reason" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "hospitals" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"area" text NOT NULL,
	"address" text NOT NULL,
	"url" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "doctor_schedules" (
	"id" text PRIMARY KEY NOT NULL,
	"doctor_id" text NOT NULL,
	"weekday" integer NOT NULL,
	"start" text NOT NULL,
	"end" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "appointment_slots" (
	"id" text PRIMARY KEY NOT NULL,
	"doctor_id" text NOT NULL,
	"date" text NOT NULL,
	"time" text NOT NULL,
	"active" integer DEFAULT 1 NOT NULL
);

CREATE TABLE IF NOT EXISTS "usage_totals" (
	"id" text PRIMARY KEY NOT NULL,
	"day" text NOT NULL,
	"intent" text NOT NULL,
	"count" integer DEFAULT 0 NOT NULL
);

CREATE TABLE IF NOT EXISTS "department_usage" (
	"id" text PRIMARY KEY NOT NULL,
	"department" text NOT NULL,
	"day" text NOT NULL,
	"count" integer DEFAULT 0 NOT NULL
);

CREATE TABLE IF NOT EXISTS "facility_directory" (
	"id" text PRIMARY KEY NOT NULL,
	"hospital_id" text NOT NULL,
	"name" text NOT NULL,
	"building" text NOT NULL,
	"floor" text NOT NULL,
	"room" text NOT NULL,
	"directions" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "followup_reminders" (
	"id" text PRIMARY KEY NOT NULL,
	"owner" text NOT NULL,
	"kind" text NOT NULL,
	"title" text NOT NULL,
	"starts_at" text NOT NULL,
	"frequency" text NOT NULL,
	"ends_on" text NOT NULL,
	"consent" integer DEFAULT 0 NOT NULL
);

CREATE TABLE IF NOT EXISTS "staff_requests" (
	"id" text PRIMARY KEY NOT NULL,
	"owner" text NOT NULL,
	"team" text NOT NULL,
	"subject" text NOT NULL,
	"message" text NOT NULL,
	"history" text NOT NULL,
	"history_consent" integer DEFAULT 0 NOT NULL,
	"status" text DEFAULT 'awaiting_demo_staff' NOT NULL,
	"reply" text DEFAULT '' NOT NULL,
	"created_at" text NOT NULL
);

ALTER TABLE "doctors" ADD COLUMN IF NOT EXISTS "fee" integer DEFAULT 0 NOT NULL;
ALTER TABLE "usage_totals" ADD COLUMN IF NOT EXISTS "duration_total" integer DEFAULT 0 NOT NULL;
ALTER TABLE "usage_totals" ADD COLUMN IF NOT EXISTS "fallback_count" integer DEFAULT 0 NOT NULL;
ALTER TABLE "usage_totals" ADD COLUMN IF NOT EXISTS "measured_count" integer DEFAULT 0 NOT NULL;
CREATE TABLE IF NOT EXISTS "doctor_presence" (
	"doctor_id" text PRIMARY KEY NOT NULL,
	"available" integer NOT NULL,
	"updated_at" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "hospital_resources" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"kind" text NOT NULL,
	"capacity" integer NOT NULL,
	"available" integer NOT NULL,
	"status" text NOT NULL,
	"updated_at" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "operations_audit" (
	"id" text PRIMARY KEY NOT NULL,
	"actor" text NOT NULL,
	"action" text NOT NULL,
	"target" text NOT NULL,
	"created_at" text NOT NULL
);

CREATE TABLE IF NOT EXISTS "queue_tokens" (
	"id" text PRIMARY KEY NOT NULL,
	"doctor_id" text NOT NULL,
	"day" text NOT NULL,
	"token" integer NOT NULL,
	"owner" text NOT NULL,
	"booking_id" text,
	"status" text DEFAULT 'waiting' NOT NULL,
	"created_at" text NOT NULL,
	"called_at" text,
	"completed_at" text
);

CREATE UNIQUE INDEX IF NOT EXISTS "queue_number" ON "queue_tokens" ("doctor_id","day","token");
CREATE UNIQUE INDEX IF NOT EXISTS "queue_booking" ON "queue_tokens" ("booking_id");
CREATE UNIQUE INDEX IF NOT EXISTS "queue_serving" ON "queue_tokens" ("doctor_id","day") WHERE "queue_tokens"."status" = 'serving';
CREATE TABLE IF NOT EXISTS "staff_roles" (
	"email" text PRIMARY KEY NOT NULL,
	"role" text NOT NULL,
	"doctor_id" text
);


UPDATE hospitals SET name='Korgaonkar Multispeciality Hospital (Demo)',area='Fictional main campus',address='Sample campus - no real hospital address',url='' WHERE id='gmc';

UPDATE hospitals SET name='Korgaonkar North Clinic (Demo)' WHERE id='north-demo';

UPDATE hospitals SET name='Korgaonkar South Hospital (Demo)' WHERE id='south-demo';

ALTER TABLE "bookings" ADD FOREIGN KEY ("slot_id") REFERENCES "appointment_slots"("id") ON UPDATE no action ON DELETE no action;
ALTER TABLE "departments" ADD FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON UPDATE no action ON DELETE no action;
ALTER TABLE "doctors" ADD FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON UPDATE no action ON DELETE no action;
ALTER TABLE "doctors" ADD FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON UPDATE no action ON DELETE no action;
ALTER TABLE "holidays" ADD FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON UPDATE no action ON DELETE no action;
ALTER TABLE "doctor_schedules" ADD FOREIGN KEY ("doctor_id") REFERENCES "doctors"("id") ON UPDATE no action ON DELETE no action;
ALTER TABLE "appointment_slots" ADD FOREIGN KEY ("doctor_id") REFERENCES "doctors"("id") ON UPDATE no action ON DELETE no action;
ALTER TABLE "facility_directory" ADD FOREIGN KEY ("hospital_id") REFERENCES "hospitals"("id") ON UPDATE no action ON DELETE no action;
ALTER TABLE "doctor_presence" ADD FOREIGN KEY ("doctor_id") REFERENCES "doctors"("id") ON UPDATE no action ON DELETE no action;
ALTER TABLE "queue_tokens" ADD FOREIGN KEY ("doctor_id") REFERENCES "doctors"("id") ON UPDATE no action ON DELETE no action;
INSERT INTO hospitals ("id","name","area","address","url") VALUES ('gmc','Korgaonkar Multispeciality Hospital (Demo)','Fictional main campus','Sample campus · no real hospital address','') ON CONFLICT DO NOTHING;
INSERT INTO hospitals ("id","name","area","address","url") VALUES ('north-demo','Korgaonkar North Clinic (Demo)','Mapusa','Mapusa area · fictional demonstration location','') ON CONFLICT DO NOTHING;
INSERT INTO hospitals ("id","name","area","address","url") VALUES ('south-demo','Korgaonkar South Hospital (Demo)','Margao','Margao area · fictional demonstration location','') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('gmc-dep0','gmc','General medicine') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('gmc-dep1','gmc','Cardiology') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('gmc-dep2','gmc','Pediatrics') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('gmc-dep3','gmc','Orthopedics') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('gmc-dep4','gmc','Dermatology') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('gmc-dep5','gmc','Diagnostics') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('north-demo-dep0','north-demo','General medicine') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('north-demo-dep1','north-demo','Cardiology') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('north-demo-dep2','north-demo','Pediatrics') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('north-demo-dep3','north-demo','Orthopedics') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('north-demo-dep4','north-demo','Dermatology') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('north-demo-dep5','north-demo','Diagnostics') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('south-demo-dep0','south-demo','General medicine') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('south-demo-dep1','south-demo','Cardiology') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('south-demo-dep2','south-demo','Pediatrics') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('south-demo-dep3','south-demo','Orthopedics') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('south-demo-dep4','south-demo','Dermatology') ON CONFLICT DO NOTHING;
INSERT INTO departments ("id","hospital_id","name") VALUES ('south-demo-dep5','south-demo','Diagnostics') ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('gmc-d0','gmc','gmc-dep0','Dr. A (Demo)','General medicine','MBBS, MD/MS (sample)',6,'English, Hindi, Konkani (sample)',1,400) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('gmc-d1','gmc','gmc-dep1','Dr. B (Demo)','Cardiology','MBBS, MD/MS (sample)',7,'English, Hindi, Konkani (sample)',1,450) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('gmc-d2','gmc','gmc-dep2','Dr. C (Demo)','Pediatrics','MBBS, MD/MS (sample)',8,'English, Hindi, Konkani (sample)',1,500) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('gmc-d3','gmc','gmc-dep3','Dr. D (Demo)','Orthopedics','MBBS, MD/MS (sample)',9,'English, Hindi, Konkani (sample)',1,550) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('gmc-d4','gmc','gmc-dep4','Dr. E (Demo)','Dermatology','MBBS, MD/MS (sample)',10,'English, Hindi, Konkani (sample)',1,600) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('gmc-d5','gmc','gmc-dep5','Dr. F (Demo)','Diagnostics','MD, Radiodiagnosis (sample)',11,'English, Hindi, Konkani (sample)',1,650) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('north-demo-d0','north-demo','north-demo-dep0','Dr. G (Demo)','General medicine','MBBS, MD/MS (sample)',6,'English, Hindi, Konkani (sample)',1,400) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('north-demo-d1','north-demo','north-demo-dep1','Dr. H (Demo)','Cardiology','MBBS, MD/MS (sample)',7,'English, Hindi, Konkani (sample)',1,450) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('north-demo-d2','north-demo','north-demo-dep2','Dr. I (Demo)','Pediatrics','MBBS, MD/MS (sample)',8,'English, Hindi, Konkani (sample)',1,500) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('north-demo-d3','north-demo','north-demo-dep3','Dr. J (Demo)','Orthopedics','MBBS, MD/MS (sample)',9,'English, Hindi, Konkani (sample)',1,550) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('north-demo-d4','north-demo','north-demo-dep4','Dr. K (Demo)','Dermatology','MBBS, MD/MS (sample)',10,'English, Hindi, Konkani (sample)',1,600) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('north-demo-d5','north-demo','north-demo-dep5','Dr. L (Demo)','Diagnostics','MD, Radiodiagnosis (sample)',11,'English, Hindi, Konkani (sample)',1,650) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('south-demo-d0','south-demo','south-demo-dep0','Dr. M (Demo)','General medicine','MBBS, MD/MS (sample)',6,'English, Hindi, Konkani (sample)',1,400) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('south-demo-d1','south-demo','south-demo-dep1','Dr. N (Demo)','Cardiology','MBBS, MD/MS (sample)',7,'English, Hindi, Konkani (sample)',1,450) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('south-demo-d2','south-demo','south-demo-dep2','Dr. O (Demo)','Pediatrics','MBBS, MD/MS (sample)',8,'English, Hindi, Konkani (sample)',1,500) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('south-demo-d3','south-demo','south-demo-dep3','Dr. P (Demo)','Orthopedics','MBBS, MD/MS (sample)',9,'English, Hindi, Konkani (sample)',1,550) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('south-demo-d4','south-demo','south-demo-dep4','Dr. Q (Demo)','Dermatology','MBBS, MD/MS (sample)',10,'English, Hindi, Konkani (sample)',1,600) ON CONFLICT DO NOTHING;
INSERT INTO doctors ("id","hospital_id","department_id","name","speciality","qualification","experience","languages","active","fee") VALUES ('south-demo-d5','south-demo','south-demo-dep5','Dr. R (Demo)','Diagnostics','MD, Radiodiagnosis (sample)',11,'English, Hindi, Konkani (sample)',1,650) ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d0-1','gmc-d0',1,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d0-3','gmc-d0',3,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d1-2','gmc-d1',2,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d1-5','gmc-d1',5,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d2-1','gmc-d2',1,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d2-3','gmc-d2',3,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d3-2','gmc-d3',2,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d3-5','gmc-d3',5,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d4-1','gmc-d4',1,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d4-3','gmc-d4',3,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d5-2','gmc-d5',2,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('gmc-d5-5','gmc-d5',5,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d0-1','north-demo-d0',1,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d0-3','north-demo-d0',3,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d1-2','north-demo-d1',2,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d1-5','north-demo-d1',5,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d2-1','north-demo-d2',1,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d2-3','north-demo-d2',3,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d3-2','north-demo-d3',2,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d3-5','north-demo-d3',5,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d4-1','north-demo-d4',1,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d4-3','north-demo-d4',3,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d5-2','north-demo-d5',2,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('north-demo-d5-5','north-demo-d5',5,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d0-1','south-demo-d0',1,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d0-3','south-demo-d0',3,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d1-2','south-demo-d1',2,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d1-5','south-demo-d1',5,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d2-1','south-demo-d2',1,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d2-3','south-demo-d2',3,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d3-2','south-demo-d3',2,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d3-5','south-demo-d3',5,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d4-1','south-demo-d4',1,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d4-3','south-demo-d4',3,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d5-2','south-demo-d5',2,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO doctor_schedules ("id","doctor_id","weekday","start","end") VALUES ('south-demo-d5-5','south-demo-d5',5,'10:00','12:00') ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-10-1000','gmc-d1','2026-11-10','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-10-1030','gmc-d1','2026-11-10','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-10-1100','gmc-d1','2026-11-10','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-10-1130','gmc-d1','2026-11-10','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-10-1000','gmc-d3','2026-11-10','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-10-1030','gmc-d3','2026-11-10','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-10-1100','gmc-d3','2026-11-10','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-10-1130','gmc-d3','2026-11-10','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-10-1000','gmc-d5','2026-11-10','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-10-1030','gmc-d5','2026-11-10','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-10-1100','gmc-d5','2026-11-10','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-10-1130','gmc-d5','2026-11-10','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-10-1000','north-demo-d1','2026-11-10','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-10-1030','north-demo-d1','2026-11-10','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-10-1100','north-demo-d1','2026-11-10','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-10-1130','north-demo-d1','2026-11-10','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-10-1000','north-demo-d3','2026-11-10','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-10-1030','north-demo-d3','2026-11-10','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-10-1100','north-demo-d3','2026-11-10','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-10-1130','north-demo-d3','2026-11-10','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-10-1000','north-demo-d5','2026-11-10','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-10-1030','north-demo-d5','2026-11-10','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-10-1100','north-demo-d5','2026-11-10','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-10-1130','north-demo-d5','2026-11-10','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-10-1000','south-demo-d1','2026-11-10','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-10-1030','south-demo-d1','2026-11-10','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-10-1100','south-demo-d1','2026-11-10','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-10-1130','south-demo-d1','2026-11-10','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-10-1000','south-demo-d3','2026-11-10','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-10-1030','south-demo-d3','2026-11-10','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-10-1100','south-demo-d3','2026-11-10','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-10-1130','south-demo-d3','2026-11-10','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-10-1000','south-demo-d5','2026-11-10','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-10-1030','south-demo-d5','2026-11-10','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-10-1100','south-demo-d5','2026-11-10','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-10-1130','south-demo-d5','2026-11-10','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-11-1000','gmc-d0','2026-11-11','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-11-1030','gmc-d0','2026-11-11','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-11-1100','gmc-d0','2026-11-11','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-11-1130','gmc-d0','2026-11-11','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-11-1000','gmc-d2','2026-11-11','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-11-1030','gmc-d2','2026-11-11','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-11-1100','gmc-d2','2026-11-11','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-11-1130','gmc-d2','2026-11-11','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-11-1000','gmc-d4','2026-11-11','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-11-1030','gmc-d4','2026-11-11','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-11-1100','gmc-d4','2026-11-11','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-11-1130','gmc-d4','2026-11-11','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-11-1000','north-demo-d0','2026-11-11','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-11-1030','north-demo-d0','2026-11-11','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-11-1100','north-demo-d0','2026-11-11','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-11-1130','north-demo-d0','2026-11-11','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-11-1000','north-demo-d2','2026-11-11','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-11-1030','north-demo-d2','2026-11-11','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-11-1100','north-demo-d2','2026-11-11','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-11-1130','north-demo-d2','2026-11-11','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-11-1000','north-demo-d4','2026-11-11','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-11-1030','north-demo-d4','2026-11-11','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-11-1100','north-demo-d4','2026-11-11','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-11-1130','north-demo-d4','2026-11-11','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-11-1000','south-demo-d0','2026-11-11','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-11-1030','south-demo-d0','2026-11-11','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-11-1100','south-demo-d0','2026-11-11','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-11-1130','south-demo-d0','2026-11-11','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-11-1000','south-demo-d2','2026-11-11','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-11-1030','south-demo-d2','2026-11-11','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-11-1100','south-demo-d2','2026-11-11','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-11-1130','south-demo-d2','2026-11-11','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-11-1000','south-demo-d4','2026-11-11','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-11-1030','south-demo-d4','2026-11-11','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-11-1100','south-demo-d4','2026-11-11','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-11-1130','south-demo-d4','2026-11-11','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-13-1000','gmc-d1','2026-11-13','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-13-1030','gmc-d1','2026-11-13','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-13-1100','gmc-d1','2026-11-13','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-13-1130','gmc-d1','2026-11-13','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-13-1000','gmc-d3','2026-11-13','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-13-1030','gmc-d3','2026-11-13','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-13-1100','gmc-d3','2026-11-13','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-13-1130','gmc-d3','2026-11-13','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-13-1000','gmc-d5','2026-11-13','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-13-1030','gmc-d5','2026-11-13','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-13-1100','gmc-d5','2026-11-13','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-13-1130','gmc-d5','2026-11-13','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-13-1000','north-demo-d1','2026-11-13','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-13-1030','north-demo-d1','2026-11-13','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-13-1100','north-demo-d1','2026-11-13','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-13-1130','north-demo-d1','2026-11-13','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-13-1000','north-demo-d3','2026-11-13','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-13-1030','north-demo-d3','2026-11-13','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-13-1100','north-demo-d3','2026-11-13','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-13-1130','north-demo-d3','2026-11-13','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-13-1000','north-demo-d5','2026-11-13','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-13-1030','north-demo-d5','2026-11-13','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-13-1100','north-demo-d5','2026-11-13','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-13-1130','north-demo-d5','2026-11-13','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-13-1000','south-demo-d1','2026-11-13','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-13-1030','south-demo-d1','2026-11-13','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-13-1100','south-demo-d1','2026-11-13','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-13-1130','south-demo-d1','2026-11-13','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-13-1000','south-demo-d3','2026-11-13','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-13-1030','south-demo-d3','2026-11-13','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-13-1100','south-demo-d3','2026-11-13','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-13-1130','south-demo-d3','2026-11-13','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-13-1000','south-demo-d5','2026-11-13','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-13-1030','south-demo-d5','2026-11-13','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-13-1100','south-demo-d5','2026-11-13','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-13-1130','south-demo-d5','2026-11-13','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-16-1000','gmc-d0','2026-11-16','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-16-1030','gmc-d0','2026-11-16','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-16-1100','gmc-d0','2026-11-16','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-16-1130','gmc-d0','2026-11-16','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-16-1000','gmc-d2','2026-11-16','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-16-1030','gmc-d2','2026-11-16','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-16-1100','gmc-d2','2026-11-16','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-16-1130','gmc-d2','2026-11-16','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-16-1000','gmc-d4','2026-11-16','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-16-1030','gmc-d4','2026-11-16','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-16-1100','gmc-d4','2026-11-16','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-16-1130','gmc-d4','2026-11-16','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-16-1000','north-demo-d0','2026-11-16','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-16-1030','north-demo-d0','2026-11-16','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-16-1100','north-demo-d0','2026-11-16','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-16-1130','north-demo-d0','2026-11-16','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-16-1000','north-demo-d2','2026-11-16','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-16-1030','north-demo-d2','2026-11-16','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-16-1100','north-demo-d2','2026-11-16','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-16-1130','north-demo-d2','2026-11-16','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-16-1000','north-demo-d4','2026-11-16','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-16-1030','north-demo-d4','2026-11-16','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-16-1100','north-demo-d4','2026-11-16','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-16-1130','north-demo-d4','2026-11-16','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-16-1000','south-demo-d0','2026-11-16','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-16-1030','south-demo-d0','2026-11-16','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-16-1100','south-demo-d0','2026-11-16','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-16-1130','south-demo-d0','2026-11-16','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-16-1000','south-demo-d2','2026-11-16','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-16-1030','south-demo-d2','2026-11-16','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-16-1100','south-demo-d2','2026-11-16','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-16-1130','south-demo-d2','2026-11-16','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-16-1000','south-demo-d4','2026-11-16','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-16-1030','south-demo-d4','2026-11-16','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-16-1100','south-demo-d4','2026-11-16','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-16-1130','south-demo-d4','2026-11-16','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-17-1000','gmc-d1','2026-11-17','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-17-1030','gmc-d1','2026-11-17','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-17-1100','gmc-d1','2026-11-17','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-17-1130','gmc-d1','2026-11-17','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-17-1000','gmc-d3','2026-11-17','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-17-1030','gmc-d3','2026-11-17','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-17-1100','gmc-d3','2026-11-17','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-17-1130','gmc-d3','2026-11-17','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-17-1000','gmc-d5','2026-11-17','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-17-1030','gmc-d5','2026-11-17','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-17-1100','gmc-d5','2026-11-17','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-17-1130','gmc-d5','2026-11-17','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-17-1000','north-demo-d1','2026-11-17','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-17-1030','north-demo-d1','2026-11-17','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-17-1100','north-demo-d1','2026-11-17','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-17-1130','north-demo-d1','2026-11-17','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-17-1000','north-demo-d3','2026-11-17','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-17-1030','north-demo-d3','2026-11-17','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-17-1100','north-demo-d3','2026-11-17','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-17-1130','north-demo-d3','2026-11-17','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-17-1000','north-demo-d5','2026-11-17','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-17-1030','north-demo-d5','2026-11-17','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-17-1100','north-demo-d5','2026-11-17','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-17-1130','north-demo-d5','2026-11-17','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-17-1000','south-demo-d1','2026-11-17','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-17-1030','south-demo-d1','2026-11-17','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-17-1100','south-demo-d1','2026-11-17','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-17-1130','south-demo-d1','2026-11-17','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-17-1000','south-demo-d3','2026-11-17','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-17-1030','south-demo-d3','2026-11-17','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-17-1100','south-demo-d3','2026-11-17','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-17-1130','south-demo-d3','2026-11-17','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-17-1000','south-demo-d5','2026-11-17','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-17-1030','south-demo-d5','2026-11-17','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-17-1100','south-demo-d5','2026-11-17','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-17-1130','south-demo-d5','2026-11-17','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-18-1000','gmc-d0','2026-11-18','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-18-1030','gmc-d0','2026-11-18','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-18-1100','gmc-d0','2026-11-18','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-18-1130','gmc-d0','2026-11-18','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-18-1000','gmc-d2','2026-11-18','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-18-1030','gmc-d2','2026-11-18','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-18-1100','gmc-d2','2026-11-18','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-18-1130','gmc-d2','2026-11-18','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-18-1000','gmc-d4','2026-11-18','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-18-1030','gmc-d4','2026-11-18','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-18-1100','gmc-d4','2026-11-18','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-18-1130','gmc-d4','2026-11-18','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-18-1000','north-demo-d0','2026-11-18','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-18-1030','north-demo-d0','2026-11-18','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-18-1100','north-demo-d0','2026-11-18','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-18-1130','north-demo-d0','2026-11-18','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-18-1000','north-demo-d2','2026-11-18','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-18-1030','north-demo-d2','2026-11-18','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-18-1100','north-demo-d2','2026-11-18','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-18-1130','north-demo-d2','2026-11-18','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-18-1000','north-demo-d4','2026-11-18','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-18-1030','north-demo-d4','2026-11-18','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-18-1100','north-demo-d4','2026-11-18','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-18-1130','north-demo-d4','2026-11-18','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-18-1000','south-demo-d0','2026-11-18','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-18-1030','south-demo-d0','2026-11-18','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-18-1100','south-demo-d0','2026-11-18','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-18-1130','south-demo-d0','2026-11-18','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-18-1000','south-demo-d2','2026-11-18','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-18-1030','south-demo-d2','2026-11-18','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-18-1100','south-demo-d2','2026-11-18','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-18-1130','south-demo-d2','2026-11-18','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-18-1000','south-demo-d4','2026-11-18','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-18-1030','south-demo-d4','2026-11-18','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-18-1100','south-demo-d4','2026-11-18','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-18-1130','south-demo-d4','2026-11-18','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-20-1000','gmc-d1','2026-11-20','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-20-1030','gmc-d1','2026-11-20','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-20-1100','gmc-d1','2026-11-20','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-20-1130','gmc-d1','2026-11-20','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-20-1000','gmc-d3','2026-11-20','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-20-1030','gmc-d3','2026-11-20','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-20-1100','gmc-d3','2026-11-20','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-20-1130','gmc-d3','2026-11-20','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-20-1000','gmc-d5','2026-11-20','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-20-1030','gmc-d5','2026-11-20','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-20-1100','gmc-d5','2026-11-20','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-20-1130','gmc-d5','2026-11-20','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-20-1000','north-demo-d1','2026-11-20','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-20-1030','north-demo-d1','2026-11-20','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-20-1100','north-demo-d1','2026-11-20','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-20-1130','north-demo-d1','2026-11-20','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-20-1000','north-demo-d3','2026-11-20','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-20-1030','north-demo-d3','2026-11-20','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-20-1100','north-demo-d3','2026-11-20','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-20-1130','north-demo-d3','2026-11-20','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-20-1000','north-demo-d5','2026-11-20','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-20-1030','north-demo-d5','2026-11-20','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-20-1100','north-demo-d5','2026-11-20','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-20-1130','north-demo-d5','2026-11-20','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-20-1000','south-demo-d1','2026-11-20','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-20-1030','south-demo-d1','2026-11-20','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-20-1100','south-demo-d1','2026-11-20','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-20-1130','south-demo-d1','2026-11-20','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-20-1000','south-demo-d3','2026-11-20','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-20-1030','south-demo-d3','2026-11-20','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-20-1100','south-demo-d3','2026-11-20','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-20-1130','south-demo-d3','2026-11-20','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-20-1000','south-demo-d5','2026-11-20','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-20-1030','south-demo-d5','2026-11-20','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-20-1100','south-demo-d5','2026-11-20','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-20-1130','south-demo-d5','2026-11-20','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-23-1000','gmc-d0','2026-11-23','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-23-1030','gmc-d0','2026-11-23','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-23-1100','gmc-d0','2026-11-23','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-23-1130','gmc-d0','2026-11-23','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-23-1000','gmc-d2','2026-11-23','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-23-1030','gmc-d2','2026-11-23','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-23-1100','gmc-d2','2026-11-23','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-23-1130','gmc-d2','2026-11-23','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-23-1000','gmc-d4','2026-11-23','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-23-1030','gmc-d4','2026-11-23','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-23-1100','gmc-d4','2026-11-23','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-23-1130','gmc-d4','2026-11-23','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-23-1000','north-demo-d0','2026-11-23','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-23-1030','north-demo-d0','2026-11-23','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-23-1100','north-demo-d0','2026-11-23','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-23-1130','north-demo-d0','2026-11-23','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-23-1000','north-demo-d2','2026-11-23','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-23-1030','north-demo-d2','2026-11-23','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-23-1100','north-demo-d2','2026-11-23','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-23-1130','north-demo-d2','2026-11-23','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-23-1000','north-demo-d4','2026-11-23','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-23-1030','north-demo-d4','2026-11-23','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-23-1100','north-demo-d4','2026-11-23','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-23-1130','north-demo-d4','2026-11-23','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-23-1000','south-demo-d0','2026-11-23','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-23-1030','south-demo-d0','2026-11-23','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-23-1100','south-demo-d0','2026-11-23','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-23-1130','south-demo-d0','2026-11-23','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-23-1000','south-demo-d2','2026-11-23','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-23-1030','south-demo-d2','2026-11-23','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-23-1100','south-demo-d2','2026-11-23','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-23-1130','south-demo-d2','2026-11-23','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-23-1000','south-demo-d4','2026-11-23','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-23-1030','south-demo-d4','2026-11-23','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-23-1100','south-demo-d4','2026-11-23','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-23-1130','south-demo-d4','2026-11-23','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-24-1000','gmc-d1','2026-11-24','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-24-1030','gmc-d1','2026-11-24','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-24-1100','gmc-d1','2026-11-24','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-24-1130','gmc-d1','2026-11-24','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-24-1000','gmc-d3','2026-11-24','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-24-1030','gmc-d3','2026-11-24','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-24-1100','gmc-d3','2026-11-24','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-24-1130','gmc-d3','2026-11-24','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-24-1000','gmc-d5','2026-11-24','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-24-1030','gmc-d5','2026-11-24','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-24-1100','gmc-d5','2026-11-24','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-24-1130','gmc-d5','2026-11-24','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-24-1000','north-demo-d1','2026-11-24','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-24-1030','north-demo-d1','2026-11-24','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-24-1100','north-demo-d1','2026-11-24','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-24-1130','north-demo-d1','2026-11-24','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-24-1000','north-demo-d3','2026-11-24','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-24-1030','north-demo-d3','2026-11-24','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-24-1100','north-demo-d3','2026-11-24','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-24-1130','north-demo-d3','2026-11-24','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-24-1000','north-demo-d5','2026-11-24','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-24-1030','north-demo-d5','2026-11-24','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-24-1100','north-demo-d5','2026-11-24','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-24-1130','north-demo-d5','2026-11-24','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-24-1000','south-demo-d1','2026-11-24','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-24-1030','south-demo-d1','2026-11-24','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-24-1100','south-demo-d1','2026-11-24','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-24-1130','south-demo-d1','2026-11-24','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-24-1000','south-demo-d3','2026-11-24','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-24-1030','south-demo-d3','2026-11-24','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-24-1100','south-demo-d3','2026-11-24','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-24-1130','south-demo-d3','2026-11-24','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-24-1000','south-demo-d5','2026-11-24','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-24-1030','south-demo-d5','2026-11-24','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-24-1100','south-demo-d5','2026-11-24','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-24-1130','south-demo-d5','2026-11-24','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-25-1000','gmc-d0','2026-11-25','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-25-1030','gmc-d0','2026-11-25','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-25-1100','gmc-d0','2026-11-25','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-25-1130','gmc-d0','2026-11-25','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-25-1000','gmc-d2','2026-11-25','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-25-1030','gmc-d2','2026-11-25','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-25-1100','gmc-d2','2026-11-25','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-25-1130','gmc-d2','2026-11-25','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-25-1000','gmc-d4','2026-11-25','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-25-1030','gmc-d4','2026-11-25','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-25-1100','gmc-d4','2026-11-25','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-25-1130','gmc-d4','2026-11-25','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-25-1000','north-demo-d0','2026-11-25','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-25-1030','north-demo-d0','2026-11-25','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-25-1100','north-demo-d0','2026-11-25','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-25-1130','north-demo-d0','2026-11-25','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-25-1000','north-demo-d2','2026-11-25','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-25-1030','north-demo-d2','2026-11-25','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-25-1100','north-demo-d2','2026-11-25','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-25-1130','north-demo-d2','2026-11-25','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-25-1000','north-demo-d4','2026-11-25','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-25-1030','north-demo-d4','2026-11-25','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-25-1100','north-demo-d4','2026-11-25','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-25-1130','north-demo-d4','2026-11-25','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-25-1000','south-demo-d0','2026-11-25','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-25-1030','south-demo-d0','2026-11-25','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-25-1100','south-demo-d0','2026-11-25','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-25-1130','south-demo-d0','2026-11-25','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-25-1000','south-demo-d2','2026-11-25','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-25-1030','south-demo-d2','2026-11-25','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-25-1100','south-demo-d2','2026-11-25','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-25-1130','south-demo-d2','2026-11-25','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-25-1000','south-demo-d4','2026-11-25','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-25-1030','south-demo-d4','2026-11-25','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-25-1100','south-demo-d4','2026-11-25','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-25-1130','south-demo-d4','2026-11-25','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-27-1000','gmc-d1','2026-11-27','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-27-1030','gmc-d1','2026-11-27','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-27-1100','gmc-d1','2026-11-27','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-11-27-1130','gmc-d1','2026-11-27','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-27-1000','gmc-d3','2026-11-27','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-27-1030','gmc-d3','2026-11-27','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-27-1100','gmc-d3','2026-11-27','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-11-27-1130','gmc-d3','2026-11-27','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-27-1000','gmc-d5','2026-11-27','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-27-1030','gmc-d5','2026-11-27','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-27-1100','gmc-d5','2026-11-27','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-11-27-1130','gmc-d5','2026-11-27','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-27-1000','north-demo-d1','2026-11-27','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-27-1030','north-demo-d1','2026-11-27','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-27-1100','north-demo-d1','2026-11-27','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-11-27-1130','north-demo-d1','2026-11-27','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-27-1000','north-demo-d3','2026-11-27','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-27-1030','north-demo-d3','2026-11-27','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-27-1100','north-demo-d3','2026-11-27','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-11-27-1130','north-demo-d3','2026-11-27','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-27-1000','north-demo-d5','2026-11-27','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-27-1030','north-demo-d5','2026-11-27','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-27-1100','north-demo-d5','2026-11-27','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-11-27-1130','north-demo-d5','2026-11-27','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-27-1000','south-demo-d1','2026-11-27','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-27-1030','south-demo-d1','2026-11-27','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-27-1100','south-demo-d1','2026-11-27','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-11-27-1130','south-demo-d1','2026-11-27','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-27-1000','south-demo-d3','2026-11-27','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-27-1030','south-demo-d3','2026-11-27','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-27-1100','south-demo-d3','2026-11-27','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-11-27-1130','south-demo-d3','2026-11-27','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-27-1000','south-demo-d5','2026-11-27','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-27-1030','south-demo-d5','2026-11-27','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-27-1100','south-demo-d5','2026-11-27','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-11-27-1130','south-demo-d5','2026-11-27','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-30-1000','gmc-d0','2026-11-30','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-30-1030','gmc-d0','2026-11-30','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-30-1100','gmc-d0','2026-11-30','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-11-30-1130','gmc-d0','2026-11-30','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-30-1000','gmc-d2','2026-11-30','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-30-1030','gmc-d2','2026-11-30','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-30-1100','gmc-d2','2026-11-30','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-11-30-1130','gmc-d2','2026-11-30','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-30-1000','gmc-d4','2026-11-30','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-30-1030','gmc-d4','2026-11-30','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-30-1100','gmc-d4','2026-11-30','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-11-30-1130','gmc-d4','2026-11-30','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-30-1000','north-demo-d0','2026-11-30','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-30-1030','north-demo-d0','2026-11-30','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-30-1100','north-demo-d0','2026-11-30','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-11-30-1130','north-demo-d0','2026-11-30','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-30-1000','north-demo-d2','2026-11-30','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-30-1030','north-demo-d2','2026-11-30','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-30-1100','north-demo-d2','2026-11-30','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-11-30-1130','north-demo-d2','2026-11-30','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-30-1000','north-demo-d4','2026-11-30','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-30-1030','north-demo-d4','2026-11-30','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-30-1100','north-demo-d4','2026-11-30','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-11-30-1130','north-demo-d4','2026-11-30','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-30-1000','south-demo-d0','2026-11-30','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-30-1030','south-demo-d0','2026-11-30','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-30-1100','south-demo-d0','2026-11-30','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-11-30-1130','south-demo-d0','2026-11-30','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-30-1000','south-demo-d2','2026-11-30','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-30-1030','south-demo-d2','2026-11-30','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-30-1100','south-demo-d2','2026-11-30','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-11-30-1130','south-demo-d2','2026-11-30','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-30-1000','south-demo-d4','2026-11-30','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-30-1030','south-demo-d4','2026-11-30','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-30-1100','south-demo-d4','2026-11-30','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-11-30-1130','south-demo-d4','2026-11-30','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-12-01-1000','gmc-d1','2026-12-01','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-12-01-1030','gmc-d1','2026-12-01','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-12-01-1100','gmc-d1','2026-12-01','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-12-01-1130','gmc-d1','2026-12-01','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-12-01-1000','gmc-d3','2026-12-01','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-12-01-1030','gmc-d3','2026-12-01','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-12-01-1100','gmc-d3','2026-12-01','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-12-01-1130','gmc-d3','2026-12-01','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-12-01-1000','gmc-d5','2026-12-01','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-12-01-1030','gmc-d5','2026-12-01','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-12-01-1100','gmc-d5','2026-12-01','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-12-01-1130','gmc-d5','2026-12-01','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-12-01-1000','north-demo-d1','2026-12-01','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-12-01-1030','north-demo-d1','2026-12-01','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-12-01-1100','north-demo-d1','2026-12-01','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-12-01-1130','north-demo-d1','2026-12-01','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-12-01-1000','north-demo-d3','2026-12-01','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-12-01-1030','north-demo-d3','2026-12-01','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-12-01-1100','north-demo-d3','2026-12-01','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-12-01-1130','north-demo-d3','2026-12-01','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-12-01-1000','north-demo-d5','2026-12-01','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-12-01-1030','north-demo-d5','2026-12-01','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-12-01-1100','north-demo-d5','2026-12-01','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-12-01-1130','north-demo-d5','2026-12-01','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-12-01-1000','south-demo-d1','2026-12-01','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-12-01-1030','south-demo-d1','2026-12-01','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-12-01-1100','south-demo-d1','2026-12-01','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-12-01-1130','south-demo-d1','2026-12-01','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-12-01-1000','south-demo-d3','2026-12-01','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-12-01-1030','south-demo-d3','2026-12-01','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-12-01-1100','south-demo-d3','2026-12-01','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-12-01-1130','south-demo-d3','2026-12-01','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-12-01-1000','south-demo-d5','2026-12-01','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-12-01-1030','south-demo-d5','2026-12-01','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-12-01-1100','south-demo-d5','2026-12-01','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-12-01-1130','south-demo-d5','2026-12-01','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-12-02-1000','gmc-d0','2026-12-02','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-12-02-1030','gmc-d0','2026-12-02','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-12-02-1100','gmc-d0','2026-12-02','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-12-02-1130','gmc-d0','2026-12-02','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-12-02-1000','gmc-d2','2026-12-02','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-12-02-1030','gmc-d2','2026-12-02','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-12-02-1100','gmc-d2','2026-12-02','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-12-02-1130','gmc-d2','2026-12-02','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-12-02-1000','gmc-d4','2026-12-02','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-12-02-1030','gmc-d4','2026-12-02','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-12-02-1100','gmc-d4','2026-12-02','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-12-02-1130','gmc-d4','2026-12-02','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-12-02-1000','north-demo-d0','2026-12-02','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-12-02-1030','north-demo-d0','2026-12-02','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-12-02-1100','north-demo-d0','2026-12-02','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-12-02-1130','north-demo-d0','2026-12-02','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-12-02-1000','north-demo-d2','2026-12-02','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-12-02-1030','north-demo-d2','2026-12-02','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-12-02-1100','north-demo-d2','2026-12-02','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-12-02-1130','north-demo-d2','2026-12-02','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-12-02-1000','north-demo-d4','2026-12-02','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-12-02-1030','north-demo-d4','2026-12-02','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-12-02-1100','north-demo-d4','2026-12-02','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-12-02-1130','north-demo-d4','2026-12-02','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-12-02-1000','south-demo-d0','2026-12-02','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-12-02-1030','south-demo-d0','2026-12-02','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-12-02-1100','south-demo-d0','2026-12-02','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-12-02-1130','south-demo-d0','2026-12-02','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-12-02-1000','south-demo-d2','2026-12-02','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-12-02-1030','south-demo-d2','2026-12-02','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-12-02-1100','south-demo-d2','2026-12-02','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-12-02-1130','south-demo-d2','2026-12-02','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-12-02-1000','south-demo-d4','2026-12-02','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-12-02-1030','south-demo-d4','2026-12-02','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-12-02-1100','south-demo-d4','2026-12-02','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-12-02-1130','south-demo-d4','2026-12-02','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-12-04-1000','gmc-d1','2026-12-04','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-12-04-1030','gmc-d1','2026-12-04','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-12-04-1100','gmc-d1','2026-12-04','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d1-2026-12-04-1130','gmc-d1','2026-12-04','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-12-04-1000','gmc-d3','2026-12-04','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-12-04-1030','gmc-d3','2026-12-04','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-12-04-1100','gmc-d3','2026-12-04','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d3-2026-12-04-1130','gmc-d3','2026-12-04','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-12-04-1000','gmc-d5','2026-12-04','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-12-04-1030','gmc-d5','2026-12-04','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-12-04-1100','gmc-d5','2026-12-04','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d5-2026-12-04-1130','gmc-d5','2026-12-04','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-12-04-1000','north-demo-d1','2026-12-04','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-12-04-1030','north-demo-d1','2026-12-04','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-12-04-1100','north-demo-d1','2026-12-04','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d1-2026-12-04-1130','north-demo-d1','2026-12-04','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-12-04-1000','north-demo-d3','2026-12-04','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-12-04-1030','north-demo-d3','2026-12-04','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-12-04-1100','north-demo-d3','2026-12-04','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d3-2026-12-04-1130','north-demo-d3','2026-12-04','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-12-04-1000','north-demo-d5','2026-12-04','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-12-04-1030','north-demo-d5','2026-12-04','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-12-04-1100','north-demo-d5','2026-12-04','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d5-2026-12-04-1130','north-demo-d5','2026-12-04','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-12-04-1000','south-demo-d1','2026-12-04','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-12-04-1030','south-demo-d1','2026-12-04','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-12-04-1100','south-demo-d1','2026-12-04','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d1-2026-12-04-1130','south-demo-d1','2026-12-04','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-12-04-1000','south-demo-d3','2026-12-04','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-12-04-1030','south-demo-d3','2026-12-04','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-12-04-1100','south-demo-d3','2026-12-04','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d3-2026-12-04-1130','south-demo-d3','2026-12-04','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-12-04-1000','south-demo-d5','2026-12-04','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-12-04-1030','south-demo-d5','2026-12-04','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-12-04-1100','south-demo-d5','2026-12-04','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d5-2026-12-04-1130','south-demo-d5','2026-12-04','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-12-07-1000','gmc-d0','2026-12-07','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-12-07-1030','gmc-d0','2026-12-07','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-12-07-1100','gmc-d0','2026-12-07','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d0-2026-12-07-1130','gmc-d0','2026-12-07','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-12-07-1000','gmc-d2','2026-12-07','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-12-07-1030','gmc-d2','2026-12-07','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-12-07-1100','gmc-d2','2026-12-07','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d2-2026-12-07-1130','gmc-d2','2026-12-07','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-12-07-1000','gmc-d4','2026-12-07','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-12-07-1030','gmc-d4','2026-12-07','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-12-07-1100','gmc-d4','2026-12-07','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('gmc-d4-2026-12-07-1130','gmc-d4','2026-12-07','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-12-07-1000','north-demo-d0','2026-12-07','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-12-07-1030','north-demo-d0','2026-12-07','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-12-07-1100','north-demo-d0','2026-12-07','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d0-2026-12-07-1130','north-demo-d0','2026-12-07','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-12-07-1000','north-demo-d2','2026-12-07','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-12-07-1030','north-demo-d2','2026-12-07','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-12-07-1100','north-demo-d2','2026-12-07','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d2-2026-12-07-1130','north-demo-d2','2026-12-07','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-12-07-1000','north-demo-d4','2026-12-07','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-12-07-1030','north-demo-d4','2026-12-07','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-12-07-1100','north-demo-d4','2026-12-07','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('north-demo-d4-2026-12-07-1130','north-demo-d4','2026-12-07','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-12-07-1000','south-demo-d0','2026-12-07','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-12-07-1030','south-demo-d0','2026-12-07','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-12-07-1100','south-demo-d0','2026-12-07','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d0-2026-12-07-1130','south-demo-d0','2026-12-07','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-12-07-1000','south-demo-d2','2026-12-07','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-12-07-1030','south-demo-d2','2026-12-07','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-12-07-1100','south-demo-d2','2026-12-07','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d2-2026-12-07-1130','south-demo-d2','2026-12-07','11:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-12-07-1000','south-demo-d4','2026-12-07','10:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-12-07-1030','south-demo-d4','2026-12-07','10:30',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-12-07-1100','south-demo-d4','2026-12-07','11:00',1) ON CONFLICT DO NOTHING;
INSERT INTO appointment_slots ("id","doctor_id","date","time","active") VALUES ('south-demo-d4-2026-12-07-1130','south-demo-d4','2026-12-07','11:30',1) ON CONFLICT DO NOTHING;
ALTER TABLE care."appointments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."bookings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."departments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."doctors" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."feedback" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."holidays" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."hospitals" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."doctor_schedules" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."appointment_slots" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."usage_totals" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."department_usage" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."facility_directory" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."followup_reminders" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."staff_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."doctor_presence" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."hospital_resources" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."operations_audit" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."queue_tokens" ENABLE ROW LEVEL SECURITY;
ALTER TABLE care."staff_roles" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON SCHEMA care FROM PUBLIC;
COMMIT;
