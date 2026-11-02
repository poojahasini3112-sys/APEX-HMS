/**
 * Centralized error handling middleware
 */
function errorHandler(err, req, res, next) {
  console.error('[Error Occurred]:', err.stack || err.message);

  const statusCode = err.status || err.statusCode || 500;
  
  // Handle MySQL duplicate key error (code 1062)
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({
      success: false,
      message: 'Duplicate entry: A record with that unique key already exists.',
      error: err.sqlMessage
    });
  }

  // Handle MySQL foreign key constraint failure
  if (err.code === 'ER_ROW_IS_REFERENCED_2' || err.code === 'ER_NO_REFERENCED_ROW_2') {
    return res.status(400).json({
      success: false,
      message: 'Referential integrity violation: Referenced record does not exist or has child records.',
      error: err.sqlMessage
    });
  }

  res.status(statusCode).json({
    success: false,
    message: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
}

module.exports = errorHandler;
