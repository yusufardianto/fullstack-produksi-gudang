const express = require('express');
const router = express.Router();

const BarangController = require('../controllers/barang.controller');
const validate = require('../middlewares/validate.middleware');
const {
  idParamValidator,
  createBarangValidator,
  updateBarangValidator,
  toggleBarangStatusValidator,
} = require('../validators/barang.validator');

// GET /api/barang - Mengambil daftar barang (bisa filter ?search= & ?is_active=)
router.get('/', BarangController.getAll);

// GET /api/barang/:id - Mengambil detail satu barang
router.get('/:id', validate(idParamValidator), BarangController.getById);

// POST /api/barang - Menambahkan master barang baru
router.post('/', validate(createBarangValidator), BarangController.create);

// PUT /api/barang/:id - Mengubah data nama dan satuan barang
router.put('/:id', validate(updateBarangValidator), BarangController.update);

// PATCH /api/barang/:id/status - Mengubah status aktif/nonaktif barang
router.patch('/:id/status', validate(toggleBarangStatusValidator), BarangController.toggleStatus);

module.exports = router;
