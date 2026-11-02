const mysql = require('mysql2/promise');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from local .env if present
dotenv.config({ path: path.join(__dirname, '..', '.env') });
dotenv.config({ path: path.join(__dirname, '..', '..', '.env') });

// Build connection configuration supporting both local DB_* and Railway MYSQL* env variables
let poolConfig;

if (process.env.MYSQL_URL || process.env.DATABASE_URL) {
  const connectionUrl = process.env.MYSQL_URL || process.env.DATABASE_URL;
  console.log('[Database] Configuring pool from connection URL');
  poolConfig = {
    uri: connectionUrl,
    waitForConnections: true,
    connectionLimit: 15,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0
  };
} else {
  const host = process.env.MYSQLHOST || process.env.DB_HOST || 'localhost';
  const user = process.env.MYSQLUSER || process.env.DB_USER || 'root';
  const password = process.env.MYSQLPASSWORD || process.env.DB_PASSWORD || '';
  const database = process.env.MYSQLDATABASE || process.env.DB_NAME || 'Hospital_Management_System';
  const port = parseInt(process.env.MYSQLPORT || process.env.DB_PORT, 10) || 3306;

  console.log(`[Database] Configuring pool for host: ${host}, database: ${database}, user: ${user}, port: ${port}`);

  poolConfig = {
    host,
    user,
    password,
    database,
    port,
    waitForConnections: true,
    connectionLimit: 15,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0,
    ...(process.env.DB_SSL === 'true' && { ssl: { rejectUnauthorized: false } })
  };
}

const pool = mysql.createPool(poolConfig);

// Test connection on startup
(async () => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query('SELECT DATABASE() AS db, VERSION() AS ver');
    console.log(`[Database] Connected successfully to MySQL: ${rows[0].db} (${rows[0].ver})`);
    connection.release();
  } catch (error) {
    console.error('[Database] Connection Error:', error.message);
  }
})();

module.exports = pool;
