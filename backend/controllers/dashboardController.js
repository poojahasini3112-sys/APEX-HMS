const pool = require('../config/db');

/**
 * Get comprehensive hospital KPI dashboard stats
 */
async function getStats(req, res, next) {
  try {
    const [[{ totalPatients }]] = await pool.query('SELECT COUNT(*) AS totalPatients FROM Patient WHERE Status = "Active"');
    const [[{ totalDoctors }]] = await pool.query('SELECT COUNT(*) AS totalDoctors FROM Doctor d JOIN Staff s ON d.Doctor_ID = s.Staff_ID WHERE s.Status = "Active"');
    const [[{ activeAdmissions }]] = await pool.query('SELECT COUNT(*) AS activeAdmissions FROM Admission WHERE Status = "Admitted"');
    
    // Bed statistics
    const [[{ totalBeds, occupiedBeds }]] = await pool.query(`
      SELECT 
        COUNT(*) AS totalBeds,
        SUM(CASE WHEN Status = 'Occupied' THEN 1 ELSE 0 END) AS occupiedBeds
      FROM Bed
    `);

    // Today's appointments count
    const [[{ todayAppointments }]] = await pool.query(`
      SELECT COUNT(*) AS todayAppointments 
      FROM Appointment 
      WHERE Appointment_Date = CURDATE()
    `);

    // Pending lab tests count
    const [[{ pendingLabs }]] = await pool.query(`
      SELECT COUNT(*) AS pendingLabs 
      FROM Lab_Order 
      WHERE Status IN ('Pending', 'In Progress', 'Sample Collected')
    `);

    // Total billing revenue collected
    const [[{ totalRevenue }]] = await pool.query('SELECT COALESCE(SUM(Amount), 0) AS totalRevenue FROM Payment WHERE Status = "Completed"');

    // Low stock medicine count
    const [[{ lowStockCount }]] = await pool.query('SELECT COUNT(*) AS lowStockCount FROM Medicine WHERE Stock_Quantity <= Reorder_Level');

    // Recent 5 admissions
    const [recentAdmissions] = await pool.query(`
      SELECT a.Admission_ID, a.Admitted_Date, a.Admission_Reason, a.Admission_Type, a.Status,
             p.Patient_ID, CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Gender,
             CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name,
             r.Room_Number, b.Bed_Number
      FROM Admission a
      JOIN Patient p ON a.Patient_ID = p.Patient_ID
      JOIN Doctor d ON a.Attending_Doctor_ID = d.Doctor_ID
      JOIN Staff s ON d.Doctor_ID = s.Staff_ID
      LEFT JOIN Bed_Allocation ba ON a.Admission_ID = ba.Admission_ID AND ba.Status = 'Active'
      LEFT JOIN Bed b ON ba.Bed_ID = b.Bed_ID
      LEFT JOIN Room r ON b.Room_ID = r.Room_ID
      ORDER BY a.Admitted_Date DESC
      LIMIT 5
    `);

    // Today's / Upcoming 5 appointments
    const [upcomingAppointments] = await pool.query(`
      SELECT ap.Appointment_ID, ap.Appointment_Date, ap.Appointment_Time, ap.Reason, ap.Status,
             p.Patient_ID, CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Phone,
             CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name, doc.Specialization
      FROM Appointment ap
      JOIN Patient p ON ap.Patient_ID = p.Patient_ID
      JOIN Doctor doc ON ap.Doctor_ID = doc.Doctor_ID
      JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
      ORDER BY ap.Appointment_Date ASC, ap.Appointment_Time ASC
      LIMIT 5
    `);

    // Bed status breakdown
    const [bedBreakdown] = await pool.query(`
      SELECT Status, COUNT(*) AS count 
      FROM Bed 
      GROUP BY Status
    `);

    res.json({
      success: true,
      stats: {
        totalPatients,
        totalDoctors,
        activeAdmissions,
        totalBeds,
        occupiedBeds: occupiedBeds || 0,
        bedOccupancyRate: totalBeds > 0 ? Math.round(((occupiedBeds || 0) / totalBeds) * 100) : 0,
        todayAppointments,
        pendingLabs,
        totalRevenue: parseFloat(totalRevenue || 0),
        lowStockCount
      },
      recentAdmissions,
      upcomingAppointments,
      bedBreakdown
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getStats
};
