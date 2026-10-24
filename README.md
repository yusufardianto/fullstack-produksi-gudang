# Fullstack Produksi & Gudang

Repository ini berisi implementasi sistem **Hasil Produksi dan Gudang** yang mencakup:
- **`backend/`**: REST API berbasis Node.js, Express, dan MySQL dengan kontrol transaksi database ACID dan kartu mutasi stok otomatis.
- **`frontend/`**: Aplikasi antarmuka pengguna berbasis Flutter.

---

## Panduan Backend REST API

Seluruh implementasi backend terletak di direktori [`backend/`](backend/):

1. **Panduan Memulai Cepat**: Silakan baca panduan lengkap di [backend/README.md](backend/README.md).
2. **Dokumentasi REST API**: Daftar seluruh endpoint dan contoh request/response ada di [backend/docs/API.md](backend/docs/API.md).
3. **Dokumentasi Database & ERD**: Struktur tabel, index, dan relasi foreign key ada di [backend/docs/DATABASE.md](backend/docs/DATABASE.md).
4. **Alur Bisnis & Transisi Status**: Logika mutasi stok dan diagram alur ada di [backend/docs/BUSINESS-FLOW.md](backend/docs/BUSINESS-FLOW.md).

### Cara Menjalankan Backend:
```powershell
cd backend
npm install
npm run dev
```

### Cara Menjalankan Pengujian Otomatis Backend:
```powershell
cd backend
npm test
```
