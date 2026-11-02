/**
 * Automated End-to-End API Test Suite
 * Tests REST endpoints across all modules against the live database
 */

const { app, server } = require('../server');

const BASE_URL = 'http://localhost:5000/api';
let authToken = '';

async function runTests() {
  console.log('\n=============================================================');
  console.log('🧪 RUNNING COMPREHENSIVE API TEST SUITE');
  console.log('=============================================================\n');

  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`  ✅ [PASS] ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ❌ [FAIL] ${name}: ${err.message}`);
      failed++;
    }
  }

  // Allow server a moment to bind port
  await new Promise(r => setTimeout(r, 800));

  try {
    // 1. Auth Test
    await test('POST /api/auth/login - Admin Login', async () => {
      const res = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: 'admin', password: 'Admin@123' })
      });
      const data = await res.json();
      if (!res.ok || !data.token) throw new Error(data.message || 'Login failed');
      authToken = data.token;
      if (data.user.role !== 'Admin') throw new Error('Role is not Admin');
    });

    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${authToken}`
    };

    // 2. Dashboard Stats
    await test('GET /api/dashboard/stats - Verify KPI Metrics', async () => {
      const res = await fetch(`${BASE_URL}/dashboard/stats`, { headers });
      const data = await res.json();
      if (!data.success || !data.stats) throw new Error('Failed to fetch dashboard stats');
      if (data.stats.totalPatients < 8) throw new Error(`Expected at least 8 patients, got ${data.stats.totalPatients}`);
      if (data.stats.totalBeds !== 12) throw new Error(`Expected 12 beds, got ${data.stats.totalBeds}`);
    });

    // 3. Patients API
    let newPatientId = null;
    await test('GET /api/patients - List Patients', async () => {
      const res = await fetch(`${BASE_URL}/patients`, { headers });
      const data = await res.json();
      if (!data.success || data.count < 8) throw new Error('Patients count mismatch');
    });

    await test('POST /api/patients - Register New Patient Transactionally', async () => {
      const res = await fetch(`${BASE_URL}/patients`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          firstName: 'Siddharth',
          lastName: 'Malhotra',
          dateOfBirth: '1993-07-21',
          gender: 'Male',
          bloodGroup: 'O+',
          phone: '+91-9988776655',
          email: 'siddharth.m@example.com',
          address: '77 Bandra West, Mumbai',
          emergencyContactName: 'Kiara Malhotra',
          emergencyContactPhone: '+91-9988776650',
          relationship: 'Spouse',
          initialCondition: 'Mild Hyperlipidemia',
          knownAllergen: 'Sulfa Drugs',
          allergenReaction: 'Skin Rash'
        })
      });
      const data = await res.json();
      if (!data.success || !data.patientId) throw new Error(data.message || 'Registration failed');
      newPatientId = data.patientId;
    });

    await test('GET /api/patients/:id - Patient 360 Degree View', async () => {
      const res = await fetch(`${BASE_URL}/patients/${newPatientId}`, { headers });
      const data = await res.json();
      if (!data.success || data.data.First_Name !== 'Siddharth') throw new Error('Profile mismatch');
      if (data.data.emergencyContacts.length === 0) throw new Error('Emergency contact missing');
      if (data.data.allergies.length === 0) throw new Error('Allergy missing');
    });

    // 4. Doctor & Staff API
    await test('GET /api/doctors - List Doctors', async () => {
      const res = await fetch(`${BASE_URL}/doctors`, { headers });
      const data = await res.json();
      if (!data.success || data.count < 5) throw new Error('Doctor count mismatch');
    });

    await test('GET /api/departments - List Departments', async () => {
      const res = await fetch(`${BASE_URL}/departments`, { headers });
      const data = await res.json();
      if (!data.success || data.count < 8) throw new Error('Departments count mismatch');
    });

    // 5. Appointments API
    let newApptId = null;
    await test('POST /api/appointments - Schedule Appointment', async () => {
      const res = await fetch(`${BASE_URL}/appointments`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          patientId: newPatientId,
          doctorId: 1,
          appointmentDate: '2026-11-20',
          appointmentTime: '10:00:00',
          reason: 'Cardiac wellness checkup'
        })
      });
      const data = await res.json();
      if (!data.success || !data.appointmentId) throw new Error(data.message || 'Scheduling failed');
      newApptId = data.appointmentId;
    });

    await test('PATCH /api/appointments/:id/status - Update Appointment Status', async () => {
      const res = await fetch(`${BASE_URL}/appointments/${newApptId}/status`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({ status: 'Completed' })
      });
      const data = await res.json();
      if (!data.success) throw new Error(data.message || 'Status update failed');
    });

    // 6. Beds & Rooms
    await test('GET /api/beds/board - Live Bed Grid', async () => {
      const res = await fetch(`${BASE_URL}/beds/board`, { headers });
      const data = await res.json();
      if (!data.success || !Array.isArray(data.data)) throw new Error('Failed to fetch bed board');
    });

    // 7. Medical Records
    await test('POST /api/medical-records - Create Record with Diagnosis & Prescription', async () => {
      const res = await fetch(`${BASE_URL}/medical-records`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          patientId: newPatientId,
          doctorId: 1,
          symptoms: 'Mild chest tightness upon brisk walking',
          physicalExamination: 'BP 130/80, HR 72, Normal heart sounds',
          treatmentNotes: 'Advised lifestyle modification and daily statin',
          followUpDate: '2026-12-20',
          diagnosisIds: [1],
          prescriptionInstructions: 'Take statin tablet once every night after food',
          prescriptionItems: [
            { medicineId: 1, dosage: '20mg', frequency: 'Once daily at bedtime', durationDays: 30, quantity: 30 }
          ]
        })
      });
      const data = await res.json();
      if (!data.success || !data.recordId) throw new Error(data.message || 'Record creation failed');
    });

    // 8. Laboratory
    await test('GET /api/lab/tests - List Lab Tests Catalog', async () => {
      const res = await fetch(`${BASE_URL}/lab/tests`, { headers });
      const data = await res.json();
      if (!data.success || data.count < 8) throw new Error('Lab tests count mismatch');
    });

    await test('POST /api/lab/orders - Place Lab Order', async () => {
      const res = await fetch(`${BASE_URL}/lab/orders`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          patientId: newPatientId,
          doctorId: 1,
          testId: 2, // Lipid Profile
          priority: 'Routine'
        })
      });
      const data = await res.json();
      if (!data.success || !data.orderId) throw new Error(data.message || 'Lab order failed');
    });

    // 9. Pharmacy & Stock
    await test('GET /api/pharmacy/medicines - List Medicines with Stock Alert', async () => {
      const res = await fetch(`${BASE_URL}/pharmacy/medicines`, { headers });
      const data = await res.json();
      if (!data.success || data.count < 10) throw new Error('Medicines count mismatch');
    });

    // 10. Billing & Payments
    let newBillId = null;
    await test('POST /api/billing/bills - Generate Bill with Items', async () => {
      const res = await fetch(`${BASE_URL}/billing/bills`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          patientId: newPatientId,
          discountAmount: 100,
          taxAmount: 50,
          items: [
            { itemType: 'Consultation', description: 'Cardiology Specialist Consultation', quantity: 1, unitPrice: 800 },
            { itemType: 'Lab Test', description: 'Lipid Profile Blood Test', quantity: 1, unitPrice: 850 }
          ]
        })
      });
      const data = await res.json();
      if (!data.success || !data.billId) throw new Error(data.message || 'Bill creation failed');
      newBillId = data.billId;
    });

    await test('POST /api/billing/payments - Record Payment', async () => {
      const res = await fetch(`${BASE_URL}/billing/payments`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          billId: newBillId,
          amount: 1600.00,
          paymentMethod: 'UPI',
          transactionReference: `UPI-TEST-${Date.now()}`
        })
      });
      const data = await res.json();
      if (!data.success || data.billStatus !== 'Paid') throw new Error(data.message || 'Payment recording failed');
    });

    // 11. Audit Logs
    await test('GET /api/audit-logs - Query Audit Trail', async () => {
      const res = await fetch(`${BASE_URL}/audit-logs`, { headers });
      const data = await res.json();
      if (!data.success || data.count === 0) throw new Error('Audit logs missing');
    });

  } finally {
    server.close();
  }

  console.log('\n=============================================================');
  console.log(`📊 TEST RESULTS: ${passed} PASSED, ${failed} FAILED (TOTAL: ${passed + failed})`);
  console.log('=============================================================\n');

  if (failed > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

runTests().catch(err => {
  console.error('Fatal Test Runner Error:', err);
  process.exit(1);
});
