import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import 'barang/barang_list_screen.dart';
import 'produksi/produksi_list_screen.dart';
import 'penerimaan/penerimaan_list_screen.dart';
import 'stok/stok_list_screen.dart';

/// Halaman Utama Aplikasi: Portal Modul Produksi & Gudang
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isServerOnline = false;
  bool _isCheckingServer = true;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    setState(() => _isCheckingServer = true);
    try {
      final ok = await ApiService.checkHealth();
      setState(() => _isServerOnline = ok);
    } catch (_) {
      setState(() => _isServerOnline = false);
    } finally {
      setState(() => _isCheckingServer = false);
    }
  }

  void _showBaseUrlDialog() {
    final urlController = TextEditingController(text: ApiService.baseUrl);

    Get.defaultDialog(
      title: 'Pengaturan Base URL API',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sesuaikan alamat backend jika menggunakan perangkat fisik, emulator, atau port lain.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'http://localhost:3000/api',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '• Web/Desktop: http://localhost:3000/api\n• Android Emulator: http://10.0.2.2:3000/api\n• HP Fisik: http://<IP_KOMPUTER>:3000/api',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
      textConfirm: 'Simpan & Tes',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      onConfirm: () {
        ApiService.baseUrl = urlController.text.trim();
        Get.back();
        _checkServer();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produksi & Gudang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet),
            tooltip: 'Atur Base URL',
            onPressed: _showBaseUrlDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Cek Server',
            onPressed: _checkServer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Koneksi Server Backend
            _buildServerStatusBar(),
            const SizedBox(height: 20),

            // Banner Selamat Datang
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.indigo.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sistem Manajemen Pabrik',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pencatatan siklus manufaktur, serah terima gudang, dan sinkronisasi saldo stok barang.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Menu Operasional Utama',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Grid 4 Menu Utama
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: [
                _buildMenuCard(
                  title: 'Master Barang',
                  subtitle: 'Katalog & status produk',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.blue,
                  onTap: () => Get.to(() => const BarangListScreen()),
                ),
                _buildMenuCard(
                  title: 'Hasil Produksi',
                  subtitle: 'Surat tugas manufaktur',
                  icon: Icons.precision_manufacturing_outlined,
                  color: Colors.amber.shade900,
                  onTap: () => Get.to(() => const ProduksiListScreen()),
                ),
                _buildMenuCard(
                  title: 'Penerimaan',
                  subtitle: 'Serah terima fisik gudang',
                  icon: Icons.warehouse_outlined,
                  color: Colors.teal.shade700,
                  onTap: () => Get.to(() => const PenerimaanListScreen()),
                ),
                _buildMenuCard(
                  title: 'Saldo Stok',
                  subtitle: 'Stok fisik & audit mutasi',
                  icon: Icons.analytics_outlined,
                  color: Colors.indigo.shade700,
                  onTap: () => Get.to(() => const StokListScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerStatusBar() {
    Color color;
    String text;
    IconData icon;

    if (_isCheckingServer) {
      color = Colors.orange;
      text = 'Menghubungkan ke server backend...';
      icon = Icons.sync;
    } else if (_isServerOnline) {
      color = Colors.green;
      text = 'Backend Terhubung (${ApiService.baseUrl})';
      icon = Icons.cloud_done;
    } else {
      color = Colors.red;
      text = 'Backend Tidak Terhubung (${ApiService.baseUrl})';
      icon = Icons.cloud_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: _showBaseUrlDialog,
            child: Text(
              'Ubah',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
