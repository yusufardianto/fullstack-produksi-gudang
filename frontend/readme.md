# Frontend Flutter — Sistem Manajemen Hasil Produksi & Gudang

Aplikasi frontend berbasis **Flutter** dan **GetX** untuk mengelola data master barang, pencatatan hasil produksi pabrik, penerimaan barang ke gudang fisik, serta pemantauan saldo stok dan kartu mutasi (*audit trail*). Terhubung langsung dengan REST API backend Node.js (Express) & database MySQL.

---

## 1. Tujuan Aplikasi dan Fitur yang Tersedia

Aplikasi ini bertujuan untuk memberikan antarmuka pengguna yang bersih, responsif, dan mudah digunakan oleh operator pabrik dan staf gudang:

1. **Modul Data Master Barang:**
   - Melihat katalog produk, kode unik, satuan, stok terkini, dan status aktif/nonaktif.
   - Pencarian barang berdasarkan nama atau kode.
   - Menambahkan barang baru via formulir tervalidasi.
   - Mengubah nama dan satuan barang.
   - Mengubah status aktif/nonaktif barang (*soft toggle*).
   - Melihat detail barang dan pintasan langsung ke kartu mutasi stoknya.

2. **Modul Hasil Produksi:**
   - Melihat daftar dokumen hasil produksi dengan filter status (`Semua`, `Draft`, `Completed`, `Cancelled`).
   - Pencarian berdasarkan nomor produksi atau catatan.
   - Formulir pembuatan hasil produksi multi-item dinamis (memilih barang aktif dan menentukan kuantitas > 0).
   - Tanggal produksi otomatis terisi hari ini dan dapat dipilih via DatePicker.
   - Mengubah status produksi: dari `draft` menjadi `completed` atau `cancelled`.
   - Tombol pintasan langsung dari produksi berstatus `completed` untuk menerbitkan tanda terima gudang.

3. **Modul Penerimaan Barang Gudang:**
   - Melihat seluruh surat tanda terima barang yang masuk ke gudang beserta filter status.
   - Formulir pencatatan penerimaan barang: hanya mengambil referensi hasil produksi yang telah berstatus `completed`.
   - Menyesuaikan kuantitas fisik aktual yang diterima per item barang.
   - Konfirmasi penerimaan (`draft` ➔ `confirmed`): menambah saldo stok fisik secara atomik di database dan otomatis mencatat mutasi `MASUK`.
   - Pembatalan penerimaan (`confirmed` ➔ `cancelled`): menarik kembali saldo stok yang sempat ditambahkan dan mencatat mutasi pembalik `KELUAR`.

4. **Modul Saldo Stok Gudang & Kartu Mutasi:**
   - Menampilkan ringkasan saldo fisik terkini seluruh barang secara real-time dari API backend (bukan angka statis).
   - Pencarian stok barang.
   - Halaman detail kartu stok (*audit trail*) per barang yang memperlihatkan riwayat mutasi masuk/keluar, kuantitas, saldo sebelum & sesudah, referensi transaksi, dan waktu mutasi.

5. **Pemeriksaan Koneksi Backend & Pengaturan URL Fleksibel:**
   - Indikator status live server backend (`/api/health`) pada halaman utama.
   - Dialog pengaturan Base URL instan tanpa perlu compile ulang.

---

## 2. Prasyarat Instalasi

Sebelum menjalankan aplikasi Flutter ini, pastikan perangkat Anda memiliki:

1. **Flutter SDK** (Channel Stable).
2. **Dart SDK** (terbawa otomatis bersama Flutter).
3. Salah satu perangkat target:
   - **Google Chrome / Microsoft Edge** (untuk menjalankan via Web).
   - **Android Emulator** (Android Studio / AVD) atau **Perangkat Fisik Android**.
   - **Windows Desktop** (jika Visual Studio C++ build tools terpasang).
4. **Backend Express.js & MySQL** dalam kondisi aktif pada port `3000`.

---

## 3. Versi Flutter dan Dart yang Digunakan

Proyek ini dibuat dan diverifikasi menggunakan:
- **Flutter Version:** `3.29.3` (Channel stable)
- **Dart SDK Version:** `3.7.2`
- **Android Target SDK:** `34.0.0`

---

## 4. Cara Menjalankan `flutter pub get`

Buka terminal di direktori proyek `frontend`, lalu jalankan:

```powershell
cd d:\project-sumber-djaja-perkasa\fullstack-produksi-gudang\frontend
flutter pub get
```

Perintah ini akan mengunduh dan menyinkronkan seluruh dependensi (`get`, `http`, `cupertino_icons`, dll.) ke komputer Anda.

---

## 5. Cara Mengatur Base URL Backend

Base URL backend dikelola pada file:  
`frontend/lib/services/api_service.dart`

```dart
class ApiService {
  static String baseUrl = _resolveDefaultBaseUrl();
  // ...
}
```

Secara default, kode otomatis mendeteksi:
- Jika dijalankan di **Web**: menggunakan `http://localhost:3000/api`.
- Jika dijalankan di **Android Emulator**: otomatis menggunakan `http://10.0.2.2:3000/api`.
- Jika dijalankan di **Desktop Windows**: menggunakan `http://localhost:3000/api`.

### Mengubah Base URL saat Aplikasi Berjalan (Runtime)
Pada **Halaman Utama (HomeScreen)**, klik tombol ikon kabel jaringan di AppBar kanan atas (**Atur Base URL**) atau tombol **"Ubah"** pada bilah status koneksi server. Anda dapat memasukkan alamat IP lokal komputer Anda secara langsung.

---

## 6. Cara Menjalankan Aplikasi (`flutter run`)

Pastikan backend Express sudah menyala di terminal terpisah (`npm run dev` pada folder `backend`).

Pilih target perangkat dan jalankan perintah:

### Menjalankan di Browser (Chrome):
```powershell
flutter run -d chrome
```

### Menjalankan di Android Emulator:
```powershell
flutter run -d android
```

### Menjalankan di Perangkat Fisik Android (via USB Debugging):
```powershell
flutter devices
flutter run -d <DEVICE_ID>
```

### Menjalankan di Windows Desktop:
```powershell
flutter run -d windows
```

---

## 7. Perbedaan Base URL Antar Platform

Penting untuk dipahami mengapa URL server berbeda-beda tergantung lingkungan eksekusi:

| Platform Target | Nilai Base URL | Alasan Teknis |
| :--- | :--- | :--- |
| **Web Browser (Chrome/Edge)** | `http://localhost:3000/api` | Berjalan di mesin host yang sama dengan server Express, sehingga port 3000 dapat diakses via `localhost`. |
| **Android Emulator** | `http://10.0.2.2:3000/api` | Android Emulator berjalan di dalam Virtual Machine terisolasi. `10.0.2.2` adalah alias khusus alias loopback virtual menuju `127.0.0.1` (localhost) komputer induk. |
| **HP Android Fisik (Kabel / WiFi)** | `http://192.168.x.x:3000/api` | Perangkat HP fisik berada di jaringan LAN WiFi. Masukkan alamat IP komputer lokal Anda (cek via `ipconfig` di Windows). |

---

## 8. Struktur Folder dan Tanggung Jawab

```text
frontend/
├── lib/
│   ├── main.dart                      # Entry point, GetMaterialApp & konfigurasi tema
│   ├── models/                        # Serialisasi & deserialisasi JSON ke objek Dart
│   │   ├── barang_model.dart          # Model katalog barang & stok
│   │   ├── produksi_model.dart        # Model transaksi produksi (header & items)
│   │   ├── penerimaan_model.dart      # Model transaksi tanda terima gudang
│   │   └── stok_model.dart            # Model ringkasan stok & kartu audit mutasi
│   ├── services/
│   │   └── api_service.dart           # Komunikasi HTTP, header, timeout & handling error
│   ├── controllers/                   # State management GetX & logika reaktif
│   │   ├── barang_controller.dart     # Pengendali state Master Barang
│   │   ├── produksi_controller.dart   # Pengendali state Hasil Produksi
│   │   ├── penerimaan_controller.dart # Pengendali state Penerimaan Gudang
│   │   └── stok_controller.dart       # Pengendali state Stok & Kartu Mutasi
│   ├── screens/                       # Tampilan antarmuka pengguna (UI)
│   │   ├── home_screen.dart           # Portal dashboard 4 modul & status server
│   │   ├── barang/                    # Halaman list, form tambah/edit, & detail barang
│   │   ├── produksi/                  # Halaman list, form produksi, & detail/status
│   │   ├── penerimaan/                # Halaman list, form tanda terima, & konfirmasi stok
│   │   └── stok/                      # Halaman saldo stok gudang & detail kartu mutasi
│   └── widgets/                       # Komponen UI seragam yang dapat dipakai ulang
│       ├── loading_widget.dart        # Indikator loading data
│       ├── error_widget.dart          # Pesan error bersahabat dengan tombol Coba Lagi
│       ├── empty_widget.dart          # Tampilan saat data kosong/belum tersedia
│       └── status_badge.dart          # Chip visual status (draft, completed, confirmed, dll)
├── test/
│   ├── widget_test.dart               # Unit test model & widget smoke test
│   └── api_service_integration_test.dart # Integration test terhadap live backend
├── README.md
└── pubspec.yaml
```

### Tanggung Jawab Setiap Layer:
- **Models:** Mengamankan tipe data (`Type Safety`). Mengonversi string/number angka dari MySQL secara aman dengan `double.tryParse` dan `int.tryParse` untuk mencegah crash runtime `type 'String' is not a subtype of type 'double'`.
- **Services (`ApiService`):** Mengelola koneksi jaringan HTTP murni, pengiriman header JSON, penanganan timeout, dan membongkar pesan error backend Express secara bersahabat.
- **Controllers (`GetxController`):** Menyimpan state reaktif (`RxList`, `RxBool`, `RxString`). Tidak ada panggilan API yang dilakukan langsung di dalam widget `build()`.
- **Screens:** Menampilkan halaman visual dan menerima aksi pengguna.
- **Widgets:** Komponen seragam untuk status loading, data kosong, dan penanganan error.

---

## 9. Penjelasan Alur Data (*Data Flow*)

Alur pergerakan data dari aksi pengguna hingga antarmuka terperbarui:

```text
[ Pengguna ] 
     │ (Tekan Tombol / Buka Layar)
     ▼
[ Screen / UI ]
     │ memanggil method controller
     ▼
[ Controller (GetX) ]
     │ mengaktifkan `isLoading.value = true`
     ▼
[ ApiService ]
     │ mengirim HTTP Request (GET/POST/PUT/PATCH)
     ▼
[ Backend Express.js & MySQL ]
     │ memproses data, database ACID, membalas JSON
     ▼
[ ApiService ]
     │ validasi status HTTP & parsing data via Model.fromJson
     ▼
[ Controller (GetX) ]
     │ memperbarui data reaktif `items.assignAll(...)`
     │ menonaktifkan `isLoading.value = false`
     ▼
[ Obx() pada Screen ]
     │ mendeteksi perubahan state secara otomatis dan merender ulang UI secara instan!
```

---

## 10. Penjelasan Singkat Cara Kerja GetX

Aplikasi ini menggunakan fitur inti GetX yang bersih dan sederhana:

1. **`GetxController`:**  
   Kelas pengelola logika dan state. Berfungsi memisahkan tampilan (UI) dari logika bisnis.
2. **Reaktivitas (`.obs`):**  
   Variabel yang diberi akhiran `.obs` (misal: `var isLoading = false.obs;`, `var items = <T>[].obs;`) otomatis menjadi *Observable*. Setiap kali nilainya berubah, ia memancarkan sinyal ke UI.
3. **`Obx(() => ...)`:**  
   Widget pembungkus reaktif. Hanya merender ulang widget spesifik di dalamnya saat variabel `.obs` yang dibaca mengalami perubahan nilai. Sangat efisien dan hemat memori.
4. **Navigasi Langsung `Get.to()`:**  
   Membuka halaman baru tanpa routing named routes yang rumit:
   ```dart
   Get.to(() => const BarangListScreen());
   ```
5. **Navigasi Kembali `Get.back()`:**  
   Menutup dialog atau kembali ke halaman sebelumnya:
   ```dart
   Get.back();
   ```
6. **Notifikasi Instan `Get.snackbar()`:**  
   Menampilkan umpan balik berhasil atau gagal kepada pengguna di bagian bawah layar secara otomatis.

---

## 11. Daftar Endpoint Backend yang Digunakan

Seluruh modul terhubung ke endpoint resmi Express.js:

| Modul | Method | URL Endpoint | Fungsi pada Frontend |
| :--- | :---: | :--- | :--- |
| **Health** | `GET` | `/api/health` | Memeriksa apakah server backend aktif dan online |
| **Barang** | `GET` | `/api/barang` | Mengambil katalog barang (mendukung pencarian `?search=`) |
| | `GET` | `/api/barang/:id` | Mengambil detail lengkap satu barang |
| | `POST` | `/api/barang` | Mendaftarkan master barang baru |
| | `PUT` | `/api/barang/:id` | Mengubah nama barang dan satuan |
| | `PATCH` | `/api/barang/:id/status` | Mengubah status aktif/nonaktif barang |
| **Produksi** | `GET` | `/api/produksi` | Mengambil riwayat produksi (filter status & pencarian) |
| | `GET` | `/api/produksi/:id` | Mengambil rincian surat produksi beserta item barang |
| | `POST` | `/api/produksi` | Membuat surat produksi baru (status awal `draft`) |
| | `PATCH` | `/api/produksi/:id/status` | Mengubah status produksi (`completed` atau `cancelled`) |
| **Penerimaan** | `GET` | `/api/penerimaan` | Mengambil daftar tanda terima barang di gudang |
| | `GET` | `/api/penerimaan/:id` | Mengambil detail penerimaan fisik beserta rincian item |
| | `POST` | `/api/penerimaan` | Mencatat penerimaan baru dari hasil produksi `completed` |
| | `PATCH` | `/api/penerimaan/:id/status` | Konfirmasi (`confirmed` ➔ stok bertambah) atau Batal (`cancelled`) |
| **Stok** | `GET` | `/api/stok` | Mengambil saldo stok fisik terkini seluruh barang |
| | `GET` | `/api/stok/:barangId` | Mengambil kartu riwayat mutasi stok (*audit trail*) per barang |

---

## 12. Cara Mengatasi Kendala Umum (*Troubleshooting*)

### A. Error: "Gagal terhubung ke server backend..."
- **Penyebab:** Backend Node.js belum dinyalakan atau alamat IP salah.
- **Solusi:**
  1. Pastikan server backend sudah menyala (`npm run dev` pada folder `backend`).
  2. Pastikan database MySQL Laragon sudah aktif (tombol "Start All" warna hijau).
  3. Jika menggunakan Android Emulator, pastikan Base URL mengarah ke `http://10.0.2.2:3000/api`.
  4. Buka menu **Atur Base URL** pada halaman utama aplikasi untuk mengoreksi IP.

### B. Error: "Koneksi ke server timeout"
- **Penyebab:** Firewall memblokir port 3000 atau IP komputer berubah.
- **Solusi:** Izinkan koneksi port 3000 pada Windows Defender Firewall atau periksa kembali alamat IP lokal komputer via `ipconfig`.

### C. Error Resolusi Dependensi saat `flutter pub get`
- **Penyebab:** Cache dependensi lama.
- **Solusi:** Jalankan:
  ```powershell
  flutter clean
  flutter pub get
  ```

---

## 13. Keterbatasan & Rencana Pengembangan Mendatang

Sesuai dengan batasan teknis saat ini pada backend:
1. **Otentikasi & Otorisasi Pengguna:**  
   Backend belum menggunakan autentikasi JWT / sesi login pengguna, sehingga frontend langsung menampilkan modul operasional tanpa layar login.
2. **Modul Pengeluaran Stok Distribusi (Sales Delivery):**  
   Fokus alur sistem saat ini adalah **Hasil Produksi dan Penerimaan Gudang**. Modul pengeluaran stok untuk pengiriman ke pelanggan dapat dihubungkan pada tahap selanjutnya dengan mekanisme mutasi `KELUAR`.
3. **Pencetakan Surat Jalan / Label Barcode:**  
   Fitur cetak fisik thermal/PDF tanda terima dapat ditambahkan pada iterasi berikutnya.
