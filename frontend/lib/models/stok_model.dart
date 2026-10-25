/// Model ringkasan stok per barang
class StokModel {
  final int id;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final double stokTerkini;
  final bool isActive;
  final DateTime? terakhirDiperbarui;

  StokModel({
    required this.id,
    required this.kodeBarang,
    required this.namaBarang,
    required this.satuan,
    required this.stokTerkini,
    required this.isActive,
    this.terakhirDiperbarui,
  });

  factory StokModel.fromJson(Map<String, dynamic> json) {
    return StokModel(
      id: int.tryParse('${json['id']}') ?? 0,
      kodeBarang: json['kode_barang']?.toString() ?? '',
      namaBarang: json['nama_barang']?.toString() ?? '',
      satuan: json['satuan']?.toString() ?? '',
      stokTerkini: double.tryParse('${json['stok_terkini'] ?? json['stok']}') ?? 0.0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      terakhirDiperbarui: json['terakhir_diperbarui'] != null || json['updated_at'] != null
          ? DateTime.tryParse((json['terakhir_diperbarui'] ?? json['updated_at']).toString())
          : null,
    );
  }
}

/// Model riwayat kartu mutasi stok (Audit Trail)
class MutasiStokModel {
  final int id;
  final String tipeMutasi; // 'MASUK' atau 'KELUAR'
  final double jumlah;
  final double stokSebelum;
  final double stokSesudah;
  final String referensiTipe; // 'PENERIMAAN' atau 'PEMBATALAN_PENERIMAAN'
  final int referensiId;
  final String keterangan;
  final DateTime? tanggalMutasi;

  MutasiStokModel({
    required this.id,
    required this.tipeMutasi,
    required this.jumlah,
    required this.stokSebelum,
    required this.stokSesudah,
    required this.referensiTipe,
    required this.referensiId,
    this.keterangan = '',
    this.tanggalMutasi,
  });

  factory MutasiStokModel.fromJson(Map<String, dynamic> json) {
    return MutasiStokModel(
      id: int.tryParse('${json['id']}') ?? 0,
      tipeMutasi: json['tipe_mutasi']?.toString() ?? '',
      jumlah: double.tryParse('${json['jumlah']}') ?? 0.0,
      stokSebelum: double.tryParse('${json['stok_sebelum']}') ?? 0.0,
      stokSesudah: double.tryParse('${json['stok_sesudah']}') ?? 0.0,
      referensiTipe: json['referensi_tipe']?.toString() ?? '',
      referensiId: int.tryParse('${json['referensi_id']}') ?? 0,
      keterangan: json['keterangan']?.toString() ?? '',
      tanggalMutasi: json['tanggal_mutasi'] != null || json['created_at'] != null
          ? DateTime.tryParse((json['tanggal_mutasi'] ?? json['created_at']).toString())
          : null,
    );
  }
}

/// Model detail stok barang beserta kartu riwayat mutasinya
class StokDetailModel {
  final StokModel barang;
  final List<MutasiStokModel> riwayatMutasi;

  StokDetailModel({
    required this.barang,
    required this.riwayatMutasi,
  });

  factory StokDetailModel.fromJson(Map<String, dynamic> json) {
    final rawBarang = json['barang'] as Map<String, dynamic>? ?? {};
    final rawMutasi = json['riwayat_mutasi'] as List? ?? [];

    return StokDetailModel(
      barang: StokModel.fromJson(rawBarang),
      riwayatMutasi: rawMutasi
          .map((m) => MutasiStokModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
