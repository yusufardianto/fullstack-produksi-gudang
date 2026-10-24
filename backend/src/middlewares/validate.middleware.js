const { validationResult } = require('express-validator');
const ApiResponse = require('../utils/api-response');

/**
 * Middleware untuk mengevaluasi hasil validasi dari express-validator.
 * Jika ditemukan kesalahan input, request langsung dihentikan dan dikembalikan
 * format error standar yang seragam untuk frontend/client.
 */
function validate(validations) {
  return async (req, res, next) => {
    // Jalankan seluruh aturan validasi
    for (const validation of validations) {
      const result = await validation.run(req);
      if (result.errors.length) break;
    }

    const errors = validationResult(req);
    if (errors.isEmpty()) {
      return next();
    }

    // Format pesan error menjadi array yang rapi { field, message }
    const formattedErrors = errors.array().map((err) => ({
      field: err.path || err.param,
      message: err.msg,
    }));

    return ApiResponse.error(res, 'Data yang dikirim belum valid', formattedErrors, 400);
  };
}

module.exports = validate;
