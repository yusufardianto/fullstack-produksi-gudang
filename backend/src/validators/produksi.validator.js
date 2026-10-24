const { body, param } = require('express-validator');

/**
 * Validator untuk parameter ID pada URL (/api/produksi/:id)
 */
const idParamValidator = [
  param('id')
    .isInt({ min: 1 })
    .withMessage('ID produksi harus berupa bilangan bulat positif'),
];

/**
 * Validator pembuatan hasil produksi (POST /api/produksi)
 */
const createProduksiValidator = [
  body('nomor_produksi')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Nomor produksi maksimal 50 karakter'),
  body('tanggal_produksi')
    .notEmpty()
    .withMessage('Tanggal produksi wajib diisi')
    .isISO8601()
    .withMessage('Format tanggal produksi harus valid (YYYY-MM-DD)'),
  body('catatan')
    .optional()
    .trim(),
  body('items')
    .isArray({ min: 1 })
    .withMessage('Detail hasil produksi wajib berupa array dan minimal berisi 1 item barang'),
  body('items.*.barang_id')
    .notEmpty()
    .withMessage('barang_id pada setiap item wajib diisi')
    .isInt({ min: 1 })
    .withMessage('barang_id harus berupa ID bilangan bulat positif'),
  body('items.*.jumlah')
    .notEmpty()
    .withMessage('Jumlah produksi wajib diisi')
    .isFloat({ gt: 0 })
    .withMessage('Jumlah produksi harus berupa angka lebih besar dari 0'),
];

/**
 * Validator perubahan status produksi (PATCH /api/produksi/:id/status)
 */
const updateProduksiStatusValidator = [
  ...idParamValidator,
  body('status')
    .notEmpty()
    .withMessage('Status wajib diisi')
    .isIn(['draft', 'completed', 'cancelled'])
    .withMessage('Status harus salah satu dari: draft, completed, cancelled'),
];

module.exports = {
  idParamValidator,
  createProduksiValidator,
  updateProduksiStatusValidator,
};
