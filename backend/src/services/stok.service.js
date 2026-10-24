const { pool } = require('../config/database');
const AppError = require('../utils/app-error');

/**
 * Service untuk memantau data stok barang dan histori mutasi gudang
 */
class StokService {
  /**
   * Mengambil daftar ringkasan stok seluruh barang yang aktif
   */
  static async getAllStok({ search = '' }) {
    let sql = `
      SELECT 
        b.id,
        b.kode_barang,
        b.nama_barang,
        b.satuan,
        b.stok AS stok_terkini,
        b.is_active,
        b.updated_at AS terakhir_diperbarui
      FROM barang b
      WHERE 1=1
    `;
    const params = [];

    if (search && search.trim() !== '') {
      sql += ` AND (b.nama_barang LIKE ? OR b.kode_barang LIKE ?)`;
      params.push(`%${search.trim()}%`, `%${search.trim()}%`);
    }

    sql += ` ORDER BY b.stok DESC, b.nama_barang ASC`;

    const [rows] = await pool.query(sql, params);
    return rows;
  }

  /**
   * Mengambil detail stok satu barang beserta kartu stok / riwayat mutasi
   */
  static async getStokByBarangId(barangId) {
    // 1. Ambil data master barang
    const barangSql = `
      SELECT id, kode_barang, nama_barang, satuan, stok AS stok_terkini, is_active, updated_at
      FROM barang
      WHERE id = ?
    `;
    const [barangRows] = await pool.query(barangSql, [barangId]);

    if (barangRows.length === 0) {
      throw new AppError(`Barang dengan ID ${barangId} tidak ditemukan`, 404);
    }

    const barang = barangRows[0];

    // 2. Ambil riwayat mutasi stok untuk barang ini (Audit Trail)
    const mutasiSql = `
      SELECT 
        ms.id,
        ms.tipe_mutasi,
        ms.jumlah,
        ms.stok_sebelum,
        ms.stok_sesudah,
        ms.referensi_tipe,
        ms.referensi_id,
        ms.keterangan,
        ms.created_at AS tanggal_mutasi
      FROM mutasi_stok ms
      WHERE ms.barang_id = ?
      ORDER BY ms.id DESC
    `;
    const [mutasiRows] = await pool.query(mutasiSql, [barangId]);

    return {
      barang,
      riwayat_mutasi: mutasiRows,
    };
  }
}

module.exports = StokService;
