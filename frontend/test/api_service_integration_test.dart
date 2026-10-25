import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/api_service.dart';

void main() {
  group('Integration Test ApiService terhadap Live Backend', () {
    setUpAll(() {
      // Pastikan menarget localhost:3000 saat pengujian lingkungan mesin lokal
      ApiService.baseUrl = 'http://localhost:3000/api';
    });

    test('1. Health check backend mengembalikan true', () async {
      final isHealthy = await ApiService.checkHealth();
      expect(isHealthy, true);
    });

    test('2. Mengambil katalog barang mengembalikan list barang valid', () async {
      final barangList = await ApiService.getBarang();
      expect(barangList, isA<List>());
      // Minimal ada data seed
      expect(barangList.isNotEmpty, true);
      final first = barangList.first;
      expect(first.id, greaterThan(0));
      expect(first.kodeBarang.isNotEmpty, true);
      expect(first.namaBarang.isNotEmpty, true);
    });

    test('3. Mengambil ringkasan saldo stok mengembalikan list stok valid', () async {
      final stokList = await ApiService.getStok();
      expect(stokList, isA<List>());
      expect(stokList.isNotEmpty, true);
      final first = stokList.first;
      expect(first.kodeBarang.isNotEmpty, true);
      expect(first.stokTerkini, greaterThanOrEqualTo(0.0));
    });

    test('4. Mengambil detail stok dan mutasi barang ID 1', () async {
      final stokDetail = await ApiService.getStokByBarangId(1);
      expect(stokDetail.barang.id, 1);
      expect(stokDetail.riwayatMutasi, isA<List>());
    });

    test('5. Mengambil daftar transaksi produksi', () async {
      final produksiList = await ApiService.getProduksi();
      expect(produksiList, isA<List>());
    });

    test('6. Mengambil daftar transaksi penerimaan', () async {
      final penerimaanList = await ApiService.getPenerimaan();
      expect(penerimaanList, isA<List>());
    });
  });
}
