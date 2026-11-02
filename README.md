# Hospital Management System (HMS) - Advanced DBMS PBL Project

A production-grade, full-stack Hospital Management System designed and implemented as an **Advanced DBMS Problem-Based Learning (PBL)** project. The application features a 34-table relational database engine in MySQL 8.0 (InnoDB), a modular Node.js/Express REST backend, and a modern hospital dashboard built with Bootstrap 5 and vanilla JavaScript.

---

## 🏥 Project Overview

- **Database**: MySQL 8.0+ (InnoDB Engine, `utf8mb4` character set, strict foreign-key constraints, CHECK constraints & indexing)
- **Backend**: Node.js & Express.js REST API with `mysql2/promise` connection pooling, JWT authentication, and transactional integrity
- **Frontend**: Responsive Single-Page Application (SPA) dashboard using Bootstrap 5, custom CSS design system, and vanilla JavaScript
- **Security**: Bcrypt password hashing, JWT-based Role-Based Access Control (RBAC), parameterized SQL queries (SQL injection prevention), and immutable audit logging
- **Development Environment**: Windows, Shell: PowerShell / Command Prompt

---

## 🗄️ Database Architecture & Relational Schema (34 Tables)

The database schema `Hospital_Management_System` contains **exactly 34 tables** divided into 8 functional modules:

```
Hospital_Management_System/
├── MODULE A: PATIENT MANAGEMENT (4 Tables)
│   ├── 1. Patient
│   ├── 2. Emergency_Contact
│   ├── 3. Patient_Medical_History
│   └── 4. Patient_Allergy
│
├── MODULE B: DOCTOR AND STAFF MANAGEMENT (5 Tables)
│   ├── 5. Department
│   ├── 6. Staff
│   ├── 7. Doctor (Subtype of Staff)
│   ├── 8. Nurse (Subtype of Staff)
│   └── 9. Doctor_Schedule
│
├── MODULE C: APPOINTMENT AND ADMISSION (5 Tables)
│   ├── 10. Appointment
│   ├── 11. Admission
│   ├── 12. Room
│   ├── 13. Bed
│   └── 14. Bed_Allocation
│
├── MODULE D: MEDICAL RECORDS AND TREATMENT (5 Tables)
│   ├── 15. Medical_Record
│   ├── 16. Diagnosis
│   ├── 17. Record_Diagnosis (M:N Link)
│   ├── 18. Prescription
│   └── 19. Prescription_Detail (M:N Link with Medicine)
│
├── MODULE E: LABORATORY MANAGEMENT (3 Tables)
│   ├── 20. Lab_Test
│   ├── 21. Lab_Order
│   └── 22. Lab_Report
│
├── MODULE F: PHARMACY AND MEDICINE INVENTORY (5 Tables)
│   ├── 23. Medicine
│   ├── 24. Supplier
│   ├── 25. Purchase
│   ├── 26. Purchase_Item (M:N Link with Medicine)
│   └── 27. Medicine_Batch
│
├── MODULE G: BILLING AND INSURANCE (5 Tables)
│   ├── 28. Bill
│   ├── 29. Bill_Item
│   ├── 30. Payment
│   ├── 31. Insurance
│   └── 32. Insurance_Claim
│
└── MODULE H: SECURITY AND AUDIT (2 Tables)
    ├── 33. User_Account
    └── 34. Audit_Log
```

### Key Relational Design Patterns
1. **Specialization / Subtype Tables**: `Doctor` and `Nurse` inherit from `Staff` using their primary key as both the PK and a foreign key (`Doctor_ID REFERENCES Staff(Staff_ID)`, `Nurse_ID REFERENCES Staff(Staff_ID)`).
2. **Many-to-Many (M:N) Relationship Resolvers**:
   - `Record_Diagnosis` bridges `Medical_Record` and `Diagnosis`.
   - `Prescription_Detail` bridges `Prescription` and `Medicine`.
   - `Purchase_Item` bridges `Purchase` and `Medicine`.
3. **One-to-Many (1:M) Hierarchies**:
   - `Patient` -> `Appointment` (1:M)
   - `Patient` -> `Admission` -> `Bed_Allocation` (1:M:M)
   - `Room` -> `Bed` (1:M)
   - `Bill` -> `Bill_Item` (1:M)
   - `Bill` -> `Payment` (1:M)
   - `Insurance` -> `Insurance_Claim` (1:M)
   - `User_Account` -> `Audit_Log` (1:M)
4. **Data Integrity & Constraints**:
   - `CHECK (Salary >= 0)`, `CHECK (Consultation_Fee >= 0)`, `CHECK (Daily_Rate >= 0)`
   - `CHECK (End_Time > Start_Time)` on doctor schedules
   - `CHECK (Expiry_Date > Manufacturing_Date)` on medicine batches
   - `CHECK (Valid_To >= Valid_From)` on insurance policies
   - `UNIQUE (Room_ID, Bed_Number)` on beds

---

## 📁 Project Directory Structure

```
Hospital_Management_System/
│
├── database/
│   ├── database.sql        # Creates database with utf8mb4
│   ├── schema.sql          # DDL for all 34 tables with PK, FK, CHECKs, Indexes
│   ├── seed.sql            # Fictional sample clinical data & bcrypt password hashes
│   └── verification.sql    # 7-phase automated verification script
│
├── backend/
│   ├── config/
│   │   └── db.js           # mysql2/promise connection pool
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── dashboardController.js
│   │   ├── patientController.js
│   │   ├── departmentStaffController.js
│   │   ├── appointmentController.js
│   │   ├── admissionBedController.js
│   │   ├── medicalRecordController.js
│   │   ├── labController.js
│   │   ├── pharmacyController.js
│   │   ├── billingController.js
│   │   └── auditUserController.js
│   ├── middleware/
│   │   ├── auth.js         # JWT verification & RBAC authorization
│   │   ├── audit.js        # Audit logging helper for Table 34
│   │   └── errorHandler.js # Centralized error handler
│   ├── routes/
│   │   └── api.js          # REST API router
│   ├── tests/
│   │   └── api_test.js     # End-to-end automated API test suite
│   ├── server.js           # Express application entrypoint
│   └── package.json        # Dependencies & scripts
│
├── frontend/
│   ├── index.html          # Main responsive SPA dashboard shell
│   ├── login.html          # Authentication portal with quick-fill demo roles
│   ├── css/
│   │   └── style.css       # Custom design system (glassmorphism, medical theme)
│   └── js/
│       └── app.js          # Client-side routing, modals, table renderers & API client
│
├── .env.example            # Environment configuration template
├── .gitignore              # Excluded node_modules & credential files
└── README.md               # Project documentation
```

---

## 🚀 Execution & Setup Instructions

### Prerequisites
1. **Node.js** (v18.0.0 or higher)
2. **MySQL 8.0 Server** (Running on port 3306)

---

### Step 1: Database Setup

Open PowerShell or Command Prompt, navigate to the `database` folder, and run the SQL scripts in order using the MySQL command-line client:

```powershell
# 1. Create the database
mysql -u root -p < database/database.sql

# 2. Build the 34 tables schema
mysql -u root -p Hospital_Management_System < database/schema.sql

# 3. Insert realistic fictional seed data
mysql -u root -p Hospital_Management_System < database/seed.sql

# 4. Run the verification test suite
mysql -u root -p Hospital_Management_System < database/verification.sql
```

*(Note: On Windows PowerShell if the `<` operator gives a parsing message, run via `cmd.exe /c "mysql -u root -p Hospital_Management_System < database\schema.sql"`)*

---

### Step 2: Configure Environment Variables

Create a file named `.env` in the `backend/` directory (or modify the existing one):

```env
PORT=5000
NODE_ENV=development

# MySQL Credentials
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=YourMySQLPasswordHere
DB_NAME=Hospital_Management_System
DB_PORT=3306

# JWT Authentication
JWT_SECRET=HospitalManagementSystem_SuperSecretJwtKey_2026_SecureKey
JWT_EXPIRES_IN=24h
```

---

### Step 3: Install Backend Dependencies

Navigate to the `backend/` directory and install the packages:

```powershell
cd backend
npm install
```

---

### Step 4: Run the Backend & Access Frontend

Start the server:

```powershell
node server.js
```

Once started, open your web browser and navigate to:
👉 **`http://localhost:5000`**

To login with demo accounts, visit:
👉 **`http://localhost:5000/login.html`**

#### Demo Accounts (Password for all: `Admin@123`):
| Username | Role | Associated Staff / Doctor | Access Scope |
| :--- | :--- | :--- | :--- |
| `admin` | Admin | Amit Trivedi (Hospital Admin) | Full Administrative Access |
| `dr.vikram` | Doctor | Dr. Vikram Aditya (Cardiologist) | Clinical Visits, Rx, Orders |
| `dr.meera` | Doctor | Dr. Meera Nambiar (Neurologist) | Clinical Visits, Rx, Orders |
| `nurse.ananya`| Nurse | Ananya Sharma (Cardiac ICU) | Ward Beds, Patient Vitals |
| `pharm.suresh`| Pharmacist| Suresh Babu (Chief Pharmacist) | Drug Inventory, Purchases |
| `recep.kiran` | Receptionist| Kiran Verma | Patient Reg, Appointments |
| `acct.sunil` | Accountant | Sunil Patil | Invoices, Cash Collections |

---

### Step 5: Run Automated Tests

To run the comprehensive 17-point automated API test suite against the live MySQL database:

```powershell
cd backend
npm test
```

Expected output:
```
=============================================================
📊 TEST RESULTS: 17 PASSED, 0 FAILED (TOTAL: 17)
=============================================================
```

---

## 🔌 API Endpoints Catalog

All endpoints are prefixed with `/api`.

| Module | Method | Endpoint | Description |
| :--- | :--- | :--- | :--- |
| **Auth** | `POST` | `/api/auth/login` | Authenticate user & issue JWT token |
| **Auth** | `GET` | `/api/auth/me` | Get authenticated user profile |
| **Dashboard** | `GET` | `/api/dashboard/stats` | Real-time hospital KPI metrics & summaries |
| **Patients** | `GET` | `/api/patients` | List patients with search & blood group filter |
| **Patients** | `GET` | `/api/patients/:id` | Full 360° patient clinical history & profile |
| **Patients** | `POST` | `/api/patients` | Register patient + emergency contact (transaction) |
| **Patients** | `PUT` | `/api/patients/:id` | Update patient demographic details |
| **Patients** | `DELETE` | `/api/patients/:id` | Delete patient record |
| **Doctors** | `GET` | `/api/doctors` | List doctors with specialization and fees |
| **Doctors** | `POST` | `/api/doctors` | Register doctor (Staff + Doctor subtype transaction) |
| **Doctors** | `GET` | `/api/doctors/:id/schedules`| Weekly consultation schedule for doctor |
| **Staff** | `GET` | `/api/staff` | List hospital staff by department and role |
| **Staff** | `GET` | `/api/nurses` | List registered nurses with ward assignments |
| **Departments**| `GET` | `/api/departments` | List departments with head doctor and counts |
| **Appointments**| `GET` | `/api/appointments` | List appointments with filter by date/doctor |
| **Appointments**| `POST` | `/api/appointments` | Book new outpatient consultation appointment |
| **Appointments**| `PATCH` | `/api/appointments/:id/status`| Update status (`Completed`, `Cancelled`) |
| **Rooms & Beds**| `GET` | `/api/rooms` | List hospital rooms with capacity counts |
| **Rooms & Beds**| `GET` | `/api/beds` | List beds with occupancy status |
| **Rooms & Beds**| `GET` | `/api/beds/board` | Visual bed board grouped by room/ward |
| **Admissions** | `GET` | `/api/admissions` | List inpatient admissions |
| **Admissions** | `POST` | `/api/admissions` | Admit patient & allocate available bed (transaction) |
| **Admissions** | `POST` | `/api/admissions/:id/discharge`| Discharge patient & release bed (transaction) |
| **Medical Records**| `GET` | `/api/medical-records` | List clinical encounter records |
| **Medical Records**| `GET` | `/api/medical-records/:id` | Get record with diagnoses and prescription items |
| **Medical Records**| `POST` | `/api/medical-records` | Create encounter with diagnosis & prescription |
| **Diagnoses** | `GET` | `/api/diagnoses` | List ICD-10 diagnosis catalog |
| **Laboratory** | `GET` | `/api/lab/tests` | Catalog of diagnostic tests and rates |
| **Laboratory** | `GET` | `/api/lab/orders` | Lab orders queue |
| **Laboratory** | `POST` | `/api/lab/orders` | Create diagnostic test order |
| **Laboratory** | `POST` | `/api/lab/reports` | Enter laboratory findings & finalize report |
| **Pharmacy** | `GET` | `/api/pharmacy/medicines` | Medicine inventory with low-stock flag |
| **Pharmacy** | `POST` | `/api/pharmacy/medicines` | Add new medicine formulation |
| **Pharmacy** | `GET` | `/api/pharmacy/batches` | Batch expiry tracking surveillance |
| **Pharmacy** | `GET` | `/api/pharmacy/suppliers` | Pharmaceutical suppliers directory |
| **Pharmacy** | `POST` | `/api/pharmacy/purchases` | Record purchase order & increment stock |
| **Billing** | `GET` | `/api/billing/bills` | List patient bills and payment statuses |
| **Billing** | `GET` | `/api/billing/bills/:id` | View itemized invoice, taxes and receipts |
| **Billing** | `POST` | `/api/billing/bills` | Generate invoice with multiple bill items |
| **Billing** | `POST` | `/api/billing/payments` | Record payment (Cash/UPI/Card/Insurance) |
| **Insurance** | `GET` | `/api/billing/insurances`| Registered patient insurance policies |
| **Insurance** | `GET` | `/api/billing/claims` | Insurance claims and cashless settlements |
| **Security** | `GET` | `/api/users` | List system user accounts |
| **Audit** | `GET` | `/api/audit-logs` | Immutable audit trail query with filters |

---

## 🔒 Security & Data Integrity Highlights

1. **SQL Injection Prevention**: 100% of SQL queries executed through parameterized prepared statements (`?` placeholders).
2. **Password Security**: Passwords hashed with salt rounds via `bcryptjs`. No plain-text passwords stored anywhere in the database.
3. **Audit Trail**: Table 34 (`Audit_Log`) records the User ID, action name, affected entity, timestamp, IP address, and JSON diffs of changes.
4. **Database ACID Transactions**:
   - `Patient Registration` creates both patient and emergency contact atomically.
   - `Patient Admission` verifies bed availability with row-locking (`FOR UPDATE`), creates admission, creates bed allocation, and sets bed status to `Occupied` within a single transaction.
   - `Patient Discharge` timestamps discharge, sets bed allocation to `Released`, and frees the bed back to `Available`.
   - `Purchase Orders` update purchase items, generate new medicine batches with expiry dates, and update stock counts within a transaction.

---

## 🔬 Validation Results

1. **Schema Integrity**: Exactly **34 tables** exist in MySQL 8.0 with InnoDB engine.
2. **Referential Integrity**: 45 foreign key constraints validated with `information_schema.KEY_COLUMN_USAGE`.
3. **Data Completeness**: Realistic fictional sample datasets inserted into all 34 tables with 0 truncation errors.
4. **Automated E2E Tests**: 17 integration tests covering authentication, patient CRUD, bed allocation, lab reports, pharmacy stock, and billing passed with **0 failures**.
5. **UI Testing**: SPA dashboard tested and operational on `http://localhost:5000` with interactive modals, tables, and search filters.
