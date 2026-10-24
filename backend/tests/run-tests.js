/**
 * Test Suite Otomatis untuk Backend REST API Hasil Produksi & Gudang
 * 
 * Menjalankan:
 * 1. Uji Validitas Sintaks & Integritas Modul
 * 2. Uji HTTP Server & Health Check Endpoint
 * 3. Uji Rule Validasi Input (Barang, Produksi, Penerimaan)
 * 4. Uji Koneksi Database & Skenario Bisnis Live (End-to-End) jika MySQL aktif
 */

const assert = require('assert');
const http = require('http');
const path = require('path');
const dotenv = require('dotenv');

// Muat variabel environment
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const app = require('../src/app');
const { pool } = require('../src/config/database');

const BarangService = require('../src/services/barang.service');
const ProduksiService = require('../src/services/produksi.service');
const PenerimaanService = require('../src/services/penerimaan.service');
const StokService = require('../src/services/stok.service');

// Helper untuk menjalankan HTTP Request sederhana ke server lokal
function makeRequest(server, options, requestBody = null) {
  return new Promise((resolve, reject) => {
    const port = server.address().port;
    const reqOptions = {
      hostname: '127.0.0.1',
      port,
      path: options.path,
      method: options.method || 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...(options.headers || {}),
      },
    };

    const req = http.request(reqOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        let parsed = null;
        try {
          parsed = JSON.parse(data);
        } catch (e) {
          parsed = data;
        }
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: parsed,
        });
      });
    });

    req.on('error', (err) => reject(err));

    if (requestBody) {
      req.write(typeof requestBody === 'string' ? requestBody : JSON.stringify(requestBody));
    }
    req.end();
  });
}

async function runTestSuite() {
  console.log('================================================================');
  console.log('🧪 MEMULAI PENGUJIAN OTOMATIS BACKEND PRODUKSI & GUDANG');
  console.log('================================================================\n');

  let testsPassed = 0;
  let testsFailed = 0;

  function recordPass(testName) {
    testsPassed++;
    console.log(`  ✅ [PASS] ${testName}`);
  }

  function recordFail(testName, error) {
    testsFailed++;
    console.error(`  ❌ [FAIL] ${testName}:`, error.message);
  }

  // ----------------------------------------------------------------------------
  // BAGIAN 1: PENGUJIAN HTTP SERVER, ROUTING, DAN HEALTH CHECK
  // ----------------------------------------------------------------------------
  console.log('--- [BAGIAN 1] UJI HTTP SERVER & HEALTH CHECK ---');
  let testServer;
  try {
    testServer = await new Promise((resolve) => {
      const s = app.listen(0, '127.0.0.1', () => resolve(s));
    });

    // Test 1: Health Check GET /api/health
    const healthRes = await makeRequest(testServer, { path: '/api/health', method: 'GET' });
    assert.strictEqual(healthRes.statusCode, 200, 'Status code harus 200');
    assert.strictEqual(healthRes.body.success, true, 'Respons success harus true');
    assert.strictEqual(healthRes.body.data.status, 'OK', 'Status data harus OK');
    recordPass('GET /api/health mengembalikan status 200 dan data OK');

    // Test 2: Rute tidak ditemukan (404)
    const notFoundRes = await makeRequest(testServer, { path: '/api/rute-palsu-123', method: 'GET' });
    assert.strictEqual(notFoundRes.statusCode, 404, 'Rute tidak dikenal harus 404');
    assert.strictEqual(notFoundRes.body.success, false, 'Respons success harus false untuk 404');
    recordPass('Rute tidak dikenal mengembalikan HTTP 404 Not Found dengan format standar');

    // Test 3: Root greeting GET /
    const rootRes = await makeRequest(testServer, { path: '/', method: 'GET' });
    assert.strictEqual(rootRes.statusCode, 200, 'Root harus 200');
    assert.strictEqual(rootRes.body.success, true, 'Root success true');
    recordPass('GET / menyambut dengan daftar endpoint yang tersedia');

  } catch (error) {
    recordFail('Pengujian HTTP Server gagal', error);
  }

  // ----------------------------------------------------------------------------
  // BAGIAN 2: PENGUJIAN VALIDASI INPUT (VALIDATORS & MIDDLEWARES)
  // ----------------------------------------------------------------------------
  console.log('\n--- [BAGIAN 2] UJI VALIDASI INPUT (EXPRESS-VALIDATOR) ---');
  try {
    // Test 4: Validasi penambahan barang kosong (POST /api/barang)
    const invalidBarangRes = await makeRequest(
      testServer,
      { path: '/api/barang', method: 'POST' },
      { kode_barang: '', nama_barang: '   ', satuan: '' }
    );
    assert.strictEqual(invalidBarangRes.statusCode, 400, 'Harus ditolak dengan status 400');
    assert.strictEqual(invalidBarangRes.body.success, false);
    assert.ok(Array.isArray(invalidBarangRes.body.errors), 'Harus memiliki array errors');
    recordPass('POST /api/barang menolak string kosong / hanya spasi dengan HTTP 400');

    // Test 5: Validasi ID URL non-numerik
    const invalidIdRes = await makeRequest(testServer, { path: '/api/barang/abc', method: 'GET' });
    assert.strictEqual(invalidIdRes.statusCode, 400, 'Harus ditolak dengan status 400');
    recordPass('GET /api/barang/:id menolak ID non-numerik dengan HTTP 400');

    // Test 6: Validasi pembuatan hasil produksi dengan kuantitas <= 0
    const invalidProduksiRes = await makeRequest(
      testServer,
      { path: '/api/produksi', method: 'POST' },
      {
        tanggal_produksi: '2026-10-24',
        items: [{ barang_id: 1, jumlah: -5 }],
      }
    );
    assert.strictEqual(invalidProduksiRes.statusCode, 400, 'Harus ditolak status 400');
    recordPass('POST /api/produksi menolak jumlah produksi <= 0 dengan HTTP 400');

    // Test 7: Validasi status produksi tidak valid
    const invalidStatusRes = await makeRequest(
      testServer,
      { path: '/api/produksi/1/status', method: 'PATCH' },
      { status: 'invalid_status_xyz' }
    );
    assert.strictEqual(invalidStatusRes.statusCode, 400, 'Harus ditolak status 400');
    recordPass('PATCH /api/produksi/:id/status menolak status di luar enum (draft, completed, cancelled)');

  } catch (error) {
    recordFail('Pengujian Validasi Input gagal', error);
  }

  // ----------------------------------------------------------------------------
  // BAGIAN 3: PENGUJIAN DATABASE & LOGIKA BISNIS
  // ----------------------------------------------------------------------------
  console.log('\n--- [BAGIAN 3] UJI DATABASE & ATURAN BISNIS LENGKAP ---');
  let dbAvailable = false;
  let connection;

  try {
    connection = await pool.getConnection();
    dbAvailable = true;
    recordPass('Koneksi ke MySQL database berhasil dibuka');
  } catch (error) {
    console.log(`  ℹ️ [INFO] Database MySQL belum dapat dihubungi (${error.message}).`);
    console.log('     Pengujian end-to-end database dilewati.');
    console.log('     Petunjuk: Pastikan Laragon/MySQL aktif dan konfigurasi .env sudah sesuai.');
  }

  if (dbAvailable && connection) {
    try {
      // 1. Tes Skema tabel ada
      const [tables] = await connection.query(`SHOW TABLES`);
      const tableNames = tables.map((t) => Object.values(t)[0]);
      const requiredTables = ['barang', 'hasil_produksi', 'detail_hasil_produksi', 'penerimaan', 'detail_penerimaan', 'mutasi_stok'];
      const missingTables = requiredTables.filter((t) => !tableNames.includes(t));

      if (missingTables.length > 0) {
        console.log(`  ⚠️ Tabel belum lengkap di database: ${missingTables.join(', ')}`);
        console.log(`     Silakan jalankan file 'sql/schema.sql' terlebih dahulu.`);
      } else {
        recordPass(`Seluruh tabel skema ditemukan: ${requiredTables.join(', ')}`);

        // Skenario Bisnis End-to-End:
        // Langkah A: Buat Barang Uji
        const uniqueSuffix = Date.now().toString().slice(-4);
        const testKode = `TEST-${uniqueSuffix}`;
        const newBarang = await BarangService.createBarang({
          kode_barang: testKode,
          nama_barang: `Barang Uji Otomatis ${uniqueSuffix}`,
          satuan: 'pcs',
        });
        assert.strictEqual(newBarang.kode_barang, testKode);
        assert.strictEqual(Number(newBarang.stok), 0, 'Stok awal barang baru harus 0.00');
        recordPass('CRUD Barang: Berhasil membuat master barang dengan stok awal 0.00');

        // Langkah B: Tolak kode barang duplikat
        try {
          await BarangService.createBarang({
            kode_barang: testKode,
            nama_barang: 'Duplikat',
            satuan: 'pcs',
          });
          assert.fail('Seharusnya melempar AppError untuk kode duplikat');
        } catch (e) {
          assert.strictEqual(e.statusCode, 409, 'Harus status code 409');
          recordPass('Validasi Unik: Kode barang duplikat berhasil ditolak dengan HTTP 409');
        }

        // Langkah C: Buat Hasil Produksi (Status draft)
        const produksiBaru = await ProduksiService.createProduksi({
          tanggal_produksi: '2026-10-24',
          catatan: 'Produksi batch uji otomatis',
          items: [
            { barang_id: newBarang.id, jumlah: 100 },
          ],
        });
        assert.strictEqual(produksiBaru.status, 'draft');
        assert.strictEqual(produksiBaru.items.length, 1);
        recordPass('Hasil Produksi: Berhasil membuat draft produksi dengan detail barang');

        // Langkah D: Tolak penerimaan jika produksi masih status 'draft'
        try {
          await PenerimaanService.createPenerimaan({
            hasil_produksi_id: produksiBaru.id,
            tanggal_penerimaan: '2026-10-24',
          });
          assert.fail('Seharusnya menolak penerimaan dari produksi draft');
        } catch (e) {
          assert.strictEqual(e.statusCode, 400);
          recordPass('Aturan Bisnis: Menolak penerimaan dari hasil produksi yang belum completed');
        }

        // Langkah E: Selesaikan produksi ('draft' -> 'completed')
        const produksiCompleted = await ProduksiService.updateStatusProduksi(produksiBaru.id, 'completed');
        assert.strictEqual(produksiCompleted.status, 'completed');
        recordPass('Hasil Produksi: Status produksi berhasil diubah menjadi completed');

        // Langkah F: Buat transaksi penerimaan (status draft)
        const penerimaanBaru = await PenerimaanService.createPenerimaan({
          hasil_produksi_id: produksiBaru.id,
          tanggal_penerimaan: '2026-10-24',
          catatan: 'Penerimaan uji',
          items: [
            { barang_id: newBarang.id, jumlah_diterima: 100 },
          ],
        });
        assert.strictEqual(penerimaanBaru.status, 'draft');

        // Verifikasi bahwa stok barang MASIH 0 (karena penerimaan masih draft)
        const cekStokDraft = await BarangService.getBarangById(newBarang.id);
        assert.strictEqual(Number(cekStokDraft.stok), 0, 'Stok tidak boleh bertambah saat penerimaan masih draft');
        recordPass('Aturan Bisnis: Pembuatan penerimaan draft tidak menambah stok');

        // Langkah G: Konfirmasi Penerimaan ('draft' -> 'confirmed')
        const penerimaanConfirmed = await PenerimaanService.updateStatusPenerimaan(penerimaanBaru.id, 'confirmed');
        assert.strictEqual(penerimaanConfirmed.status, 'confirmed');

        // Verifikasi stok barang SEKARANG bertambah menjadi 100
        const cekStokConfirmed = await BarangService.getBarangById(newBarang.id);
        assert.strictEqual(Number(cekStokConfirmed.stok), 100, 'Stok harus bertambah 100 setelah konfirmasi');
        recordPass('Aturan Bisnis: Konfirmasi penerimaan menambah stok gudang secara atomik');

        // Langkah H: Verifikasi kartu mutasi stok tercatat
        const stokInfo = await StokService.getStokByBarangId(newBarang.id);
        assert.strictEqual(stokInfo.riwayat_mutasi.length >= 1, true);
        assert.strictEqual(stokInfo.riwayat_mutasi[0].tipe_mutasi, 'MASUK');
        assert.strictEqual(Number(stokInfo.riwayat_mutasi[0].jumlah), 100);
        recordPass('Audit Trail: Mutasi stok MASUK berhasil tercatat dengan referensi PENERIMAAN');

        // Langkah I: Uji Idempotensi (Konfirmasi ulang harus ditolak)
        try {
          await PenerimaanService.updateStatusPenerimaan(penerimaanBaru.id, 'confirmed');
          assert.fail('Seharusnya menolak konfirmasi ganda');
        } catch (e) {
          assert.strictEqual(e.statusCode, 400);
          recordPass('Aturan Bisnis: Satu penerimaan hanya dapat menambah stok satu kali (idempotent)');
        }

        // Langkah J: Uji Pembatalan Penerimaan ('confirmed' -> 'cancelled')
        const penerimaanCancelled = await PenerimaanService.updateStatusPenerimaan(penerimaanBaru.id, 'cancelled');
        assert.strictEqual(penerimaanCancelled.status, 'cancelled');

        // Verifikasi bahwa stok barang KEMBALI menjadi 0
        const cekStokCancelled = await BarangService.getBarangById(newBarang.id);
        assert.strictEqual(Number(cekStokCancelled.stok), 0, 'Stok harus kembali 0 setelah pembatalan penerimaan');
        recordPass('Aturan Bisnis: Pembatalan penerimaan mengurangi kembali stok gudang secara atomik');

        // Verifikasi mutasi pembalik tercatat
        const stokInfoAfterCancel = await StokService.getStokByBarangId(newBarang.id);
        assert.strictEqual(stokInfoAfterCancel.riwayat_mutasi[0].tipe_mutasi, 'KELUAR');
        recordPass('Audit Trail: Mutasi stok KELUAR pembalik berhasil dicatat di mutasi_stok');
      }
    } catch (dbErr) {
      recordFail('Skenario Bisnis Database gagal', dbErr);
    } finally {
      connection.release();
    }
  }

  // Tutup server pengujian
  if (testServer) {
    await new Promise((resolve) => testServer.close(resolve));
  }
  await pool.end();

  console.log('\n================================================================');
  console.log(`📊 RINGKASAN PENGUJIAN:`);
  console.log(`   - Total Berhasil (PASS) : ${testsPassed}`);
  console.log(`   - Total Gagal (FAIL)    : ${testsFailed}`);
  console.log('================================================================\n');

  if (testsFailed > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

runTestSuite().catch((err) => {
  console.error('[FATAL] Test runner crash:', err);
  process.exit(1);
});
