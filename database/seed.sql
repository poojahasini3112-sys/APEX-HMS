-- ============================================================================
-- SEED DATA SCRIPT: Hospital_Management_System
-- Comprehensive realistic fictional sample data for all 34 tables
-- Passwords hashed with bcrypt: 'Admin@123'
-- Hash: $2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG
-- ============================================================================

USE Hospital_Management_System;

SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- 1. MODULE B: DEPARTMENTS & STAFF
-- ----------------------------------------------------------------------------
TRUNCATE TABLE Audit_Log;
TRUNCATE TABLE User_Account;
TRUNCATE TABLE Insurance_Claim;
TRUNCATE TABLE Insurance;
TRUNCATE TABLE Payment;
TRUNCATE TABLE Bill_Item;
TRUNCATE TABLE Bill;
TRUNCATE TABLE Medicine_Batch;
TRUNCATE TABLE Purchase_Item;
TRUNCATE TABLE Purchase;
TRUNCATE TABLE Supplier;
TRUNCATE TABLE Lab_Report;
TRUNCATE TABLE Lab_Order;
TRUNCATE TABLE Lab_Test;
TRUNCATE TABLE Prescription_Detail;
TRUNCATE TABLE Medicine;
TRUNCATE TABLE Prescription;
TRUNCATE TABLE Record_Diagnosis;
TRUNCATE TABLE Diagnosis;
TRUNCATE TABLE Medical_Record;
TRUNCATE TABLE Bed_Allocation;
TRUNCATE TABLE Admission;
TRUNCATE TABLE Appointment;
TRUNCATE TABLE Bed;
TRUNCATE TABLE Room;
TRUNCATE TABLE Patient_Allergy;
TRUNCATE TABLE Patient_Medical_History;
TRUNCATE TABLE Emergency_Contact;
TRUNCATE TABLE Patient;
TRUNCATE TABLE Doctor_Schedule;
TRUNCATE TABLE Nurse;
TRUNCATE TABLE Doctor;
TRUNCATE TABLE Staff;
TRUNCATE TABLE Department;

INSERT INTO Department (Department_ID, Department_Name, Description, Head_Of_Department, Location, Contact_Number) VALUES
(1, 'Cardiology', 'Diagnosis and treatment of congenital heart defects, coronary artery disease and heart failure', NULL, 'Wing A, Floor 2', '+91-9876543001'),
(2, 'Neurology', 'Disorders of the nervous system, brain, spinal cord and peripheral nerves', NULL, 'Wing B, Floor 3', '+91-9876543002'),
(3, 'Orthopedics', 'Musculoskeletal system including bones, joints, ligaments and tendons', NULL, 'Wing A, Floor 1', '+91-9876543003'),
(4, 'Pediatrics', 'Comprehensive medical care for infants, children and adolescents', NULL, 'Wing C, Floor 1', '+91-9876543004'),
(5, 'General Medicine', 'Prevention, diagnosis, and non-surgical treatment of adult diseases', NULL, 'Wing B, Floor 1', '+91-9876543005'),
(6, 'Emergency Medicine', 'Urgent medical care, acute trauma, and critical resuscitation', NULL, 'Ground Floor, ER', '+91-9876543006'),
(7, 'Radiology & Imaging', 'Diagnostic imaging including X-Ray, CT Scan, MRI and Ultrasound', NULL, 'Basement 1', '+91-9876543007'),
(8, 'Pathology & Lab', 'Laboratory testing, clinical biochemistry, and microbiological analysis', NULL, 'Basement 2', '+91-9876543008');

INSERT INTO Staff (Staff_ID, First_Name, Last_Name, Email, Phone, Role, Department_ID, Date_Of_Joining, Salary, Status) VALUES
(1, 'Vikram', 'Aditya', 'vikram.aditya@apexcare.org', '+91-9811122201', 'Doctor', 1, '2021-03-15', 185000.00, 'Active'),
(2, 'Meera', 'Nambiar', 'meera.nambiar@apexcare.org', '+91-9811122202', 'Doctor', 2, '2020-07-01', 190000.00, 'Active'),
(3, 'Rajesh', 'Khanna', 'rajesh.khanna@apexcare.org', '+91-9811122203', 'Doctor', 3, '2019-11-10', 175000.00, 'Active'),
(4, 'Sneha', 'Deshmukh', 'sneha.deshmukh@apexcare.org', '+91-9811122204', 'Doctor', 4, '2022-01-20', 160000.00, 'Active'),
(5, 'Arun', 'Venkatesh', 'arun.venkatesh@apexcare.org', '+91-9811122205', 'Doctor', 5, '2018-05-12', 170000.00, 'Active'),
(6, 'Ananya', 'Sharma', 'ananya.sharma@apexcare.org', '+91-9811122206', 'Nurse', 1, '2022-06-15', 55000.00, 'Active'),
(7, 'Pooja', 'Menon', 'pooja.menon@apexcare.org', '+91-9811122207', 'Nurse', 6, '2021-09-01', 58000.00, 'Active'),
(8, 'Kavita', 'Reddy', 'kavita.reddy@apexcare.org', '+91-9811122208', 'Nurse', 3, '2023-02-10', 52000.00, 'Active'),
(9, 'Suresh', 'Babu', 'suresh.babu@apexcare.org', '+91-9811122209', 'Pharmacist', 5, '2020-04-18', 65000.00, 'Active'),
(10, 'Divya', 'Iyer', 'divya.iyer@apexcare.org', '+91-9811122210', 'Lab Technician', 8, '2021-11-25', 60000.00, 'Active'),
(11, 'Kiran', 'Verma', 'kiran.verma@apexcare.org', '+91-9811122211', 'Receptionist', 5, '2023-03-01', 40000.00, 'Active'),
(12, 'Amit', 'Trivedi', 'amit.trivedi@apexcare.org', '+91-9811122212', 'Admin', 5, '2018-01-10', 95000.00, 'Active'),
(13, 'Sunil', 'Patil', 'sunil.patil@apexcare.org', '+91-9811122213', 'Accountant', 5, '2021-08-14', 70000.00, 'Active');

-- Update Department Heads
UPDATE Department SET Head_Of_Department = 1 WHERE Department_ID = 1;
UPDATE Department SET Head_Of_Department = 2 WHERE Department_ID = 2;
UPDATE Department SET Head_Of_Department = 3 WHERE Department_ID = 3;
UPDATE Department SET Head_Of_Department = 4 WHERE Department_ID = 4;
UPDATE Department SET Head_Of_Department = 5 WHERE Department_ID = 5;

-- Table 7: Doctor Subtype (Staff_ID as Doctor_ID)
INSERT INTO Doctor (Doctor_ID, Specialization, Qualification, License_Number, Consultation_Fee, Room_Number) VALUES
(1, 'Interventional Cardiology', 'MD, DM (Cardiology), FACC', 'MCI-CARD-2021-881', 800.00, 'A-201'),
(2, 'Neurology & Neurophysiology', 'MBBS, MD, DM (Neurology)', 'MCI-NEUR-2020-412', 900.00, 'B-305'),
(3, 'Orthopedic Surgery & Arthroplasty', 'MS (Orthopedics), MCh', 'MCI-ORTH-2019-903', 750.00, 'A-108'),
(4, 'Pediatric Critical Care', 'MD (Pediatrics), DNB', 'MCI-PEDI-2022-119', 600.00, 'C-102'),
(5, 'Internal Medicine & Diabetology', 'MBBS, MD (General Medicine)', 'MCI-GMED-2018-654', 650.00, 'B-104');

-- Table 8: Nurse Subtype (Staff_ID as Nurse_ID)
INSERT INTO Nurse (Nurse_ID, Qualification, License_Number, Shift, Assigned_Ward) VALUES
(6, 'B.Sc. Nursing, Cardiac Critical Care Cert', 'INC-RN-2022-771', 'Morning', 'Cardiac ICU'),
(7, 'B.Sc. Nursing, Trauma Life Support (ATLS)', 'INC-RN-2021-504', 'Rotational', 'Emergency Trauma Unit'),
(8, 'General Nursing and Midwifery (GNM)', 'INC-RN-2023-339', 'Evening', 'Orthopedic Inpatient Ward');

-- Table 9: Doctor_Schedule
INSERT INTO Doctor_Schedule (Schedule_ID, Doctor_ID, Day_Of_Week, Start_Time, End_Time, Max_Appointments, Status) VALUES
(1, 1, 'Monday', '09:00:00', '13:00:00', 15, 'Available'),
(2, 1, 'Wednesday', '09:00:00', '13:00:00', 15, 'Available'),
(3, 1, 'Friday', '14:00:00', '18:00:00', 15, 'Available'),
(4, 2, 'Tuesday', '10:00:00', '14:00:00', 12, 'Available'),
(5, 2, 'Thursday', '10:00:00', '14:00:00', 12, 'Available'),
(6, 3, 'Monday', '14:00:00', '18:00:00', 16, 'Available'),
(7, 3, 'Wednesday', '14:00:00', '18:00:00', 16, 'Available'),
(8, 4, 'Monday', '09:30:00', '13:30:00', 20, 'Available'),
(9, 4, 'Thursday', '09:30:00', '13:30:00', 20, 'Available'),
(10, 5, 'Friday', '09:00:00', '17:00:00', 25, 'Available'),
(11, 5, 'Monday', '09:00:00', '17:00:00', 25, 'Available'),
(12, 5, 'Wednesday', '09:00:00', '17:00:00', 25, 'Available');

-- ----------------------------------------------------------------------------
-- 2. MODULE A: PATIENTS, CONTACTS, MEDICAL HISTORY, ALLERGIES
-- ----------------------------------------------------------------------------
INSERT INTO Patient (Patient_ID, First_Name, Last_Name, Date_Of_Birth, Gender, Blood_Group, Phone, Email, Address, Emergency_Contact_Name, Emergency_Contact_Phone, Registration_Date, Status) VALUES
(1, 'Rohan', 'Gupta', '1985-04-12', 'Male', 'B+', '+91-9123456701', 'rohan.gupta@example.com', '45 MG Road, Indiranagar, Bangalore', 'Neha Gupta', '+91-9123456791', '2024-01-15 10:30:00', 'Active'),
(2, 'Ananya', 'Chatterjee', '1992-08-25', 'Female', 'O+', '+91-9123456702', 'ananya.c@example.com', '12 Salt Lake Sector V, Kolkata', 'Sourav Chatterjee', '+91-9123456792', '2024-02-10 11:15:00', 'Active'),
(3, 'Mohammed', 'Farhan', '1978-11-03', 'Male', 'A+', '+91-9123456703', 'm.farhan@example.com', '78 Banjara Hills Road No 3, Hyderabad', 'Ayesha Farhan', '+91-9123456793', '2024-03-01 09:45:00', 'Active'),
(4, 'Deepika', 'Padukone', '1990-01-05', 'Female', 'AB+', '+91-9123456704', 'deepika.p@example.com', '14 Marine Drive, Nariman Point, Mumbai', 'Prakash Padukone', '+91-9123456794', '2024-03-12 14:00:00', 'Active'),
(5, 'Suresh', 'Raina', '1986-11-27', 'Male', 'O-', '+91-9123456705', 'suresh.r@example.com', '22 Hazratganj, Lucknow', 'Priyanka Raina', '+91-9123456795', '2024-04-05 16:20:00', 'Active'),
(6, 'Priya', 'Sundaram', '1995-06-18', 'Female', 'A-', '+91-9123456706', 'priya.sundaram@example.com', '88 Anna Nagar 2nd Avenue, Chennai', 'Sundaram R', '+91-9123456796', '2024-04-18 08:30:00', 'Active'),
(7, 'Aarav', 'Sharma', '2016-09-14', 'Male', 'B-', '+91-9123456707', 'aarav.sharma.parents@example.com', '56 Model Town, Jalandhar', 'Ritu Sharma', '+91-9123456797', '2024-05-02 12:10:00', 'Active'),
(8, 'Lakshmi', 'Narayanan', '1962-03-30', 'Female', 'AB-', '+91-9123456708', 'lakshmi.n@example.com', '10 Malleswaram 8th Cross, Bangalore', 'Venkatesh Narayanan', '+91-9123456798', '2024-05-20 15:00:00', 'Active');

INSERT INTO Emergency_Contact (Contact_ID, Patient_ID, Contact_Name, Relationship, Phone, Alternate_Phone, Address) VALUES
(1, 1, 'Neha Gupta', 'Spouse', '+91-9123456791', '+91-9123456001', '45 MG Road, Indiranagar, Bangalore'),
(2, 2, 'Sourav Chatterjee', 'Brother', '+91-9123456792', NULL, '12 Salt Lake Sector V, Kolkata'),
(3, 3, 'Ayesha Farhan', 'Spouse', '+91-9123456793', '+91-9123456003', '78 Banjara Hills Road No 3, Hyderabad'),
(4, 4, 'Prakash Padukone', 'Father', '+91-9123456794', NULL, '14 Marine Drive, Nariman Point, Mumbai'),
(5, 5, 'Priyanka Raina', 'Spouse', '+91-9123456795', NULL, '22 Hazratganj, Lucknow'),
(6, 6, 'Sundaram R', 'Father', '+91-9123456796', '+91-9123456006', '88 Anna Nagar 2nd Avenue, Chennai'),
(7, 7, 'Ritu Sharma', 'Mother', '+91-9123456797', NULL, '56 Model Town, Jalandhar'),
(8, 8, 'Venkatesh Narayanan', 'Son', '+91-9123456798', '+91-9123456008', '10 Malleswaram 8th Cross, Bangalore');

INSERT INTO Patient_Medical_History (History_ID, Patient_ID, Condition_Name, Diagnosed_Date, Status, Notes) VALUES
(1, 1, 'Essential Hypertension', '2019-05-10', 'Chronic', 'Controlled with Telmisartan 40mg once daily'),
(2, 1, 'Type 2 Diabetes Mellitus', '2021-08-14', 'Chronic', 'Under HbA1c surveillance, diet regulated'),
(3, 2, 'Migraine with Aura', '2018-02-20', 'Ongoing', 'Unilateral throbbing episodes triggered by stress'),
(4, 3, 'Coronary Artery Disease', '2022-04-11', 'Ongoing', 'Post angioplasty with stent to LAD in 2022'),
(5, 5, 'Lumbar Disc Herniation L4-L5', '2020-09-15', 'In Remission', 'Managed with physiotherapy and ergonomic changes'),
(6, 6, 'Bronchial Asthma', '2015-11-20', 'Chronic', 'Uses Salbutamol inhaler as SOS'),
(7, 7, 'Childhood Febrile Seizures', '2020-03-05', 'Cured', 'Single episode during high grade viral fever'),
(8, 8, 'Osteoarthritis Both Knees', '2017-06-30', 'Chronic', 'Grade 3 changes, scheduled for knee joint assessment');

INSERT INTO Patient_Allergy (Allergy_ID, Patient_ID, Allergen, Reaction, Severity) VALUES
(1, 1, 'Penicillin', 'Urticaria, facial angioedema', 'Severe'),
(2, 2, 'Sulfa Drugs', 'Erythematous rash, pruritus', 'Moderate'),
(3, 3, 'Aspirin', 'Bronchospasm, wheezing', 'Critical'),
(4, 4, 'Peanuts', 'Anaphylactic throat constriction', 'Critical'),
(5, 5, 'Ibuprofen', 'Gastric pain, nausea', 'Mild'),
(6, 6, 'Dust Mites & Pollen', 'Allergic rhinitis and bronchoconstriction', 'Moderate'),
(7, 7, 'Amoxicillin', 'Mild rash across trunk', 'Mild'),
(8, 8, 'Contrast Dye (Iodinated)', 'Skin flushing and hives', 'Moderate');

-- ----------------------------------------------------------------------------
-- 3. MODULE C: ROOMS, BEDS, APPOINTMENTS, ADMISSIONS, ALLOCATIONS
-- ----------------------------------------------------------------------------
INSERT INTO Room (Room_ID, Room_Number, Room_Type, Department_ID, Daily_Rate, Status) VALUES
(1, 'ICU-101', 'ICU', 1, 5500.00, 'Occupied'),
(2, 'ICU-102', 'ICU', 6, 5500.00, 'Available'),
(3, 'PVT-201', 'Private', 5, 3000.00, 'Occupied'),
(4, 'PVT-202', 'Private', 2, 3000.00, 'Available'),
(5, 'SPV-301', 'Semi-Private', 3, 1800.00, 'Occupied'),
(6, 'GEN-401', 'General', 5, 800.00, 'Occupied');

INSERT INTO Bed (Bed_ID, Room_ID, Bed_Number, Status) VALUES
(1, 1, 'ICU-101-A', 'Occupied'),
(2, 1, 'ICU-101-B', 'Available'),
(3, 2, 'ICU-102-A', 'Available'),
(4, 2, 'ICU-102-B', 'Available'),
(5, 3, 'PVT-201-A', 'Occupied'),
(6, 4, 'PVT-202-A', 'Available'),
(7, 5, 'SPV-301-A', 'Occupied'),
(8, 5, 'SPV-301-B', 'Available'),
(9, 6, 'GEN-401-A', 'Occupied'),
(10, 6, 'GEN-401-B', 'Available'),
(11, 6, 'GEN-401-C', 'Available'),
(12, 6, 'GEN-401-D', 'Available');

INSERT INTO Appointment (Appointment_ID, Patient_ID, Doctor_ID, Appointment_Date, Appointment_Time, Reason, Status) VALUES
(1, 1, 1, '2026-11-03', '09:30:00', 'Routine cardiac follow-up and blood pressure evaluation', 'Scheduled'),
(2, 2, 2, '2026-11-03', '10:15:00', 'Persistent throbbing migraine headaches with vision aura', 'Scheduled'),
(3, 3, 1, '2026-11-04', '11:00:00', 'Post-stent annual cardiology evaluation and ECG check', 'Scheduled'),
(4, 4, 3, '2026-11-04', '15:00:00', 'Acute knee pain after sporting activity', 'Scheduled'),
(5, 5, 3, '2026-11-05', '16:00:00', 'Low back pain radiating to left lower limb', 'Scheduled'),
(6, 6, 5, '2026-11-02', '10:00:00', 'Chronic cough and recurrent wheezing on exertion', 'Completed'),
(7, 7, 4, '2026-11-02', '11:30:00', 'Pediatric developmental milestone review & vaccination', 'Completed'),
(8, 8, 5, '2026-11-06', '09:00:00', 'General geriatric checkup and osteoarthritis review', 'Scheduled');

INSERT INTO Admission (Admission_ID, Patient_ID, Admitted_Date, Discharge_Date, Attending_Doctor_ID, Admission_Reason, Admission_Type, Status) VALUES
(1, 3, '2026-10-30 08:00:00', NULL, 1, 'Acute Unstable Angina with ischemic changes', 'Emergency', 'Admitted'),
(2, 1, '2026-10-31 14:30:00', NULL, 5, 'Uncontrolled diabetic ketoacidosis and fever', 'Urgent', 'Admitted'),
(3, 5, '2026-11-01 10:15:00', NULL, 3, 'Elective lumbar decompression surgery', 'Elective', 'Admitted'),
(4, 6, '2026-10-25 12:00:00', '2026-10-28 16:00:00', 5, 'Severe acute exacerbation of bronchial asthma', 'Emergency', 'Discharged'),
(5, 8, '2026-10-20 09:30:00', '2026-10-24 11:00:00', 3, 'Total Knee Replacement Pre-Op Assessment', 'Elective', 'Discharged');

INSERT INTO Bed_Allocation (Allocation_ID, Admission_ID, Bed_ID, Allocated_From, Allocated_To, Status) VALUES
(1, 1, 1, '2026-10-30 08:30:00', NULL, 'Active'),
(2, 2, 5, '2026-10-31 15:00:00', NULL, 'Active'),
(3, 3, 7, '2026-11-01 11:00:00', NULL, 'Active'),
(4, 4, 9, '2026-10-25 12:30:00', '2026-10-28 16:00:00', 'Released'),
(5, 5, 8, '2026-10-20 10:00:00', '2026-10-24 11:00:00', 'Released');

-- ----------------------------------------------------------------------------
-- 4. MODULE D: MEDICAL RECORDS, DIAGNOSES, PRESCRIPTIONS
-- ----------------------------------------------------------------------------
INSERT INTO Medical_Record (Record_ID, Patient_ID, Doctor_ID, Visit_Date, Symptoms, Physical_Examination, Treatment_Notes, Follow_Up_Date) VALUES
(1, 3, 1, '2026-10-30 08:30:00', 'Severe retrosternal squeezing chest pain, radiating to left shoulder, diaphoresis', 'BP 150/95 mmHg, HR 98 bpm, Heart sounds regular, no S3/S4', 'Admitted to Cardiac ICU. Administered loading dose of antiplatelets and sublingual nitrates.', '2026-11-10'),
(2, 1, 5, '2026-10-31 15:00:00', 'Polyuria, polydipsia, high grade fever with chills for 3 days', 'Dehydrated, dry tongue, BP 110/70, Random Blood Sugar 380 mg/dL', 'IV fluid resuscitation started with normal saline and regular insulin infusion protocol.', '2026-11-08'),
(3, 5, 3, '2026-11-01 11:00:00', 'Low back pain radiating along L5 dermatome, positive Straight Leg Raise test at 40 degrees', 'Motor strength 4/5 in left extensor hallucis longus, intact sensation', 'Prepped for lumbar microdiscectomy. Pre-anesthesia clearance secured.', '2026-11-15'),
(4, 6, 5, '2026-11-02 10:30:00', 'Productive cough with yellow sputum, shortness of breath, bilateral expiratory wheeze', 'SpO2 96% on room air, RR 22/min, diffuse polyphonic wheeze on auscultation', 'Prescribed bronchodilator nebulization and short course oral steroids.', '2026-11-09'),
(5, 2, 2, '2026-10-20 10:30:00', 'Unilateral pulsating headache behind right eye with photophobia and nausea', 'Cranial nerves II-XII intact, no meningeal signs, fundoscopy normal', 'Advised lifestyle modification, sleep hygiene, and triptan therapy.', '2026-11-20'),
(6, 4, 3, '2026-10-22 14:30:00', 'Swelling and mechanical popping in right knee after badminton match', 'Lachman test positive, joint effusion present, tenderness over lateral joint line', 'MRI of right knee advised to evaluate anterior cruciate ligament tear.', '2026-11-04'),
(7, 7, 4, '2026-11-02 11:45:00', 'Parent requests periodic physical growth audit and influenza booster vaccination', 'Height 122 cm, Weight 23 kg (50th percentile), normal development', 'Vaccine administered uneventfully in right deltoid. Observation for 30 mins.', '2027-05-02'),
(8, 8, 5, '2026-10-18 10:00:00', 'Bilateral knee stiffness worse in mornings, crepitus during ambulation', 'Bilateral medial joint line tenderness, bony enlargement, no erythema', 'Advised quadriceps strengthening exercises, topical NSAID gel, and calcium supplements.', '2026-11-18');

INSERT INTO Diagnosis (Diagnosis_ID, ICD_Code, Diagnosis_Name, Description, Category) VALUES
(1, 'I20.0', 'Unstable Angina', 'Clinical syndrome characterized by ischemic chest pain occurring with minimal exertion or at rest', 'Cardiovascular'),
(2, 'E11.65', 'Type 2 Diabetes with Hyperglycemia', 'Non-insulin-dependent diabetes mellitus with poor glycemic control', 'Endocrine'),
(3, 'M51.26', 'Intervertebral Disc Displacement L4-L5', 'Lumbosacral disc herniation with nerve root impingement and radiculopathy', 'Musculoskeletal'),
(4, 'J45.909', 'Bronchial Asthma, Unspecified', 'Chronic inflammatory disorder of airways leading to wheeze, breathlessness and chest tightness', 'Respiratory'),
(5, 'G43.109', 'Migraine with Aura, Not Intractable', 'Recurrent neurological disorder presenting with reversible visual aura and throbbing hemicrania', 'Neurological'),
(6, 'S83.511A', 'Sprain of Anterior Cruciate Ligament Right Knee', 'Traumatic tear or stretch of the ACL ligament of right knee joint', 'Musculoskeletal'),
(7, 'Z00.129', 'Routine Child Health Examination', 'Encounter for routine child health check with normal findings', 'Preventive'),
(8, 'M17.0', 'Bilateral Primary Osteoarthritis of Knee', 'Degenerative joint disease of both knee joints involving cartilage loss and osteophytes', 'Musculoskeletal');

INSERT INTO Record_Diagnosis (Record_ID, Diagnosis_ID, Severity) VALUES
(1, 1, 'Primary'),
(2, 2, 'Primary'),
(3, 3, 'Primary'),
(4, 4, 'Primary'),
(5, 5, 'Primary'),
(6, 6, 'Primary'),
(7, 7, 'Primary'),
(8, 8, 'Primary'),
(1, 2, 'Secondary');

INSERT INTO Prescription (Prescription_ID, Record_ID, Patient_ID, Doctor_ID, Prescribed_Date, Instructions) VALUES
(1, 1, 3, 1, '2026-10-30 09:00:00', 'Take after meals. Monitor for any signs of bleeding. Maintain strict low salt diet.'),
(2, 2, 1, 5, '2026-10-31 15:30:00', 'Administer insulin as per sliding scale before meals. Drink at least 2.5 liters of water daily.'),
(3, 3, 5, 3, '2026-11-01 11:30:00', 'Analgesic cover for post-operative pain. Avoid bending and heavy lifting.'),
(4, 4, 6, 5, '2026-11-02 11:00:00', 'Rinse mouth thoroughly with warm water after using the inhaler to prevent oral candidiasis.'),
(5, 5, 2, 2, '2026-10-20 11:00:00', 'Take Sumatriptan at the earliest onset of visual aura or throbbing pain.'),
(6, 6, 4, 3, '2026-10-22 15:00:00', 'Apply cold compress for 15 minutes twice daily. Use knee brace during walking.'),
(7, 7, 7, 4, '2026-11-02 12:00:00', 'Paracetamol syrup SOS in case of mild post-vaccine pyrexia.'),
(8, 8, 8, 5, '2026-10-18 10:30:00', 'Take calcium and vitamin D supplement with breakfast. Topical gel to knees twice daily.');

-- ----------------------------------------------------------------------------
-- 5. MODULE F: PHARMACY, MEDICINES, SUPPLIERS, PURCHASES
-- ----------------------------------------------------------------------------
INSERT INTO Medicine (Medicine_ID, Medicine_Name, Generic_Name, Category, Unit_Price, Stock_Quantity, Reorder_Level, Manufacturer) VALUES
(1, 'Atorvastatin 20mg', 'Atorvastatin Calcium', 'Cardiovascular', 15.50, 450, 50, 'Sun Pharmaceutical Ltd'),
(2, 'Telmisartan 40mg', 'Telmisartan', 'Antihypertensive', 12.00, 520, 60, 'Cipla Therapeutics'),
(3, 'Metformin 500mg', 'Metformin Hydrochloride', 'Antidiabetic', 5.50, 800, 100, 'Torrent Pharmaceuticals'),
(4, 'Clopidogrel 75mg', 'Clopidogrel Bisulfate', 'Antiplatelet', 18.00, 320, 40, 'Sanofi India'),
(5, 'Human Actrapid 100IU/ml', 'Regular Soluble Insulin', 'Antidiabetic', 240.00, 85, 20, 'Novo Nordisk'),
(6, 'Paracetamol 650mg', 'Acetaminophen', 'Antipyretic & Analgesic', 3.00, 1200, 150, 'Micro Labs Ltd'),
(7, 'Amoxicillin-Clavulanate 625mg', 'Amoxicillin + Clavulanic Acid', 'Antibiotic', 24.50, 380, 50, 'GlaxoSmithKline India'),
(8, 'Salbutamol Inhaler 100mcg', 'Albuterol Sulfate', 'Respiratory', 165.00, 110, 25, 'Cipla Ltd'),
(9, 'Sumatriptan 50mg', 'Sumatriptan Succinate', 'Neurological', 42.00, 140, 30, 'Sun Pharmaceutical Ltd'),
(10, 'Pregabalin 75mg', 'Pregabalin', 'Analgesic / Neuro', 28.00, 210, 40, 'Lupin Limited');

INSERT INTO Prescription_Detail (Prescription_Detail_ID, Prescription_ID, Medicine_ID, Dosage, Frequency, Duration_Days, Quantity, Notes) VALUES
(1, 1, 4, '75mg', 'Once daily at bedtime', 30, 30, 'Blood thinner - do not stop suddenly'),
(2, 1, 1, '20mg', 'Once daily at bedtime', 30, 30, 'Cholesterol regulating statin'),
(3, 2, 5, '8 Units', 'Three times daily before food', 14, 2, 'Subcutaneous insulin injection'),
(4, 2, 3, '500mg', 'Twice daily with meals', 30, 60, 'Glycemic control agent'),
(5, 3, 10, '75mg', 'Once daily at night', 15, 15, 'Neuropathic pain relief'),
(6, 3, 6, '650mg', 'SOS every 8 hours', 5, 10, 'For pain relief if required'),
(7, 4, 8, '2 Puffs', 'Twice daily and SOS', 30, 1, 'Inhale deeply through spacer'),
(8, 4, 7, '625mg', 'Twice daily after food', 7, 14, 'Complete full 7-day course'),
(9, 5, 9, '50mg', 'At headache onset', 10, 6, 'Max 2 tablets in 24 hours'),
(10, 8, 6, '650mg', 'As needed for joint ache', 15, 20, 'Do not exceed 3 tablets a day');

INSERT INTO Supplier (Supplier_ID, Supplier_Name, Contact_Person, Phone, Email, Address, Status) VALUES
(1, 'MedPharma Distributors Pvt Ltd', 'Ramesh Kothari', '+91-9845012345', 'ramesh@medpharma.in', 'Building 4B, Peenya Industrial Area, Bangalore', 'Active'),
(2, 'Global Healthcare Logistics', 'Sunita Rao', '+91-9845012346', 'orders@globalhealthlog.com', 'Plot 29, Turbhe MIDC, Navi Mumbai', 'Active'),
(3, 'Apex Lifesciences Wholesale', 'Harish Chandra', '+91-9845012347', 'harish@apexlifesciences.org', '18 Industrial Estate, Guindy, Chennai', 'Active'),
(4, 'Zenith Surgical & Pharma Supplies', 'Mohit Jain', '+91-9845012348', 'sales@zenithsurg.com', '72 Okhla Phase III, New Delhi', 'Active'),
(5, 'LifeLine Medical Equipment Ltd', 'Pooja Agarwal', '+91-9845012349', 'care@lifelinemed.in', '54 Somajiguda, Hyderabad', 'Active');

INSERT INTO Purchase (Purchase_ID, Supplier_ID, Purchase_Date, Total_Amount, Status, Invoice_Number) VALUES
(1, 1, '2026-10-01 10:00:00', 45000.00, 'Received', 'INV-MED-2026-101'),
(2, 2, '2026-10-08 11:30:00', 62500.00, 'Received', 'INV-MED-2026-102'),
(3, 3, '2026-10-15 14:00:00', 38000.00, 'Received', 'INV-MED-2026-103'),
(4, 1, '2026-10-22 09:45:00', 18500.00, 'Received', 'INV-MED-2026-104'),
(5, 4, '2026-10-28 16:15:00', 54000.00, 'Ordered', 'INV-MED-2026-105');

INSERT INTO Purchase_Item (Purchase_Item_ID, Purchase_ID, Medicine_ID, Quantity, Unit_Cost, Total_Price) VALUES
(1, 1, 1, 500, 11.00, 5500.00),
(2, 1, 2, 600, 8.50, 5100.00),
(3, 1, 3, 1000, 3.80, 3800.00),
(4, 2, 4, 400, 13.50, 5400.00),
(5, 2, 5, 100, 185.00, 18500.00),
(6, 3, 6, 2000, 2.10, 4200.00),
(7, 3, 7, 500, 18.00, 9000.00),
(8, 4, 8, 150, 120.00, 18000.00);

INSERT INTO Medicine_Batch (Batch_ID, Medicine_ID, Batch_Number, Manufacturing_Date, Expiry_Date, Quantity, Purchase_Item_ID) VALUES
(1, 1, 'BAT-ATOR-26A', '2026-08-01', '2028-07-31', 450, 1),
(2, 2, 'BAT-TELM-26B', '2026-07-15', '2028-06-30', 520, 2),
(3, 3, 'BAT-METF-26C', '2026-09-01', '2029-08-31', 800, 3),
(4, 4, 'BAT-CLOP-26D', '2026-08-10', '2028-07-31', 320, 4),
(5, 5, 'BAT-INSU-26E', '2026-09-20', '2027-09-19', 85, 5),
(6, 6, 'BAT-PARA-26F', '2026-10-01', '2029-09-30', 1200, 6),
(7, 7, 'BAT-AUGM-26G', '2026-09-10', '2028-08-31', 380, 7),
(8, 8, 'BAT-SALB-26H', '2026-08-25', '2028-08-24', 110, 8);

-- ----------------------------------------------------------------------------
-- 6. MODULE E: LABORATORY TESTS, ORDERS, REPORTS
-- ----------------------------------------------------------------------------
INSERT INTO Lab_Test (Test_ID, Test_Name, Category, Cost, Normal_Range, Unit, Description) VALUES
(1, 'Complete Blood Count (CBC)', 'Hematology', 450.00, 'Reference profile', 'Profile', 'WBC, RBC, Hemoglobin, Hematocrit, Platelets and differential count'),
(2, 'Lipid Profile', 'Biochemistry', 850.00, 'Total Chol < 200, LDL < 100', 'mg/dL', 'Total cholesterol, HDL, LDL, VLDL and Triglycerides'),
(3, 'Fasting & Postprandial Blood Glucose', 'Biochemistry', 250.00, 'Fasting: 70-99, PP: < 140', 'mg/dL', 'Venous plasma glucose for diabetes mellitus evaluation'),
(4, 'Liver Function Test (LFT)', 'Biochemistry', 900.00, 'Bilirubin < 1.2, SGOT < 40', 'U/L', 'Serum Bilirubin, SGOT, SGPT, Alkaline Phosphatase, Total Protein, Albumin'),
(5, 'Digital Chest X-Ray PA View', 'Radiology', 600.00, 'Normal lung fields & cardiothoracic ratio', 'Images', 'High resolution radiograph of chest, thoracic spine and ribs'),
(6, 'MRI Brain with Contrast', 'Radiology', 6500.00, 'No acute infarct or mass effect', 'Scans', 'Magnetic resonance imaging for cerebral parenchymal evaluation'),
(7, 'Urine Routine and Microscopy', 'Clinical Pathology', 200.00, 'Clear, pale yellow, protein absent', 'Microscopy', 'Physical, chemical and microscopic sediment analysis'),
(8, 'Troponin-I Quantitative', 'Cardiac Markers', 1200.00, '< 0.04', 'ng/mL', 'High sensitivity cardiac biomarker for myocardial infarction');

INSERT INTO Lab_Order (Order_ID, Patient_ID, Doctor_ID, Test_ID, Order_Date, Priority, Status) VALUES
(1, 3, 1, 8, '2026-10-30 08:45:00', 'STAT', 'Completed'),
(2, 3, 1, 2, '2026-10-30 09:00:00', 'Routine', 'Completed'),
(3, 1, 5, 3, '2026-10-31 15:15:00', 'Urgent', 'Completed'),
(4, 1, 5, 1, '2026-10-31 15:15:00', 'Routine', 'Completed'),
(5, 6, 5, 5, '2026-11-02 10:45:00', 'Urgent', 'Completed'),
(6, 2, 2, 6, '2026-10-20 10:45:00', 'Routine', 'Completed'),
(7, 4, 3, 1, '2026-11-02 14:00:00', 'Routine', 'Pending'),
(8, 8, 5, 4, '2026-11-02 16:00:00', 'Routine', 'In Progress');

INSERT INTO Lab_Report (Report_ID, Order_ID, Conducted_By, Result_Value, Comments, Report_Date, Status) VALUES
(1, 1, 10, '1.85 ng/mL (High)', 'Elevated cardiac Troponin-I diagnostic of acute coronary syndrome.', '2026-10-30 09:30:00', 'Critical'),
(2, 2, 10, 'Total Chol: 245 mg/dL, LDL: 165 mg/dL, HDL: 38 mg/dL, Trig: 210 mg/dL', 'Dyslipidemia with atherogenic lipid profile.', '2026-10-30 14:00:00', 'Abnormal'),
(3, 3, 10, 'Fasting: 240 mg/dL, Postprandial: 380 mg/dL', 'Marked hyperglycemia consistent with acute diabetic decompensation.', '2026-10-31 16:30:00', 'Critical'),
(4, 4, 10, 'Hb: 13.5 g/dL, Total WBC: 14,200 /cu.mm, Platelets: 280,000 /cu.mm', 'Leukocytosis with neutrophilic predominance suggesting underlying infection.', '2026-10-31 16:45:00', 'Abnormal'),
(5, 5, 10, 'Hyperinflated lung fields, flattened diaphragms, no focal consolidation.', 'Findings suggestive of acute bronchial asthma with hyperaeration.', '2026-11-02 11:30:00', 'Normal'),
(6, 6, 10, 'Brain parenchyma unremarkable. No intra-axial hemorrhage, acute ischemic stroke or mass lesion.', 'Normal MRI scan of brain with contrast.', '2026-10-21 15:00:00', 'Normal');

-- ----------------------------------------------------------------------------
-- 7. MODULE G: BILLING, BILL ITEMS, PAYMENTS, INSURANCE & CLAIMS
-- ----------------------------------------------------------------------------
INSERT INTO Bill (Bill_ID, Patient_ID, Admission_ID, Bill_Date, Total_Amount, Discount_Amount, Tax_Amount, Net_Amount, Paid_Amount, Payment_Status) VALUES
(1, 3, 1, '2026-10-31 18:00:00', 32000.00, 2000.00, 1500.00, 31500.00, 31500.00, 'Paid'),
(2, 1, 2, '2026-11-01 12:00:00', 14500.00, 500.00, 700.00, 14700.00, 10000.00, 'Partially Paid'),
(3, 6, 4, '2026-10-28 15:30:00', 12800.00, 800.00, 600.00, 12600.00, 12600.00, 'Paid'),
(4, 2, NULL, '2026-10-20 11:30:00', 7400.00, 0.00, 370.00, 7770.00, 7770.00, 'Paid'),
(5, 5, 3, '2026-11-01 14:00:00', 25000.00, 1000.00, 1200.00, 25200.00, 0.00, 'Pending'),
(6, 4, NULL, '2026-10-22 15:30:00', 1350.00, 0.00, 67.50, 1417.50, 1417.50, 'Paid');

INSERT INTO Bill_Item (Bill_Item_ID, Bill_ID, Item_Type, Description, Quantity, Unit_Price, Total_Price) VALUES
(1, 1, 'Room Charge', 'Cardiac ICU Bed charges (2 days)', 2, 5500.00, 11000.00),
(2, 1, 'Consultation', 'Consultant Cardiologist emergency visit & rounds', 2, 800.00, 1600.00),
(3, 1, 'Lab Test', 'Cardiac Troponin-I & Lipid Profile', 1, 2050.00, 2050.00),
(4, 1, 'Procedure', 'Coronary Angiography emergency screening', 1, 15000.00, 15000.00),
(5, 1, 'Medicine', 'Emergency IV infusions and statin loading', 1, 2350.00, 2350.00),
(6, 2, 'Room Charge', 'Private Room Bed charges (1 day)', 1, 3000.00, 3000.00),
(7, 2, 'Consultation', 'Internal Medicine Specialist Consultation', 1, 650.00, 650.00),
(8, 2, 'Lab Test', 'Fasting & PP Glucose, Complete Blood Count', 1, 700.00, 700.00),
(9, 2, 'Medicine', 'Insulin vials, IV Normal Saline infusions', 1, 10150.00, 10150.00),
(10, 3, 'Room Charge', 'General Ward Bed charges (3 days)', 3, 800.00, 2400.00),
(11, 3, 'Consultation', 'Pulmonology & General Medicine follow-up visits', 3, 650.00, 1950.00),
(12, 3, 'Lab Test', 'Digital Chest X-Ray PA View', 1, 600.00, 600.00),
(13, 3, 'Procedure', 'Continuous Nebulization therapy sessions (8)', 8, 250.00, 2000.00),
(14, 3, 'Medicine', 'Antibiotics, bronchodilators and IV steroids', 1, 5850.00, 5850.00),
(15, 4, 'Consultation', 'Neurology Specialist Initial Consultation', 1, 900.00, 900.00),
(16, 4, 'Lab Test', 'MRI Brain with Contrast', 1, 6500.00, 6500.00);

INSERT INTO Payment (Payment_ID, Bill_ID, Payment_Date, Amount, Payment_Method, Transaction_Reference, Status) VALUES
(1, 1, '2026-10-31 18:30:00', 31500.00, 'Insurance', 'TXN-INS-CLAIM-8821', 'Completed'),
(2, 2, '2026-11-01 12:30:00', 10000.00, 'UPI', 'UPI-HDFC-9923847291', 'Completed'),
(3, 3, '2026-10-28 16:00:00', 12600.00, 'Credit Card', 'CC-AUTH-AXIS-771249', 'Completed'),
(4, 4, '2026-10-20 11:45:00', 7770.00, 'Debit Card', 'DC-AUTH-SBI-4439120', 'Completed'),
(5, 6, '2026-10-22 15:45:00', 1417.50, 'UPI', 'UPI-ICICI-66281903', 'Completed');

INSERT INTO Insurance (Insurance_ID, Patient_ID, Provider_Name, Policy_Number, Coverage_Limit, Valid_From, Valid_To, Status) VALUES
(1, 3, 'Star Health & Allied Insurance', 'SHAI-POL-2023-8829', 500000.00, '2024-01-01', '2027-12-31', 'Active'),
(2, 1, 'HDFC ERGO Health Suraksha', 'HDFC-HS-2022-4410', 750000.00, '2023-05-15', '2027-05-14', 'Active'),
(3, 5, 'ICICI Lombard Complete Health', 'ICICI-CH-2021-9923', 1000000.00, '2022-03-01', '2028-02-28', 'Active'),
(4, 6, 'Care Health Insurance', 'CARE-HI-2023-1184', 400000.00, '2023-10-01', '2026-12-31', 'Active'),
(5, 8, 'Max Bupa Senior First', 'MAXB-SF-2020-6642', 300000.00, '2021-04-10', '2027-04-09', 'Active');

INSERT INTO Insurance_Claim (Claim_ID, Insurance_ID, Bill_ID, Claim_Date, Claimed_Amount, Approved_Amount, Claim_Status, Settlement_Date, Remarks) VALUES
(1, 1, 1, '2026-10-31 18:15:00', 31500.00, 31500.00, 'Settled', '2026-10-31', 'Emergency cardiac admission cashless claim approved 100%'),
(2, 3, 5, '2026-11-01 14:30:00', 25200.00, 22000.00, 'Approved', NULL, 'Pre-authorization approved for lumbar decompression surgery'),
(3, 2, 2, '2026-11-01 13:00:00', 4700.00, 0.00, 'In Review', NULL, 'Co-payment assessment under verification'),
(4, 4, 3, '2026-10-28 15:45:00', 12600.00, 12600.00, 'Settled', '2026-10-28', 'Cashless reimbursement settled for acute asthma care');

-- ----------------------------------------------------------------------------
-- 8. MODULE H: USER ACCOUNTS & AUDIT LOGS
-- ----------------------------------------------------------------------------
-- Standard password for all seed accounts: Admin@123
INSERT INTO User_Account (User_ID, Username, Password_Hash, Role, Staff_ID, Patient_ID, Status, Last_Login) VALUES
(1, 'admin', '$2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG', 'Admin', 12, NULL, 'Active', '2026-11-02 08:30:00'),
(2, 'dr.vikram', '$2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG', 'Doctor', 1, NULL, 'Active', '2026-11-02 09:00:00'),
(3, 'dr.meera', '$2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG', 'Doctor', 2, NULL, 'Active', '2026-11-01 14:15:00'),
(4, 'dr.rajesh', '$2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG', 'Doctor', 3, NULL, 'Active', '2026-11-01 16:30:00'),
(5, 'nurse.ananya', '$2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG', 'Nurse', 6, NULL, 'Active', '2026-11-02 07:00:00'),
(6, 'pharm.suresh', '$2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG', 'Pharmacist', 9, NULL, 'Active', '2026-11-02 08:45:00'),
(7, 'lab.divya', '$2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG', 'Admin', 10, NULL, 'Active', '2026-11-02 09:15:00'),
(8, 'recep.kiran', '$2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG', 'Receptionist', 11, NULL, 'Active', '2026-11-02 08:00:00'),
(9, 'acct.sunil', '$2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG', 'Accountant', 13, NULL, 'Active', '2026-11-02 08:15:00'),
(10, 'patient.rohan', '$2b$10$QwYhWFbv4lucXvcjtFgAJOw/4vhLpbkO0YAuS95OwRWG7J/QuvsjG', 'Patient', NULL, 1, 'Active', '2026-10-31 10:00:00');

INSERT INTO Audit_Log (Log_ID, User_ID, Action, Entity_Name, Entity_ID, Old_Values, New_Values, IP_Address, Timestamp) VALUES
(1, 1, 'USER_LOGIN', 'User_Account', 1, NULL, '{"status": "success", "username": "admin"}', '127.0.0.1', '2026-11-02 08:30:00'),
(2, 8, 'REGISTER_PATIENT', 'Patient', 8, NULL, '{"first_name": "Lakshmi", "last_name": "Narayanan", "phone": "+91-9123456708"}', '192.168.1.15', '2024-05-20 15:00:00'),
(3, 2, 'CREATE_MEDICAL_RECORD', 'Medical_Record', 1, NULL, '{"patient_id": 3, "doctor_id": 1, "diagnosis": "Unstable Angina"}', '192.168.1.20', '2026-10-30 08:35:00'),
(4, 2, 'ISSUE_PRESCRIPTION', 'Prescription', 1, NULL, '{"record_id": 1, "patient_id": 3, "items_count": 2}', '192.168.1.20', '2026-10-30 09:00:00'),
(5, 7, 'COMPLETE_LAB_REPORT', 'Lab_Report', 1, '{"status": "Pending"}', '{"status": "Completed", "result": "1.85 ng/mL"}', '192.168.1.45', '2026-10-30 09:30:00'),
(6, 9, 'GENERATE_BILL', 'Bill', 1, NULL, '{"patient_id": 3, "net_amount": 31500.00}', '192.168.1.30', '2026-10-31 18:00:00'),
(7, 9, 'PROCESS_PAYMENT', 'Payment', 1, NULL, '{"bill_id": 1, "amount": 31500.00, "method": "Insurance"}', '192.168.1.30', '2026-10-31 18:30:00'),
(8, 8, 'SCHEDULE_APPOINTMENT', 'Appointment', 1, NULL, '{"patient_id": 1, "doctor_id": 1, "date": "2026-11-03"}', '192.168.1.15', '2026-11-01 10:00:00'),
(9, 6, 'UPDATE_STOCK', 'Medicine', 1, '{"old_stock": 400}', '{"new_stock": 450}', '192.168.1.50', '2026-11-01 11:00:00'),
(10, 1, 'UPDATE_STAFF', 'Staff', 1, '{"salary": 175000}', '{"salary": 185000}', '127.0.0.1', '2026-11-01 17:00:00');

SET FOREIGN_KEY_CHECKS = 1;
