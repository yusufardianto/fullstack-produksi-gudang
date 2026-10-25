import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/produksi_controller.dart';
import '../../models/produksi_model.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'produksi_detail_screen.dart';
import 'produksi_form_screen.dart';

/// Halaman Daftar Transaksi Hasil Produksi
class ProduksiListScreen extends StatelessWidget {
  const ProduksiListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProduksiController());
    final searchController = TextEditingController(text: controller.searchQuery.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Produksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => controller.fetchProduksi(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Status & Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari nomor produksi atau catatan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    controller.fetchProduksi(search: '');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (val) => controller.fetchProduksi(search: val),
            ),
          ),

          // Filter Tab Status
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    _buildFilterChip(controller, '', 'Semua Status'),
                    const SizedBox(width: 8),
                    _buildFilterChip(controller, 'draft', 'Draft'),
                    const SizedBox(width: 8),
                    _buildFilterChip(controller, 'completed', 'Completed'),
                    const SizedBox(width: 8),
                    _buildFilterChip(controller, 'cancelled', 'Cancelled'),
                  ],
                ),
              )),

          // Daftar Produksi
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.produksiList.isEmpty) {
                return const LoadingWidget(message: 'Mengambil data produksi...');
              }

              if (controller.errorMessage.isNotEmpty && controller.produksiList.isEmpty) {
                return AppErrorWidget(
                  message: controller.errorMessage.value,
                  onRetry: () => controller.fetchProduksi(),
                );
              }

              if (controller.produksiList.isEmpty) {
                return EmptyWidget(
                  title: 'Belum Ada Hasil Produksi',
                  message: 'Tidak ada dokumen produksi yang sesuai filter.',
                  icon: Icons.precision_manufacturing_outlined,
                  actionLabel: 'Buat Produksi Baru',
                  onAction: () => Get.to(() => const ProduksiFormScreen()),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchProduksi(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: controller.produksiList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = controller.produksiList[index];
                    return _buildProduksiCard(context, item);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const ProduksiFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Produksi Baru'),
      ),
    );
  }

  Widget _buildFilterChip(ProduksiController controller, String value, String label) {
    final isSelected = controller.statusFilter.value == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          controller.fetchProduksi(status: value);
        }
      },
    );
  }

  Widget _buildProduksiCard(BuildContext context, ProduksiModel item) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => ProduksiDetailScreen(produksiId: item.id)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment_outlined, size: 20, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        item.nomorProduksi,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Tanggal: ${item.tanggalProduksi}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
              if (item.catatan.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.notes_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.catatan,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${item.totalItem} item (${item.totalKuantitas.toStringAsFixed(0)} unit)',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Row(
                    children: [
                      Text(
                        'Rincian',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: Colors.blue.shade700),
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
