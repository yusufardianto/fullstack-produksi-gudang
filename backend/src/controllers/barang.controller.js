const BarangService = require('../services/barang.service');
const ApiResponse = require('../utils/api-response');

/**
 * Controller untuk menangani HTTP Request seputar Master Barang
 */
class BarangController {
  static async getAll(req, res, next) {
    try {
      const { search, is_active } = req.query;
      const data = await BarangService.getAllBarang({ search, is_active });
      return ApiResponse.success(res, 'Daftar data barang berhasil diambil', data);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req, res, next) {
    try {
      const { id } = req.params;
      const data = await BarangService.getBarangById(id);
      return ApiResponse.success(res, 'Detail barang berhasil diambil', data);
    } catch (error) {
      next(error);
    }
  }

  static async create(req, res, next) {
    try {
      const { kode_barang, nama_barang, satuan } = req.body;
      const data = await BarangService.createBarang({ kode_barang, nama_barang, satuan });
      return ApiResponse.success(res, 'Data barang berhasil ditambahkan', data, 201);
    } catch (error) {
      next(error);
    }
  }

  static async update(req, res, next) {
    try {
      const { id } = req.params;
      const { nama_barang, satuan } = req.body;
      const data = await BarangService.updateBarang(id, { nama_barang, satuan });
      return ApiResponse.success(res, 'Data barang berhasil diperbarui', data);
    } catch (error) {
      next(error);
    }
  }

  static async toggleStatus(req, res, next) {
    try {
      const { id } = req.params;
      const { is_active } = req.body;
      const data = await BarangService.toggleStatusBarang(id, is_active);
      const statusText = data.is_active ? 'diaktifkan' : 'dinonaktifkan';
      return ApiResponse.success(res, `Barang berhasil ${statusText}`, data);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = BarangController;
