const ApiResponse = require('../utils/api-response');
const AppError = require('../utils/app-error');

/**
 * Global Error Handling Middleware
 * 
 * Menangkap seluruh error dari async controller maupun internal Express.
 * Memastikan tidak ada stack trace sensitif yang bocor ke klien,
 * serta menerjemahkan kode error MySQL umum menjadi respons yang bersahabat.
 */
function errorHandler(err, req, res, next) {
  // Log error di console server untuk kebutuhan debugging pengembang
  console.error(`[ERROR] [${req.method}] ${req.originalUrl}:`, err);

  // 1. Tangani AppError (Error operasional terencana yang dilempar dari service/controller)
  if (err instanceof AppError) {
    return ApiResponse.error(res, err.message, err.errors, err.statusCode);
  }

  // 2. Tangani Error Duplikasi Key MySQL (misal kode barang / nomor transaksi sudah ada)
  if (err.code === 'ER_DUP_ENTRY') {
    return ApiResponse.error(
      res,
      'Data dengan kode atau nomor transaksi tersebut sudah terdaftar (duplikat)',
      null,
      409
    );
  }

  // 3. Tangani Error Foreign Key Constraint MySQL
  if (err.code === 'ER_ROW_IS_REFERENCED_2') {
    return ApiResponse.error(
      res,
      'Data tidak dapat dihapus atau diubah karena masih digunakan dalam transaksi lain',
      null,
      409
    );
  }

  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    return ApiResponse.error(
      res,
      'Referensi data terkait tidak ditemukan dalam database',
      null,
      400
    );
  }

  // 4. Tangani Syntax Error JSON pada Body Request
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return ApiResponse.error(
      res,
      'Format JSON pada body request tidak valid',
      null,
      400
    );
  }

  // 5. Error Tak Terduga (Internal Server Error)
  const isDev = process.env.NODE_ENV === 'development';
  return ApiResponse.error(
    res,
    isDev ? `Kesalahan server: ${err.message}` : 'Terjadi kesalahan internal pada server',
    null,
    500
  );
}

module.exports = errorHandler;
