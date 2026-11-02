const pool = require('../config/db');
const { logAudit } = require('../middleware/audit');

/**
 * -------------------------------------------------------------
 * BILLING & BILL ITEMS (Transactional)
 * -------------------------------------------------------------
 */
async function getAllBills(req, res, next) {
  try {
    const { status, patientId } = req.query;
    let query = `
      SELECT b.*, 
             CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Phone AS Patient_Phone,
             adm.Admission_Reason, adm.Admitted_Date
      FROM Bill b
      JOIN Patient p ON b.Patient_ID = p.Patient_ID
      LEFT JOIN Admission adm ON b.Admission_ID = adm.Admission_ID
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      query += ' AND b.Payment_Status = ?';
      params.push(status);
    }
    if (patientId) {
      query += ' AND b.Patient_ID = ?';
      params.push(patientId);
    }

    query += ' ORDER BY b.Bill_Date DESC';
    const [bills] = await pool.query(query, params);
    res.json({ success: true, count: bills.length, data: bills });
  } catch (error) {
    next(error);
  }
}

async function getBillById(req, res, next) {
  try {
    const billId = req.params.id;

    const [[bill]] = await pool.query(`
      SELECT b.*, 
             CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Phone AS Patient_Phone, p.Email AS Patient_Email, p.Address,
             adm.Admission_Reason, adm.Admitted_Date, adm.Discharge_Date
      FROM Bill b
      JOIN Patient p ON b.Patient_ID = p.Patient_ID
      LEFT JOIN Admission adm ON b.Admission_ID = adm.Admission_ID
      WHERE b.Bill_ID = ?
    `, [billId]);

    if (!bill) {
      return res.status(404).json({ success: false, message: 'Bill not found.' });
    }

    // Bill Items
    const [items] = await pool.query('SELECT * FROM Bill_Item WHERE Bill_ID = ?', [billId]);

    // Payments
    const [payments] = await pool.query('SELECT * FROM Payment WHERE Bill_ID = ? ORDER BY Payment_Date DESC', [billId]);

    // Insurance claims
    const [claims] = await pool.query(`
      SELECT ic.*, ins.Provider_Name, ins.Policy_Number
      FROM Insurance_Claim ic
      JOIN Insurance ins ON ic.Insurance_ID = ins.Insurance_ID
      WHERE ic.Bill_ID = ?
    `, [billId]);

    res.json({
      success: true,
      data: {
        ...bill,
        items,
        payments,
        claims
      }
    });
  } catch (error) {
    next(error);
  }
}

async function createBill(req, res, next) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { patientId, admissionId, discountAmount = 0, taxAmount = 0, items } = req.body;

    if (!patientId || !items || !Array.isArray(items) || items.length === 0) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Patient and at least one bill item are required.' });
    }

    // Calculate item total
    const totalAmount = items.reduce((acc, item) => acc + (item.quantity * item.unitPrice), 0);
    const netAmount = Math.max(0, totalAmount - parseFloat(discountAmount) + parseFloat(taxAmount));

    // 1. Insert Bill
    const [billResult] = await connection.query(
      `INSERT INTO Bill (Patient_ID, Admission_ID, Bill_Date, Total_Amount, Discount_Amount, Tax_Amount, Net_Amount, Paid_Amount, Payment_Status)
       VALUES (?, ?, NOW(), ?, ?, ?, ?, 0.00, 'Pending')`,
      [patientId, admissionId || null, totalAmount, discountAmount, taxAmount, netAmount]
    );

    const billId = billResult.insertId;

    // 2. Insert Bill_Items
    for (const item of items) {
      const totalPrice = item.quantity * item.unitPrice;
      await connection.query(
        `INSERT INTO Bill_Item (Bill_ID, Item_Type, Description, Quantity, Unit_Price, Total_Price)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [billId, item.itemType || 'Other', item.description, item.quantity || 1, item.unitPrice, totalPrice]
      );
    }

    await connection.commit();

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'GENERATE_BILL',
      entityName: 'Bill',
      entityId: billId,
      newValues: { patientId, netAmount, itemsCount: items.length },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({ success: true, message: 'Bill generated successfully.', billId, netAmount });
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
}

/**
 * -------------------------------------------------------------
 * PAYMENTS (Transactional)
 * -------------------------------------------------------------
 */
async function recordPayment(req, res, next) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { billId, amount, paymentMethod, transactionReference } = req.body;

    if (!billId || !amount || amount <= 0 || !paymentMethod) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Valid bill ID, positive payment amount, and method are required.' });
    }

    // Check Bill
    const [[bill]] = await connection.query('SELECT * FROM Bill WHERE Bill_ID = ? FOR UPDATE', [billId]);
    if (!bill) {
      await connection.rollback();
      return res.status(404).json({ success: false, message: 'Bill not found.' });
    }

    // 1. Insert Payment
    const txnRef = transactionReference || `TXN-${Date.now()}`;
    const [payResult] = await connection.query(
      `INSERT INTO Payment (Bill_ID, Payment_Date, Amount, Payment_Method, Transaction_Reference, Status)
       VALUES (?, NOW(), ?, ?, ?, 'Completed')`,
      [billId, amount, paymentMethod, txnRef]
    );

    // 2. Update Bill Paid_Amount and Payment_Status
    const newPaidAmount = parseFloat(bill.Paid_Amount) + parseFloat(amount);
    let newStatus = 'Partially Paid';
    if (newPaidAmount >= parseFloat(bill.Net_Amount)) {
      newStatus = 'Paid';
    }

    await connection.query(
      'UPDATE Bill SET Paid_Amount = ?, Payment_Status = ? WHERE Bill_ID = ?',
      [newPaidAmount, newStatus, billId]
    );

    await connection.commit();

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'PROCESS_PAYMENT',
      entityName: 'Payment',
      entityId: payResult.insertId,
      newValues: { billId, amount, paymentMethod, newPaidAmount, newStatus },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({
      success: true,
      message: 'Payment recorded successfully.',
      paymentId: payResult.insertId,
      billStatus: newStatus,
      paidAmount: newPaidAmount
    });
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
}

/**
 * -------------------------------------------------------------
 * INSURANCE & CLAIMS
 * -------------------------------------------------------------
 */
async function getAllInsurances(req, res, next) {
  try {
    const { patientId } = req.query;
    let query = `
      SELECT ins.*, 
             CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name, p.Phone AS Patient_Phone
      FROM Insurance ins
      JOIN Patient p ON ins.Patient_ID = p.Patient_ID
      WHERE 1=1
    `;
    const params = [];

    if (patientId) {
      query += ' AND ins.Patient_ID = ?';
      params.push(patientId);
    }

    query += ' ORDER BY ins.Insurance_ID DESC';
    const [insurances] = await pool.query(query, params);
    res.json({ success: true, count: insurances.length, data: insurances });
  } catch (error) {
    next(error);
  }
}

async function createInsurance(req, res, next) {
  try {
    const { patientId, providerName, policyNumber, coverageLimit, validFrom, validTo } = req.body;

    if (!patientId || !providerName || !policyNumber || coverageLimit === undefined || !validFrom || !validTo) {
      return res.status(400).json({ success: false, message: 'All insurance fields are required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Insurance (Patient_ID, Provider_Name, Policy_Number, Coverage_Limit, Valid_From, Valid_To, Status)
       VALUES (?, ?, ?, ?, ?, ?, 'Active')`,
      [patientId, providerName, policyNumber, coverageLimit, validFrom, validTo]
    );

    res.status(201).json({ success: true, message: 'Insurance policy registered.', insuranceId: result.insertId });
  } catch (error) {
    next(error);
  }
}

async function getAllClaims(req, res, next) {
  try {
    const [claims] = await pool.query(`
      SELECT ic.*, 
             ins.Provider_Name, ins.Policy_Number,
             b.Total_Amount, b.Net_Amount, b.Payment_Status,
             CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient_Name
      FROM Insurance_Claim ic
      JOIN Insurance ins ON ic.Insurance_ID = ins.Insurance_ID
      JOIN Bill b ON ic.Bill_ID = b.Bill_ID
      JOIN Patient p ON b.Patient_ID = p.Patient_ID
      ORDER BY ic.Claim_Date DESC
    `);
    res.json({ success: true, count: claims.length, data: claims });
  } catch (error) {
    next(error);
  }
}

async function createClaim(req, res, next) {
  try {
    const { insuranceId, billId, claimedAmount, remarks } = req.body;

    if (!insuranceId || !billId || !claimedAmount) {
      return res.status(400).json({ success: false, message: 'Insurance ID, Bill ID and Claimed Amount are required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Insurance_Claim (Insurance_ID, Bill_ID, Claim_Date, Claimed_Amount, Approved_Amount, Claim_Status, Remarks)
       VALUES (?, ?, NOW(), ?, 0.00, 'Submitted', ?)`,
      [insuranceId, billId, claimedAmount, remarks || null]
    );

    res.status(201).json({ success: true, message: 'Insurance claim submitted.', claimId: result.insertId });
  } catch (error) {
    next(error);
  }
}

async function updateClaimStatus(req, res, next) {
  try {
    const claimId = req.params.id;
    const { status, approvedAmount, settlementDate, remarks } = req.body;

    if (!['Submitted', 'In Review', 'Approved', 'Rejected', 'Settled'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid claim status.' });
    }

    await pool.query(
      `UPDATE Insurance_Claim 
       SET Claim_Status = ?, Approved_Amount = COALESCE(?, Approved_Amount), 
           Settlement_Date = ?, Remarks = COALESCE(?, Remarks)
       WHERE Claim_ID = ?`,
      [status, approvedAmount, settlementDate || null, remarks, claimId]
    );

    res.json({ success: true, message: `Claim updated to ${status}.` });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllBills,
  getBillById,
  createBill,
  recordPayment,
  getAllInsurances,
  createInsurance,
  getAllClaims,
  createClaim,
  updateClaimStatus
};
