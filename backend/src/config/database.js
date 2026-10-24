const mysql = require('mysql2/promise');
const dotenv = require('dotenv');
const path = require('path');

// Pastikan file .env dibaca dari root folder backend
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

/**
 * Konfigurasi Koneksi Database MySQL
 * Menggunakan Connection Pool agar koneksi dapat digunakan kembali secara efisien
 * tanpa perlu membuka dan menutup koneksi TCP secara berulang-ulang untuk setiap request.
 */
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'db_produksi_gudang',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  decimalNumbers: true, // Otomatis mengembalikan kolom DECIMAL sebagai tipe number di JS
  timezone: '+07:00',   // Waktu Indonesia Barat (WIB)
});

/**
 * Menguji koneksi database saat aplikasi pertama kali dijalankan.
 * Memberikan log yang mudah dipahami bagi pengguna pemula jika terjadi kendala.
 */
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log(`[DATABASE] Berhasil terhubung ke database '${process.env.DB_NAME || 'db_produksi_gudang'}' di ${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 3306}`);
    connection.release();
    return true;
  } catch (error) {
    console.error('================================================================');
    console.error('[DATABASE ERROR] Gagal terhubung ke MySQL:');
    console.error(`- Pesan: ${error.message}`);
    console.error(`- Kode: ${error.code}`);
    console.error('\nTips Pemeriksaan untuk Laragon:');
    console.error('1. Pastikan Laragon sudah berjalan dan tombol "Start All" telah ditekan.');
    console.error('2. Periksa apakah nama database sudah dibuat di HeidiSQL / phpMyAdmin.');
    console.error('3. Periksa file .env di folder backend/ (DB_USER, DB_PASSWORD, DB_PORT).');
    console.error('================================================================');
    return false;
  }
}

module.exports = {
  pool,
  testConnection,
};
