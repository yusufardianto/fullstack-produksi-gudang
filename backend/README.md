# Backend REST API — Hasil Produksi dan Gudang

Aplikasi backend ini dibangun menggunakan **Node.js**, **Express**, dan **MySQL** untuk mencatat alur siklus hidup proses manufaktur pabrik, serah terima barang ke gudang, dan pengelolaan saldo stok fisik secara akurat, aman, dan dapat diaudit (*audit trail*).

---

## 1. Apa Fungsi Aplikasi Ini?

Aplikasi ini bertindak sebagai **sumber kebenaran tunggal (*Single Source of Truth*)** untuk operasional pabrik dan gudang:
1. **Master Barang:** Mengelola katalog produk, kode unik, satuan, dan status aktif/nonaktif.
2. **Hasil Produksi:** Mencatat surat pengerjaan produksi (header & detail banyak item barang) dengan status `draft`, `completed`, atau `cancelled`.
3. **Penerimaan Barang:** Mencatat serah terima fisik barang hasil produksi masuk ke gudang dengan status `draft`, `confirmed`, atau `cancelled`.
4. **Stok & Kartu Mutasi:** Mengelola penambahan stok secara atomik hanya saat penerimaan dikonfirmasi, serta mencatat riwayat kartu stok (*audit trail*) setiap kali terjadi transaksi masuk atau pembatalan.

---

## 2. Teknologi yang Digunakan

- **Node.js (v18+)** — Lingkungan eksekusi JavaScript sisi server (CommonJS `require`/`module.exports`).
- **Express.js (v5)** — Framework minimalis dan fleksibel untuk membangun REST API.
- **MySQL (v5.7 / v8.x / MariaDB)** — Database relasional dengan engine InnoDB untuk integritas data ACID.
- **`mysql2`** — Driver database MySQL berkinerja tinggi dengan dukungan koneksi pool dan Promise (`async/await`).
- **`dotenv`** — Memuat konfigurasi sensitif (koneksi database & port) dari file `.env`.
- **`express-validator`** — Validasi dan sanitasi input body, parameter, dan query request.
- **`cors`** — Mengizinkan komunikasi aman lintas domain (Cross-Origin Resource Sharing) dengan frontend Flutter.
- **`nodemon`** — Memulai ulang server secara otomatis saat ada perubahan kode selama proses pengembangan.

---

## 3. Gambaran Arsitektur Komunikasi Sistem

```
+---------------------------------------+
|          Frontend (Flutter)           |
|  (Mobile Android/iOS, Web, Desktop)   |
+-------------------+-------------------+
                    |
                    | HTTP JSON (REST API via CORS)
                    v
+-------------------+-------------------+
|            Express.js                 |
|  - Routing (/api/...)                 |
|  - Validasi (express-validator)       |
|  - Controllers & Services             |
|  - Error & Concurrency Locking        |
+-------------------+-------------------+
                    |
                    | Parameterized SQL Queries & Transactions
                    v
+-------------------+-------------------+
|         MySQL Database                |
|  - Engine: InnoDB                     |
|  - Foreign Key Constraints            |
|  - Kartu Mutasi & Saldo Stok          |
+---------------------------------------+
```

1. **Aplikasi Flutter** mengirimkan HTTP Request (misal: `POST /api/produksi`) dalam format JSON.
2. **Express.js Backend** memvalidasi kelengkapan data (kuantitas > 0, barang aktif).
3. **Service Layer** membuka transaksi database MySQL, melakukan penguncian baris (*row-level locking*), memodifikasi stok, dan mencatat riwayat mutasi.
4. **Database MySQL** mengembalikan data hasil, lalu backend membalas Flutter dengan format JSON standar.

---

## 4. Prasyarat Instalasi

Sebelum memulai, pastikan perangkat Anda telah terpasang:
1. **Node.js** (versi 18.0.0 atau lebih baru) — Periksa dengan perintah: `node -v`
2. **NPM** (versi 9.0.0 atau lebih baru) — Periksa dengan perintah: `npm -v`
3. **Laragon** (atau XAMPP / MySQL Server lokal) yang sudah terpasang di komputer Anda.

---

## 5. Cara Menjalankan MySQL Melalui Laragon

1. Buka aplikasi **Laragon** di komputer Anda.
2. Klik tombol **"Start All"** pada jendela utama Laragon.
3. Pastikan indikator **MySQL** berwarna hijau dan port `3306` aktif.
4. Anda dapat membuka antarmuka database bawaan Laragon dengan mengklik tombol **"Database"** (membuka HeidiSQL).

---

## 6. Cara Membuat Database dan Menjalankan File SQL

Anda dapat membuat database menggunakan **HeidiSQL** (bawaan Laragon), **phpMyAdmin**, atau melalui **Terminal**:

### Menggunakan Terminal / Command Prompt:
1. Masuk ke direktori proyek backend:
   ```powershell
   cd d:\project-sumber-djaja-perkasa\fullstack-produksi-gudang\backend
   ```
2. Jalankan skema tabel menggunakan client MySQL:
   ```powershell
   mysql -u root -p < sql/schema.sql
   ```
   *(Tekan Enter jika Laragon Anda tidak menggunakan password).*
3. Masukkan data awal (seed data) untuk contoh:
   ```powershell
   mysql -u root -p < sql/seed.sql
   ```

### Atau Menggunakan HeidiSQL / phpMyAdmin:
1. Buka HeidiSQL dari Laragon.
2. Buat database baru bernama: `db_produksi_gudang`.
3. Buka menu **File -> Load SQL File...**, pilih file `sql/schema.sql`, lalu klik tombol **Execute (F9)**.
4. Ulangi untuk file `sql/seed.sql`.

---

## 7. Cara Mengatur File `.env`

Di dalam folder `backend/`, buat salinan dari `.env.example` menjadi `.env`:

```powershell
cp .env.example .env
```
*(atau buat file baru bernama `.env` di dalam folder `backend`)*

Isi file `.env` disesuaikan dengan konfigurasi MySQL komputer Anda:

```env
# Port aplikasi server Node.js
PORT=3000

# Lingkungan pengembangan
NODE_ENV=development

# Konfigurasi Koneksi Database MySQL
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
# Kosongkan jika MySQL Laragon Anda tidak menggunakan password (default Laragon)
DB_PASSWORD=
DB_NAME=db_produksi_gudang
```

---

## 8. Cara Menginstal Dependency

Buka terminal di dalam direktori `backend/`, lalu jalankan:

```powershell
cd d:\project-sumber-djaja-perkasa\fullstack-produksi-gudang\backend
npm install
```

---

## 9. Cara Menjalankan Backend

Tersedia dua opsi perintah:

### A. Mode Pengembangan (Development dengan Auto-reload Nodemon):
```powershell
npm run dev
```
Server akan otomatis menyala ulang setiap kali Anda menyimpan perubahan kode.

### B. Mode Produksi (Standar Node.js):
```powershell
npm start
```

Jika server berhasil menyala, Anda akan melihat pesan berikut di terminal:
```
================================================================
🚀 Memulai Server REST API Hasil Produksi & Gudang...
================================================================
[DATABASE] Berhasil terhubung ke database 'db_produksi_gudang' di localhost:3306
[SERVER] Berjalan pada: http://localhost:3000
[HEALTH] Health check: http://localhost:3000/api/health
[INFO] Tekan CTRL + C untuk menghentikan server.
================================================================
```

---

## 10. Cara Memeriksa Apakah Server Hidup (Health Check)

Buka browser atau gunakan curl:

```powershell
curl http://localhost:3000/api/health
```

Respons yang diharapkan:
```json
{
  "success": true,
  "message": "Server API Produksi & Gudang berjalan dengan normal",
  "data": {
    "status": "OK",
    "uptime_seconds": 15,
    "timestamp": "2026-10-24T13:45:00.000Z"
  }
}
```

---

## 11. Cara Menjalankan Pengujian Otomatis

Backend ini telah dilengkapi pengujian otomatis bawaan tanpa dependensi luar yang rumit. Jalankan perintah:

```powershell
npm test
```

Pengujian akan menguji:
- Integritas HTTP routing dan health check.
- Validasi input express-validator (penolakan kuantitas <= 0, ID salah, field kosong/spasi).
- Koneksi database dan alur transaksi bisnis (jika database lokal MySQL aktif).

---

## 12. Daftar Endpoint Utama

| Modul | Method | URL Endpoint | Keterangan |
| :--- | :---: | :--- | :--- |
| **Health** | `GET` | `/api/health` | Pemeriksaan kesehatan server |
| **Barang** | `GET` | `/api/barang` | Daftar seluruh katalog barang |
| | `GET` | `/api/barang/:id` | Detail barang berdasarkan ID |
| | `POST` | `/api/barang` | Menambah master barang baru |
| | `PUT` | `/api/barang/:id` | Mengubah nama & satuan barang |
| | `PATCH` | `/api/barang/:id/status` | Menonaktifkan/mengaktifkan barang |
| **Produksi** | `GET` | `/api/produksi` | Daftar seluruh hasil produksi |
| | `GET` | `/api/produksi/:id` | Detail hasil produksi beserta rincian barang |
| | `POST` | `/api/produksi` | Membuat hasil produksi baru (status `draft`) |
| | `PATCH` | `/api/produksi/:id/status` | Mengubah status (`completed` / `cancelled`) |
| **Penerimaan**| `GET` | `/api/penerimaan` | Daftar seluruh tanda terima gudang |
| | `GET` | `/api/penerimaan/:id` | Detail penerimaan beserta rincian item |
| | `POST` | `/api/penerimaan` | Membuat penerimaan baru dari produksi `completed` |
| | `PATCH` | `/api/penerimaan/:id/status` | Konfirmasi (`confirmed`) atau Batalkan (`cancelled`) |
| **Stok** | `GET` | `/api/stok` | Daftar saldo stok seluruh barang |
| | `GET` | `/api/stok/:barangId` | Kartu riwayat mutasi stok per barang |

Dokumentasi payload dan parameter selengkapnya dapat dibaca di [docs/API.md](docs/API.md).

---

## 13. Contoh Alur Lengkap: Dari Produksi Hingga Stok Bertambah

Berikut adalah alur pengujian langsung menggunakan `curl` atau **Postman**:

### Langkah 1: Buat Master Barang Baru
```powershell
curl -X POST http://localhost:3000/api/barang `
  -H "Content-Type: application/json" `
  -d '{\"kode_barang\": \"BRG-100\", \"nama_barang\": \"Pipa PVC 2 Inch\", \"satuan\": \"batang\"}'
```
*Hasil: Barang terdaftar dengan stok awal `0.00`.*

### Langkah 2: Buat Dokumen Hasil Produksi
```powershell
curl -X POST http://localhost:3000/api/produksi `
  -H "Content-Type: application/json" `
  -d '{\"tanggal_produksi\": \"2026-10-24\", \"items\": [{\"barang_id\": 1, \"jumlah\": 50}]}'
```
*Hasil: Dokumen produksi terbit dengan status `draft`. Stok gudang masih `0.00`.*

### Langkah 3: Selesaikan Produksi
```powershell
curl -X PATCH http://localhost:3000/api/produksi/1/status `
  -H "Content-Type: application/json" `
  -d '{\"status\": \"completed\"}'
```
*Hasil: Dokumen produksi dinyatakan `completed`.*

### Langkah 4: Petugas Gudang Mencatat Penerimaan
```powershell
curl -X POST http://localhost:3000/api/penerimaan `
  -H "Content-Type: application/json" `
  -d '{\"hasil_produksi_id\": 1, \"tanggal_penerimaan\": \"2026-10-24\"}'
```
*Hasil: Dokumen penerimaan terbuat dengan status `draft`. Stok gudang masih `0.00`.*

### Langkah 5: Konfirmasi Penerimaan Gudang
```powershell
curl -X PATCH http://localhost:3000/api/penerimaan/1/status `
  -H "Content-Type: application/json" `
  -d '{\"status\": \"confirmed\"}'
```
*Hasil: Penerimaan `confirmed`. Transaksi database atomik menambah stok fisik menjadi `50` dan mencatat kartu mutasi masuk.*

### Langkah 6: Cek Saldo & Kartu Mutasi Stok
```powershell
curl http://localhost:3000/api/stok/1
```
*Hasil: Menampilkan saldo stok `50` beserta riwayat mutasi bertipe `MASUK` dengan referensi `PENERIMAAN`.*

---

## 14. Cara Mengatasi Kendala Umum (*Troubleshooting*)

1. **`Access denied for user 'root'@'localhost'`**
   - **Penyebab:** Password MySQL di file `.env` tidak cocok dengan password root MySQL Anda.
   - **Solusi:** Buka file `backend/.env`. Jika Laragon default tanpa password, kosongkan `DB_PASSWORD=`. Jika Anda mengatur password, masukkan password Anda di variabel tersebut.

2. **`Unknown database 'db_produksi_gudang'`**
   - **Penyebab:** Database belum dibuat di MySQL.
   - **Solusi:** Jalankan skrip `sql/schema.sql` terlebih dahulu melalui HeidiSQL atau terminal MySQL.

3. **`connect ECONNREFUSED 127.0.0.1:3306`**
   - **Penyebab:** Layanan MySQL belum dinyalakan.
   - **Solusi:** Buka Laragon dan klik tombol **"Start All"**.

4. **Port 3000 sudah terpakai (`EADDRINUSE`)**
   - **Penyebab:** Ada aplikasi lain yang berjalan di port 3000.
   - **Solusi:** Buka `backend/.env` dan ubah variabel `PORT=3001` atau port lain yang bebas.

---

## 15. Batasan Implementasi yang Ada

1. **Penerimaan Parsial:**  
   Backend mendukung penerimaan bertahap selama kuantitas kumulatif tidak melebihi hasil produksi. Namun, satu nomor penerimaan hanya merujuk satu nomor hasil produksi.
2. **Otentikasi & Otorisasi:**  
   Sesuai batasan teknis tes, endpoint belum dilengkapi JWT / Session otentikasi peran (role RBAC) agar mudah diuji secara langsung oleh penguji tanpa token login.
3. **Pengurangan Stok Distribusi:**  
   Fokus studi kasus saat ini adalah **Hasil Produksi dan Penerimaan Gudang**. Modul pengeluaran stok untuk pengiriman ke konsumen (*sales delivery*) dapat ditambahkan pada iterasi berikutnya menggunakan mekanisme mutasi `KELUAR` yang serupa.
