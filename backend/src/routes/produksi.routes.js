const express = require('express');
const router = express.Router();

const ProduksiController = require('../controllers/produksi.controller');
const validate = require('../middlewares/validate.middleware');
const {
  idParamValidator,
  createProduksiValidator,
  updateProduksiStatusValidator,
} = require('../validators/produksi.validator');

// GET /api/produksi - Mengambil daftar transaksi hasil produksi (filter ?status= & ?search=)
router.get('/', ProduksiController.getAll);

// GET /api/produksi/:id - Mengambil detail satu hasil produksi beserta detail barangnya
router.get('/:id', validate(idParamValidator), ProduksiController.getById);

// POST /api/produksi - Membuat transaksi hasil produksi baru
router.post('/', validate(createProduksiValidator), ProduksiController.create);

// PATCH /api/produksi/:id/status - Mengubah status produksi (draft -> completed / cancelled)
router.patch('/:id/status', validate(updateProduksiStatusValidator), ProduksiController.updateStatus);

module.exports = router;
