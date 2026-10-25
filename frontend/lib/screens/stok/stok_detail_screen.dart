import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/stok_controller.dart';
import '../../models/stok_model.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';

/// Halaman Detail Stok & Kartu Audit Mutasi Per Barang
class StokDetailScreen extends StatefulWidget {
  final int barangId;

  const StokDetailScreen({super.key, required this.barangId});

  @override
  State<StokDetailScreen> createState() => _StokDetailScreenState();
}

class _StokDetailScreenState extends State<StokDetailScreen> {
  final controller = Get.put(StokController());

  @override
  void initState() {
    super.initState();
    controller.fetchDetail(widget.barangId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartu Mutasi Stok'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => controller.fetchDetail(widget.barangId),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const LoadingWidget(message: 'Memuat histori mutasi stok...');
        }

        final detail = controller.selectedStokDetail.value;
        if (detail == null || detail.barang.id != widget.barangId) {
          return AppErrorWidget(
            message: 'Informasi stok barang tidak ditemukan',
            onRetry: () => controller.fetchDetail(widget.barangId),
          );
        }

        final barang = detail.barang;
        final mutasiList = detail.riwayatMutasi;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ringkasan Master Barang & Stok Terkini
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  barang.namaBarang,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kode: ${barang.kodeBarang}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: barang.isActive ? 'Aktif' : 'Nonaktif'),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Saldo Stok Fisik Terkini',
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    barang.stokTerkini.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    barang.satuan,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Kartu Mutasi / Riwayat Audit Trail
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Kartu Mutasi (Audit Trail)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${mutasiList.length} transaksi',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (mutasiList.isEmpty)
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                    child: EmptyWidget(
                      title: 'Belum Ada Mutasi',
                      message: 'Barang ini belum pernah mengalami pergerakan stok masuk atau keluar.',
                      icon: Icons.history,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mutasiList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final mutasi = mutasiList[index];
                    return _buildMutasiCard(mutasi, barang.satuan);
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMutasiCard(MutasiStokModel mutasi, String satuan) {
    final isMasuk = mutasi.tipeMutasi == 'MASUK';
    final color = isMasuk ? Colors.green.shade700 : Colors.red.shade700;
    final bgColor = isMasuk ? Colors.green.shade50 : Colors.red.shade50;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: bgColor,
                  child: Icon(
                    isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mutasi ${mutasi.tipeMutasi}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Ref: ${mutasi.referensiTipe} #${mutasi.referensiId}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isMasuk ? "+" : "-"}${mutasi.jumlah.toStringAsFixed(0)} $satuan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo: ${mutasi.stokSebelum.toStringAsFixed(0)} ➔ ${mutasi.stokSesudah.toStringAsFixed(0)} $satuan',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (mutasi.tanggalMutasi != null)
                  Text(
                    mutasi.tanggalMutasi!.toLocal().toString().split('.')[0],
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
              ],
            ),
            if (mutasi.keterangan.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                mutasi.keterangan,
                style: TextStyle(color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
