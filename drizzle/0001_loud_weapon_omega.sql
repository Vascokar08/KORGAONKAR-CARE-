CREATE TABLE `bookings` (
	`id` text PRIMARY KEY NOT NULL,
	`owner` text NOT NULL,
	`name` text NOT NULL,
	`slot_id` text NOT NULL,
	`status` text DEFAULT 'awaiting_hospital_confirmation' NOT NULL,
	`reminder` integer DEFAULT 0 NOT NULL,
	`created_at` text NOT NULL,
	FOREIGN KEY (`slot_id`) REFERENCES `appointment_slots`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `one_active_booking_per_slot` ON `bookings` (`slot_id`) WHERE "bookings"."status" != 'cancelled';--> statement-breakpoint
CREATE TABLE `departments` (
	`id` text PRIMARY KEY NOT NULL,
	`hospital_id` text NOT NULL,
	`name` text NOT NULL,
	FOREIGN KEY (`hospital_id`) REFERENCES `hospitals`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `doctors` (
	`id` text PRIMARY KEY NOT NULL,
	`hospital_id` text NOT NULL,
	`department_id` text NOT NULL,
	`name` text NOT NULL,
	`speciality` text NOT NULL,
	`qualification` text NOT NULL,
	`experience` integer NOT NULL,
	`languages` text NOT NULL,
	`active` integer DEFAULT 1 NOT NULL,
	FOREIGN KEY (`hospital_id`) REFERENCES `hospitals`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`department_id`) REFERENCES `departments`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `feedback` (
	`id` text PRIMARY KEY NOT NULL,
	`owner` text NOT NULL,
	`rating` integer NOT NULL,
	`topic` text NOT NULL,
	`comment` text NOT NULL,
	`created_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `holidays` (
	`id` text PRIMARY KEY NOT NULL,
	`hospital_id` text NOT NULL,
	`date` text NOT NULL,
	`reason` text NOT NULL,
	FOREIGN KEY (`hospital_id`) REFERENCES `hospitals`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `hospitals` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`area` text NOT NULL,
	`address` text NOT NULL,
	`url` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `doctor_schedules` (
	`id` text PRIMARY KEY NOT NULL,
	`doctor_id` text NOT NULL,
	`weekday` integer NOT NULL,
	`start` text NOT NULL,
	`end` text NOT NULL,
	FOREIGN KEY (`doctor_id`) REFERENCES `doctors`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `appointment_slots` (
	`id` text PRIMARY KEY NOT NULL,
	`doctor_id` text NOT NULL,
	`date` text NOT NULL,
	`time` text NOT NULL,
	`active` integer DEFAULT 1 NOT NULL,
	FOREIGN KEY (`doctor_id`) REFERENCES `doctors`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `usage_totals` (
	`id` text PRIMARY KEY NOT NULL,
	`day` text NOT NULL,
	`intent` text NOT NULL,
	`count` integer DEFAULT 0 NOT NULL
);
