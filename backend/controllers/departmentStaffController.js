const pool = require('../config/db');
const { logAudit } = require('../middleware/audit');

/**
 * -------------------------------------------------------------
 * DEPARTMENTS
 * -------------------------------------------------------------
 */
async function getAllDepartments(req, res, next) {
  try {
    const [departments] = await pool.query(`
      SELECT d.*, 
             CONCAT(s.First_Name, ' ', s.Last_Name) AS Head_Doctor_Name,
             (SELECT COUNT(*) FROM Staff WHERE Department_ID = d.Department_ID) AS Total_Staff_Count,
             (SELECT COUNT(*) FROM Doctor doc JOIN Staff st ON doc.Doctor_ID = st.Staff_ID WHERE st.Department_ID = d.Department_ID) AS Doctors_Count
      FROM Department d
      LEFT JOIN Staff s ON d.Head_Of_Department = s.Staff_ID
      ORDER BY d.Department_ID ASC
    `);
    res.json({ success: true, count: departments.length, data: departments });
  } catch (error) {
    next(error);
  }
}

async function createDepartment(req, res, next) {
  try {
    const { departmentName, description, headOfDepartment, location, contactNumber } = req.body;
    if (!departmentName || !location || !contactNumber) {
      return res.status(400).json({ success: false, message: 'Department name, location and contact number are required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Department (Department_Name, Description, Head_Of_Department, Location, Contact_Number)
       VALUES (?, ?, ?, ?, ?)`,
      [departmentName, description || null, headOfDepartment || null, location, contactNumber]
    );

    res.status(201).json({ success: true, message: 'Department created.', departmentId: result.insertId });
  } catch (error) {
    next(error);
  }
}

/**
 * -------------------------------------------------------------
 * STAFF & NURSES
 * -------------------------------------------------------------
 */
async function getAllStaff(req, res, next) {
  try {
    const { role, departmentId } = req.query;
    let query = `
      SELECT s.*, d.Department_Name
      FROM Staff s
      JOIN Department d ON s.Department_ID = d.Department_ID
      WHERE 1=1
    `;
    const params = [];

    if (role) {
      query += ' AND s.Role = ?';
      params.push(role);
    }
    if (departmentId) {
      query += ' AND s.Department_ID = ?';
      params.push(departmentId);
    }

    query += ' ORDER BY s.Staff_ID ASC';
    const [staff] = await pool.query(query, params);
    res.json({ success: true, count: staff.length, data: staff });
  } catch (error) {
    next(error);
  }
}

/**
 * -------------------------------------------------------------
 * DOCTORS & SPECIALIZATION (Subtype of Staff)
 * -------------------------------------------------------------
 */
async function getAllDoctors(req, res, next) {
  try {
    const { departmentId, specialization } = req.query;
    let query = `
      SELECT d.Doctor_ID, d.Specialization, d.Qualification, d.License_Number, d.Consultation_Fee, d.Room_Number,
             s.First_Name, s.Last_Name, s.Email, s.Phone, s.Status AS Staff_Status, s.Department_ID,
             dept.Department_Name
      FROM Doctor d
      JOIN Staff s ON d.Doctor_ID = s.Staff_ID
      JOIN Department dept ON s.Department_ID = dept.Department_ID
      WHERE s.Status = 'Active'
    `;
    const params = [];

    if (departmentId) {
      query += ' AND s.Department_ID = ?';
      params.push(departmentId);
    }
    if (specialization) {
      query += ' AND d.Specialization LIKE ?';
      params.push(`%${specialization}%`);
    }

    query += ' ORDER BY s.First_Name ASC';
    const [doctors] = await pool.query(query, params);
    res.json({ success: true, count: doctors.length, data: doctors });
  } catch (error) {
    next(error);
  }
}

async function createDoctor(req, res, next) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const {
      firstName,
      lastName,
      email,
      phone,
      departmentId,
      dateOfJoining,
      salary,
      specialization,
      qualification,
      licenseNumber,
      consultationFee,
      roomNumber
    } = req.body;

    if (!firstName || !lastName || !email || !phone || !departmentId || !specialization || !licenseNumber) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Missing required doctor fields.' });
    }

    // 1. Insert into Staff
    const [staffResult] = await connection.query(
      `INSERT INTO Staff (First_Name, Last_Name, Email, Phone, Role, Department_ID, Date_Of_Joining, Salary, Status)
       VALUES (?, ?, ?, ?, 'Doctor', ?, ?, ?, 'Active')`,
      [firstName, lastName, email, phone, departmentId, dateOfJoining || new Date(), salary || 150000.00]
    );

    const staffId = staffResult.insertId;

    // 2. Insert into Doctor subtype table
    await connection.query(
      `INSERT INTO Doctor (Doctor_ID, Specialization, Qualification, License_Number, Consultation_Fee, Room_Number)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [staffId, specialization, qualification || 'MBBS, MD', licenseNumber, consultationFee || 600.00, roomNumber || 'OPD-1']
    );

    await connection.commit();

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'CREATE_DOCTOR',
      entityName: 'Doctor',
      entityId: staffId,
      newValues: { firstName, lastName, specialization, licenseNumber },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({ success: true, message: 'Doctor registered successfully.', doctorId: staffId });
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
}

/**
 * -------------------------------------------------------------
 * DOCTOR SCHEDULES
 * -------------------------------------------------------------
 */
async function getDoctorSchedules(req, res, next) {
  try {
    const doctorId = req.params.id;
    const [schedules] = await pool.query(
      `SELECT ds.*, CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name
       FROM Doctor_Schedule ds
       JOIN Doctor d ON ds.Doctor_ID = d.Doctor_ID
       JOIN Staff s ON d.Doctor_ID = s.Staff_ID
       WHERE ds.Doctor_ID = ?
       ORDER BY FIELD(ds.Day_Of_Week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')`,
      [doctorId]
    );
    res.json({ success: true, data: schedules });
  } catch (error) {
    next(error);
  }
}

async function addDoctorSchedule(req, res, next) {
  try {
    const doctorId = req.params.id;
    const { dayOfWeek, startTime, endTime, maxAppointments } = req.body;

    if (!dayOfWeek || !startTime || !endTime) {
      return res.status(400).json({ success: false, message: 'Day of week, start time and end time are required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Doctor_Schedule (Doctor_ID, Day_Of_Week, Start_Time, End_Time, Max_Appointments, Status)
       VALUES (?, ?, ?, ?, ?, 'Available')`,
      [doctorId, dayOfWeek, startTime, endTime, maxAppointments || 20]
    );

    res.status(201).json({ success: true, message: 'Schedule added.', scheduleId: result.insertId });
  } catch (error) {
    next(error);
  }
}

/**
 * -------------------------------------------------------------
 * NURSES (Subtype of Staff)
 * -------------------------------------------------------------
 */
async function getAllNurses(req, res, next) {
  try {
    const [nurses] = await pool.query(`
      SELECT n.Nurse_ID, n.Qualification, n.License_Number, n.Shift, n.Assigned_Ward,
             s.First_Name, s.Last_Name, s.Email, s.Phone, s.Status, d.Department_Name
      FROM Nurse n
      JOIN Staff s ON n.Nurse_ID = s.Staff_ID
      JOIN Department d ON s.Department_ID = d.Department_ID
      WHERE s.Status = 'Active'
      ORDER BY s.First_Name ASC
    `);
    res.json({ success: true, count: nurses.length, data: nurses });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllDepartments,
  createDepartment,
  getAllStaff,
  getAllDoctors,
  createDoctor,
  getDoctorSchedules,
  addDoctorSchedule,
  getAllNurses
};
