const pool = require('../config/db');
const { logAudit } = require('../middleware/audit');

/**
 * -------------------------------------------------------------
 * MEDICAL RECORDS & DIAGNOSES (M:N)
 * -------------------------------------------------------------
 */
async function getAllMedicalRecords(req, res, next) {
  try {
    const { patientId, doctorId } = req.query;
    let query = `
      SELECT mr.*, 
             CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Gender, p.Date_Of_Birth, p.Blood_Group,
             CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name, doc.Specialization,
             GROUP_CONCAT(d.Diagnosis_Name SEPARATOR '; ') AS Diagnoses_List
      FROM Medical_Record mr
      JOIN Patient p ON mr.Patient_ID = p.Patient_ID
      JOIN Doctor doc ON mr.Doctor_ID = doc.Doctor_ID
      JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
      LEFT JOIN Record_Diagnosis rd ON mr.Record_ID = rd.Record_ID
      LEFT JOIN Diagnosis d ON rd.Diagnosis_ID = d.Diagnosis_ID
      WHERE 1=1
    `;
    const params = [];

    if (patientId) {
      query += ' AND mr.Patient_ID = ?';
      params.push(patientId);
    }
    if (doctorId) {
      query += ' AND mr.Doctor_ID = ?';
      params.push(doctorId);
    }

    query += ' GROUP BY mr.Record_ID ORDER BY mr.Visit_Date DESC';
    const [records] = await pool.query(query, params);
    res.json({ success: true, count: records.length, data: records });
  } catch (error) {
    next(error);
  }
}

async function getMedicalRecordById(req, res, next) {
  try {
    const recordId = req.params.id;

    const [[record]] = await pool.query(`
      SELECT mr.*, 
             CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Gender, p.Date_Of_Birth, p.Blood_Group, p.Phone,
             CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name, doc.Specialization
      FROM Medical_Record mr
      JOIN Patient p ON mr.Patient_ID = p.Patient_ID
      JOIN Doctor doc ON mr.Doctor_ID = doc.Doctor_ID
      JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
      WHERE mr.Record_ID = ?
    `, [recordId]);

    if (!record) {
      return res.status(404).json({ success: false, message: 'Medical record not found.' });
    }

    // Diagnoses (M:N through Record_Diagnosis)
    const [diagnoses] = await pool.query(`
      SELECT d.*, rd.Severity, rd.Recorded_Date
      FROM Record_Diagnosis rd
      JOIN Diagnosis d ON rd.Diagnosis_ID = d.Diagnosis_ID
      WHERE rd.Record_ID = ?
    `, [recordId]);

    // Prescriptions & Details
    const [prescriptions] = await pool.query(`
      SELECT rx.*, 
             CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name
      FROM Prescription rx
      JOIN Doctor doc ON rx.Doctor_ID = doc.Doctor_ID
      JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
      WHERE rx.Record_ID = ?
    `, [recordId]);

    for (const rx of prescriptions) {
      const [details] = await pool.query(`
        SELECT pd.*, m.Medicine_Name, m.Category, m.Unit_Price
        FROM Prescription_Detail pd
        JOIN Medicine m ON pd.Medicine_ID = m.Medicine_ID
        WHERE pd.Prescription_ID = ?
      `, [rx.Prescription_ID]);
      rx.items = details;
    }

    res.json({
      success: true,
      data: {
        ...record,
        diagnoses,
        prescriptions
      }
    });
  } catch (error) {
    next(error);
  }
}

async function createMedicalRecord(req, res, next) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const {
      patientId,
      doctorId,
      symptoms,
      physicalExamination,
      treatmentNotes,
      followUpDate,
      diagnosisIds, // array of { diagnosisId, severity }
      prescriptionInstructions,
      prescriptionItems // array of { medicineId, dosage, frequency, durationDays, quantity, notes }
    } = req.body;

    if (!patientId || !doctorId || !symptoms) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Patient, Doctor and Symptoms are required.' });
    }

    // 1. Insert Medical_Record
    const [mrResult] = await connection.query(
      `INSERT INTO Medical_Record (Patient_ID, Doctor_ID, Visit_Date, Symptoms, Physical_Examination, Treatment_Notes, Follow_Up_Date)
       VALUES (?, ?, NOW(), ?, ?, ?, ?)`,
      [patientId, doctorId, symptoms, physicalExamination || null, treatmentNotes || null, followUpDate || null]
    );

    const recordId = mrResult.insertId;

    // 2. Insert M:N Record_Diagnosis
    if (diagnosisIds && Array.isArray(diagnosisIds) && diagnosisIds.length > 0) {
      for (const item of diagnosisIds) {
        const diagId = typeof item === 'object' ? item.diagnosisId : item;
        const severity = typeof item === 'object' && item.severity ? item.severity : 'Primary';
        await connection.query(
          `INSERT INTO Record_Diagnosis (Record_ID, Diagnosis_ID, Severity, Recorded_Date)
           VALUES (?, ?, ?, NOW())`,
          [recordId, diagId, severity]
        );
      }
    }

    // 3. Insert Prescription if items provided
    if (prescriptionItems && Array.isArray(prescriptionItems) && prescriptionItems.length > 0) {
      const [rxResult] = await connection.query(
        `INSERT INTO Prescription (Record_ID, Patient_ID, Doctor_ID, Prescribed_Date, Instructions)
         VALUES (?, ?, ?, NOW(), ?)`,
        [recordId, patientId, doctorId, prescriptionInstructions || 'Take medications as directed.']
      );

      const rxId = rxResult.insertId;

      for (const item of prescriptionItems) {
        await connection.query(
          `INSERT INTO Prescription_Detail (Prescription_ID, Medicine_ID, Dosage, Frequency, Duration_Days, Quantity, Notes)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [rxId, item.medicineId, item.dosage || 'Standard', item.frequency || 'Once daily', item.durationDays || 5, item.quantity || 5, item.notes || null]
        );
      }
    }

    await connection.commit();

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'CREATE_MEDICAL_RECORD',
      entityName: 'Medical_Record',
      entityId: recordId,
      newValues: { patientId, doctorId, symptoms },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({ success: true, message: 'Medical record created successfully.', recordId });
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
}

/**
 * -------------------------------------------------------------
 * DIAGNOSES CATALOG
 * -------------------------------------------------------------
 */
async function getAllDiagnoses(req, res, next) {
  try {
    const [diagnoses] = await pool.query('SELECT * FROM Diagnosis ORDER BY Category, Diagnosis_Name');
    res.json({ success: true, count: diagnoses.length, data: diagnoses });
  } catch (error) {
    next(error);
  }
}

/**
 * -------------------------------------------------------------
 * PRESCRIPTIONS
 * -------------------------------------------------------------
 */
async function getPrescriptionById(req, res, next) {
  try {
    const rxId = req.params.id;
    const [[rx]] = await pool.query(`
      SELECT rx.*, 
             CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Phone, p.Blood_Group,
             CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name, doc.Specialization
      FROM Prescription rx
      JOIN Patient p ON rx.Patient_ID = p.Patient_ID
      JOIN Doctor doc ON rx.Doctor_ID = doc.Doctor_ID
      JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
      WHERE rx.Prescription_ID = ?
    `, [rxId]);

    if (!rx) {
      return res.status(404).json({ success: false, message: 'Prescription not found.' });
    }

    const [items] = await pool.query(`
      SELECT pd.*, m.Medicine_Name, m.Category, m.Unit_Price
      FROM Prescription_Detail pd
      JOIN Medicine m ON pd.Medicine_ID = m.Medicine_ID
      WHERE pd.Prescription_ID = ?
    `, [rxId]);

    res.json({ success: true, data: { ...rx, items } });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllMedicalRecords,
  getMedicalRecordById,
  createMedicalRecord,
  getAllDiagnoses,
  getPrescriptionById
};
