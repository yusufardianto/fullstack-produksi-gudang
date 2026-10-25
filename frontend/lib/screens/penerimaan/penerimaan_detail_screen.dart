import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/penerimaan_controller.dart';
import '../../models/penerimaan_model.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import '../stok/stok_list_screen.dart';

/// Halaman Detail Surat Penerimaan Barang Gudang
class PenerimaanDetailScreen extends StatefulWidget {
  final int penerimaanId;

  const PenerimaanDetailScreen({super.key, required this.penerimaanId});

  @override
  State<PenerimaanDetailScreen> createState() => _PenerimaanDetailScreenState();
}

class _PenerimaanDetailScreenState extends State<PenerimaanDetailScreen> {
  final controller = Get.find<PenerimaanController>();

  @override
  void initState() {
    super.initState();
    controller.fetchDetail(widget.penerimaanId);
  }

  void _confirmUpdateStatus(BuildContext context, PenerimaanModel penerimaan, String newStatus) {
    final isConfirming = newStatus == 'confirmed';
    final title = isConfirming ? 'Konfirmasi Penerimaan Fisik' : 'Batalkan Penerimaan';
    final desc = isConfirming
        ? 'Dengan mengonfirmasi, stok fisik di master barang akan bertambah secara otomatis dan tercatat pada kartu mutasi audit trail.'
        : 'Membatalkan penerimaan yang sudah terkonfirmasi akan menarik kembali saldo stok yang sebelumnya bertambah.';

    Get.defaultDialog(
      title: title,
      middleText: desc,
      textConfirm: isConfirming ? 'Ya, Konfirmasi & Tambah Stok' : 'Ya, Batalkan Penerimaan',
      textCancel: 'Kembali',
      confirmTextColor: Colors.white,
      buttonColor: isConfirming ? Colors.teal.shade700 : Colors.red,
      onConfirm: () async {
        Get.back();
        await controller.updateStatus(penerimaan.id, newStatus);
        controller.fetchDetail(widget.penerimaanId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Penerimaan Gudang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => controller.fetchDetail(widget.penerimaanId),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const LoadingWidget(message: 'Memuat detail penerimaan...');
        }

        final penerimaan = controller.selectedPenerimaan.value;
        if (penerimaan == null || penerimaan.id != widget.penerimaanId) {
          return AppErrorWidget(
            message: 'Data penerimaan tidak ditemukan',
            onRetry: () => controller.fetchDetail(widget.penerimaanId),
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
                              penerimaan.nomorPenerimaan,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          StatusBadge(status: penerimaan.status),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildRow('No. Referensi Produksi', penerimaan.nomorProduksi),
                      _buildRow('Tanggal Penerimaan', penerimaan.tanggalPenerimaan),
                      _buildRow('Catatan', penerimaan.catatan.isEmpty ? '-' : penerimaan.catatan),
                      _buildRow('Total Jenis Item', '${penerimaan.items.length} macam barang'),
                      _buildRow(
                        'Total Diterima',
                        '${penerimaan.items.fold(0.0, (s, i) => s + i.jumlahDiterima).toStringAsFixed(0)} unit',
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rincian Item Fisik
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Barang yang Diterima Masuk Gudang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (penerimaan.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Tidak ada rincian item pada tanda terima ini.'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: penerimaan.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final item = penerimaan.items[index];
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.teal.shade50,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.teal.shade800,
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
                                  '${item.jumlahDiterima.toStringAsFixed(0)} ${item.satuan}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.teal,
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
              if (penerimaan.status == 'draft') ...[
                ElevatedButton.icon(
                  onPressed: () => _confirmUpdateStatus(context, penerimaan, 'confirmed'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Konfirmasi Penerimaan (Tambah Stok Fisik)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _confirmUpdateStatus(context, penerimaan, 'cancelled'),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text('Batalkan Penerimaan (Draft Batal)', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ] else if (penerimaan.status == 'confirmed') ...[
                // Info bahwa stok sudah bertambah
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: Colors.teal),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Penerimaan telah dikonfirmasi dan stok gudang sudah bertambah otomatis.',
                          style: TextStyle(fontSize: 13, color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => const StokListScreen());
                  },
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Periksa Saldo Stok Gudang'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _confirmUpdateStatus(context, penerimaan, 'cancelled'),
                  icon: const Icon(Icons.undo, color: Colors.red),
                  label: const Text('Batalkan Penerimaan (Tarik Kembali Stok)', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.grey),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Surat penerimaan ini telah dibatalkan.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
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
              color: isHighlight ? Colors.teal.shade900 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
