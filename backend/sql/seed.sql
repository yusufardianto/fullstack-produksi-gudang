-- ==============================================================================
-- DATA AWAL (SEED): SISTEM HASIL PRODUKSI DAN GUDANG
-- ==============================================================================

USE `db_produksi_gudang`;

-- 1. Data Awal Master Barang
-- Stok awal adalah 0.00 karena stok HANYA boleh bertambah dari konfirmasi penerimaan yang sah.
INSERT INTO `barang` (`id`, `kode_barang`, `nama_barang`, `satuan`, `stok`, `is_active`) VALUES
(1, 'BRG-001', 'Pipa PVC AW 1/2 Inch', 'batang', 0.00, 1),
(2, 'BRG-002', 'Pipa PVC AW 3/4 Inch', 'batang', 0.00, 1),
(3, 'BRG-003', 'Talang Air Kotak 4 Meter', 'batang', 0.00, 1),
(4, 'BRG-004', 'Fitting Knee 1/2 Inch', 'dus', 0.00, 1),
(5, 'BRG-005', 'Lem PVC Standar 400g', 'kaleng', 0.00, 0) -- Contoh barang nonaktif untuk pengujian validasi
ON DUPLICATE KEY UPDATE `nama_barang` = VALUES(`nama_barang`);

-- 2. Contoh Transaksi Hasil Produksi (Header)
-- Transaksi 1: Status draft (belum selesai)
INSERT INTO `hasil_produksi` (`id`, `nomor_produksi`, `tanggal_produksi`, `status`, `catatan`) VALUES
(1, 'PRD-20261024-001', '2026-10-24', 'completed', 'Produksi batch pagi shift 1 selesai tepat waktu'),
(2, 'PRD-20261024-002', '2026-10-24', 'draft', 'Sedang dalam pengerjaan mesin line 2')
ON DUPLICATE KEY UPDATE `status` = VALUES(`status`);

-- 3. Contoh Detail Hasil Produksi
INSERT INTO `detail_hasil_produksi` (`id`, `hasil_produksi_id`, `barang_id`, `jumlah`) VALUES
(1, 1, 1, 100.00), -- 100 batang Pipa 1/2 Inch
(2, 1, 2, 50.00),  -- 50 batang Pipa 3/4 Inch
(3, 2, 3, 30.00)   -- 30 batang Talang Air
ON DUPLICATE KEY UPDATE `jumlah` = VALUES(`jumlah`);

-- 4. Contoh Transaksi Penerimaan Gudang dari Hasil Produksi #1
-- Penerimaan berstatus draft (belum confirmed, sehingga stok fisik belum bertambah)
INSERT INTO `penerimaan` (`id`, `nomor_penerimaan`, `hasil_produksi_id`, `tanggal_penerimaan`, `status`, `catatan`) VALUES
(1, 'RCV-20261024-001', 1, '2026-10-24', 'draft', 'Menunggu verifikasi fisik oleh kepala gudang')
ON DUPLICATE KEY UPDATE `status` = VALUES(`status`);

-- 5. Detail Penerimaan Gudang
INSERT INTO `detail_penerimaan` (`id`, `penerimaan_id`, `barang_id`, `jumlah_diterima`) VALUES
(1, 1, 1, 100.00),
(2, 1, 2, 50.00)
ON DUPLICATE KEY UPDATE `jumlah_diterima` = VALUES(`jumlah_diterima`);
