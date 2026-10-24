const { body, param } = require('express-validator');

/**
 * Validator untuk parameter ID pada URL (/api/penerimaan/:id)
 */
const idParamValidator = [
  param('id')
    .isInt({ min: 1 })
    .withMessage('ID penerimaan harus berupa bilangan bulat positif'),
];

/**
 * Validator pembuatan penerimaan barang (POST /api/penerimaan)
 */
const createPenerimaanValidator = [
  body('nomor_penerimaan')
    .optional()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Nomor penerimaan maksimal 50 karakter'),
  body('hasil_produksi_id')
    .notEmpty()
    .withMessage('ID hasil produksi (hasil_produksi_id) wajib diisi')
    .isInt({ min: 1 })
    .withMessage('hasil_produksi_id harus berupa bilangan bulat positif'),
  body('tanggal_penerimaan')
    .notEmpty()
    .withMessage('Tanggal penerimaan wajib diisi')
    .isISO8601()
    .withMessage('Format tanggal penerimaan harus valid (YYYY-MM-DD)'),
  body('catatan')
    .optional()
    .trim(),
  body('items')
    .optional()
    .isArray({ min: 1 })
    .withMessage('Jika item ditentukan, harus berupa array minimal 1 barang'),
  body('items.*.barang_id')
    .optional()
    .isInt({ min: 1 })
    .withMessage('barang_id harus berupa bilangan bulat positif'),
  body('items.*.jumlah_diterima')
    .optional()
    .isFloat({ gt: 0 })
    .withMessage('jumlah_diterima harus berupa angka lebih besar dari 0'),
];

/**
 * Validator perubahan status penerimaan (PATCH /api/penerimaan/:id/status)
 */
const updatePenerimaanStatusValidator = [
  ...idParamValidator,
  body('status')
    .notEmpty()
    .withMessage('Status wajib diisi')
    .isIn(['draft', 'confirmed', 'cancelled'])
    .withMessage('Status harus salah satu dari: draft, confirmed, cancelled'),
];

module.exports = {
  idParamValidator,
  createPenerimaanValidator,
  updatePenerimaanStatusValidator,
};
