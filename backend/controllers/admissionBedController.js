const pool = require('../config/db');
const { logAudit } = require('../middleware/audit');

/**
 * -------------------------------------------------------------
 * ROOMS & BEDS
 * -------------------------------------------------------------
 */
async function getAllRooms(req, res, next) {
  try {
    const [rooms] = await pool.query(`
      SELECT r.*, d.Department_Name,
             (SELECT COUNT(*) FROM Bed WHERE Room_ID = r.Room_ID) AS Total_Beds,
             (SELECT COUNT(*) FROM Bed WHERE Room_ID = r.Room_ID AND Status = 'Available') AS Available_Beds
      FROM Room r
      JOIN Department d ON r.Department_ID = d.Department_ID
      ORDER BY r.Room_Number ASC
    `);
    res.json({ success: true, count: rooms.length, data: rooms });
  } catch (error) {
    next(error);
  }
}

async function getAllBeds(req, res, next) {
  try {
    const { status, roomId } = req.query;
    let query = `
      SELECT b.*, r.Room_Number, r.Room_Type, r.Daily_Rate, d.Department_Name,
             ba.Allocation_ID, ba.Admission_ID,
             p.Patient_ID, CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name
      FROM Bed b
      JOIN Room r ON b.Room_ID = r.Room_ID
      JOIN Department d ON r.Department_ID = d.Department_ID
      LEFT JOIN Bed_Allocation ba ON b.Bed_ID = ba.Bed_ID AND ba.Status = 'Active'
      LEFT JOIN Admission adm ON ba.Admission_ID = adm.Admission_ID
      LEFT JOIN Patient p ON adm.Patient_ID = p.Patient_ID
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      query += ' AND b.Status = ?';
      params.push(status);
    }
    if (roomId) {
      query += ' AND b.Room_ID = ?';
      params.push(roomId);
    }

    query += ' ORDER BY r.Room_Number ASC, b.Bed_Number ASC';
    const [beds] = await pool.query(query, params);
    res.json({ success: true, count: beds.length, data: beds });
  } catch (error) {
    next(error);
  }
}

/**
 * Live visual bed board grouped by Room
 */
async function getBedStatusBoard(req, res, next) {
  try {
    const [rooms] = await pool.query('SELECT * FROM Room ORDER BY Room_Number ASC');
    const [beds] = await pool.query(`
      SELECT b.*, ba.Allocation_ID, adm.Admission_ID, adm.Admitted_Date,
             p.Patient_ID, CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Gender
      FROM Bed b
      LEFT JOIN Bed_Allocation ba ON b.Bed_ID = ba.Bed_ID AND ba.Status = 'Active'
      LEFT JOIN Admission adm ON ba.Admission_ID = adm.Admission_ID
      LEFT JOIN Patient p ON adm.Patient_ID = p.Patient_ID
      ORDER BY b.Bed_Number ASC
    `);

    const board = rooms.map(room => ({
      ...room,
      beds: beds.filter(bed => bed.Room_ID === room.Room_ID)
    }));

    res.json({ success: true, data: board });
  } catch (error) {
    next(error);
  }
}

/**
 * -------------------------------------------------------------
 * ADMISSIONS & BED ALLOCATION (Transactional)
 * -------------------------------------------------------------
 */
async function getAllAdmissions(req, res, next) {
  try {
    const { status, patientId } = req.query;
    let query = `
      SELECT adm.*, 
             CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Phone AS Patient_Phone, p.Blood_Group,
             CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name, doc.Specialization,
             r.Room_Number, r.Room_Type, b.Bed_Number, b.Bed_ID, ba.Allocation_ID
      FROM Admission adm
      JOIN Patient p ON adm.Patient_ID = p.Patient_ID
      JOIN Doctor doc ON adm.Attending_Doctor_ID = doc.Doctor_ID
      JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
      LEFT JOIN Bed_Allocation ba ON adm.Admission_ID = ba.Admission_ID AND ba.Status = 'Active'
      LEFT JOIN Bed b ON ba.Bed_ID = b.Bed_ID
      LEFT JOIN Room r ON b.Room_ID = r.Room_ID
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      query += ' AND adm.Status = ?';
      params.push(status);
    }
    if (patientId) {
      query += ' AND adm.Patient_ID = ?';
      params.push(patientId);
    }

    query += ' ORDER BY adm.Admitted_Date DESC';
    const [admissions] = await pool.query(query, params);
    res.json({ success: true, count: admissions.length, data: admissions });
  } catch (error) {
    next(error);
  }
}

async function createAdmission(req, res, next) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { patientId, attendingDoctorId, admissionReason, admissionType, bedId } = req.body;

    if (!patientId || !attendingDoctorId || !admissionReason || !bedId) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Patient, Doctor, Reason and Bed are required for admission.' });
    }

    // Verify bed is Available
    const [[bed]] = await connection.query('SELECT Status FROM Bed WHERE Bed_ID = ? FOR UPDATE', [bedId]);
    if (!bed) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Bed not found.' });
    }
    if (bed.Status !== 'Available') {
      await connection.rollback();
      return res.status(409).json({ success: false, message: `Bed is currently ${bed.Status}. Choose an available bed.` });
    }

    // 1. Create Admission record
    const [admResult] = await connection.query(
      `INSERT INTO Admission (Patient_ID, Admitted_Date, Attending_Doctor_ID, Admission_Reason, Admission_Type, Status)
       VALUES (?, NOW(), ?, ?, ?, 'Admitted')`,
      [patientId, attendingDoctorId, admissionReason, admissionType || 'Elective']
    );

    const admissionId = admResult.insertId;

    // 2. Create Bed Allocation record
    await connection.query(
      `INSERT INTO Bed_Allocation (Admission_ID, Bed_ID, Allocated_From, Status)
       VALUES (?, ?, NOW(), 'Active')`,
      [admissionId, bedId]
    );

    // 3. Mark Bed as Occupied
    await connection.query('UPDATE Bed SET Status = "Occupied" WHERE Bed_ID = ?', [bedId]);

    await connection.commit();

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'ADMIT_PATIENT',
      entityName: 'Admission',
      entityId: admissionId,
      newValues: { patientId, bedId, admissionReason },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({ success: true, message: 'Patient admitted successfully.', admissionId });
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
}

async function dischargePatient(req, res, next) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const admissionId = req.params.id;

    const [[adm]] = await connection.query('SELECT * FROM Admission WHERE Admission_ID = ? FOR UPDATE', [admissionId]);
    if (!adm) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Admission record not found.' });
    }
    if (adm.Status === 'Discharged') {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Patient is already discharged.' });
    }

    // 1. Update Admission status & Discharge_Date
    await connection.query(
      'UPDATE Admission SET Status = "Discharged", Discharge_Date = NOW() WHERE Admission_ID = ?',
      [admissionId]
    );

    // 2. Release active Bed_Allocation and get Bed_ID
    const [allocations] = await connection.query(
      'SELECT Bed_ID FROM Bed_Allocation WHERE Admission_ID = ? AND Status = "Active"',
      [admissionId]
    );

    if (allocations.length > 0) {
      const bedId = allocations[0].Bed_ID;
      await connection.query(
        'UPDATE Bed_Allocation SET Status = "Released", Allocated_To = NOW() WHERE Admission_ID = ? AND Status = "Active"',
        [admissionId]
      );

      // 3. Mark Bed as Available
      await connection.query('UPDATE Bed SET Status = "Available" WHERE Bed_ID = ?', [bedId]);
    }

    await connection.commit();

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'DISCHARGE_PATIENT',
      entityName: 'Admission',
      entityId: admissionId,
      newValues: { status: 'Discharged' },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.json({ success: true, message: 'Patient discharged and bed released successfully.' });
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
}

module.exports = {
  getAllRooms,
  getAllBeds,
  getBedStatusBoard,
  getAllAdmissions,
  createAdmission,
  dischargePatient
};
