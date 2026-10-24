const express = require('express');
const router = express.Router();
const { param } = require('express-validator');

const StokController = require('../controllers/stok.controller');
const validate = require('../middlewares/validate.middleware');

const barangIdValidator = [
  param('barangId')
    .isInt({ min: 1 })
    .withMessage('ID barang harus berupa bilangan bulat positif'),
];

// GET /api/stok - Mengambil ringkasan stok seluruh barang
router.get('/', StokController.getAll);

// GET /api/stok/:barangId - Mengambil detail stok barang & kartu riwayat mutasi
router.get('/:barangId', validate(barangIdValidator), StokController.getByBarangId);

module.exports = router;
