import 'package:get/get.dart';
import '../models/penerimaan_model.dart';
import '../services/api_service.dart';

/// Controller GetX untuk mengelola state Penerimaan Barang Gudang
class PenerimaanController extends GetxController {
  var penerimaanList = <PenerimaanModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var statusFilter = ''.obs; // '', 'draft', 'confirmed', 'cancelled'
  var searchQuery = ''.obs;

  // Detail penerimaan terpilih
  var selectedPenerimaan = Rxn<PenerimaanModel>();
  var isDetailLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPenerimaan();
  }

  /// Mengambil daftar penerimaan barang dari API
  Future<void> fetchPenerimaan({String? status, String? search}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      if (status != null) statusFilter.value = status;
      if (search != null) searchQuery.value = search;

      final data = await ApiService.getPenerimaan(
        status: statusFilter.value.isEmpty ? null : statusFilter.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );
      penerimaanList.assignAll(data);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengambil rincian satu tanda terima barang
  Future<void> fetchDetail(int id) async {
    try {
      isDetailLoading.value = true;
      final data = await ApiService.getPenerimaanById(id);
      selectedPenerimaan.value = data;
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

  /// Membuat surat tanda terima barang gudang baru
  Future<bool> createPenerimaan({
    String? nomorPenerimaan,
    required int hasilProduksiId,
    required String tanggalPenerimaan,
    String? catatan,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      isLoading.value = true;
      final result = await ApiService.createPenerimaan(
        nomorPenerimaan: nomorPenerimaan,
        hasilProduksiId: hasilProduksiId,
        tanggalPenerimaan: tanggalPenerimaan,
        catatan: catatan,
        items: items,
      );
      Get.snackbar(
        'Berhasil',
        'Surat penerimaan ${result.nomorPenerimaan} berhasil dicatat',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchPenerimaan();
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal Mencatat Penerimaan',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengubah status penerimaan ('confirmed' -> stok bertambah, 'cancelled' -> batal)
  Future<bool> updateStatus(int id, String status) async {
    try {
      isLoading.value = true;
      final updated = await ApiService.updateStatusPenerimaan(id: id, status: status);
      selectedPenerimaan.value = updated;
      
      String message = 'Status penerimaan kini menjadi: $status';
      if (status == 'confirmed') {
        message = 'Penerimaan telah dikonfirmasi dan stok gudang berhasil bertambah!';
      } else if (status == 'cancelled') {
        message = 'Penerimaan dibatalkan dan penyesuaian stok telah dilakukan.';
      }

      Get.snackbar(
        'Operasi Berhasil',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchPenerimaan();
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal Memperbarui Status',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
