const pool = require('../config/db');
const { logAudit } = require('../middleware/audit');

/**
 * -------------------------------------------------------------
 * LAB TESTS CATALOG
 * -------------------------------------------------------------
 */
async function getAllLabTests(req, res, next) {
  try {
    const [tests] = await pool.query('SELECT * FROM Lab_Test ORDER BY Category, Test_Name');
    res.json({ success: true, count: tests.length, data: tests });
  } catch (error) {
    next(error);
  }
}

async function createLabTest(req, res, next) {
  try {
    const { testName, category, cost, normalRange, unit, description } = req.body;
    if (!testName || !category || cost === undefined) {
      return res.status(400).json({ success: false, message: 'Test name, category and cost are required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Lab_Test (Test_Name, Category, Cost, Normal_Range, Unit, Description)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [testName, category, cost, normalRange || null, unit || null, description || null]
    );

    res.status(201).json({ success: true, message: 'Lab test created.', testId: result.insertId });
  } catch (error) {
    next(error);
  }
}

/**
 * -------------------------------------------------------------
 * LAB ORDERS & REPORTS
 * -------------------------------------------------------------
 */
async function getAllLabOrders(req, res, next) {
  try {
    const { status, patientId } = req.query;
    let query = `
      SELECT lo.*, 
             CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Phone AS Patient_Phone, p.Blood_Group,
             CONCAT(s.First_Name, ' ', s.Last_Name) AS Doctor_Name,
             lt.Test_Name, lt.Category AS Test_Category, lt.Cost, lt.Normal_Range, lt.Unit,
             lr.Report_ID, lr.Result_Value, lr.Comments, lr.Report_Date, lr.Status AS Report_Status,
             CONCAT(tech.First_Name, ' ', tech.Last_Name) AS Conducted_By_Name
      FROM Lab_Order lo
      JOIN Patient p ON lo.Patient_ID = p.Patient_ID
      JOIN Doctor doc ON lo.Doctor_ID = doc.Doctor_ID
      JOIN Staff s ON doc.Doctor_ID = s.Staff_ID
      JOIN Lab_Test lt ON lo.Test_ID = lt.Test_ID
      LEFT JOIN Lab_Report lr ON lo.Order_ID = lr.Order_ID
      LEFT JOIN Staff tech ON lr.Conducted_By = tech.Staff_ID
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      query += ' AND lo.Status = ?';
      params.push(status);
    }
    if (patientId) {
      query += ' AND lo.Patient_ID = ?';
      params.push(patientId);
    }

    query += ' ORDER BY lo.Order_Date DESC';
    const [orders] = await pool.query(query, params);
    res.json({ success: true, count: orders.length, data: orders });
  } catch (error) {
    next(error);
  }
}

async function createLabOrder(req, res, next) {
  try {
    const { patientId, doctorId, testId, priority } = req.body;

    if (!patientId || !doctorId || !testId) {
      return res.status(400).json({ success: false, message: 'Patient, Doctor and Test ID are required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Lab_Order (Patient_ID, Doctor_ID, Test_ID, Order_Date, Priority, Status)
       VALUES (?, ?, ?, NOW(), ?, 'Pending')`,
      [patientId, doctorId, testId, priority || 'Routine']
    );

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'CREATE_LAB_ORDER',
      entityName: 'Lab_Order',
      entityId: result.insertId,
      newValues: { patientId, doctorId, testId, priority },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({ success: true, message: 'Lab test ordered.', orderId: result.insertId });
  } catch (error) {
    next(error);
  }
}

async function createLabReport(req, res, next) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { orderId, conductedBy, resultValue, comments, status } = req.body;

    if (!orderId || !conductedBy || !resultValue) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Order ID, Technician Staff ID and Result Value are required.' });
    }

    // 1. Insert Lab_Report
    const [reportResult] = await connection.query(
      `INSERT INTO Lab_Report (Order_ID, Conducted_By, Result_Value, Comments, Report_Date, Status)
       VALUES (?, ?, ?, ?, NOW(), ?)`,
      [orderId, conductedBy, resultValue, comments || null, status || 'Normal']
    );

    // 2. Update Lab_Order status to 'Completed'
    await connection.query('UPDATE Lab_Order SET Status = "Completed" WHERE Order_ID = ?', [orderId]);

    await connection.commit();

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'COMPLETE_LAB_REPORT',
      entityName: 'Lab_Report',
      entityId: reportResult.insertId,
      newValues: { orderId, resultValue, status },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({ success: true, message: 'Lab report uploaded successfully.', reportId: reportResult.insertId });
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
}

module.exports = {
  getAllLabTests,
  createLabTest,
  getAllLabOrders,
  createLabOrder,
  createLabReport
};
