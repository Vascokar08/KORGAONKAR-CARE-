CREATE TABLE `doctor_presence` (
	`doctor_id` text PRIMARY KEY NOT NULL,
	`available` integer NOT NULL,
	`updated_at` text NOT NULL,
	FOREIGN KEY (`doctor_id`) REFERENCES `doctors`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `hospital_resources` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`kind` text NOT NULL,
	`capacity` integer NOT NULL,
	`available` integer NOT NULL,
	`status` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `operations_audit` (
	`id` text PRIMARY KEY NOT NULL,
	`actor` text NOT NULL,
	`action` text NOT NULL,
	`target` text NOT NULL,
	`created_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `queue_tokens` (
	`id` text PRIMARY KEY NOT NULL,
	`doctor_id` text NOT NULL,
	`day` text NOT NULL,
	`token` integer NOT NULL,
	`owner` text NOT NULL,
	`booking_id` text,
	`status` text DEFAULT 'waiting' NOT NULL,
	`created_at` text NOT NULL,
	`called_at` text,
	`completed_at` text,
	FOREIGN KEY (`doctor_id`) REFERENCES `doctors`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `queue_number` ON `queue_tokens` (`doctor_id`,`day`,`token`);--> statement-breakpoint
CREATE UNIQUE INDEX `queue_booking` ON `queue_tokens` (`booking_id`);--> statement-breakpoint
CREATE UNIQUE INDEX `queue_serving` ON `queue_tokens` (`doctor_id`,`day`) WHERE "queue_tokens"."status" = 'serving';--> statement-breakpoint
CREATE TABLE `staff_roles` (
	`email` text PRIMARY KEY NOT NULL,
	`role` text NOT NULL,
	`doctor_id` text
);

--> statement-breakpoint
UPDATE hospitals SET name='Korgaonkar Multispeciality Hospital (Demo)',area='Fictional main campus',address='Sample campus - no real hospital address',url='' WHERE id='gmc';
--> statement-breakpoint
UPDATE hospitals SET name='Korgaonkar North Clinic (Demo)' WHERE id='north-demo';
--> statement-breakpoint
UPDATE hospitals SET name='Korgaonkar South Hospital (Demo)' WHERE id='south-demo';
