CREATE TABLE `appointments` (
	`id` text PRIMARY KEY NOT NULL,
	`owner` text NOT NULL,
	`name` text NOT NULL,
	`department` text NOT NULL,
	`date` text NOT NULL,
	`time` text NOT NULL,
	`created_at` text NOT NULL
);
