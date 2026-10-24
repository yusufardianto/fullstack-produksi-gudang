-- ==============================================================================
-- SKEMA DATABASE: SISTEM HASIL PRODUKSI DAN GUDANG
-- Engine: InnoDB (Mendukung Foreign Key dan Transaksi ACID)
-- ==============================================================================

-- 1. Buat Database jika belum ada
CREATE DATABASE IF NOT EXISTS `db_produksi_gudang` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `db_produksi_gudang`;

-- ------------------------------------------------------------------------------
-- 2. TABEL: barang (Master Barang)
-- Menyimpan katalog barang, satuan, stok terkini, dan status aktif.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `barang` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `kode_barang` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Kode unik barang, misal BRG-001',
    `nama_barang` VARCHAR(255) NOT NULL COMMENT 'Nama lengkap barang',
    `satuan` VARCHAR(50) NOT NULL COMMENT 'Satuan barang, misal: pcs, box, kg',
    `stok` DECIMAL(12, 2) NOT NULL DEFAULT 0.00 COMMENT 'Jumlah stok fisik terkini di gudang',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = Aktif, 0 = Nonaktif (Soft delete)',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_barang_kode` (`kode_barang`),
    INDEX `idx_barang_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 3. TABEL: hasil_produksi (Header Transaksi Produksi)
-- Mencatat transaksi proses produksi beserta status penyelesaiannya.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `hasil_produksi` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `nomor_produksi` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Nomor seri unik produksi, misal PRD-20261024-001',
    `tanggal_produksi` DATE NOT NULL COMMENT 'Tanggal dilakukannya produksi',
    `status` ENUM('draft', 'completed', 'cancelled') NOT NULL DEFAULT 'draft' COMMENT 'Status siklus hidup produksi',
    `catatan` TEXT NULL COMMENT 'Keterangan tambahan proses produksi',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_produksi_nomor` (`nomor_produksi`),
    INDEX `idx_produksi_status` (`status`),
    INDEX `idx_produksi_tanggal` (`tanggal_produksi`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 4. TABEL: detail_hasil_produksi (Detail Barang Hasil Produksi)
-- Menghubungkan satu transaksi produksi dengan banyak barang dan kuantitasnya.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `detail_hasil_produksi` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `hasil_produksi_id` INT NOT NULL COMMENT 'Relasi ke header hasil_produksi',
    `barang_id` INT NOT NULL COMMENT 'Relasi ke master barang',
    `jumlah` DECIMAL(12, 2) NOT NULL COMMENT 'Kuantitas barang yang diproduksi (harus > 0)',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_produksi_barang` (`hasil_produksi_id`, `barang_id`),
    INDEX `idx_detail_produksi_barang` (`barang_id`),
    CONSTRAINT `chk_jumlah_produksi_positif` CHECK (`jumlah` > 0),
    CONSTRAINT `fk_detail_produksi_header` 
        FOREIGN KEY (`hasil_produksi_id`) REFERENCES `hasil_produksi` (`id`) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_detail_produksi_barang` 
        FOREIGN KEY (`barang_id`) REFERENCES `barang` (`id`) 
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 5. TABEL: penerimaan (Header Transaksi Penerimaan Gudang)
-- Mencatat penerimaan fisik barang dari hasil produksi yang sudah selesai.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `penerimaan` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `nomor_penerimaan` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Nomor unik surat penerimaan barang, misal RCV-20261024-001',
    `hasil_produksi_id` INT NOT NULL COMMENT 'Relasi ke transaksi hasil produksi (harus status completed)',
    `tanggal_penerimaan` DATE NOT NULL COMMENT 'Tanggal barang diterima di gudang',
    `status` ENUM('draft', 'confirmed', 'cancelled') NOT NULL DEFAULT 'draft' COMMENT 'Status penerimaan: draft, confirmed (stok bertambah), cancelled (batal)',
    `catatan` TEXT NULL COMMENT 'Catatan serah terima gudang',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_penerimaan_nomor` (`nomor_penerimaan`),
    INDEX `idx_penerimaan_status` (`status`),
    INDEX `idx_penerimaan_produksi` (`hasil_produksi_id`),
    CONSTRAINT `fk_penerimaan_produksi` 
        FOREIGN KEY (`hasil_produksi_id`) REFERENCES `hasil_produksi` (`id`) 
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 6. TABEL: detail_penerimaan (Detail Barang Diterima)
-- Mencatat item barang dan kuantitas aktual yang diterima masuk ke gudang.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `detail_penerimaan` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `penerimaan_id` INT NOT NULL COMMENT 'Relasi ke header penerimaan',
    `barang_id` INT NOT NULL COMMENT 'Relasi ke master barang',
    `jumlah_diterima` DECIMAL(12, 2) NOT NULL COMMENT 'Jumlah fisik barang yang diterima di gudang',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_penerimaan_barang` (`penerimaan_id`, `barang_id`),
    INDEX `idx_detail_penerimaan_barang` (`barang_id`),
    CONSTRAINT `chk_jumlah_diterima_positif` CHECK (`jumlah_diterima` > 0),
    CONSTRAINT `fk_detail_penerimaan_header` 
        FOREIGN KEY (`penerimaan_id`) REFERENCES `penerimaan` (`id`) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_detail_penerimaan_barang` 
        FOREIGN KEY (`barang_id`) REFERENCES `barang` (`id`) 
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 7. TABEL: mutasi_stok (Kartu Stok / Audit Trail Mutasi Stok)
-- Mencatat setiap riwayat perubahan stok masuk/keluar untuk transparansi audit.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mutasi_stok` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `barang_id` INT NOT NULL COMMENT 'Relasi ke barang',
    `tipe_mutasi` ENUM('MASUK', 'KELUAR') NOT NULL COMMENT 'Arah aliran barang',
    `jumlah` DECIMAL(12, 2) NOT NULL COMMENT 'Jumlah mutasi',
    `stok_sebelum` DECIMAL(12, 2) NOT NULL COMMENT 'Kondisi stok sebelum transaksi',
    `stok_sesudah` DECIMAL(12, 2) NOT NULL COMMENT 'Kondisi stok sesudah transaksi',
    `referensi_tipe` VARCHAR(50) NOT NULL COMMENT 'Jenis transaksi: PENERIMAAN / PEMBATALAN_PENERIMAAN',
    `referensi_id` INT NOT NULL COMMENT 'ID dari transaksi referensi (penerimaan_id)',
    `keterangan` VARCHAR(255) NULL COMMENT 'Keterangan audit mutasi',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_mutasi_barang` (`barang_id`),
    INDEX `idx_mutasi_referensi` (`referensi_tipe`, `referensi_id`),
    CONSTRAINT `fk_mutasi_barang` 
        FOREIGN KEY (`barang_id`) REFERENCES `barang` (`id`) 
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
