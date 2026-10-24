const StokService = require('../services/stok.service');
const ApiResponse = require('../utils/api-response');

/**
 * Controller untuk menangani HTTP Request Informasi Stok dan Mutasi
 */
class StokController {
  static async getAll(req, res, next) {
    try {
      const { search } = req.query;
      const data = await StokService.getAllStok({ search });
      return ApiResponse.success(res, 'Data stok barang berhasil diambil', data);
    } catch (error) {
      next(error);
    }
  }

  static async getByBarangId(req, res, next) {
    try {
      const { barangId } = req.params;
      const data = await StokService.getStokByBarangId(barangId);
      return ApiResponse.success(res, 'Detail stok dan kartu mutasi berhasil diambil', data);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = StokController;
