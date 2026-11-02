const pool = require('../config/db');
const { logAudit } = require('../middleware/audit');

/**
 * -------------------------------------------------------------
 * MEDICINE INVENTORY
 * -------------------------------------------------------------
 */
async function getAllMedicines(req, res, next) {
  try {
    const { search, category, lowStockOnly } = req.query;
    let query = `
      SELECT m.*, 
             IF(m.Stock_Quantity <= m.Reorder_Level, 1, 0) AS Is_Low_Stock
      FROM Medicine m
      WHERE 1=1
    `;
    const params = [];

    if (search) {
      query += ' AND (m.Medicine_Name LIKE ? OR m.Generic_Name LIKE ? OR m.Manufacturer LIKE ?)';
      const s = `%${search}%`;
      params.push(s, s, s);
    }
    if (category) {
      query += ' AND m.Category = ?';
      params.push(category);
    }
    if (lowStockOnly === 'true') {
      query += ' AND m.Stock_Quantity <= m.Reorder_Level';
    }

    query += ' ORDER BY m.Medicine_Name ASC';
    const [medicines] = await pool.query(query, params);
    res.json({ success: true, count: medicines.length, data: medicines });
  } catch (error) {
    next(error);
  }
}

async function createMedicine(req, res, next) {
  try {
    const { medicineName, genericName, category, unitPrice, stockQuantity, reorderLevel, manufacturer } = req.body;

    if (!medicineName || !category || unitPrice === undefined || !manufacturer) {
      return res.status(400).json({ success: false, message: 'Medicine name, category, unit price and manufacturer are required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Medicine (Medicine_Name, Generic_Name, Category, Unit_Price, Stock_Quantity, Reorder_Level, Manufacturer)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [medicineName, genericName || null, category, unitPrice, stockQuantity || 0, reorderLevel || 10, manufacturer]
    );

    res.status(201).json({ success: true, message: 'Medicine added.', medicineId: result.insertId });
  } catch (error) {
    next(error);
  }
}

async function updateMedicineStock(req, res, next) {
  try {
    const medicineId = req.params.id;
    const { stockQuantity } = req.body;

    if (stockQuantity === undefined || stockQuantity < 0) {
      return res.status(400).json({ success: false, message: 'Valid stock quantity is required.' });
    }

    await pool.query('UPDATE Medicine SET Stock_Quantity = ? WHERE Medicine_ID = ?', [stockQuantity, medicineId]);
    res.json({ success: true, message: 'Stock updated.' });
  } catch (error) {
    next(error);
  }
}

/**
 * -------------------------------------------------------------
 * SUPPLIERS
 * -------------------------------------------------------------
 */
async function getAllSuppliers(req, res, next) {
  try {
    const [suppliers] = await pool.query('SELECT * FROM Supplier ORDER BY Supplier_Name ASC');
    res.json({ success: true, count: suppliers.length, data: suppliers });
  } catch (error) {
    next(error);
  }
}

async function createSupplier(req, res, next) {
  try {
    const { supplierName, contactPerson, phone, email, address } = req.body;

    if (!supplierName || !contactPerson || !phone || !address) {
      return res.status(400).json({ success: false, message: 'Supplier name, contact person, phone and address are required.' });
    }

    const [result] = await pool.query(
      `INSERT INTO Supplier (Supplier_Name, Contact_Person, Phone, Email, Address, Status)
       VALUES (?, ?, ?, ?, ?, 'Active')`,
      [supplierName, contactPerson, phone, email || null, address]
    );

    res.status(201).json({ success: true, message: 'Supplier registered.', supplierId: result.insertId });
  } catch (error) {
    next(error);
  }
}

/**
 * -------------------------------------------------------------
 * PURCHASES & BATCHES (Transactional)
 * -------------------------------------------------------------
 */
async function getAllPurchases(req, res, next) {
  try {
    const [purchases] = await pool.query(`
      SELECT p.*, s.Supplier_Name, s.Phone AS Supplier_Phone
      FROM Purchase p
      JOIN Supplier s ON p.Supplier_ID = s.Supplier_ID
      ORDER BY p.Purchase_Date DESC
    `);

    for (const purch of purchases) {
      const [items] = await pool.query(`
        SELECT pi.*, m.Medicine_Name, m.Category
        FROM Purchase_Item pi
        JOIN Medicine m ON pi.Medicine_ID = m.Medicine_ID
        WHERE pi.Purchase_ID = ?
      `, [purch.Purchase_ID]);
      purch.items = items;
    }

    res.json({ success: true, count: purchases.length, data: purchases });
  } catch (error) {
    next(error);
  }
}

async function createPurchase(req, res, next) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { supplierId, invoiceNumber, items } = req.body;

    if (!supplierId || !items || !Array.isArray(items) || items.length === 0) {
      await connection.rollback();
      return res.status(400).json({ success: false, message: 'Supplier and at least one purchase item are required.' });
    }

    // Calculate total amount
    const totalAmount = items.reduce((acc, item) => acc + (item.quantity * item.unitCost), 0);

    // 1. Insert Purchase
    const [purchResult] = await connection.query(
      `INSERT INTO Purchase (Supplier_ID, Purchase_Date, Total_Amount, Status, Invoice_Number)
       VALUES (?, NOW(), ?, 'Received', ?)`,
      [supplierId, totalAmount, invoiceNumber || `INV-${Date.now()}`]
    );

    const purchaseId = purchResult.insertId;

    // 2. Insert Purchase_Items, Batches & Update Medicine stock
    for (const item of items) {
      const totalPrice = item.quantity * item.unitCost;
      const [piResult] = await connection.query(
        `INSERT INTO Purchase_Item (Purchase_ID, Medicine_ID, Quantity, Unit_Cost, Total_Price)
         VALUES (?, ?, ?, ?, ?)`,
        [purchaseId, item.medicineId, item.quantity, item.unitCost, totalPrice]
      );

      const purchaseItemId = piResult.insertId;

      // Create batch
      const batchNum = item.batchNumber || `BAT-${Date.now().toString().slice(-6)}`;
      const mfgDate = item.manufacturingDate || new Date().toISOString().split('T')[0];
      const expiryDate = item.expiryDate || '2028-12-31';

      await connection.query(
        `INSERT INTO Medicine_Batch (Medicine_ID, Batch_Number, Manufacturing_Date, Expiry_Date, Quantity, Purchase_Item_ID)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [item.medicineId, batchNum, mfgDate, expiryDate, item.quantity, purchaseItemId]
      );

      // Increase Medicine stock
      await connection.query(
        'UPDATE Medicine SET Stock_Quantity = Stock_Quantity + ? WHERE Medicine_ID = ?',
        [item.quantity, item.medicineId]
      );
    }

    await connection.commit();

    await logAudit({
      userId: req.user ? req.user.userId : null,
      action: 'RECORD_PURCHASE',
      entityName: 'Purchase',
      entityId: purchaseId,
      newValues: { supplierId, totalAmount, itemsCount: items.length },
      ipAddress: req.ip || '127.0.0.1'
    });

    res.status(201).json({ success: true, message: 'Purchase and inventory batches recorded.', purchaseId });
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
}

async function getMedicineBatches(req, res, next) {
  try {
    const { medicineId } = req.query;
    let query = `
      SELECT mb.*, m.Medicine_Name, m.Category,
             DATEDIFF(mb.Expiry_Date, CURDATE()) AS Days_Until_Expiry
      FROM Medicine_Batch mb
      JOIN Medicine m ON mb.Medicine_ID = m.Medicine_ID
      WHERE 1=1
    `;
    const params = [];

    if (medicineId) {
      query += ' AND mb.Medicine_ID = ?';
      params.push(medicineId);
    }

    query += ' ORDER BY mb.Expiry_Date ASC';
    const [batches] = await pool.query(query, params);
    res.json({ success: true, count: batches.length, data: batches });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllMedicines,
  createMedicine,
  updateMedicineStock,
  getAllSuppliers,
  createSupplier,
  getAllPurchases,
  createPurchase,
  getMedicineBatches
};
