const bcrypt = require('bcryptjs');
const pool = require('../config/db');
const { logAudit } = require('../middleware/audit');

/**
 * -------------------------------------------------------------
 * USER ACCOUNTS
 * -------------------------------------------------------------
 */
async function getAllUsers(req, res, next) {
  try {
    const [users] = await pool.query(`
      SELECT u.User_ID, u.Username, u.Role, u.Staff_ID, u.Patient_ID, u.Status, u.Last_Login, u.Created_At,
             s.First_Name AS Staff_First_Name, s.Last_Name AS Staff_Last_Name,
             p.First_Name AS Patient_First_Name, p.Last_Name AS Patient_Last_Name
      FROM User_Account u
      LEFT JOIN Staff s ON u.Staff_ID = s.Staff_ID
      LEFT JOIN Patient p ON u.Patient_ID = p.Patient_ID
      ORDER BY u.User_ID ASC
    `);
    res.json({ success: true, count: users.length, data: users });
  } catch (error) {
    next(error);
  }
}

async function createUser(req, res, next) {
  try {
    const { username, password, role, staffId, patientId } = req.body;

    if (!username || !password || !role) {
      return res.status(400).json({ success: false, message: 'Username, password and role are required.' });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const [result] = await pool.query(
      `INSERT INTO User_Account (Username, Password_Hash, Role, Staff_ID, Patient_ID, Status, Created_At)
       VALUES (?, ?, ?, ?, ?, 'Active', NOW())`,
      [username, passwordHash, role, staffId || null, patientId || null]
    );

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'CREATE_USER_ACCOUNT',
      entityName: 'User_Account',
      entityId: result.insertId,
      newValues: { username, role, staffId, patientId },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({ success: true, message: 'User account created.', userId: result.insertId });
  } catch (error) {
    next(error);
  }
}

/**
 * -------------------------------------------------------------
 * AUDIT LOGS
 * -------------------------------------------------------------
 */
async function getAllAuditLogs(req, res, next) {
  try {
    const { entity, action, limit = 50 } = req.query;
    let query = `
      SELECT al.*, u.Username, u.Role AS User_Role
      FROM Audit_Log al
      LEFT JOIN User_Account u ON al.User_ID = u.User_ID
      WHERE 1=1
    `;
    const params = [];

    if (entity) {
      query += ' AND al.Entity_Name = ?';
      params.push(entity);
    }
    if (action) {
      query += ' AND al.Action LIKE ?';
      params.push(`%${action}%`);
    }

    query += ' ORDER BY al.Timestamp DESC LIMIT ?';
    params.push(parseInt(limit, 10));

    const [logs] = await pool.query(query, params);
    res.json({ success: true, count: logs.length, data: logs });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllUsers,
  createUser,
  getAllAuditLogs
};
