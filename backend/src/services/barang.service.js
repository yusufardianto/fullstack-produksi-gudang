const { pool } = require('../config/database');
const AppError = require('../utils/app-error');

/**
 * Service untuk menangani logika bisnis Master Barang
 */
class BarangService {
  /**
   * Mengambil semua daftar barang (dengan filter pencarian dan status)
   */
  static async getAllBarang({ search = '', is_active }) {
    let sql = `
      SELECT id, kode_barang, nama_barang, satuan, stok, is_active, created_at, updated_at 
      FROM barang 
      WHERE 1=1
    `;
    const params = [];

    // Filter pencarian berdasarkan nama atau kode barang
    if (search && search.trim() !== '') {
      sql += ` AND (nama_barang LIKE ? OR kode_barang LIKE ?)`;
      params.push(`%${search.trim()}%`, `%${search.trim()}%`);
    }

    // Filter status aktif jika diberikan
    if (is_active !== undefined && is_active !== null && is_active !== '') {
      const activeValue = (is_active === 'true' || is_active === true || is_active === '1' || is_active === 1) ? 1 : 0;
      sql += ` AND is_active = ?`;
      params.push(activeValue);
    }

    sql += ` ORDER BY id DESC`;

    const [rows] = await pool.query(sql, params);
    return rows;
  }

  /**
   * Mengambil detail satu barang berdasarkan ID
   */
  static async getBarangById(id) {
    const sql = `
      SELECT id, kode_barang, nama_barang, satuan, stok, is_active, created_at, updated_at 
      FROM barang 
      WHERE id = ?
    `;
    const [rows] = await pool.query(sql, [id]);

    if (rows.length === 0) {
      throw new AppError(`Barang dengan ID ${id} tidak ditemukan`, 404);
    }

    return rows[0];
  }

  /**
   * Menambahkan barang baru
   */
  static async createBarang({ kode_barang, nama_barang, satuan }) {
    // 1. Validasi keunikan kode barang
    const checkSql = `SELECT id FROM barang WHERE kode_barang = ?`;
    const [existing] = await pool.query(checkSql, [kode_barang.trim()]);
    if (existing.length > 0) {
      throw new AppError(`Kode barang '${kode_barang}' sudah digunakan oleh barang lain`, 409);
    }

    // 2. Simpan barang baru dengan stok awal 0.00
    const insertSql = `
      INSERT INTO barang (kode_barang, nama_barang, satuan, stok, is_active)
      VALUES (?, ?, ?, 0.00, 1)
    `;
    const [result] = await pool.query(insertSql, [
      kode_barang.trim(),
      nama_barang.trim(),
      satuan.trim(),
    ]);

    return this.getBarangById(result.insertId);
  }

  /**
   * Mengubah data barang (nama dan satuan)
   */
  static async updateBarang(id, { nama_barang, satuan }) {
    // Pastikan barang ada
    await this.getBarangById(id);

    const updateSql = `
      UPDATE barang 
      SET nama_barang = ?, satuan = ?
      WHERE id = ?
    `;
    await pool.query(updateSql, [nama_barang.trim(), satuan.trim(), id]);

    return this.getBarangById(id);
  }

  /**
   * Mengubah status aktif / nonaktif (Soft Deactivation)
   * Barang nonaktif tidak boleh dihapus agar histori transaksi tidak rusak.
   */
  static async toggleStatusBarang(id, is_active) {
    await this.getBarangById(id);

    const activeValue = (is_active === true || is_active === 'true' || is_active === 1 || is_active === '1') ? 1 : 0;

    const updateSql = `UPDATE barang SET is_active = ? WHERE id = ?`;
    await pool.query(updateSql, [activeValue, id]);

    return this.getBarangById(id);
  }
}

module.exports = BarangService;
