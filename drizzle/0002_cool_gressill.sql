CREATE TABLE `department_usage` (
	`id` text PRIMARY KEY NOT NULL,
	`department` text NOT NULL,
	`day` text NOT NULL,
	`count` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE `facility_directory` (
	`id` text PRIMARY KEY NOT NULL,
	`hospital_id` text NOT NULL,
	`name` text NOT NULL,
	`building` text NOT NULL,
	`floor` text NOT NULL,
	`room` text NOT NULL,
	`directions` text NOT NULL,
	FOREIGN KEY (`hospital_id`) REFERENCES `hospitals`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `followup_reminders` (
	`id` text PRIMARY KEY NOT NULL,
	`owner` text NOT NULL,
	`kind` text NOT NULL,
	`title` text NOT NULL,
	`starts_at` text NOT NULL,
	`frequency` text NOT NULL,
	`ends_on` text NOT NULL,
	`consent` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE `staff_requests` (
	`id` text PRIMARY KEY NOT NULL,
	`owner` text NOT NULL,
	`team` text NOT NULL,
	`subject` text NOT NULL,
	`message` text NOT NULL,
	`history` text NOT NULL,
	`history_consent` integer DEFAULT 0 NOT NULL,
	`status` text DEFAULT 'awaiting_demo_staff' NOT NULL,
	`reply` text DEFAULT '' NOT NULL,
	`created_at` text NOT NULL
);
--> statement-breakpoint
ALTER TABLE `doctors` ADD `fee` integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE `usage_totals` ADD `duration_total` integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE `usage_totals` ADD `fallback_count` integer DEFAULT 0 NOT NULL;