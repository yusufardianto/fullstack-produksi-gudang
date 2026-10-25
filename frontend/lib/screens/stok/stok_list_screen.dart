import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/stok_controller.dart';
import '../../models/stok_model.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'stok_detail_screen.dart';

/// Halaman Daftar Ringkasan Saldo Stok Gudang
class StokListScreen extends StatelessWidget {
  const StokListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StokController());
    final searchController = TextEditingController(text: controller.searchQuery.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saldo Stok Gudang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => controller.fetchStok(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bar Pencarian
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari barang pada stok gudang...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    controller.fetchStok(search: '');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (val) => controller.fetchStok(search: val),
            ),
          ),

          // Konten Utama
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.stokList.isEmpty) {
                return const LoadingWidget(message: 'Memuat saldo stok gudang...');
              }

              if (controller.errorMessage.isNotEmpty && controller.stokList.isEmpty) {
                return AppErrorWidget(
                  message: controller.errorMessage.value,
                  onRetry: () => controller.fetchStok(),
                );
              }

              if (controller.stokList.isEmpty) {
                return EmptyWidget(
                  title: 'Stok Kosong',
                  message: 'Tidak ada data stok barang yang sesuai kriteria.',
                  icon: Icons.inventory_2_outlined,
                  actionLabel: 'Segarkan',
                  onAction: () => controller.fetchStok(),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchStok(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: controller.stokList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = controller.stokList[index];
                    return _buildStokCard(context, item);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStokCard(BuildContext context, StokModel item) {
    final hasStock = item.stokTerkini > 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => StokDetailScreen(barangId: item.id)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Ikon Stok
              CircleAvatar(
                radius: 24,
                backgroundColor: hasStock ? Colors.teal.shade50 : Colors.red.shade50,
                foregroundColor: hasStock ? Colors.teal.shade800 : Colors.red.shade700,
                child: Icon(hasStock ? Icons.inventory_2 : Icons.remove_shopping_cart),
              ),
              const SizedBox(width: 12),
              // Nama & Kode Barang
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaBarang,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kode: ${item.kodeBarang}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: item.isActive ? 'Aktif' : 'Nonaktif'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Kuantitas Stok & Navigasi
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.stokTerkini.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: hasStock ? Colors.teal.shade800 : Colors.red.shade700,
                    ),
                  ),
                  Text(
                    item.satuan,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Kartu Mutasi',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: Colors.blue.shade700),
                    ],
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
