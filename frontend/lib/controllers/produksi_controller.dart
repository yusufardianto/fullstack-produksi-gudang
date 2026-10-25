import 'package:get/get.dart';
import '../models/produksi_model.dart';
import '../services/api_service.dart';

/// Controller GetX untuk mengelola state Transaksi Hasil Produksi
class ProduksiController extends GetxController {
  var produksiList = <ProduksiModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var statusFilter = ''.obs; // '', 'draft', 'completed', 'cancelled'
  var searchQuery = ''.obs;

  // Detail yang sedang dibuka
  var selectedProduksi = Rxn<ProduksiModel>();
  var isDetailLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProduksi();
  }

  /// Mengambil daftar hasil produksi dari API
  Future<void> fetchProduksi({String? status, String? search}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      if (status != null) statusFilter.value = status;
      if (search != null) searchQuery.value = search;

      final data = await ApiService.getProduksi(
        status: statusFilter.value.isEmpty ? null : statusFilter.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );
      produksiList.assignAll(data);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengambil detail satu transaksi hasil produksi beserta itemnya
  Future<void> fetchDetail(int id) async {
    try {
      isDetailLoading.value = true;
      final data = await ApiService.getProduksiById(id);
      selectedProduksi.value = data;
    } catch (e) {
      Get.snackbar(
        'Gagal Memuat Detail',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDetailLoading.value = false;
    }
  }

  /// Membuat transaksi hasil produksi baru
  Future<bool> createProduksi({
    String? nomorProduksi,
    required String tanggalProduksi,
    String? catatan,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      isLoading.value = true;
      final result = await ApiService.createProduksi(
        nomorProduksi: nomorProduksi,
        tanggalProduksi: tanggalProduksi,
        catatan: catatan,
        items: items,
      );
      Get.snackbar(
        'Berhasil',
        'Hasil produksi ${result.nomorProduksi} berhasil dibuat',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchProduksi();
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal Membuat Produksi',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengubah status hasil produksi ('completed' atau 'cancelled')
  Future<bool> updateStatus(int id, String status) async {
    try {
      isLoading.value = true;
      final updated = await ApiService.updateStatusProduksi(id: id, status: status);
      selectedProduksi.value = updated;
      Get.snackbar(
        'Status Berhasil Diubah',
        'Status produksi kini menjadi: $status',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchProduksi();
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal Mengubah Status',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
