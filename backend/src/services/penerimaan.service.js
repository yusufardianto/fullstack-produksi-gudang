const { pool } = require('../config/database');
const AppError = require('../utils/app-error');

/**
 * Service untuk menangani logika bisnis Penerimaan Barang Gudang
 */
class PenerimaanService {
  /**
   * Helper untuk membuat nomor penerimaan otomatis
   * Format: RCV-YYYYMMDD-XXXX (contoh: RCV-20261024-0001)
   */
  static async generateNomorPenerimaan(connection) {
    const today = new Date();
    const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');
    const prefix = `RCV-${dateStr}-`;

    const [rows] = await connection.query(
      `SELECT nomor_penerimaan FROM penerimaan WHERE nomor_penerimaan LIKE ? ORDER BY id DESC LIMIT 1`,
      [`${prefix}%`]
    );

    let nextSeq = 1;
    if (rows.length > 0) {
      const lastNomor = rows[0].nomor_penerimaan;
      const parts = lastNomor.split('-');
      const lastSeq = parseInt(parts[2], 10);
      if (!isNaN(lastSeq)) {
        nextSeq = lastSeq + 1;
      }
    }

    return `${prefix}${String(nextSeq).padStart(4, '0')}`;
  }

  /**
   * Mengambil daftar seluruh transaksi penerimaan
   */
  static async getAllPenerimaan({ status, search = '' }) {
    let sql = `
      SELECT 
        p.id,
        p.nomor_penerimaan,
        p.hasil_produksi_id,
        hp.nomor_produksi,
        p.tanggal_penerimaan,
        p.status,
        p.catatan,
        p.created_at,
        p.updated_at,
        COUNT(dp.id) AS total_item,
        COALESCE(SUM(dp.jumlah_diterima), 0) AS total_kuantitas_diterima
      FROM penerimaan p
      JOIN hasil_produksi hp ON p.hasil_produksi_id = hp.id
      LEFT JOIN detail_penerimaan dp ON p.id = dp.penerimaan_id
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      sql += ` AND p.status = ?`;
      params.push(status);
    }

    if (search && search.trim() !== '') {
      sql += ` AND (p.nomor_penerimaan LIKE ? OR hp.nomor_produksi LIKE ? OR p.catatan LIKE ?)`;
      params.push(`%${search.trim()}%`, `%${search.trim()}%`, `%${search.trim()}%`);
    }

    sql += ` GROUP BY p.id ORDER BY p.id DESC`;

    const [rows] = await pool.query(sql, params);
    return rows;
  }

  /**
   * Mengambil detail satu penerimaan beserta daftar item barang yang diterima
   */
  static async getPenerimaanById(id) {
    // 1. Ambil data header penerimaan
    const headerSql = `
      SELECT 
        p.id,
        p.nomor_penerimaan,
        p.hasil_produksi_id,
        hp.nomor_produksi,
        hp.tanggal_produksi,
        p.tanggal_penerimaan,
        p.status,
        p.catatan,
        p.created_at,
        p.updated_at
      FROM penerimaan p
      JOIN hasil_produksi hp ON p.hasil_produksi_id = hp.id
      WHERE p.id = ?
    `;
    const [headerRows] = await pool.query(headerSql, [id]);

    if (headerRows.length === 0) {
      throw new AppError(`Transaksi penerimaan dengan ID ${id} tidak ditemukan`, 404);
    }

    const header = headerRows[0];

    // 2. Ambil data detail barang yang diterima
    const detailSql = `
      SELECT 
        dp.id,
        dp.barang_id,
        b.kode_barang,
        b.nama_barang,
        b.satuan,
        dp.jumlah_diterima,
        dp.created_at
      FROM detail_penerimaan dp
      JOIN barang b ON dp.barang_id = b.id
      WHERE dp.penerimaan_id = ?
      ORDER BY dp.id ASC
    `;
    const [details] = await pool.query(detailSql, [id]);

    return {
      ...header,
      items: details,
    };
  }

  /**
   * Membuat transaksi penerimaan barang baru.
   * Aturan bisnis:
   * - Menolak penerimaan jika hasil produksi belum berstatus 'completed'
   * - Memvalidasi kuantitas kumulatif agar tidak melebihi hasil produksi
   * - Status awal transaksi penerimaan adalah 'draft' (belum menambah stok gudang)
   */
  static async createPenerimaan({
    nomor_penerimaan,
    hasil_produksi_id,
    tanggal_penerimaan,
    catatan = null,
    items,
  }) {
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // 1. Periksa keberadaan dan status hasil produksi
      const [produksiRows] = await connection.query(
        `SELECT id, nomor_produksi, status FROM hasil_produksi WHERE id = ?`,
        [hasil_produksi_id]
      );

      if (produksiRows.length === 0) {
        throw new AppError(`Hasil produksi dengan ID ${hasil_produksi_id} tidak ditemukan`, 404);
      }

      const produksi = produksiRows[0];

      // Aturan Bisnis: Tolak penerimaan jika produksi belum selesai (completed)
      if (produksi.status !== 'completed') {
        throw new AppError(
          `Penerimaan gudang ditolak: Hasil produksi '${produksi.nomor_produksi}' belum berstatus 'completed' (status saat ini: '${produksi.status}')`,
          400
        );
      }

      // 2. Ambil seluruh item yang diproduksi pada transaksi tersebut
      const [detailProduksiRows] = await connection.query(
        `SELECT barang_id, jumlah FROM detail_hasil_produksi WHERE hasil_produksi_id = ?`,
        [hasil_produksi_id]
      );

      const produksiQtyMap = new Map();
      detailProduksiRows.forEach((row) => {
        produksiQtyMap.set(row.barang_id, Number(row.jumlah));
      });

      // 3. Ambil jumlah kumulatif yang sudah pernah diterima untuk produksi ini (hanya yang status draft & confirmed)
      const [existingReceivedRows] = await connection.query(
        `SELECT dp.barang_id, SUM(dp.jumlah_diterima) AS total_diterima
         FROM penerimaan p
         JOIN detail_penerimaan dp ON p.id = dp.penerimaan_id
         WHERE p.hasil_produksi_id = ? AND p.status IN ('draft', 'confirmed')
         GROUP BY dp.barang_id`,
        [hasil_produksi_id]
      );

      const existingReceivedMap = new Map();
      existingReceivedRows.forEach((row) => {
        existingReceivedMap.set(row.barang_id, Number(row.total_diterima));
      });

      // 4. Tentukan item yang diterima
      // Jika client tidak menyediakan parameter items, otomatis menerima seluruh item dari hasil produksi
      let finalItems = [];

      if (!items || !Array.isArray(items) || items.length === 0) {
        // Otomatis isi dengan sisa kuantitas yang belum diterima
        for (const [barangId, totalProduksi] of produksiQtyMap.entries()) {
          const sudahDiterima = existingReceivedMap.get(barangId) || 0;
          const sisa = totalProduksi - sudahDiterima;

          if (sisa > 0) {
            finalItems.push({
              barang_id: barangId,
              jumlah_diterima: sisa,
            });
          }
        }

        if (finalItems.length === 0) {
          throw new AppError(
            `Seluruh barang dari hasil produksi '${produksi.nomor_produksi}' sudah diterima penuh di gudang`,
            400
          );
        }
      } else {
        // Validasi item yang dikirim client secara spesifik
        const inputSet = new Set();

        for (const item of items) {
          if (inputSet.has(item.barang_id)) {
            throw new AppError(`Terdapat duplikasi barang ID ${item.barang_id} dalam daftar penerimaan`, 400);
          }
          inputSet.add(item.barang_id);

          const totalProduksi = produksiQtyMap.get(item.barang_id);
          if (totalProduksi === undefined) {
            throw new AppError(
              `Barang ID ${item.barang_id} tidak terdapat pada transaksi hasil produksi '${produksi.nomor_produksi}'`,
              400
            );
          }

          const sudahDiterima = existingReceivedMap.get(item.barang_id) || 0;
          const sisaBolehDiterima = totalProduksi - sudahDiterima;
          const jumlahInput = Number(item.jumlah_diterima);

          if (jumlahInput <= 0) {
            throw new AppError(`Jumlah diterima untuk barang ID ${item.barang_id} harus lebih besar dari 0`, 400);
          }

          if (jumlahInput > sisaBolehDiterima) {
            throw new AppError(
              `Jumlah diterima untuk barang ID ${item.barang_id} (${jumlahInput}) melebihi sisa hasil produksi yang belum diterima (${sisaBolehDiterima})`,
              400
            );
          }

          finalItems.push({
            barang_id: item.barang_id,
            jumlah_diterima: jumlahInput,
          });
        }
      }

      // 5. Tentukan nomor penerimaan
      let finalNomorPenerimaan = nomor_penerimaan ? nomor_penerimaan.trim() : null;
      if (!finalNomorPenerimaan) {
        finalNomorPenerimaan = await this.generateNomorPenerimaan(connection);
      } else {
        const [existing] = await connection.query(
          `SELECT id FROM penerimaan WHERE nomor_penerimaan = ?`,
          [finalNomorPenerimaan]
        );
        if (existing.length > 0) {
          throw new AppError(`Nomor penerimaan '${finalNomorPenerimaan}' sudah pernah digunakan`, 409);
        }
      }

      // 6. Simpan Header Penerimaan (Status awal: 'draft')
      const insertHeaderSql = `
        INSERT INTO penerimaan (nomor_penerimaan, hasil_produksi_id, tanggal_penerimaan, status, catatan)
        VALUES (?, ?, ?, 'draft', ?)
      `;
      const [headerResult] = await connection.query(insertHeaderSql, [
        finalNomorPenerimaan,
        hasil_produksi_id,
        tanggal_penerimaan,
        catatan ? catatan.trim() : null,
      ]);

      const penerimaanId = headerResult.insertId;

      // 7. Simpan Detail Penerimaan
      const detailValues = finalItems.map((item) => [
        penerimaanId,
        item.barang_id,
        item.jumlah_diterima,
      ]);

      const insertDetailSql = `
        INSERT INTO detail_penerimaan (penerimaan_id, barang_id, jumlah_diterima)
        VALUES ?
      `;
      await connection.query(insertDetailSql, [detailValues]);

      await connection.commit();

      return this.getPenerimaanById(penerimaanId);
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  /**
   * Mengubah status penerimaan (draft -> confirmed ATAU cancelled)
   * 
   * ATURAN KRITIKAL STOK & TRANSAKSI DATABASE:
   * 1. Status 'draft' -> 'confirmed':
   *    - Row-level lock pada master barang (SELECT ... FOR UPDATE) untuk mencegah race condition.
   *    - Tambah stok fisik barang di gudang.
   *    - Catat riwayat audit ke tabel mutasi_stok (Tipe: 'MASUK', Referensi: 'PENERIMAAN').
   *    - Ubah status menjadi 'confirmed'.
   *    - Mencegah konfirmasi ganda (idempotent): hanya status 'draft' yang boleh dikonfirmasi.
   * 
   * 2. Status 'confirmed' -> 'cancelled':
   *    - Penerimaan yang sudah masuk gudang dibatalkan.
   *    - Kurangi kembali stok fisik barang di master barang.
   *    - Catat riwayat audit ke tabel mutasi_stok (Tipe: 'KELUAR', Referensi: 'PEMBATALAN_PENERIMAAN').
   *    - Ubah status menjadi 'cancelled'.
   * 
   * 3. Status 'draft' -> 'cancelled':
   *    - Cukup ubah status menjadi 'cancelled' tanpa memengaruhi stok (karena draft belum menambah stok).
   */
  static async updateStatusPenerimaan(id, newStatus) {
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // 1. Kunci baris penerimaan untuk mencegah update bersamaan (Concurrency Control)
      const [penerimaanRows] = await connection.query(
        `SELECT id, nomor_penerimaan, status FROM penerimaan WHERE id = ? FOR UPDATE`,
        [id]
      );

      if (penerimaanRows.length === 0) {
        throw new AppError(`Transaksi penerimaan dengan ID ${id} tidak ditemukan`, 404);
      }

      const penerimaan = penerimaanRows[0];
      const currentStatus = penerimaan.status;

      if (currentStatus === newStatus) {
        throw new AppError(`Status transaksi penerimaan sudah '${newStatus}'`, 400);
      }

      if (currentStatus === 'cancelled') {
        throw new AppError('Transaksi penerimaan yang sudah dibatalkan (cancelled) tidak dapat diubah lagi', 400);
      }

      if (currentStatus === 'confirmed' && newStatus === 'draft') {
        throw new AppError('Penerimaan yang sudah dikonfirmasi tidak dapat dikembalikan ke status draft', 400);
      }

      // Ambil detail barang dari penerimaan ini
      const [detailItems] = await connection.query(
        `SELECT barang_id, jumlah_diterima FROM detail_penerimaan WHERE penerimaan_id = ?`,
        [id]
      );

      // KASUS 1: Konfirmasi Penerimaan (draft -> confirmed) -> STOK GUDANG BERTAMBAH
      if (newStatus === 'confirmed') {
        if (currentStatus !== 'draft') {
          throw new AppError(`Hanya penerimaan berstatus 'draft' yang dapat dikonfirmasi`, 400);
        }

        for (const item of detailItems) {
          // Kunci baris barang untuk update stok yang aman dari race condition
          const [barangRows] = await connection.query(
            `SELECT id, nama_barang, stok FROM barang WHERE id = ? FOR UPDATE`,
            [item.barang_id]
          );

          if (barangRows.length === 0) {
            throw new AppError(`Barang dengan ID ${item.barang_id} tidak ditemukan`, 404);
          }

          const barang = barangRows[0];
          const stokSebelum = Number(barang.stok);
          const jumlahDiterima = Number(item.jumlah_diterima);
          const stokSesudah = stokSebelum + jumlahDiterima;

          // Perbarui angka stok di master barang
          await connection.query(
            `UPDATE barang SET stok = ? WHERE id = ?`,
            [stokSesudah, item.barang_id]
          );

          // Catat ke kartu audit mutasi stok
          await connection.query(
            `INSERT INTO mutasi_stok 
              (barang_id, tipe_mutasi, jumlah, stok_sebelum, stok_sesudah, referensi_tipe, referensi_id, keterangan)
             VALUES (?, 'MASUK', ?, ?, ?, 'PENERIMAAN', ?, ?)`,
            [
              item.barang_id,
              jumlahDiterima,
              stokSebelum,
              stokSesudah,
              id,
              `Penerimaan barang dari produksi No: ${penerimaan.nomor_penerimaan}`,
            ]
          );
        }

        // Update status penerimaan menjadi confirmed
        await connection.query(
          `UPDATE penerimaan SET status = 'confirmed' WHERE id = ?`,
          [id]
        );
      }

      // KASUS 2: Pembatalan Penerimaan (-> cancelled)
      else if (newStatus === 'cancelled') {
        // Jika sebelumnya sudah 'confirmed', maka stok yang sempat ditambahkan harus ditarik kembali
        if (currentStatus === 'confirmed') {
          for (const item of detailItems) {
            const [barangRows] = await connection.query(
              `SELECT id, nama_barang, stok FROM barang WHERE id = ? FOR UPDATE`,
              [item.barang_id]
            );

            if (barangRows.length === 0) {
              throw new AppError(`Barang dengan ID ${item.barang_id} tidak ditemukan`, 404);
            }

            const barang = barangRows[0];
            const stokSebelum = Number(barang.stok);
            const jumlahDibatalkan = Number(item.jumlah_diterima);
            const stokSesudah = stokSebelum - jumlahDibatalkan;

            // Update pengurangan stok master barang
            await connection.query(
              `UPDATE barang SET stok = ? WHERE id = ?`,
              [stokSesudah, item.barang_id]
            );

            // Catat mutasi pembalik stok
            await connection.query(
              `INSERT INTO mutasi_stok 
                (barang_id, tipe_mutasi, jumlah, stok_sebelum, stok_sesudah, referensi_tipe, referensi_id, keterangan)
               VALUES (?, 'KELUAR', ?, ?, ?, 'PEMBATALAN_PENERIMAAN', ?, ?)`,
              [
                item.barang_id,
                jumlahDibatalkan,
                stokSebelum,
                stokSesudah,
                id,
                `Pembatalan penerimaan No: ${penerimaan.nomor_penerimaan}`,
              ]
            );
          }
        }

        // Ubah status penerimaan menjadi cancelled
        await connection.query(
          `UPDATE penerimaan SET status = 'cancelled' WHERE id = ?`,
          [id]
        );
      }

      // Selesai seluruh operasi -> Komit transaksi ke MySQL
      await connection.commit();

      return this.getPenerimaanById(id);
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }
}

module.exports = PenerimaanService;
