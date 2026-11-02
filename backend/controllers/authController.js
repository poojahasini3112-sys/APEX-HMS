const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { JWT_SECRET } = require('../middleware/auth');
const { logAudit } = require('../middleware/audit');

/**
 * Login user and issue JWT token
 */
async function login(req, res, next) {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Username and password are required.'
      });
    }

    const [rows] = await pool.query(
      `SELECT u.User_ID, u.Username, u.Password_Hash, u.Role, u.Staff_ID, u.Patient_ID, u.Status,
              s.First_Name AS Staff_First_Name, s.Last_Name AS Staff_Last_Name,
              p.First_Name AS Patient_First_Name, p.Last_Name AS Patient_Last_Name
       FROM User_Account u
       LEFT JOIN Staff s ON u.Staff_ID = s.Staff_ID
       LEFT JOIN Patient p ON u.Patient_ID = p.Patient_ID
       WHERE u.Username = ?`,
      [username]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid username or password.'
      });
    }

    const user = rows[0];

    if (user.Status !== 'Active') {
      return res.status(403).json({
        success: false,
        message: `Account is ${user.Status}. Please contact the administrator.`
      });
    }

    const isMatch = await bcrypt.compare(password, user.Password_Hash);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid username or password.'
      });
    }

    // Update Last_Login
    await pool.query('UPDATE User_Account SET Last_Login = NOW() WHERE User_ID = ?', [user.User_ID]);

    const displayName = user.Staff_First_Name ? `${user.Staff_First_Name} ${user.Staff_Last_Name}`
                      : user.Patient_First_Name ? `${user.Patient_First_Name} ${user.Patient_Last_Name}`
                      : user.Username;

    const token = jwt.sign(
      {
        userId: user.User_ID,
        username: user.Username,
        role: user.Role,
        staffId: user.Staff_ID,
        patientId: user.Patient_ID,
        name: displayName
      },
      JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    // Audit log
    await logAudit({
      userId: user.User_ID,
      action: 'USER_LOGIN',
      entityName: 'User_Account',
      entityId: user.User_ID,
      newValues: { username: user.Username, role: user.Role },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.json({
      success: true,
      message: 'Login successful.',
      token,
      user: {
        userId: user.User_ID,
        username: user.Username,
        role: user.Role,
        name: displayName,
        staffId: user.Staff_ID,
        patientId: user.Patient_ID
      }
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Get current user profile from token
 */
async function getProfile(req, res, next) {
  try {
    const [rows] = await pool.query(
      `SELECT u.User_ID, u.Username, u.Role, u.Staff_ID, u.Patient_ID, u.Status, u.Last_Login, u.Created_At,
              s.First_Name, s.Last_Name, s.Email, s.Phone, s.Department_ID,
              d.Department_Name
       FROM User_Account u
       LEFT JOIN Staff s ON u.Staff_ID = s.Staff_ID
       LEFT JOIN Department d ON s.Department_ID = d.Department_ID
       WHERE u.User_ID = ?`,
      [req.user.userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    res.json({ success: true, user: rows[0] });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  login,
  getProfile
};
