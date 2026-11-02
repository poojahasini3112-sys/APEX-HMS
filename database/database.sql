-- ============================================================================
-- DATABASE CREATION SCRIPT: Hospital_Management_System
-- Database Engine: MySQL 8.0+ / InnoDB
-- Character Set: utf8mb4, Collation: utf8mb4_unicode_ci
-- ============================================================================

CREATE DATABASE IF NOT EXISTS Hospital_Management_System
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE Hospital_Management_System;

-- Verify database creation
SELECT DATABASE() AS Current_Database;
