import 'package:get/get.dart';
import '../models/stok_model.dart';
import '../services/api_service.dart';

/// Controller GetX untuk mengelola state Stok Gudang dan Kartu Mutasi
class StokController extends GetxController {
  var stokList = <StokModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var searchQuery = ''.obs;

  // Detail stok dan audit trail mutasi barang terpilih
  var selectedStokDetail = Rxn<StokDetailModel>();
  var isDetailLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStok();
  }

  /// Mengambil daftar ringkasan saldo stok dari API
  Future<void> fetchStok({String? search}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      if (search != null) searchQuery.value = search;

      final data = await ApiService.getStok(
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );
      stokList.assignAll(data);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengambil kartu stok mutasi per barang
  Future<void> fetchDetail(int barangId) async {
    try {
      isDetailLoading.value = true;
      final data = await ApiService.getStokByBarangId(barangId);
      selectedStokDetail.value = data;
    } catch (e) {
      Get.snackbar(
        'Gagal Memuat Riwayat Stok',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDetailLoading.value = false;
    }
  }
}
