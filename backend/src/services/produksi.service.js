const { pool } = require('../config/database');
const AppError = require('../utils/app-error');

/**
 * Service untuk menangani logika bisnis Hasil Produksi
 */
class ProduksiService {
  /**
   * Helper untuk membuat nomor produksi otomatis jika tidak disediakan
   * Format: PRD-YYYYMMDD-XXXX (contoh: PRD-20261024-0001)
   */
  static async generateNomorProduksi(connection) {
    const today = new Date();
    const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');
    const prefix = `PRD-${dateStr}-`;

    const [rows] = await connection.query(
      `SELECT nomor_produksi FROM hasil_produksi WHERE nomor_produksi LIKE ? ORDER BY id DESC LIMIT 1`,
      [`${prefix}%`]
    );

    let nextSeq = 1;
    if (rows.length > 0) {
      const lastNomor = rows[0].nomor_produksi;
      const parts = lastNomor.split('-');
      const lastSeq = parseInt(parts[2], 10);
      if (!isNaN(lastSeq)) {
        nextSeq = lastSeq + 1;
      }
    }

    return `${prefix}${String(nextSeq).padStart(4, '0')}`;
  }

  /**
   * Mengambil daftar seluruh hasil produksi (dengan filter status & pencarian)
   */
  static async getAllProduksi({ status, search = '' }) {
    let sql = `
      SELECT 
        hp.id,
        hp.nomor_produksi,
        hp.tanggal_produksi,
        hp.status,
        hp.catatan,
        hp.created_at,
        hp.updated_at,
        COUNT(dhp.id) AS total_item,
        COALESCE(SUM(dhp.jumlah), 0) AS total_kuantitas
      FROM hasil_produksi hp
      LEFT JOIN detail_hasil_produksi dhp ON hp.id = dhp.hasil_produksi_id
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      sql += ` AND hp.status = ?`;
      params.push(status);
    }

    if (search && search.trim() !== '') {
      sql += ` AND (hp.nomor_produksi LIKE ? OR hp.catatan LIKE ?)`;
      params.push(`%${search.trim()}%`, `%${search.trim()}%`);
    }

    sql += ` GROUP BY hp.id ORDER BY hp.id DESC`;

    const [rows] = await pool.query(sql, params);
    return rows;
  }

  /**
   * Mengambil detail hasil produksi beserta daftar barang di dalamnya
   */
  static async getProduksiById(id) {
    // 1. Ambil data header
    const headerSql = `
      SELECT id, nomor_produksi, tanggal_produksi, status, catatan, created_at, updated_at
      FROM hasil_produksi
      WHERE id = ?
    `;
    const [headerRows] = await pool.query(headerSql, [id]);

    if (headerRows.length === 0) {
      throw new AppError(`Hasil produksi dengan ID ${id} tidak ditemukan`, 404);
    }

    const header = headerRows[0];

    // 2. Ambil data detail barang
    const detailSql = `
      SELECT 
        dhp.id,
        dhp.barang_id,
        b.kode_barang,
        b.nama_barang,
        b.satuan,
        dhp.jumlah,
        dhp.created_at
      FROM detail_hasil_produksi dhp
      JOIN barang b ON dhp.barang_id = b.id
      WHERE dhp.hasil_produksi_id = ?
      ORDER BY dhp.id ASC
    `;
    const [details] = await pool.query(detailSql, [id]);

    return {
      ...header,
      items: details,
    };
  }

  /**
   * Membuat transaksi hasil produksi baru beserta detail barangnya.
   * Menggunakan Transaksi Database untuk menjamin header dan detail tersimpan secara atomik.
   */
  static async createProduksi({ nomor_produksi, tanggal_produksi, catatan = null, items }) {
    if (!items || !Array.isArray(items) || items.length === 0) {
      throw new AppError('Hasil produksi harus memiliki minimal satu detail item barang', 400);
    }

    // Periksa apakah ada barang_id duplikat dalam list item
    const barangIdSet = new Set();
    for (const item of items) {
      if (barangIdSet.has(item.barang_id)) {
        throw new AppError(`Terdapat duplikasi barang ID ${item.barang_id} pada daftar item produksi`, 400);
      }
      barangIdSet.add(item.barang_id);

      if (Number(item.jumlah) <= 0) {
        throw new AppError(`Jumlah produksi untuk barang ID ${item.barang_id} harus lebih besar dari nol`, 400);
      }
    }

    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // 1. Validasi keberadaan dan status aktif seluruh barang yang diproduksi
      const barangIds = Array.from(barangIdSet);
      const placeholders = barangIds.map(() => '?').join(',');
      const [barangRows] = await connection.query(
        `SELECT id, kode_barang, nama_barang, is_active FROM barang WHERE id IN (${placeholders})`,
        barangIds
      );

      if (barangRows.length !== barangIds.length) {
        throw new AppError('Satu atau lebih barang yang dipilih tidak ditemukan di database', 400);
      }

      // Pastikan semua barang aktif
      const inactiveBarang = barangRows.find((b) => b.is_active === 0 || b.is_active === false);
      if (inactiveBarang) {
        throw new AppError(
          `Barang '${inactiveBarang.nama_barang}' (${inactiveBarang.kode_barang}) berstatus nonaktif dan tidak dapat digunakan untuk produksi baru`,
          400
        );
      }

      // 2. Tentukan nomor produksi (generate otomatis jika tidak diisi pengguna)
      let finalNomorProduksi = nomor_produksi ? nomor_produksi.trim() : null;
      if (!finalNomorProduksi) {
        finalNomorProduksi = await this.generateNomorProduksi(connection);
      } else {
        // Cek keunikan nomor produksi manual
        const [existing] = await connection.query(
          `SELECT id FROM hasil_produksi WHERE nomor_produksi = ?`,
          [finalNomorProduksi]
        );
        if (existing.length > 0) {
          throw new AppError(`Nomor produksi '${finalNomorProduksi}' sudah pernah digunakan`, 409);
        }
      }

      // 3. Simpan Header Hasil Produksi (Status awal selalu 'draft')
      const insertHeaderSql = `
        INSERT INTO hasil_produksi (nomor_produksi, tanggal_produksi, status, catatan)
        VALUES (?, ?, 'draft', ?)
      `;
      const [headerResult] = await connection.query(insertHeaderSql, [
        finalNomorProduksi,
        tanggal_produksi,
        catatan ? catatan.trim() : null,
      ]);

      const hasilProduksiId = headerResult.insertId;

      // 4. Simpan Detail Barang Produksi
      const detailValues = items.map((item) => [
        hasilProduksiId,
        item.barang_id,
        item.jumlah,
      ]);

      const insertDetailSql = `
        INSERT INTO detail_hasil_produksi (hasil_produksi_id, barang_id, jumlah)
        VALUES ?
      `;
      await connection.query(insertDetailSql, [detailValues]);

      // Komit seluruh perubahan database
      await connection.commit();

      // Kembalikan objek data yang lengkap
      return this.getProduksiById(hasilProduksiId);
    } catch (error) {
      // Jika terjadi kesalahan apa pun, batalkan seluruh query yang sempat dieksekusi
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  /**
   * Mengubah status hasil produksi (draft -> completed / cancelled)
   * Aturan bisnis:
   * - 'draft' dapat diubah ke 'completed' atau 'cancelled'
   * - 'completed' tidak dapat diubah kembali ke 'draft'
   * - 'completed' tidak dapat dibatalkan jika sudah memiliki transaksi penerimaan
   * - 'cancelled' adalah status akhir dan tidak dapat diubah lagi
   */
  static async updateStatusProduksi(id, newStatus) {
    const produksi = await this.getProduksiById(id);

    if (produksi.status === newStatus) {
      throw new AppError(`Status hasil produksi sudah '${newStatus}'`, 400);
    }

    if (produksi.status === 'cancelled') {
      throw new AppError('Hasil produksi yang sudah dibatalkan (cancelled) tidak dapat diubah lagi', 400);
    }

    if (produksi.status === 'completed' && newStatus === 'draft') {
      throw new AppError('Hasil produksi yang sudah selesai (completed) tidak dapat dikembalikan ke status draft', 400);
    }

    // Jika ingin membatalkan transaksi yang sudah completed, periksa apakah ada penerimaan yang merujuknya
    if (newStatus === 'cancelled') {
      const [penerimaanRows] = await pool.query(
        `SELECT id, nomor_penerimaan, status FROM penerimaan WHERE hasil_produksi_id = ? AND status != 'cancelled'`,
        [id]
      );
      if (penerimaanRows.length > 0) {
        throw new AppError(
          `Hasil produksi tidak dapat dibatalkan karena sudah memiliki transaksi penerimaan aktif (${penerimaanRows[0].nomor_penerimaan})`,
          409
        );
      }
    }

    const updateSql = `UPDATE hasil_produksi SET status = ? WHERE id = ?`;
    await pool.query(updateSql, [newStatus, id]);

    return this.getProduksiById(id);
  }
}

module.exports = ProduksiService;
