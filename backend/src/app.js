const express = require('express');
const cors = require('cors');

const barangRoutes = require('./routes/barang.routes');
const produksiRoutes = require('./routes/produksi.routes');
const penerimaanRoutes = require('./routes/penerimaan.routes');
const stokRoutes = require('./routes/stok.routes');

const notFoundHandler = require('./middlewares/not-found.middleware');
const errorHandler = require('./middlewares/error.middleware');
const ApiResponse = require('./utils/api-response');

const app = express();

// ==============================================================================
// 1. GLOBAL MIDDLEWARES
// ==============================================================================

// Mengizinkan Cross-Origin Resource Sharing (CORS) agar dapat diakses dari Flutter
app.use(cors());

// Membatasi ukuran payload JSON hingga 1MB untuk keamanan dasar dari request flooding
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// ==============================================================================
// 2. HEALTH CHECK & ROOT ENDPOINT
// ==============================================================================

// Health Check Endpoint (GET /api/health)
app.get('/api/health', (req, res) => {
  return ApiResponse.success(res, 'Server API Produksi & Gudang berjalan dengan normal', {
    status: 'OK',
    uptime_seconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
  });
});

// Root path sambutan ramah
app.get('/', (req, res) => {
  return ApiResponse.success(res, 'Selamat datang di REST API Hasil Produksi dan Gudang', {
    health_check: '/api/health',
    endpoints: {
      barang: '/api/barang',
      produksi: '/api/produksi',
      penerimaan: '/api/penerimaan',
      stok: '/api/stok',
    },
  });
});

// ==============================================================================
// 3. API ROUTING (PREFIX: /api)
// ==============================================================================

app.use('/api/barang', barangRoutes);
app.use('/api/produksi', produksiRoutes);
app.use('/api/penerimaan', penerimaanRoutes);
app.use('/api/stok', stokRoutes);

// ==============================================================================
// 4. ERROR HANDLING
// ==============================================================================

// Tangani route yang tidak terdaftar (404)
app.use(notFoundHandler);

// Tangani seluruh error aplikasi secara terpusat
app.use(errorHandler);

module.exports = app;
