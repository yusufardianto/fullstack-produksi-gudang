const ProduksiService = require('../services/produksi.service');
const ApiResponse = require('../utils/api-response');

/**
 * Controller untuk menangani HTTP Request Hasil Produksi
 */
class ProduksiController {
  static async getAll(req, res, next) {
    try {
      const { status, search } = req.query;
      const data = await ProduksiService.getAllProduksi({ status, search });
      return ApiResponse.success(res, 'Daftar hasil produksi berhasil diambil', data);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req, res, next) {
    try {
      const { id } = req.params;
      const data = await ProduksiService.getProduksiById(id);
      return ApiResponse.success(res, 'Detail hasil produksi berhasil diambil', data);
    } catch (error) {
      next(error);
    }
  }

  static async create(req, res, next) {
    try {
      const { nomor_produksi, tanggal_produksi, catatan, items } = req.body;
      const data = await ProduksiService.createProduksi({
        nomor_produksi,
        tanggal_produksi,
        catatan,
        items,
      });
      return ApiResponse.success(res, 'Hasil produksi berhasil dibuat', data, 201);
    } catch (error) {
      next(error);
    }
  }

  static async updateStatus(req, res, next) {
    try {
      const { id } = req.params;
      const { status } = req.body;
      const data = await ProduksiService.updateStatusProduksi(id, status);
      return ApiResponse.success(res, `Status hasil produksi berhasil diubah menjadi '${status}'`, data);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = ProduksiController;
