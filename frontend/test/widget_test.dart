import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/barang_model.dart';
import 'package:frontend/models/produksi_model.dart';
import 'package:frontend/models/penerimaan_model.dart';
import 'package:frontend/models/stok_model.dart';

void main() {
  group('Unit Test Models', () {
    test('BarangModel.fromJson parsing valid', () {
      final json = {
        'id': 1,
        'kode_barang': 'BRG-001',
        'nama_barang': 'Pipa PVC AW 1/2 Inch',
        'satuan': 'batang',
        'stok': '100.00',
        'is_active': 1,
        'created_at': '2026-10-24T12:00:00.000Z',
      };

      final model = BarangModel.fromJson(json);

      expect(model.id, 1);
      expect(model.kodeBarang, 'BRG-001');
      expect(model.namaBarang, 'Pipa PVC AW 1/2 Inch');
      expect(model.satuan, 'batang');
      expect(model.stok, 100.0);
      expect(model.isActive, true);
    });

    test('ProduksiModel.fromJson parsing valid', () {
      final json = {
        'id': 10,
        'nomor_produksi': 'PRD-20261024-0001',
        'tanggal_produksi': '2026-10-24',
        'status': 'completed',
        'catatan': 'Batch 1',
        'items': [
          {
            'id': 1,
            'barang_id': 2,
            'kode_barang': 'BRG-002',
            'nama_barang': 'Pipa PVC AW 3/4 Inch',
            'satuan': 'batang',
            'jumlah': 50,
          }
        ]
      };

      final model = ProduksiModel.fromJson(json);

      expect(model.id, 10);
      expect(model.nomorProduksi, 'PRD-20261024-0001');
      expect(model.status, 'completed');
      expect(model.items.length, 1);
      expect(model.items.first.jumlah, 50.0);
    });

    test('PenerimaanModel.fromJson parsing valid', () {
      final json = {
        'id': 5,
        'nomor_penerimaan': 'RCV-20261024-0001',
        'hasil_produksi_id': 10,
        'nomor_produksi': 'PRD-20261024-0001',
        'tanggal_penerimaan': '2026-10-24',
        'status': 'confirmed',
        'total_item': 1,
        'total_kuantitas_diterima': 50,
      };

      final model = PenerimaanModel.fromJson(json);

      expect(model.id, 5);
      expect(model.nomorPenerimaan, 'RCV-20261024-0001');
      expect(model.status, 'confirmed');
      expect(model.totalKuantitasDiterima, 50.0);
    });

    test('StokDetailModel.fromJson parsing valid', () {
      final json = {
        'barang': {
          'id': 1,
          'kode_barang': 'BRG-001',
          'nama_barang': 'Pipa PVC',
          'satuan': 'batang',
          'stok_terkini': 180,
          'is_active': 1,
        },
        'riwayat_mutasi': [
          {
            'id': 1,
            'tipe_mutasi': 'MASUK',
            'jumlah': 80,
            'stok_sebelum': 100,
            'stok_sesudah': 180,
            'referensi_tipe': 'PENERIMAAN',
            'referensi_id': 2,
            'keterangan': 'Penerimaan barang',
          }
        ]
      };

      final model = StokDetailModel.fromJson(json);

      expect(model.barang.kodeBarang, 'BRG-001');
      expect(model.barang.stokTerkini, 180.0);
      expect(model.riwayatMutasi.length, 1);
      expect(model.riwayatMutasi.first.tipeMutasi, 'MASUK');
    });
  });

  group('Widget Smoke Test', () {
    testWidgets('ProduksiGudangApp builds and shows HomeScreen portal', (tester) async {
      await tester.pumpWidget(const ProduksiGudangApp());

      expect(find.text('Produksi & Gudang'), findsOneWidget);
      expect(find.text('Master Barang'), findsOneWidget);
      expect(find.text('Hasil Produksi'), findsOneWidget);
      expect(find.text('Penerimaan'), findsOneWidget);
      expect(find.text('Saldo Stok'), findsOneWidget);
    });
  });
}
