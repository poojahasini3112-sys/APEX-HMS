const pool = require('../config/db');
const { logAudit } = require('../middleware/audit');

/**
 * List all patients with search filtering
 */
async function getAllPatients(req, res, next) {
  try {
    const { search, status, bloodGroup } = req.query;
    let query = 'SELECT * FROM Patient WHERE 1=1';
    const params = [];

    if (search) {
      query += ' AND (First_Name LIKE ? OR Last_Name LIKE ? OR Phone LIKE ? OR Email LIKE ?)';
      const s = `%${search}%`;
      params.push(s, s, s, s);
    }

    if (status) {
      query += ' AND Status = ?';
      params.push(status);
    }

    if (bloodGroup) {
      query += ' AND Blood_Group = ?';
      params.push(bloodGroup);
    }

    query += ' ORDER BY Patient_ID DESC';

    const [patients] = await pool.query(query, params);
    res.json({ success: true, count: patients.length, data: patients });
  } catch (error) {
    next(error);
  }
}

/**
 * Get comprehensive 360-degree patient details
 */
async function getPatientById(req, res, next) {
  try {
    const patientId = req.params.id;

    const [[patient]] = await pool.query('SELECT * FROM Patient WHERE Patient_ID = ?', [patientId]);
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Patient not found.' });
    }

    // Emergency Contacts
    const [contacts] = await pool.query('SELECT * FROM Emergency_Contact WHERE Patient_ID = ?', [patientId]);

    // Medical History
    const [history] = await pool.query('SELECT * FROM Patient_Medical_History WHERE Patient_ID = ? ORDER BY Recorded_Date DESC', [patientId]);

    // Allergies
    const [allergies] = await pool.query('SELECT * FROM Patient_Allergy WHERE Patient_ID = ? ORDER BY Recorded_Date DESC', [patientId]);

    // Admissions
    const [admissions] = await pool.query(`
      SELECT a.*, CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name, doc.Specialization,
             r.Room_Number, b.Bed_Number
      FROM Admission a
      JOIN Doctor doc ON a.Attending_Doctor_ID = doc.Doctor_ID
      JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
      LEFT JOIN Bed_Allocation ba ON a.Admission_ID = ba.Admission_ID AND ba.Status = 'Active'
      LEFT JOIN Bed b ON ba.Bed_ID = b.Bed_ID
      LEFT JOIN Room r ON b.Room_ID = r.Room_ID
      WHERE a.Patient_ID = ?
      ORDER BY a.Admitted_Date DESC
    `, [patientId]);

    // Appointments
    const [appointments] = await pool.query(`
      SELECT ap.*, CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name, doc.Specialization
      FROM Appointment ap
      JOIN Doctor doc ON ap.Doctor_ID = doc.Doctor_ID
      JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
      WHERE ap.Patient_ID = ?
      ORDER BY ap.Appointment_Date DESC
    `, [patientId]);

    // Bills
    const [bills] = await pool.query('SELECT * FROM Bill WHERE Patient_ID = ? ORDER BY Bill_Date DESC', [patientId]);

    // Insurance
    const [insurances] = await pool.query('SELECT * FROM Insurance WHERE Patient_ID = ?', [patientId]);

    res.json({
      success: true,
      data: {
        ...patient,
        emergencyContacts: contacts,
        medicalHistory: history,
        allergies,
        admissions,
        appointments,
        bills,
        insurances
      }
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Register a new patient (transactionally with emergency contact & medical history)
 */
async function createPatient(req, res, next) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const {
      firstName,
      lastName,
      dateOfBirth,
      gender,
      bloodGroup,
      phone,
      email,
      address,
      emergencyContactName,
      emergencyContactPhone,
      relationship,
      initialCondition,
      knownAllergen,
      allergenReaction,
      allergySeverity
    } = req.body;

    if (!firstName || !lastName || !dateOfBirth || !gender || !bloodGroup || !phone || !address) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Missing required patient fields (First Name, Last Name, DOB, Gender, Blood Group, Phone, Address).'
      });
    }

    const [patientResult] = await connection.query(
      `INSERT INTO Patient 
       (First_Name, Last_Name, Date_Of_Birth, Gender, Blood_Group, Phone, Email, Address, Emergency_Contact_Name, Emergency_Contact_Phone, Registration_Date, Status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 'Active')`,
      [firstName, lastName, dateOfBirth, gender, bloodGroup, phone, email || null, address, emergencyContactName || null, emergencyContactPhone || null]
    );

    const newPatientId = patientResult.insertId;

    // Insert Emergency Contact if provided
    if (emergencyContactName && emergencyContactPhone) {
      await connection.query(
        `INSERT INTO Emergency_Contact (Patient_ID, Contact_Name, Relationship, Phone, Address)
         VALUES (?, ?, ?, ?, ?)`,
        [newPatientId, emergencyContactName, relationship || 'Relative', emergencyContactPhone, address]
      );
    }

    // Insert Initial Medical History if provided
    if (initialCondition) {
      await connection.query(
        `INSERT INTO Patient_Medical_History (Patient_ID, Condition_Name, Diagnosed_Date, Status, Notes, Recorded_Date)
         VALUES (?, ?, CURDATE(), 'Ongoing', 'Recorded upon initial registration', NOW())`,
        [newPatientId, initialCondition]
      );
    }

    // Insert Allergy if provided
    if (knownAllergen) {
      await connection.query(
        `INSERT INTO Patient_Allergy (Patient_ID, Allergen, Reaction, Severity, Recorded_Date)
         VALUES (?, ?, ?, ?, NOW())`,
        [newPatientId, knownAllergen, allergenReaction || 'Allergic reaction', allergySeverity || 'Moderate']
      );
    }

    await connection.commit();

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'CREATE_PATIENT',
      entityName: 'Patient',
      entityId: newPatientId,
      newValues: { firstName, lastName, phone, bloodGroup },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({
      success: true,
      message: 'Patient registered successfully.',
      patientId: newPatientId
    });
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
}

/**
 * Update patient profile
 */
async function updatePatient(req, res, next) {
  try {
    const patientId = req.params.id;
    const { firstName, lastName, dateOfBirth, gender, bloodGroup, phone, email, address, status } = req.body;

    const [[existing]] = await pool.query('SELECT * FROM Patient WHERE Patient_ID = ?', [patientId]);
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Patient not found.' });
    }

    await pool.query(
      `UPDATE Patient 
       SET First_Name = ?, Last_Name = ?, Date_Of_Birth = ?, Gender = ?, Blood_Group = ?, 
           Phone = ?, Email = ?, Address = ?, Status = ?
       WHERE Patient_ID = ?`,
      [
        firstName || existing.First_Name,
        lastName || existing.Last_Name,
        dateOfBirth || existing.Date_Of_Birth,
        gender || existing.Gender,
        bloodGroup || existing.Blood_Group,
        phone || existing.Phone,
        email !== undefined ? email : existing.Email,
        address || existing.Address,
        status || existing.Status,
        patientId
      ]
    );

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'UPDATE_PATIENT',
      entityName: 'Patient',
      entityId: patientId,
      oldValues: existing,
      newValues: req.body,
      ipAddress: req.ip || '127.0.0.1'
    });

    res.json({ success: true, message: 'Patient updated successfully.' });
  } catch (error) {
    next(error);
  }
}

/**
 * Delete patient
 */
async function deletePatient(req, res, next) {
  try {
    const patientId = req.params.id;
    await pool.query('DELETE FROM Patient WHERE Patient_ID = ?', [patientId]);

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'DELETE_PATIENT',
      entityName: 'Patient',
      entityId: patientId,
      ipAddress: req.ip || '127.0.0.1'
    });

    res.json({ success: true, message: 'Patient deleted successfully.' });
  } catch (error) {
    next(error);
  }
}

/**
 * Add Medical History for a patient
 */
async function addMedicalHistory(req, res, next) {
  try {
    const patientId = req.params.id;
    const { conditionName, diagnosedDate, status, notes } = req.body;

    if (!conditionName) {
      return res.status(400).json({ success: false, message: 'Condition name is required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Patient_Medical_History (Patient_ID, Condition_Name, Diagnosed_Date, Status, Notes, Recorded_Date)
       VALUES (?, ?, ?, ?, ?, NOW())`,
      [patientId, conditionName, diagnosedDate || null, status || 'Ongoing', notes || null]
    );

    res.status(201).json({ success: true, message: 'Medical history recorded.', historyId: result.insertId });
  } catch (error) {
    next(error);
  }
}

/**
 * Add Allergy for a patient
 */
async function addAllergy(req, res, next) {
  try {
    const patientId = req.params.id;
    const { allergen, reaction, severity } = req.body;

    if (!allergen || !reaction) {
      return res.status(400).json({ success: false, message: 'Allergen and reaction are required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Patient_Allergy (Patient_ID, Allergen, Reaction, Severity, Recorded_Date)
       VALUES (?, ?, ?, ?, NOW())`,
      [patientId, allergen, reaction, severity || 'Moderate']
    );

    res.status(201).json({ success: true, message: 'Allergy recorded.', allergyId: result.insertId });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllPatients,
  getPatientById,
  createPatient,
  updatePatient,
  deletePatient,
  addMedicalHistory,
  addAllergy
};
