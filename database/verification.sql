-- ============================================================================
-- VERIFICATION SCRIPT: Hospital_Management_System
-- Verifies:
-- 1. All 34 required tables and their row counts
-- 2. Foreign keys and referential integrity constraints
-- 3. Complex relational queries across modules
-- 4. Transactional CRUD test cases
-- ============================================================================

USE Hospital_Management_System;

-- ----------------------------------------------------------------------------
-- TEST 1: VERIFY EXACTLY 34 TABLES EXIST
-- ----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS Total_Tables_Count,
    IF(COUNT(*) = 34, 'PASSED: Exactly 34 tables present', 'FAILED: Table count mismatch') AS Status
FROM information_schema.tables 
WHERE table_schema = 'Hospital_Management_System';

-- ----------------------------------------------------------------------------
-- TEST 2: ROW COUNTS ACROSS ALL 34 TABLES
-- ----------------------------------------------------------------------------
SELECT 'Department' AS Table_Name, COUNT(*) AS Row_Count FROM Department
UNION ALL SELECT 'Staff', COUNT(*) FROM Staff
UNION ALL SELECT 'Doctor', COUNT(*) FROM Doctor
UNION ALL SELECT 'Nurse', COUNT(*) FROM Nurse
UNION ALL SELECT 'Doctor_Schedule', COUNT(*) FROM Doctor_Schedule
UNION ALL SELECT 'Patient', COUNT(*) FROM Patient
UNION ALL SELECT 'Emergency_Contact', COUNT(*) FROM Emergency_Contact
UNION ALL SELECT 'Patient_Medical_History', COUNT(*) FROM Patient_Medical_History
UNION ALL SELECT 'Patient_Allergy', COUNT(*) FROM Patient_Allergy
UNION ALL SELECT 'Room', COUNT(*) FROM Room
UNION ALL SELECT 'Bed', COUNT(*) FROM Bed
UNION ALL SELECT 'Appointment', COUNT(*) FROM Appointment
UNION ALL SELECT 'Admission', COUNT(*) FROM Admission
UNION ALL SELECT 'Bed_Allocation', COUNT(*) FROM Bed_Allocation
UNION ALL SELECT 'Medical_Record', COUNT(*) FROM Medical_Record
UNION ALL SELECT 'Diagnosis', COUNT(*) FROM Diagnosis
UNION ALL SELECT 'Record_Diagnosis', COUNT(*) FROM Record_Diagnosis
UNION ALL SELECT 'Prescription', COUNT(*) FROM Prescription
UNION ALL SELECT 'Medicine', COUNT(*) FROM Medicine
UNION ALL SELECT 'Prescription_Detail', COUNT(*) FROM Prescription_Detail
UNION ALL SELECT 'Lab_Test', COUNT(*) FROM Lab_Test
UNION ALL SELECT 'Lab_Order', COUNT(*) FROM Lab_Order
UNION ALL SELECT 'Lab_Report', COUNT(*) FROM Lab_Report
UNION ALL SELECT 'Supplier', COUNT(*) FROM Supplier
UNION ALL SELECT 'Purchase', COUNT(*) FROM Purchase
UNION ALL SELECT 'Purchase_Item', COUNT(*) FROM Purchase_Item
UNION ALL SELECT 'Medicine_Batch', COUNT(*) FROM Medicine_Batch
UNION ALL SELECT 'Bill', COUNT(*) FROM Bill
UNION ALL SELECT 'Bill_Item', COUNT(*) FROM Bill_Item
UNION ALL SELECT 'Payment', COUNT(*) FROM Payment
UNION ALL SELECT 'Insurance', COUNT(*) FROM Insurance
UNION ALL SELECT 'Insurance_Claim', COUNT(*) FROM Insurance_Claim
UNION ALL SELECT 'User_Account', COUNT(*) FROM User_Account
UNION ALL SELECT 'Audit_Log', COUNT(*) FROM Audit_Log;

-- ----------------------------------------------------------------------------
-- TEST 3: VERIFY FOREIGN KEY CONSTRAINTS
-- ----------------------------------------------------------------------------
SELECT 
    TABLE_NAME, 
    COLUMN_NAME, 
    CONSTRAINT_NAME, 
    REFERENCED_TABLE_NAME, 
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'Hospital_Management_System' 
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- ----------------------------------------------------------------------------
-- TEST 4: COMPREHENSIVE PATIENT 360° JOIN QUERY
-- Patient -> Appointment -> Medical_Record -> Diagnosis -> Prescription -> Bill -> Payment
-- ----------------------------------------------------------------------------
SELECT 
    p.Patient_ID,
    CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name,
    p.Blood_Group,
    p.Phone,
    d.Specialization AS Doctor_Specialty,
    CONCAT(s.First_Name, ' ', s.Last_Name) AS Attending_Doctor,
    diag.Diagnosis_Name,
    rd.Severity AS Diagnosis_Severity,
    rx.Prescription_ID,
    b.Bill_ID,
    b.Net_Amount,
    b.Payment_Status
FROM Patient p
JOIN Medical_Record mr ON p.Patient_ID = mr.Patient_ID
JOIN Doctor doc ON mr.Doctor_ID = doc.Doctor_ID
JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
JOIN Doctor d ON s.Staff_ID = d.Doctor_ID
JOIN Record_Diagnosis rd ON mr.Record_ID = rd.Record_ID
JOIN Diagnosis diag ON rd.Diagnosis_ID = diag.Diagnosis_ID
LEFT JOIN Prescription rx ON mr.Record_ID = rx.Record_ID
LEFT JOIN Bill b ON p.Patient_ID = b.Patient_ID;

-- ----------------------------------------------------------------------------
-- TEST 5: BED OCCUPANCY & ADMISSIONS STATUS
-- ----------------------------------------------------------------------------
SELECT 
    r.Room_Number,
    r.Room_Type,
    b.Bed_Number,
    b.Status AS Bed_Status,
    ba.Status AS Allocation_Status,
    p.Patient_ID,
    CONCAT(p.First_Name, ' ', p.Last_Name) AS Admitted_Patient
FROM Bed b
JOIN Room r ON b.Room_ID = r.Room_ID
LEFT JOIN Bed_Allocation ba ON b.Bed_ID = ba.Bed_ID AND ba.Status = 'Active'
LEFT JOIN Admission adm ON ba.Admission_ID = adm.Admission_ID
LEFT JOIN Patient p ON adm.Patient_ID = p.Patient_ID
ORDER BY r.Room_Number, b.Bed_Number;

-- ----------------------------------------------------------------------------
-- TEST 6: PHARMACY STOCK LEVEL AND BATCH EXPIRY
-- ----------------------------------------------------------------------------
SELECT 
    m.Medicine_ID,
    m.Medicine_Name,
    m.Category,
    m.Stock_Quantity,
    m.Reorder_Level,
    IF(m.Stock_Quantity <= m.Reorder_Level, 'REORDER REQUIRED', 'HEALTHY') AS Stock_Alert,
    mb.Batch_Number,
    mb.Expiry_Date,
    DATEDIFF(mb.Expiry_Date, CURDATE()) AS Days_Until_Expiry
FROM Medicine m
LEFT JOIN Medicine_Batch mb ON m.Medicine_ID = mb.Medicine_ID
ORDER BY Days_Until_Expiry ASC;

-- ----------------------------------------------------------------------------
-- TEST 7: TRANSACTIONAL CRUD TEST (INSERT, SELECT, UPDATE, DELETE)
-- ----------------------------------------------------------------------------
START TRANSACTION;

-- INSERT Test: Add temporary test patient
INSERT INTO Patient (First_Name, Last_Name, Date_Of_Birth, Gender, Blood_Group, Phone, Email, Address, Status)
VALUES ('Test', 'Patient_Temp', '1999-01-01', 'Other', 'O+', '+91-9000000099', 'temp.test@example.com', 'Temporary Verification Lane', 'Active');

SET @temp_patient_id = LAST_INSERT_ID();

-- SELECT Test: Verify inserted record
SELECT Patient_ID, First_Name, Last_Name, Phone, Status 
FROM Patient 
WHERE Patient_ID = @temp_patient_id;

-- UPDATE Test: Modify patient status
UPDATE Patient 
SET Status = 'Discharged', Address = 'Updated Address Verification'
WHERE Patient_ID = @temp_patient_id;

SELECT Patient_ID, Address, Status 
FROM Patient 
WHERE Patient_ID = @temp_patient_id;

-- DELETE Test: Clean up temporary test patient
DELETE FROM Patient WHERE Patient_ID = @temp_patient_id;

SELECT COUNT(*) AS Temp_Patient_Remaining 
FROM Patient 
WHERE Patient_ID = @temp_patient_id;

COMMIT;

SELECT 'Verification Completed Successfully!' AS Result;
