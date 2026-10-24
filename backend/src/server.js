const path = require('path');
const dotenv = require('dotenv');

// Load environment variables dari root folder backend
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const app = require('./app');
const { testConnection } = require('./config/database');

const PORT = parseInt(process.env.PORT, 10) || 3000;

async function startServer() {
  console.log('================================================================');
  console.log('🚀 Memulai Server REST API Hasil Produksi & Gudang...');
  console.log('================================================================');

  // Tes koneksi database terlebih dahulu
  await testConnection();

  const server = app.listen(PORT, () => {
    console.log(`[SERVER] Berjalan pada: http://localhost:${PORT}`);
    console.log(`[HEALTH] Health check: http://localhost:${PORT}/api/health`);
    console.log(`[INFO] Tekan CTRL + C untuk menghentikan server.`);
    console.log('================================================================');
  });

  // Graceful shutdown saat server dihentikan (misal CTRL+C di terminal)
  const shutdown = () => {
    console.log('\n[SERVER] Menutup server secara aman (graceful shutdown)...');
    server.close(() => {
      console.log('[SERVER] Server telah dinonaktifkan.');
      process.exit(0);
    });
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

startServer();
