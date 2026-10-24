const ApiResponse = require('../utils/api-response');

/**
 * Middleware untuk rute yang tidak ditemukan (404)
 */
function notFoundHandler(req, res, next) {
  return ApiResponse.error(
    res,
    `Rute '${req.method} ${req.originalUrl}' tidak ditemukan pada server ini`,
    null,
    404
  );
}

module.exports = notFoundHandler;
