/**
 * Custom Error Class untuk menangani error operasional aplikasi dengan status code HTTP.
 * 
 * Mengapa menggunakan AppError?
 * Agar kita dapat membedakan antara:
 * 1. Error operasional (misal: input salah, data tidak ditemukan, status tidak valid) -> ditangani rapi.
 * 2. Error pemrograman tak terduga (misal: syntax error, library crash) -> status 500 tanpa membocorkan info internal.
 */
class AppError extends Error {
  /**
   * @param {string} message - Pesan kesalahan yang ramah pengguna
   * @param {number} statusCode - HTTP status code (misal: 400, 404, 409)
   * @param {Array|null} errors - Rincian error validasi (opsional)
   */
  constructor(message, statusCode = 400, errors = null) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true; // Menandakan bahwa error ini sengaja dilempar oleh aplikasi
    this.errors = errors;

    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = AppError;
