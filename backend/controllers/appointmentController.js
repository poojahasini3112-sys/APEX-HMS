const pool = require('../config/db');
const { logAudit } = require('../middleware/audit');

async function getAllAppointments(req, res, next) {
  try {
    const { date, doctorId, patientId, status } = req.query;
    let query = `
      SELECT ap.*, 
             CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Phone AS Patient_Phone, p.Blood_Group,
             CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name, doc.Specialization, doc.Consultation_Fee, doc.Room_Number
      FROM Appointment ap
      JOIN Patient p ON ap.Patient_ID = p.Patient_ID
      JOIN Doctor doc ON ap.Doctor_ID = doc.Doctor_ID
      JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
      WHERE 1=1
    `;
    const params = [];

    if (date) {
      query += ' AND ap.Appointment_Date = ?';
      params.push(date);
    }
    if (doctorId) {
      query += ' AND ap.Doctor_ID = ?';
      params.push(doctorId);
    }
    if (patientId) {
      query += ' AND ap.Patient_ID = ?';
      params.push(patientId);
    }
    if (status) {
      query += ' AND ap.Status = ?';
      params.push(status);
    }

    query += ' ORDER BY ap.Appointment_Date DESC, ap.Appointment_Time ASC';
    const [appointments] = await pool.query(query, params);
    res.json({ success: true, count: appointments.length, data: appointments });
  } catch (error) {
    next(error);
  }
}

async function createAppointment(req, res, next) {
  try {
    const { patientId, doctorId, appointmentDate, appointmentTime, reason } = req.body;

    if (!patientId || !doctorId || !appointmentDate || !appointmentTime || !reason) {
      return res.status(400).json({ success: false, message: 'All appointment fields are required.' });
    }

    // Check if slot already booked for doctor
    const [existing] = await pool.query(
      `SELECT Appointment_ID FROM Appointment 
       WHERE Doctor_ID = ? AND Appointment_Date = ? AND Appointment_Time = ? AND Status = 'Scheduled'`,
      [doctorId, appointmentDate, appointmentTime]
    );

    if (existing.length > 0) {
      return res.status(409).json({ success: false, message: 'Doctor is already booked for this time slot.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Appointment (Patient_ID, Doctor_ID, Appointment_Date, Appointment_Time, Reason, Status, Created_At)
       VALUES (?, ?, ?, ?, ?, 'Scheduled', NOW())`,
      [patientId, doctorId, appointmentDate, appointmentTime, reason]
    );

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'SCHEDULE_APPOINTMENT',
      entityName: 'Appointment',
      entityId: result.insertId,
      newValues: { patientId, doctorId, appointmentDate, appointmentTime },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({ success: true, message: 'Appointment scheduled.', appointmentId: result.insertId });
  } catch (error) {
    next(error);
  }
}

async function updateAppointmentStatus(req, res, next) {
  try {
    const appointmentId = req.params.id;
    const { status } = req.body;

    if (!['Scheduled', 'Completed', 'Cancelled', 'No-Show'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid appointment status.' });
    }

    await pool.query('UPDATE Appointment SET Status = ? WHERE Appointment_ID = ?', [status, appointmentId]);

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'UPDATE_APPOINTMENT_STATUS',
      entityName: 'Appointment',
      entityId: appointmentId,
      newValues: { status },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.json({ success: true, message: `Appointment status updated to ${status}.` });
  } catch (error) {
    next(error);
  }
}

async function deleteAppointment(req, res, next) {
  try {
    const appointmentId = req.params.id;
    await pool.query('DELETE FROM Appointment WHERE Appointment_ID = ?', [appointmentId]);
    res.json({ success: true, message: 'Appointment deleted.' });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllAppointments,
  createAppointment,
  updateAppointmentStatus,
  deleteAppointment
};
