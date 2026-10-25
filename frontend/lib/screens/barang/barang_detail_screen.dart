import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/barang_model.dart';
import '../../services/api_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import '../stok/stok_detail_screen.dart';
import 'barang_form_screen.dart';

/// Halaman Rincian Detail Satu Master Barang
class BarangDetailScreen extends StatefulWidget {
  final int barangId;

  const BarangDetailScreen({super.key, required this.barangId});

  @override
  State<BarangDetailScreen> createState() => _BarangDetailScreenState();
}

class _BarangDetailScreenState extends State<BarangDetailScreen> {
  late Future<BarangModel> _detailFuture;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    _detailFuture = ApiService.getBarangById(widget.barangId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => setState(() => _loadDetail()),
          ),
        ],
      ),
      body: FutureBuilder<BarangModel>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Memuat rincian barang...');
          }

          if (snapshot.hasError) {
            return AppErrorWidget(
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: () => setState(() => _loadDetail()),
            );
          }

          final barang = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.inventory_2, size: 40, color: Colors.blue.shade900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          barang.namaBarang,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          barang.kodeBarang,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        StatusBadge(status: barang.isActive ? 'Aktif' : 'Nonaktif'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kartu Informasi Teknis
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Barang',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        _buildRow('ID Database', '#${barang.id}'),
                        _buildRow('Kode Unik', barang.kodeBarang),
                        _buildRow('Nama Produk', barang.namaBarang),
                        _buildRow('Satuan Unit', barang.satuan),
                        _buildRow(
                          'Stok Terkini',
                          '${barang.stok.toStringAsFixed(0)} ${barang.satuan}',
                          isHighlight: true,
                        ),
                        _buildRow(
                          'Status Master',
                          barang.isActive ? 'Aktif (Dapat Ditransaksikan)' : 'Nonaktif (Arsip)',
                        ),
                        if (barang.createdAt != null)
                          _buildRow('Tanggal Dibuat', barang.createdAt!.toLocal().toString().split('.')[0]),
                        if (barang.updatedAt != null)
                          _buildRow('Terakhir Diperbarui', barang.updatedAt!.toLocal().toString().split('.')[0]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Aksi Tambahan
                ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => StokDetailScreen(barangId: barang.id));
                  },
                  icon: const Icon(Icons.history_edu),
                  label: const Text('Lihat Riwayat Mutasi Stok'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Get.to(() => BarangFormScreen(barangToEdit: barang));
                    setState(() => _loadDetail());
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Informasi Barang'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? Colors.blue.shade800 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
