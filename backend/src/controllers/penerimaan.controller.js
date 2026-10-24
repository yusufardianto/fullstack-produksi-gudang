const PenerimaanService = require('../services/penerimaan.service');
const ApiResponse = require('../utils/api-response');

/**
 * Controller untuk menangani HTTP Request Penerimaan Barang Gudang
 */
class PenerimaanController {
  static async getAll(req, res, next) {
    try {
      const { status, search } = req.query;
      const data = await PenerimaanService.getAllPenerimaan({ status, search });
      return ApiResponse.success(res, 'Daftar transaksi penerimaan berhasil diambil', data);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req, res, next) {
    try {
      const { id } = req.params;
      const data = await PenerimaanService.getPenerimaanById(id);
      return ApiResponse.success(res, 'Detail transaksi penerimaan berhasil diambil', data);
    } catch (error) {
      next(error);
    }
  }

  static async create(req, res, next) {
    try {
      const { nomor_penerimaan, hasil_produksi_id, tanggal_penerimaan, catatan, items } = req.body;
      const data = await PenerimaanService.createPenerimaan({
        nomor_penerimaan,
        hasil_produksi_id,
        tanggal_penerimaan,
        catatan,
        items,
      });
      return ApiResponse.success(res, 'Transaksi penerimaan berhasil dicatat', data, 201);
    } catch (error) {
      next(error);
    }
  }

  static async updateStatus(req, res, next) {
    try {
      const { id } = req.params;
      const { status } = req.body;
      const data = await PenerimaanService.updateStatusPenerimaan(id, status);

      let message = `Status transaksi penerimaan berhasil diubah menjadi '${status}'`;
      if (status === 'confirmed') {
        message = 'Penerimaan berhasil dikonfirmasi. Stok barang di gudang telah bertambah.';
      } else if (status === 'cancelled') {
        message = 'Penerimaan berhasil dibatalkan. Stok barang di gudang telah disesuaikan kembali.';
      }

      return ApiResponse.success(res, message, data);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = PenerimaanController;
