const { body, param } = require('express-validator');

/**
 * Validator untuk parameter ID pada URL (/api/barang/:id)
 */
const idParamValidator = [
  param('id')
    .isInt({ min: 1 })
    .withMessage('ID barang harus berupa bilangan bulat positif'),
];

/**
 * Validator saat menambah barang baru (POST /api/barang)
 */
const createBarangValidator = [
  body('kode_barang')
    .trim()
    .notEmpty()
    .withMessage('Kode barang wajib diisi')
    .isLength({ max: 50 })
    .withMessage('Kode barang maksimal 50 karakter')
    .custom((val) => {
      if (val.trim().length === 0) {
        throw new Error('Kode barang tidak boleh hanya berisi spasi');
      }
      return true;
    }),
  body('nama_barang')
    .trim()
    .notEmpty()
    .withMessage('Nama barang wajib diisi')
    .isLength({ max: 255 })
    .withMessage('Nama barang maksimal 255 karakter')
    .custom((val) => {
      if (val.trim().length === 0) {
        throw new Error('Nama barang tidak boleh hanya berisi spasi');
      }
      return true;
    }),
  body('satuan')
    .trim()
    .notEmpty()
    .withMessage('Satuan barang wajib diisi')
    .isLength({ max: 50 })
    .withMessage('Satuan maksimal 50 karakter')
    .custom((val) => {
      if (val.trim().length === 0) {
        throw new Error('Satuan tidak boleh hanya berisi spasi');
      }
      return true;
    }),
];

/**
 * Validator saat memperbarui data barang (PUT /api/barang/:id)
 */
const updateBarangValidator = [
  ...idParamValidator,
  body('nama_barang')
    .trim()
    .notEmpty()
    .withMessage('Nama barang wajib diisi')
    .isLength({ max: 255 })
    .withMessage('Nama barang maksimal 255 karakter'),
  body('satuan')
    .trim()
    .notEmpty()
    .withMessage('Satuan barang wajib diisi')
    .isLength({ max: 50 })
    .withMessage('Satuan maksimal 50 karakter'),
];

/**
 * Validator saat mengubah status aktif/nonaktif barang (PATCH /api/barang/:id/status)
 */
const toggleBarangStatusValidator = [
  ...idParamValidator,
  body('is_active')
    .notEmpty()
    .withMessage('Status is_active wajib diisi')
    .isBoolean()
    .withMessage('Status is_active harus berupa nilai boolean (true/false)'),
];

module.exports = {
  idParamValidator,
  createBarangValidator,
  updateBarangValidator,
  toggleBarangStatusValidator,
};
