# Dokumentasi Lengkap REST API: Hasil Produksi & Gudang

Dokumentasi ini mencakup seluruh endpoint yang tersedia di backend, lengkap dengan parameter, contoh payload request JSON, contoh respons sukses, serta penanganan error.

- **Base URL Lokal:** `http://localhost:3000`
- **Prefix API:** `/api`
- **Format Pertukaran Data:** `application/json`

---

## Format Standar Respons JSON

### Respons Sukses
```json
{
  "success": true,
  "message": "Pesan keberhasilan operasi",
  "data": { ... }
}
```

### Respons Gagal / Error Validasi (HTTP 400)
```json
{
  "success": false,
  "message": "Data yang dikirim belum valid",
  "errors": [
    {
      "field": "nama_barang",
      "message": "Nama barang wajib diisi"
    }
  ]
}
```

---

## 1. Modul Pemeriksaan (Health Check)

### `GET /api/health`
Memeriksa status operasional server dan waktu aktif (uptime).

- **Method:** `GET`
- **Header:** Tidak ada
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Server API Produksi & Gudang berjalan dengan normal",
  "data": {
    "status": "OK",
    "uptime_seconds": 124,
    "timestamp": "2026-10-24T13:58:12.345Z"
  }
}
```

---

## 2. Modul Master Barang

### A. `GET /api/barang`
Mengambil daftar seluruh barang katalog.

- **Method:** `GET`
- **Query Parameter (Opsional):**
  - `search` (string): Mencari barang berdasarkan nama atau kode barang (misal: `?search=pipa`).
  - `is_active` (boolean / number): Filter status aktif (`?is_active=1` atau `?is_active=0`).
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Daftar data barang berhasil diambil",
  "data": [
    {
      "id": 1,
      "kode_barang": "BRG-001",
      "nama_barang": "Pipa PVC AW 1/2 Inch",
      "satuan": "batang",
      "stok": 100,
      "is_active": 1,
      "created_at": "2026-10-24T12:00:00.000Z",
      "updated_at": "2026-10-24T12:30:00.000Z"
    }
  ]
}
```

---

### B. `GET /api/barang/:id`
Mengambil detail satu data barang berdasarkan ID.

- **Method:** `GET`
- **Path Parameter:** `id` (integer)
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Detail barang berhasil diambil",
  "data": {
    "id": 1,
    "kode_barang": "BRG-001",
    "nama_barang": "Pipa PVC AW 1/2 Inch",
    "satuan": "batang",
    "stok": 100,
    "is_active": 1,
    "created_at": "2026-10-24T12:00:00.000Z",
    "updated_at": "2026-10-24T12:30:00.000Z"
  }
}
```
- **Error:**
  - `HTTP 404`: Jika barang tidak ditemukan.

---

### C. `POST /api/barang`
Mendaftarkan master barang baru.

- **Method:** `POST`
- **Request Body (JSON):**
```json
{
  "kode_barang": "BRG-006",
  "nama_barang": "Sambungan T PVC 1/2 Inch",
  "satuan": "pcs"
}
```
- **Response Sukses (HTTP 201 Created):**
```json
{
  "success": true,
  "message": "Data barang berhasil ditambahkan",
  "data": {
    "id": 6,
    "kode_barang": "BRG-006",
    "nama_barang": "Sambungan T PVC 1/2 Inch",
    "satuan": "pcs",
    "stok": 0,
    "is_active": 1,
    "created_at": "2026-10-24T13:00:00.000Z",
    "updated_at": "2026-10-24T13:00:00.000Z"
  }
}
```
- **Error:**
  - `HTTP 400`: Field kosong atau hanya spasi.
  - `HTTP 409`: Kode barang sudah terdaftar (duplikat).

---

### D. `PUT /api/barang/:id`
Memperbarui informasi nama dan satuan barang.

- **Method:** `PUT`
- **Path Parameter:** `id` (integer)
- **Request Body (JSON):**
```json
{
  "nama_barang": "Sambungan T PVC 1/2 Inch Tebal",
  "satuan": "dus"
}
```
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Data barang berhasil diperbarui",
  "data": {
    "id": 6,
    "kode_barang": "BRG-006",
    "nama_barang": "Sambungan T PVC 1/2 Inch Tebal",
    "satuan": "dus",
    "stok": 0,
    "is_active": 1,
    "created_at": "2026-10-24T13:00:00.000Z",
    "updated_at": "2026-10-24T13:05:00.000Z"
  }
}
```

---

### E. `PATCH /api/barang/:id/status`
Menonaktifkan atau mengaktifkan kembali barang (*Soft Deactivation*).

- **Method:** `PATCH`
- **Path Parameter:** `id` (integer)
- **Request Body (JSON):**
```json
{
  "is_active": false
}
```
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Barang berhasil dinonaktifkan",
  "data": {
    "id": 6,
    "kode_barang": "BRG-006",
    "nama_barang": "Sambungan T PVC 1/2 Inch Tebal",
    "satuan": "dus",
    "stok": 0,
    "is_active": 0,
    "created_at": "2026-10-24T13:00:00.000Z",
    "updated_at": "2026-10-24T13:10:00.000Z"
  }
}
```

---

## 3. Modul Hasil Produksi

### A. `GET /api/produksi`
Mengambil seluruh dokumen hasil produksi.

- **Method:** `GET`
- **Query Parameter (Opsional):**
  - `status`: Filter status (`draft`, `completed`, `cancelled`).
  - `search`: Pencarian nomor produksi atau catatan.
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Daftar hasil produksi berhasil diambil",
  "data": [
    {
      "id": 1,
      "nomor_produksi": "PRD-20261024-0001",
      "tanggal_produksi": "2026-10-24",
      "status": "completed",
      "catatan": "Produksi shift 1",
      "total_item": 2,
      "total_kuantitas": 150
    }
  ]
}
```

---

### B. `GET /api/produksi/:id`
Mengambil detail satu dokumen hasil produksi beserta daftar barang yang diproduksi.

- **Method:** `GET`
- **Path Parameter:** `id` (integer)
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Detail hasil produksi berhasil diambil",
  "data": {
    "id": 1,
    "nomor_produksi": "PRD-20261024-0001",
    "tanggal_produksi": "2026-10-24",
    "status": "completed",
    "catatan": "Produksi shift 1",
    "items": [
      {
        "id": 1,
        "barang_id": 1,
        "kode_barang": "BRG-001",
        "nama_barang": "Pipa PVC AW 1/2 Inch",
        "satuan": "batang",
        "jumlah": 100
      },
      {
        "id": 2,
        "barang_id": 2,
        "kode_barang": "BRG-002",
        "nama_barang": "Pipa PVC AW 3/4 Inch",
        "satuan": "batang",
        "jumlah": 50
      }
    ]
  }
}
```

---

### C. `POST /api/produksi`
Membuat transaksi hasil produksi baru.

- **Method:** `POST`
- **Request Body (JSON):**
```json
{
  "nomor_produksi": "PRD-20261024-0002",
  "tanggal_produksi": "2026-10-24",
  "catatan": "Pencetakan pipa batch 2",
  "items": [
    {
      "barang_id": 1,
      "jumlah": 80
    },
    {
      "barang_id": 2,
      "jumlah": 40
    }
  ]
}
```
*Catatan: Parameter `nomor_produksi` bersifat opsional. Jika dikosongkan, nomor otomatis digenerate dengan format `PRD-YYYYMMDD-XXXX`.*
- **Response Sukses (HTTP 201 Created):**
```json
{
  "success": true,
  "message": "Hasil produksi berhasil dibuat",
  "data": {
    "id": 2,
    "nomor_produksi": "PRD-20261024-0002",
    "tanggal_produksi": "2026-10-24",
    "status": "draft",
    "catatan": "Pencetakan pipa batch 2",
    "items": [ ... ]
  }
}
```
- **Error:**
  - `HTTP 400`: Jumlah <= 0, barang nonaktif dipilih, atau format tidak valid.

---

### D. `PATCH /api/produksi/:id/status`
Mengubah status hasil produksi (`draft` -> `completed` / `cancelled`).

- **Method:** `PATCH`
- **Path Parameter:** `id` (integer)
- **Request Body (JSON):**
```json
{
  "status": "completed"
}
```
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Status hasil produksi berhasil diubah menjadi 'completed'",
  "data": {
    "id": 2,
    "nomor_produksi": "PRD-20261024-0002",
    "status": "completed"
  }
}
```
- **Error:**
  - `HTTP 400`: Transisi status tidak sah (misal dari completed kembali ke draft).
  - `HTTP 409`: Mencoba membatalkan produksi yang sudah memiliki penerimaan gudang.

---

## 4. Modul Penerimaan Gudang

### A. `GET /api/penerimaan`
Mengambil daftar seluruh transaksi penerimaan barang di gudang.

- **Method:** `GET`
- **Query Parameter (Opsional):**
  - `status`: `draft`, `confirmed`, `cancelled`.
  - `search`: Pencarian nomor penerimaan atau nomor produksi.
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Daftar transaksi penerimaan berhasil diambil",
  "data": [
    {
      "id": 1,
      "nomor_penerimaan": "RCV-20261024-0001",
      "hasil_produksi_id": 1,
      "nomor_produksi": "PRD-20261024-0001",
      "tanggal_penerimaan": "2026-10-24",
      "status": "draft",
      "total_item": 2,
      "total_kuantitas_diterima": 150
    }
  ]
}
```

---

### B. `GET /api/penerimaan/:id`
Mengambil detail satu penerimaan beserta barang fisik yang diterima.

- **Method:** `GET`
- **Path Parameter:** `id` (integer)
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Detail transaksi penerimaan berhasil diambil",
  "data": {
    "id": 1,
    "nomor_penerimaan": "RCV-20261024-0001",
    "hasil_produksi_id": 1,
    "nomor_produksi": "PRD-20261024-0001",
    "tanggal_penerimaan": "2026-10-24",
    "status": "draft",
    "items": [
      {
        "id": 1,
        "barang_id": 1,
        "kode_barang": "BRG-001",
        "nama_barang": "Pipa PVC AW 1/2 Inch",
        "satuan": "batang",
        "jumlah_diterima": 100
      }
    ]
  }
}
```

---

### C. `POST /api/penerimaan`
Mencatat dokumen penerimaan baru dari hasil produksi yang sudah selesai.

- **Method:** `POST`
- **Request Body (JSON):**
```json
{
  "nomor_penerimaan": "RCV-20261024-0002",
  "hasil_produksi_id": 2,
  "tanggal_penerimaan": "2026-10-24",
  "catatan": "Barang telah tiba di pintu gerbang gudang 2",
  "items": [
    {
      "barang_id": 1,
      "jumlah_diterima": 80
    },
    {
      "barang_id": 2,
      "jumlah_diterima": 40
    }
  ]
}
```
*Catatan:*
- Jika properti `items` tidak dikirim, sistem secara otomatis menerima seluruh barang yang ada pada hasil produksi terkait.
- Jika dikirim, jumlah diterima tidak boleh melebihi sisa yang belum diterima.
- **Response Sukses (HTTP 201 Created):**
```json
{
  "success": true,
  "message": "Transaksi penerimaan berhasil dicatat",
  "data": {
    "id": 2,
    "nomor_penerimaan": "RCV-20261024-0002",
    "hasil_produksi_id": 2,
    "status": "draft",
    "items": [ ... ]
  }
}
```
- **Error:**
  - `HTTP 400`: Hasil produksi belum berstatus `completed` atau kuantitas melebihi yang diproduksi.

---

### D. `PATCH /api/penerimaan/:id/status`
Mengonfirmasi penerimaan atau membatalkannya.

- **Method:** `PATCH`
- **Path Parameter:** `id` (integer)
- **Request Body (JSON) Konfirmasi:**
```json
{
  "status": "confirmed"
}
```
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Penerimaan berhasil dikonfirmasi. Stok barang di gudang telah bertambah.",
  "data": {
    "id": 2,
    "nomor_penerimaan": "RCV-20261024-0002",
    "status": "confirmed"
  }
}
```

- **Request Body (JSON) Pembatalan:**
```json
{
  "status": "cancelled"
}
```
- **Response Sukses Pembatalan (HTTP 200):**
```json
{
  "success": true,
  "message": "Penerimaan berhasil dibatalkan. Stok barang di gudang telah disesuaikan kembali.",
  "data": {
    "id": 2,
    "nomor_penerimaan": "RCV-20261024-0002",
    "status": "cancelled"
  }
}
```

---

## 5. Modul Stok & Mutasi Gudang

### A. `GET /api/stok`
Melihat ringkasan stok fisik terkini dari seluruh barang.

- **Method:** `GET`
- **Query Parameter (Opsional):**
  - `search`: Filter berdasarkan kode atau nama barang.
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Data stok barang berhasil diambil",
  "data": [
    {
      "id": 1,
      "kode_barang": "BRG-001",
      "nama_barang": "Pipa PVC AW 1/2 Inch",
      "satuan": "batang",
      "stok_terkini": 180,
      "is_active": 1,
      "terakhir_diperbarui": "2026-10-24T13:45:00.000Z"
    }
  ]
}
```

---

### B. `GET /api/stok/:barangId`
Melihat rincian saldo stok barang tertentu beserta kartu riwayat mutasi (*audit trail*).

- **Method:** `GET`
- **Path Parameter:** `barangId` (integer)
- **Response Sukses (HTTP 200):**
```json
{
  "success": true,
  "message": "Detail stok dan kartu mutasi berhasil diambil",
  "data": {
    "barang": {
      "id": 1,
      "kode_barang": "BRG-001",
      "nama_barang": "Pipa PVC AW 1/2 Inch",
      "satuan": "batang",
      "stok_terkini": 180,
      "is_active": 1
    },
    "riwayat_mutasi": [
      {
        "id": 2,
        "tipe_mutasi": "MASUK",
        "jumlah": 80,
        "stok_sebelum": 100,
        "stok_sesudah": 180,
        "referensi_tipe": "PENERIMAAN",
        "referensi_id": 2,
        "keterangan": "Penerimaan barang dari produksi No: RCV-20261024-0002",
        "tanggal_mutasi": "2026-10-24T13:45:00.000Z"
      },
      {
        "id": 1,
        "tipe_mutasi": "MASUK",
        "jumlah": 100,
        "stok_sebelum": 0,
        "stok_sesudah": 100,
        "referensi_tipe": "PENERIMAAN",
        "referensi_id": 1,
        "keterangan": "Penerimaan barang dari produksi No: RCV-20261024-0001",
        "tanggal_mutasi": "2026-10-24T12:30:00.000Z"
      }
    ]
  }
}
```
