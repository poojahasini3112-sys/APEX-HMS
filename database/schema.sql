-- ============================================================================
-- SCHEMA DDL SCRIPT: Hospital_Management_System
-- 34 Relational Tables with InnoDB, UTF8MB4, PKs, FKs, CHECKs, UNIQUEs & Indexes
-- ============================================================================

USE Hospital_Management_System;

-- Disable foreign key checks during schema creation/reset
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- MODULE B: DOCTOR AND STAFF MANAGEMENT (Base Entities needed first)
-- ----------------------------------------------------------------------------

-- Table 5: Department
DROP TABLE IF EXISTS Department;
CREATE TABLE Department (
    Department_ID INT AUTO_INCREMENT PRIMARY KEY,
    Department_Name VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT,
    Head_Of_Department INT NULL,
    Location VARCHAR(100) NOT NULL,
    Contact_Number VARCHAR(20) NOT NULL,
    Created_At DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_dept_name (Department_Name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 6: Staff
DROP TABLE IF EXISTS Staff;
CREATE TABLE Staff (
    Staff_ID INT AUTO_INCREMENT PRIMARY KEY,
    First_Name VARCHAR(50) NOT NULL,
    Last_Name VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(20) NOT NULL UNIQUE,
    Role ENUM('Doctor', 'Nurse', 'Pharmacist', 'Lab Technician', 'Receptionist', 'Admin', 'Accountant', 'Other') NOT NULL,
    Department_ID INT NOT NULL,
    Date_Of_Joining DATE NOT NULL,
    Salary DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    Status ENUM('Active', 'On Leave', 'Resigned', 'Terminated') DEFAULT 'Active',
    Created_At DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_staff_salary CHECK (Salary >= 0),
    CONSTRAINT fk_staff_dept FOREIGN KEY (Department_ID) REFERENCES Department (Department_ID) ON DELETE RESTRICT,
    INDEX idx_staff_role (Role),
    INDEX idx_staff_dept (Department_ID),
    INDEX idx_staff_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Department Head foreign key (self-referencing / referencing Staff)
ALTER TABLE Department
    ADD CONSTRAINT fk_dept_head FOREIGN KEY (Head_Of_Department) REFERENCES Staff (Staff_ID) ON DELETE SET NULL;

-- Table 7: Doctor (Specialization of Staff - 1:1 subtype table)
DROP TABLE IF EXISTS Doctor;
CREATE TABLE Doctor (
    Doctor_ID INT PRIMARY KEY,
    Specialization VARCHAR(100) NOT NULL,
    Qualification VARCHAR(100) NOT NULL,
    License_Number VARCHAR(50) NOT NULL UNIQUE,
    Consultation_Fee DECIMAL(10, 2) NOT NULL DEFAULT 500.00,
    Room_Number VARCHAR(20) NOT NULL,
    CONSTRAINT chk_doc_fee CHECK (Consultation_Fee >= 0),
    CONSTRAINT fk_doctor_staff FOREIGN KEY (Doctor_ID) REFERENCES Staff (Staff_ID) ON DELETE CASCADE,
    INDEX idx_doctor_specialization (Specialization)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 8: Nurse (Specialization of Staff - 1:1 subtype table)
DROP TABLE IF EXISTS Nurse;
CREATE TABLE Nurse (
    Nurse_ID INT PRIMARY KEY,
    Qualification VARCHAR(100) NOT NULL,
    License_Number VARCHAR(50) NOT NULL UNIQUE,
    Shift ENUM('Morning', 'Evening', 'Night', 'Rotational') DEFAULT 'Morning',
    Assigned_Ward VARCHAR(50) NOT NULL,
    CONSTRAINT fk_nurse_staff FOREIGN KEY (Nurse_ID) REFERENCES Staff (Staff_ID) ON DELETE CASCADE,
    INDEX idx_nurse_shift (Shift)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 9: Doctor_Schedule (Doctor to Doctor_Schedule 1:M)
DROP TABLE IF EXISTS Doctor_Schedule;
CREATE TABLE Doctor_Schedule (
    Schedule_ID INT AUTO_INCREMENT PRIMARY KEY,
    Doctor_ID INT NOT NULL,
    Day_Of_Week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    Start_Time TIME NOT NULL,
    End_Time TIME NOT NULL,
    Max_Appointments INT DEFAULT 20,
    Status ENUM('Available', 'Unavailable', 'On Leave') DEFAULT 'Available',
    CONSTRAINT chk_sched_time CHECK (End_Time > Start_Time),
    CONSTRAINT chk_sched_max CHECK (Max_Appointments > 0),
    CONSTRAINT fk_sched_doctor FOREIGN KEY (Doctor_ID) REFERENCES Doctor (Doctor_ID) ON DELETE CASCADE,
    INDEX idx_sched_doc_day (Doctor_ID, Day_Of_Week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- MODULE A: PATIENT MANAGEMENT
-- ----------------------------------------------------------------------------

-- Table 1: Patient
DROP TABLE IF EXISTS Patient;
CREATE TABLE Patient (
    Patient_ID INT AUTO_INCREMENT PRIMARY KEY,
    First_Name VARCHAR(50) NOT NULL,
    Last_Name VARCHAR(50) NOT NULL,
    Date_Of_Birth DATE NOT NULL,
    Gender ENUM('Male', 'Female', 'Other') NOT NULL,
    Blood_Group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    Phone VARCHAR(20) NOT NULL UNIQUE,
    Email VARCHAR(100) UNIQUE,
    Address VARCHAR(255) NOT NULL,
    Emergency_Contact_Name VARCHAR(100),
    Emergency_Contact_Phone VARCHAR(20),
    Registration_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    Status ENUM('Active', 'Discharged', 'Deceased') DEFAULT 'Active',
    INDEX idx_patient_name (Last_Name, First_Name),
    INDEX idx_patient_phone (Phone),
    INDEX idx_patient_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 2: Emergency_Contact
DROP TABLE IF EXISTS Emergency_Contact;
CREATE TABLE Emergency_Contact (
    Contact_ID INT AUTO_INCREMENT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Contact_Name VARCHAR(100) NOT NULL,
    Relationship VARCHAR(50) NOT NULL,
    Phone VARCHAR(20) NOT NULL,
    Alternate_Phone VARCHAR(20),
    Address VARCHAR(255),
    CONSTRAINT fk_ec_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE CASCADE,
    INDEX idx_ec_patient (Patient_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 3: Patient_Medical_History
DROP TABLE IF EXISTS Patient_Medical_History;
CREATE TABLE Patient_Medical_History (
    History_ID INT AUTO_INCREMENT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Condition_Name VARCHAR(100) NOT NULL,
    Diagnosed_Date DATE,
    Status ENUM('Chronic', 'Cured', 'Ongoing', 'In Remission') DEFAULT 'Ongoing',
    Notes TEXT,
    Recorded_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pmh_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE CASCADE,
    INDEX idx_pmh_patient (Patient_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 4: Patient_Allergy
DROP TABLE IF EXISTS Patient_Allergy;
CREATE TABLE Patient_Allergy (
    Allergy_ID INT AUTO_INCREMENT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Allergen VARCHAR(100) NOT NULL,
    Reaction VARCHAR(255) NOT NULL,
    Severity ENUM('Mild', 'Moderate', 'Severe', 'Critical') DEFAULT 'Moderate',
    Recorded_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_allergy_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE CASCADE,
    INDEX idx_allergy_patient (Patient_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- MODULE C: APPOINTMENT AND ADMISSION (Rooms & Beds)
-- ----------------------------------------------------------------------------

-- Table 12: Room (Room to Bed 1:M)
DROP TABLE IF EXISTS Room;
CREATE TABLE Room (
    Room_ID INT AUTO_INCREMENT PRIMARY KEY,
    Room_Number VARCHAR(20) NOT NULL UNIQUE,
    Room_Type ENUM('General', 'Semi-Private', 'Private', 'ICU', 'Operation Theater', 'Recovery') NOT NULL,
    Department_ID INT NOT NULL,
    Daily_Rate DECIMAL(10, 2) NOT NULL DEFAULT 1000.00,
    Status ENUM('Available', 'Occupied', 'Maintenance') DEFAULT 'Available',
    CONSTRAINT chk_room_rate CHECK (Daily_Rate >= 0),
    CONSTRAINT fk_room_dept FOREIGN KEY (Department_ID) REFERENCES Department (Department_ID) ON DELETE RESTRICT,
    INDEX idx_room_type (Room_Type),
    INDEX idx_room_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 13: Bed (Room to Bed 1:M)
DROP TABLE IF EXISTS Bed;
CREATE TABLE Bed (
    Bed_ID INT AUTO_INCREMENT PRIMARY KEY,
    Room_ID INT NOT NULL,
    Bed_Number VARCHAR(20) NOT NULL,
    Status ENUM('Available', 'Occupied', 'Under Cleaning', 'Maintenance') DEFAULT 'Available',
    UNIQUE KEY uk_room_bed (Room_ID, Bed_Number),
    CONSTRAINT fk_bed_room FOREIGN KEY (Room_ID) REFERENCES Room (Room_ID) ON DELETE CASCADE,
    INDEX idx_bed_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 10: Appointment (Patient to Appointment 1:M)
DROP TABLE IF EXISTS Appointment;
CREATE TABLE Appointment (
    Appointment_ID INT AUTO_INCREMENT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Doctor_ID INT NOT NULL,
    Appointment_Date DATE NOT NULL,
    Appointment_Time TIME NOT NULL,
    Reason VARCHAR(255) NOT NULL,
    Status ENUM('Scheduled', 'Completed', 'Cancelled', 'No-Show') DEFAULT 'Scheduled',
    Created_At DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_appt_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE RESTRICT,
    CONSTRAINT fk_appt_doctor FOREIGN KEY (Doctor_ID) REFERENCES Doctor (Doctor_ID) ON DELETE RESTRICT,
    INDEX idx_appt_date (Appointment_Date),
    INDEX idx_appt_patient (Patient_ID),
    INDEX idx_appt_doctor (Doctor_ID),
    INDEX idx_appt_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 11: Admission (Patient to Admission 1:M)
DROP TABLE IF EXISTS Admission;
CREATE TABLE Admission (
    Admission_ID INT AUTO_INCREMENT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Admitted_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Discharge_Date DATETIME NULL,
    Attending_Doctor_ID INT NOT NULL,
    Admission_Reason VARCHAR(255) NOT NULL,
    Admission_Type ENUM('Emergency', 'Elective', 'Urgent') DEFAULT 'Elective',
    Status ENUM('Admitted', 'Discharged', 'Transferred') DEFAULT 'Admitted',
    CONSTRAINT fk_adm_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE RESTRICT,
    CONSTRAINT fk_adm_doctor FOREIGN KEY (Attending_Doctor_ID) REFERENCES Doctor (Doctor_ID) ON DELETE RESTRICT,
    INDEX idx_adm_patient (Patient_ID),
    INDEX idx_adm_status (Status),
    INDEX idx_adm_doctor (Attending_Doctor_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 14: Bed_Allocation (Admission to Bed_Allocation 1:M)
DROP TABLE IF EXISTS Bed_Allocation;
CREATE TABLE Bed_Allocation (
    Allocation_ID INT AUTO_INCREMENT PRIMARY KEY,
    Admission_ID INT NOT NULL,
    Bed_ID INT NOT NULL,
    Allocated_From DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Allocated_To DATETIME NULL,
    Status ENUM('Active', 'Released', 'Transferred') DEFAULT 'Active',
    CONSTRAINT fk_ba_admission FOREIGN KEY (Admission_ID) REFERENCES Admission (Admission_ID) ON DELETE RESTRICT,
    CONSTRAINT fk_ba_bed FOREIGN KEY (Bed_ID) REFERENCES Bed (Bed_ID) ON DELETE RESTRICT,
    INDEX idx_ba_admission (Admission_ID),
    INDEX idx_ba_bed (Bed_ID),
    INDEX idx_ba_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- MODULE D: MEDICAL RECORDS AND TREATMENT
-- ----------------------------------------------------------------------------

-- Table 15: Medical_Record
DROP TABLE IF EXISTS Medical_Record;
CREATE TABLE Medical_Record (
    Record_ID INT AUTO_INCREMENT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Doctor_ID INT NOT NULL,
    Visit_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Symptoms TEXT NOT NULL,
    Physical_Examination TEXT,
    Treatment_Notes TEXT,
    Follow_Up_Date DATE NULL,
    CONSTRAINT fk_mr_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE RESTRICT,
    CONSTRAINT fk_mr_doctor FOREIGN KEY (Doctor_ID) REFERENCES Doctor (Doctor_ID) ON DELETE RESTRICT,
    INDEX idx_mr_patient (Patient_ID),
    INDEX idx_mr_doctor (Doctor_ID),
    INDEX idx_mr_date (Visit_Date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 16: Diagnosis
DROP TABLE IF EXISTS Diagnosis;
CREATE TABLE Diagnosis (
    Diagnosis_ID INT AUTO_INCREMENT PRIMARY KEY,
    ICD_Code VARCHAR(20) NOT NULL UNIQUE,
    Diagnosis_Name VARCHAR(150) NOT NULL,
    Description TEXT,
    Category VARCHAR(100),
    INDEX idx_diag_code (ICD_Code),
    INDEX idx_diag_name (Diagnosis_Name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 17: Record_Diagnosis (M:N between Medical_Record and Diagnosis)
DROP TABLE IF EXISTS Record_Diagnosis;
CREATE TABLE Record_Diagnosis (
    Record_ID INT NOT NULL,
    Diagnosis_ID INT NOT NULL,
    Severity ENUM('Primary', 'Secondary', 'Suspected', 'Differential') DEFAULT 'Primary',
    Recorded_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (Record_ID, Diagnosis_ID),
    CONSTRAINT fk_rd_record FOREIGN KEY (Record_ID) REFERENCES Medical_Record (Record_ID) ON DELETE CASCADE,
    CONSTRAINT fk_rd_diagnosis FOREIGN KEY (Diagnosis_ID) REFERENCES Diagnosis (Diagnosis_ID) ON DELETE RESTRICT,
    INDEX idx_rd_diag (Diagnosis_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 18: Prescription
DROP TABLE IF EXISTS Prescription;
CREATE TABLE Prescription (
    Prescription_ID INT AUTO_INCREMENT PRIMARY KEY,
    Record_ID INT NOT NULL,
    Patient_ID INT NOT NULL,
    Doctor_ID INT NOT NULL,
    Prescribed_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Instructions TEXT,
    CONSTRAINT fk_rx_record FOREIGN KEY (Record_ID) REFERENCES Medical_Record (Record_ID) ON DELETE CASCADE,
    CONSTRAINT fk_rx_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE RESTRICT,
    CONSTRAINT fk_rx_doctor FOREIGN KEY (Doctor_ID) REFERENCES Doctor (Doctor_ID) ON DELETE RESTRICT,
    INDEX idx_rx_patient (Patient_ID),
    INDEX idx_rx_doctor (Doctor_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- MODULE F: PHARMACY AND MEDICINE MANAGEMENT
-- ----------------------------------------------------------------------------

-- Table 23: Medicine
DROP TABLE IF EXISTS Medicine;
CREATE TABLE Medicine (
    Medicine_ID INT AUTO_INCREMENT PRIMARY KEY,
    Medicine_Name VARCHAR(100) NOT NULL,
    Generic_Name VARCHAR(100),
    Category VARCHAR(50) NOT NULL,
    Unit_Price DECIMAL(10, 2) NOT NULL CHECK (Unit_Price >= 0),
    Stock_Quantity INT NOT NULL DEFAULT 0 CHECK (Stock_Quantity >= 0),
    Reorder_Level INT NOT NULL DEFAULT 10 CHECK (Reorder_Level >= 0),
    Manufacturer VARCHAR(100) NOT NULL,
    INDEX idx_med_name (Medicine_Name),
    INDEX idx_med_category (Category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 19: Prescription_Detail (M:N between Prescription and Medicine)
DROP TABLE IF EXISTS Prescription_Detail;
CREATE TABLE Prescription_Detail (
    Prescription_Detail_ID INT AUTO_INCREMENT PRIMARY KEY,
    Prescription_ID INT NOT NULL,
    Medicine_ID INT NOT NULL,
    Dosage VARCHAR(50) NOT NULL,
    Frequency VARCHAR(50) NOT NULL,
    Duration_Days INT NOT NULL CHECK (Duration_Days > 0),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Notes VARCHAR(255),
    CONSTRAINT fk_pd_rx FOREIGN KEY (Prescription_ID) REFERENCES Prescription (Prescription_ID) ON DELETE CASCADE,
    CONSTRAINT fk_pd_med FOREIGN KEY (Medicine_ID) REFERENCES Medicine (Medicine_ID) ON DELETE RESTRICT,
    INDEX idx_pd_rx (Prescription_ID),
    INDEX idx_pd_med (Medicine_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 24: Supplier
DROP TABLE IF EXISTS Supplier;
CREATE TABLE Supplier (
    Supplier_ID INT AUTO_INCREMENT PRIMARY KEY,
    Supplier_Name VARCHAR(100) NOT NULL UNIQUE,
    Contact_Person VARCHAR(100) NOT NULL,
    Phone VARCHAR(20) NOT NULL,
    Email VARCHAR(100),
    Address VARCHAR(255) NOT NULL,
    Status ENUM('Active', 'Inactive') DEFAULT 'Active',
    INDEX idx_supplier_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 25: Purchase (Supplier to Purchase 1:M)
DROP TABLE IF EXISTS Purchase;
CREATE TABLE Purchase (
    Purchase_ID INT AUTO_INCREMENT PRIMARY KEY,
    Supplier_ID INT NOT NULL,
    Purchase_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Total_Amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (Total_Amount >= 0),
    Status ENUM('Ordered', 'Received', 'Cancelled') DEFAULT 'Ordered',
    Invoice_Number VARCHAR(50) UNIQUE,
    CONSTRAINT fk_purch_supplier FOREIGN KEY (Supplier_ID) REFERENCES Supplier (Supplier_ID) ON DELETE RESTRICT,
    INDEX idx_purch_supplier (Supplier_ID),
    INDEX idx_purch_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 26: Purchase_Item (M:N between Purchase and Medicine)
DROP TABLE IF EXISTS Purchase_Item;
CREATE TABLE Purchase_Item (
    Purchase_Item_ID INT AUTO_INCREMENT PRIMARY KEY,
    Purchase_ID INT NOT NULL,
    Medicine_ID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Unit_Cost DECIMAL(10, 2) NOT NULL CHECK (Unit_Cost >= 0),
    Total_Price DECIMAL(10, 2) NOT NULL CHECK (Total_Price >= 0),
    CONSTRAINT fk_pi_purchase FOREIGN KEY (Purchase_ID) REFERENCES Purchase (Purchase_ID) ON DELETE CASCADE,
    CONSTRAINT fk_pi_medicine FOREIGN KEY (Medicine_ID) REFERENCES Medicine (Medicine_ID) ON DELETE RESTRICT,
    INDEX idx_pi_purch (Purchase_ID),
    INDEX idx_pi_med (Medicine_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 27: Medicine_Batch
DROP TABLE IF EXISTS Medicine_Batch;
CREATE TABLE Medicine_Batch (
    Batch_ID INT AUTO_INCREMENT PRIMARY KEY,
    Medicine_ID INT NOT NULL,
    Batch_Number VARCHAR(50) NOT NULL,
    Manufacturing_Date DATE NOT NULL,
    Expiry_Date DATE NOT NULL,
    Quantity INT NOT NULL DEFAULT 0 CHECK (Quantity >= 0),
    Purchase_Item_ID INT NULL,
    CONSTRAINT chk_batch_expiry CHECK (Expiry_Date > Manufacturing_Date),
    CONSTRAINT fk_batch_med FOREIGN KEY (Medicine_ID) REFERENCES Medicine (Medicine_ID) ON DELETE CASCADE,
    CONSTRAINT fk_batch_pi FOREIGN KEY (Purchase_Item_ID) REFERENCES Purchase_Item (Purchase_Item_ID) ON DELETE SET NULL,
    INDEX idx_batch_med (Medicine_ID),
    INDEX idx_batch_expiry (Expiry_Date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- MODULE E: LABORATORY MANAGEMENT
-- ----------------------------------------------------------------------------

-- Table 20: Lab_Test
DROP TABLE IF EXISTS Lab_Test;
CREATE TABLE Lab_Test (
    Test_ID INT AUTO_INCREMENT PRIMARY KEY,
    Test_Name VARCHAR(100) NOT NULL UNIQUE,
    Category VARCHAR(50) NOT NULL,
    Cost DECIMAL(10, 2) NOT NULL CHECK (Cost >= 0),
    Normal_Range VARCHAR(100),
    Unit VARCHAR(30),
    Description TEXT,
    INDEX idx_test_cat (Category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 21: Lab_Order
DROP TABLE IF EXISTS Lab_Order;
CREATE TABLE Lab_Order (
    Order_ID INT AUTO_INCREMENT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Doctor_ID INT NOT NULL,
    Test_ID INT NOT NULL,
    Order_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Priority ENUM('Routine', 'Urgent', 'STAT') DEFAULT 'Routine',
    Status ENUM('Pending', 'Sample Collected', 'In Progress', 'Completed', 'Cancelled') DEFAULT 'Pending',
    CONSTRAINT fk_lo_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE RESTRICT,
    CONSTRAINT fk_lo_doctor FOREIGN KEY (Doctor_ID) REFERENCES Doctor (Doctor_ID) ON DELETE RESTRICT,
    CONSTRAINT fk_lo_test FOREIGN KEY (Test_ID) REFERENCES Lab_Test (Test_ID) ON DELETE RESTRICT,
    INDEX idx_lo_patient (Patient_ID),
    INDEX idx_lo_doctor (Doctor_ID),
    INDEX idx_lo_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 22: Lab_Report (1:1 with Lab_Order)
DROP TABLE IF EXISTS Lab_Report;
CREATE TABLE Lab_Report (
    Report_ID INT AUTO_INCREMENT PRIMARY KEY,
    Order_ID INT NOT NULL UNIQUE,
    Conducted_By INT NOT NULL,
    Result_Value VARCHAR(255) NOT NULL,
    Comments TEXT,
    Report_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status ENUM('Normal', 'Abnormal', 'Critical') DEFAULT 'Normal',
    CONSTRAINT fk_lr_order FOREIGN KEY (Order_ID) REFERENCES Lab_Order (Order_ID) ON DELETE CASCADE,
    CONSTRAINT fk_lr_staff FOREIGN KEY (Conducted_By) REFERENCES Staff (Staff_ID) ON DELETE RESTRICT,
    INDEX idx_lr_order (Order_ID),
    INDEX idx_lr_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- MODULE G: BILLING AND INSURANCE
-- ----------------------------------------------------------------------------

-- Table 28: Bill
DROP TABLE IF EXISTS Bill;
CREATE TABLE Bill (
    Bill_ID INT AUTO_INCREMENT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Admission_ID INT NULL,
    Bill_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Total_Amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (Total_Amount >= 0),
    Discount_Amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (Discount_Amount >= 0),
    Tax_Amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (Tax_Amount >= 0),
    Net_Amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (Net_Amount >= 0),
    Paid_Amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (Paid_Amount >= 0),
    Payment_Status ENUM('Pending', 'Partially Paid', 'Paid', 'Cancelled') DEFAULT 'Pending',
    CONSTRAINT fk_bill_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE RESTRICT,
    CONSTRAINT fk_bill_adm FOREIGN KEY (Admission_ID) REFERENCES Admission (Admission_ID) ON DELETE SET NULL,
    INDEX idx_bill_patient (Patient_ID),
    INDEX idx_bill_status (Payment_Status),
    INDEX idx_bill_date (Bill_Date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 29: Bill_Item (Bill to Bill_Item 1:M)
DROP TABLE IF EXISTS Bill_Item;
CREATE TABLE Bill_Item (
    Bill_Item_ID INT AUTO_INCREMENT PRIMARY KEY,
    Bill_ID INT NOT NULL,
    Item_Type ENUM('Consultation', 'Room Charge', 'Lab Test', 'Medicine', 'Procedure', 'Other') NOT NULL,
    Description VARCHAR(255) NOT NULL,
    Quantity INT NOT NULL DEFAULT 1 CHECK (Quantity > 0),
    Unit_Price DECIMAL(10, 2) NOT NULL CHECK (Unit_Price >= 0),
    Total_Price DECIMAL(10, 2) NOT NULL CHECK (Total_Price >= 0),
    CONSTRAINT fk_bi_bill FOREIGN KEY (Bill_ID) REFERENCES Bill (Bill_ID) ON DELETE CASCADE,
    INDEX idx_bi_bill (Bill_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 30: Payment (Bill to Payment 1:M)
DROP TABLE IF EXISTS Payment;
CREATE TABLE Payment (
    Payment_ID INT AUTO_INCREMENT PRIMARY KEY,
    Bill_ID INT NOT NULL,
    Payment_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Amount DECIMAL(10, 2) NOT NULL CHECK (Amount > 0),
    Payment_Method ENUM('Cash', 'Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Insurance') NOT NULL,
    Transaction_Reference VARCHAR(100) UNIQUE,
    Status ENUM('Completed', 'Failed', 'Refunded') DEFAULT 'Completed',
    CONSTRAINT fk_pay_bill FOREIGN KEY (Bill_ID) REFERENCES Bill (Bill_ID) ON DELETE RESTRICT,
    INDEX idx_pay_bill (Bill_ID),
    INDEX idx_pay_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 31: Insurance (Patient to Insurance 1:M)
DROP TABLE IF EXISTS Insurance;
CREATE TABLE Insurance (
    Insurance_ID INT AUTO_INCREMENT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Provider_Name VARCHAR(100) NOT NULL,
    Policy_Number VARCHAR(50) NOT NULL UNIQUE,
    Coverage_Limit DECIMAL(12, 2) NOT NULL CHECK (Coverage_Limit >= 0),
    Valid_From DATE NOT NULL,
    Valid_To DATE NOT NULL,
    Status ENUM('Active', 'Expired', 'Terminated') DEFAULT 'Active',
    CONSTRAINT chk_ins_dates CHECK (Valid_To >= Valid_From),
    CONSTRAINT fk_ins_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE RESTRICT,
    INDEX idx_ins_patient (Patient_ID),
    INDEX idx_ins_policy (Policy_Number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 32: Insurance_Claim (Insurance to Insurance_Claim 1:M)
DROP TABLE IF EXISTS Insurance_Claim;
CREATE TABLE Insurance_Claim (
    Claim_ID INT AUTO_INCREMENT PRIMARY KEY,
    Insurance_ID INT NOT NULL,
    Bill_ID INT NOT NULL,
    Claim_Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Claimed_Amount DECIMAL(10, 2) NOT NULL CHECK (Claimed_Amount > 0),
    Approved_Amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (Approved_Amount >= 0),
    Claim_Status ENUM('Submitted', 'In Review', 'Approved', 'Rejected', 'Settled') DEFAULT 'Submitted',
    Settlement_Date DATE NULL,
    Remarks TEXT,
    CONSTRAINT fk_ic_insurance FOREIGN KEY (Insurance_ID) REFERENCES Insurance (Insurance_ID) ON DELETE RESTRICT,
    CONSTRAINT fk_ic_bill FOREIGN KEY (Bill_ID) REFERENCES Bill (Bill_ID) ON DELETE RESTRICT,
    INDEX idx_ic_insurance (Insurance_ID),
    INDEX idx_ic_bill (Bill_ID),
    INDEX idx_ic_status (Claim_Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- MODULE H: SECURITY AND AUDIT
-- ----------------------------------------------------------------------------

-- Table 33: User_Account
DROP TABLE IF EXISTS User_Account;
CREATE TABLE User_Account (
    User_ID INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password_Hash VARCHAR(255) NOT NULL,
    Role ENUM('Admin', 'Doctor', 'Nurse', 'Pharmacist', 'Receptionist', 'Accountant', 'Patient') NOT NULL,
    Staff_ID INT NULL,
    Patient_ID INT NULL,
    Status ENUM('Active', 'Inactive', 'Suspended') DEFAULT 'Active',
    Last_Login DATETIME NULL,
    Created_At DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_staff FOREIGN KEY (Staff_ID) REFERENCES Staff (Staff_ID) ON DELETE SET NULL,
    CONSTRAINT fk_user_patient FOREIGN KEY (Patient_ID) REFERENCES Patient (Patient_ID) ON DELETE SET NULL,
    INDEX idx_user_role (Role),
    INDEX idx_user_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 34: Audit_Log (User_Account to Audit_Log 1:M)
DROP TABLE IF EXISTS Audit_Log;
CREATE TABLE Audit_Log (
    Log_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT NULL,
    Action VARCHAR(100) NOT NULL,
    Entity_Name VARCHAR(50) NOT NULL,
    Entity_ID INT NULL,
    Old_Values JSON NULL,
    New_Values JSON NULL,
    IP_Address VARCHAR(45),
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user FOREIGN KEY (User_ID) REFERENCES User_Account (User_ID) ON DELETE SET NULL,
    INDEX idx_audit_user (User_ID),
    INDEX idx_audit_entity (Entity_Name, Entity_ID),
    INDEX idx_audit_time (Timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;
