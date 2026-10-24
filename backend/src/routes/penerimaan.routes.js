const express = require('express');
const router = express.Router();

const PenerimaanController = require('../controllers/penerimaan.controller');
const validate = require('../middlewares/validate.middleware');
const {
  idParamValidator,
  createPenerimaanValidator,
  updatePenerimaanStatusValidator,
} = require('../validators/penerimaan.validator');

// GET /api/penerimaan - Mengambil daftar transaksi penerimaan barang
router.get('/', PenerimaanController.getAll);

// GET /api/penerimaan/:id - Mengambil detail satu transaksi penerimaan
router.get('/:id', validate(idParamValidator), PenerimaanController.getById);

// POST /api/penerimaan - Mencatat transaksi penerimaan baru dari hasil produksi
router.post('/', validate(createPenerimaanValidator), PenerimaanController.create);

// PATCH /api/penerimaan/:id/status - Mengubah status penerimaan (draft -> confirmed / cancelled)
router.patch('/:id/status', validate(updatePenerimaanStatusValidator), PenerimaanController.updateStatus);

module.exports = router;
