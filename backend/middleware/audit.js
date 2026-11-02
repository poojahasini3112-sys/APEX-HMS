const pool = require('../config/db');

/**
 * Record an audit log entry in table 34 (Audit_Log)
 * @param {Object} params
 * @param {number|null} params.userId - User_ID performing the action
 * @param {string} params.action - Action name (e.g., 'CREATE_PATIENT', 'UPDATE_BILL')
 * @param {string} params.entityName - Entity table name (e.g., 'Patient')
 * @param {number|null} params.entityId - Primary key value of the affected record
 * @param {Object|null} params.oldValues - State before change
 * @param {Object|null} params.newValues - State after change
 * @param {string|null} params.ipAddress - Client IP address
 */
async function logAudit({
  userId = null,
  action,
  entityName,
  entityId = null,
  oldValues = null,
  newValues = null,
  ipAddress = '127.0.0.1'
}) {
  try {
    const query = `
      INSERT INTO Audit_Log (User_ID, Action, Entity_Name, Entity_ID, Old_Values, New_Values, IP_Address, Timestamp)
      VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
    `;
    await pool.query(query, [
      userId,
      action,
      entityName,
      entityId,
      oldValues ? JSON.stringify(oldValues) : null,
      newValues ? JSON.stringify(newValues) : null,
      ipAddress
    ]);
  } catch (error) {
    console.error('[AuditLog Error]', error.message);
  }
}

module.exports = { logAudit };
