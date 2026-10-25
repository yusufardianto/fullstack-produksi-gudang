import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/penerimaan_controller.dart';
import '../../models/penerimaan_model.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'penerimaan_detail_screen.dart';
import 'penerimaan_form_screen.dart';

/// Halaman Daftar Transaksi Penerimaan Barang Gudang
class PenerimaanListScreen extends StatelessWidget {
  const PenerimaanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PenerimaanController());
    final searchController = TextEditingController(text: controller.searchQuery.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penerimaan Gudang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => controller.fetchPenerimaan(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bar Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari nomor penerimaan atau nomor produksi...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    controller.fetchPenerimaan(search: '');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (val) => controller.fetchPenerimaan(search: val),
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
                    _buildFilterChip(controller, 'confirmed', 'Confirmed'),
                    const SizedBox(width: 8),
                    _buildFilterChip(controller, 'cancelled', 'Cancelled'),
                  ],
                ),
              )),

          // Daftar Penerimaan
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.penerimaanList.isEmpty) {
                return const LoadingWidget(message: 'Mengambil data penerimaan gudang...');
              }

              if (controller.errorMessage.isNotEmpty && controller.penerimaanList.isEmpty) {
                return AppErrorWidget(
                  message: controller.errorMessage.value,
                  onRetry: () => controller.fetchPenerimaan(),
                );
              }

              if (controller.penerimaanList.isEmpty) {
                return EmptyWidget(
                  title: 'Belum Ada Penerimaan',
                  message: 'Tidak ada surat tanda terima gudang yang sesuai.',
                  icon: Icons.warehouse_outlined,
                  actionLabel: 'Catat Penerimaan',
                  onAction: () => Get.to(() => const PenerimaanFormScreen()),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchPenerimaan(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: controller.penerimaanList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = controller.penerimaanList[index];
                    return _buildPenerimaanCard(context, item);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const PenerimaanFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Catat Penerimaan'),
      ),
    );
  }

  Widget _buildFilterChip(PenerimaanController controller, String value, String label) {
    final isSelected = controller.statusFilter.value == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          controller.fetchPenerimaan(status: value);
        }
      },
    );
  }

  Widget _buildPenerimaanCard(BuildContext context, PenerimaanModel item) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => PenerimaanDetailScreen(penerimaanId: item.id)),
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
                      Icon(Icons.inventory_outlined, size: 20, color: Colors.teal.shade700),
                      const SizedBox(width: 8),
                      Text(
                        item.nomorPenerimaan,
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
                  Icon(Icons.link, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Ref. Produksi: ${item.nomorProduksi}',
                    style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Diterima: ${item.tanggalPenerimaan}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Diterima: ${item.totalItem} item (${item.totalKuantitasDiterima.toStringAsFixed(0)} unit)',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Row(
                    children: [
                      Text(
                        'Detail',
                        style: TextStyle(color: Colors.teal.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: Colors.teal.shade700),
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
