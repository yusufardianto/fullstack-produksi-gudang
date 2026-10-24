/**
 * Standard API Response Helper
 * 
 * Menyeragamkan seluruh struktur respons JSON yang dikirim ke klien (Frontend / Flutter / Postman).
 * 
 * Format Sukses:
 * {
 *   "success": true,
 *   "message": "...",
 *   "data": { ... }
 * }
 * 
 * Format Gagal / Error:
 * {
 *   "success": false,
 *   "message": "...",
 *   "errors": [ ... ]
 * }
 */
class ApiResponse {
  /**
   * Mengirim respons sukses standar
   * @param {object} res - Express Response object
   * @param {string} message - Pesan keberhasilan
   * @param {any} data - Payload data yang dikembalikan
   * @param {number} statusCode - HTTP status code (default: 200)
   */
  static success(res, message = 'Operasi berhasil', data = null, statusCode = 200) {
    const responsePayload = {
      success: true,
      message,
    };

    if (data !== null && data !== undefined) {
      responsePayload.data = data;
    }

    return res.status(statusCode).json(responsePayload);
  }

  /**
   * Mengirim respons error standar
   * @param {object} res - Express Response object
   * @param {string} message - Pesan kesalahan
   * @param {Array|null} errors - Detail array validasi error (opsional)
   * @param {number} statusCode - HTTP status code (default: 400)
   */
  static error(res, message = 'Terjadi kesalahan', errors = null, statusCode = 400) {
    const responsePayload = {
      success: false,
      message,
    };

    if (errors && Array.isArray(errors) && errors.length > 0) {
      responsePayload.errors = errors;
    }

    return res.status(statusCode).json(responsePayload);
  }
}

module.exports = ApiResponse;
