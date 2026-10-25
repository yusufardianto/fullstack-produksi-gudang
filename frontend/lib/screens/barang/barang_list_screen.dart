import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/barang_controller.dart';
import '../../models/barang_model.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';
import 'barang_detail_screen.dart';
import 'barang_form_screen.dart';

/// Halaman Daftar Master Barang
class BarangListScreen extends StatelessWidget {
  const BarangListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi atau temukan controller GetX
    final controller = Get.put(BarangController());
    final searchController = TextEditingController(text: controller.searchQuery.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Master Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => controller.fetchBarang(),
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
                hintText: 'Cari kode atau nama barang...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    controller.fetchBarang(search: '');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (val) => controller.fetchBarang(search: val),
            ),
          ),

          // Konten Utama
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.barangList.isEmpty) {
                return const LoadingWidget(message: 'Mengambil data master barang...');
              }

              if (controller.errorMessage.isNotEmpty && controller.barangList.isEmpty) {
                return AppErrorWidget(
                  message: controller.errorMessage.value,
                  onRetry: () => controller.fetchBarang(),
                );
              }

              if (controller.barangList.isEmpty) {
                return EmptyWidget(
                  title: 'Belum Ada Barang',
                  message: 'Tidak ada data barang yang sesuai kriteria pencarian.',
                  icon: Icons.inventory_2_outlined,
                  actionLabel: 'Tambah Barang Baru',
                  onAction: () => Get.to(() => const BarangFormScreen()),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchBarang(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: controller.barangList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = controller.barangList[index];
                    return _buildBarangCard(context, item, controller);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const BarangFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Barang'),
      ),
    );
  }

  Widget _buildBarangCard(BuildContext context, BarangModel item, BarangController controller) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => BarangDetailScreen(barangId: item.id)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Avatar
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade800,
                    child: const Icon(Icons.category_outlined),
                  ),
                  const SizedBox(width: 12),
                  // Info Barang
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.namaBarang,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kode: ${item.kodeBarang}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge Status
                  StatusBadge(status: item.isActive ? 'Aktif' : 'Nonaktif'),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Stok: ',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      children: [
                        TextSpan(
                          text: '${item.stok.toStringAsFixed(0)} ${item.satuan}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Tombol Edit
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: Colors.blue,
                        tooltip: 'Edit Data',
                        onPressed: () => Get.to(() => BarangFormScreen(barangToEdit: item)),
                      ),
                      // Tombol Ubah Status
                      IconButton(
                        icon: Icon(
                          item.isActive ? Icons.toggle_on : Icons.toggle_off,
                          size: 26,
                          color: item.isActive ? Colors.green : Colors.grey,
                        ),
                        tooltip: item.isActive ? 'Nonaktifkan' : 'Aktifkan',
                        onPressed: () => _confirmToggleStatus(context, item, controller),
                      ),
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

  void _confirmToggleStatus(BuildContext context, BarangModel item, BarangController controller) {
    final nextStatus = !item.isActive;
    final actionText = nextStatus ? 'mengaktifkan' : 'menonaktifkan';

    Get.defaultDialog(
      title: 'Konfirmasi Status',
      middleText: 'Apakah Anda yakin ingin $actionText barang "${item.namaBarang}"?',
      textConfirm: 'Ya, Lanjutkan',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.toggleStatus(item.id, item.isActive);
      },
    );
  }
}
