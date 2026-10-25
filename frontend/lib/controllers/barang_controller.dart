import 'package:get/get.dart';
import '../models/barang_model.dart';
import '../services/api_service.dart';

/// Controller GetX untuk mengelola state Master Barang
class BarangController extends GetxController {
  // Reactive State
  var barangList = <BarangModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBarang();
  }

  /// Mengambil daftar barang dari API
  Future<void> fetchBarang({String? search}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      if (search != null) {
        searchQuery.value = search;
      }
      final data = await ApiService.getBarang(
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );
      barangList.assignAll(data);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  /// Menambahkan master barang baru
  Future<bool> createBarang({
    required String kodeBarang,
    required String namaBarang,
    required String satuan,
  }) async {
    try {
      isLoading.value = true;
      await ApiService.createBarang(
        kodeBarang: kodeBarang,
        namaBarang: namaBarang,
        satuan: satuan,
      );
      Get.snackbar(
        'Berhasil',
        'Data barang $namaBarang berhasil ditambahkan',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchBarang();
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal Menambah Barang',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengubah nama & satuan barang
  Future<bool> updateBarang({
    required int id,
    required String namaBarang,
    required String satuan,
  }) async {
    try {
      isLoading.value = true;
      await ApiService.updateBarang(
        id: id,
        namaBarang: namaBarang,
        satuan: satuan,
      );
      Get.snackbar(
        'Berhasil',
        'Data barang berhasil diperbarui',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchBarang();
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal Memperbarui',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengaktifkan / menonaktifkan barang
  Future<bool> toggleStatus(int id, bool currentStatus) async {
    try {
      isLoading.value = true;
      final newStatus = !currentStatus;
      await ApiService.toggleStatusBarang(id: id, isActive: newStatus);
      Get.snackbar(
        'Berhasil',
        'Status barang berhasil diubah menjadi ${newStatus ? "Aktif" : "Nonaktif"}',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchBarang();
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
