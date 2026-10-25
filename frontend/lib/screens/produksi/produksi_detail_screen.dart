import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/produksi_controller.dart';
import '../../models/produksi_model.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import '../penerimaan/penerimaan_form_screen.dart';

/// Halaman Detail Transaksi Hasil Produksi Beserta Rincian Item
class ProduksiDetailScreen extends StatefulWidget {
  final int produksiId;

  const ProduksiDetailScreen({super.key, required this.produksiId});

  @override
  State<ProduksiDetailScreen> createState() => _ProduksiDetailScreenState();
}

class _ProduksiDetailScreenState extends State<ProduksiDetailScreen> {
  final controller = Get.find<ProduksiController>();

  @override
  void initState() {
    super.initState();
    controller.fetchDetail(widget.produksiId);
  }

  void _confirmUpdateStatus(BuildContext context, ProduksiModel produksi, String newStatus) {
    String actionLabel = newStatus == 'completed' ? 'Menyelesaikan' : 'Membatalkan';
    Color confirmColor = newStatus == 'completed' ? Colors.green : Colors.red;

    Get.defaultDialog(
      title: 'Konfirmasi Perubahan Status',
      middleText:
          'Apakah Anda yakin ingin $actionLabel transaksi produksi "${produksi.nomorProduksi}"? Tindakan ini akan mengubah status menjadi $newStatus.',
      textConfirm: 'Ya, $actionLabel',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: confirmColor,
      onConfirm: () async {
        Get.back();
        await controller.updateStatus(produksi.id, newStatus);
        controller.fetchDetail(widget.produksiId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Hasil Produksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => controller.fetchDetail(widget.produksiId),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const LoadingWidget(message: 'Memuat detail produksi...');
        }

        final produksi = controller.selectedProduksi.value;
        if (produksi == null || produksi.id != widget.produksiId) {
          return AppErrorWidget(
            message: 'Data produksi tidak ditemukan',
            onRetry: () => controller.fetchDetail(widget.produksiId),
          );
        }

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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              produksi.nomorProduksi,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          StatusBadge(status: produksi.status),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildRow('Tanggal Produksi', produksi.tanggalProduksi),
                      _buildRow('Catatan', produksi.catatan.isEmpty ? '-' : produksi.catatan),
                      _buildRow('Total Jenis Item', '${produksi.items.length} macam barang'),
                      _buildRow(
                        'Total Kuantitas',
                        '${produksi.items.fold(0.0, (s, i) => s + i.jumlah).toStringAsFixed(0)} unit',
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rincian Item Barang
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Barang yang Diproduksi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (produksi.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Tidak ada item pada transaksi ini.'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: produksi.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final item = produksi.items[index];
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue.shade50,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.namaBarang,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Kode: ${item.kodeBarang}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.jumlah.toStringAsFixed(0)} ${item.satuan}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Aksi Status
              if (produksi.status == 'draft') ...[
                ElevatedButton.icon(
                  onPressed: () => _confirmUpdateStatus(context, produksi, 'completed'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Selesaikan Produksi (Completed)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _confirmUpdateStatus(context, produksi, 'cancelled'),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text('Batalkan Produksi (Cancelled)', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ] else if (produksi.status == 'completed') ...[
                // Tombol cepat buat penerimaan gudang
                ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => PenerimaanFormScreen(preselectedProduksi: produksi));
                  },
                  icon: const Icon(Icons.warehouse),
                  label: const Text('Catat Penerimaan Gudang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _confirmUpdateStatus(context, produksi, 'cancelled'),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text('Batalkan Produksi (Cancelled)', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.blue.shade900 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
