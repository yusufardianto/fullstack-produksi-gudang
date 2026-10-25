/// Model detail barang di dalam surat penerimaan gudang
class PenerimaanItemModel {
  final int? id;
  final int barangId;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final double jumlahDiterima;

  PenerimaanItemModel({
    this.id,
    required this.barangId,
    this.kodeBarang = '',
    this.namaBarang = '',
    this.satuan = '',
    required this.jumlahDiterima,
  });

  factory PenerimaanItemModel.fromJson(Map<String, dynamic> json) {
    return PenerimaanItemModel(
      id: json['id'] != null ? int.tryParse('${json['id']}') : null,
      barangId: int.tryParse('${json['barang_id']}') ?? 0,
      kodeBarang: json['kode_barang']?.toString() ?? '',
      namaBarang: json['nama_barang']?.toString() ?? '',
      satuan: json['satuan']?.toString() ?? '',
      jumlahDiterima: double.tryParse('${json['jumlah_diterima']}') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barang_id': barangId,
      'jumlah_diterima': jumlahDiterima,
    };
  }
}

/// Model transaksi Penerimaan Barang Gudang (Header & Detail)
class PenerimaanModel {
  final int id;
  final String nomorPenerimaan;
  final int hasilProduksiId;
  final String nomorProduksi;
  final String tanggalProduksi;
  final String tanggalPenerimaan;
  final String status; // 'draft', 'confirmed', 'cancelled'
  final String catatan;
  final int totalItem;
  final double totalKuantitasDiterima;
  final DateTime? createdAt;
  final List<PenerimaanItemModel> items;

  PenerimaanModel({
    required this.id,
    required this.nomorPenerimaan,
    required this.hasilProduksiId,
    required this.nomorProduksi,
    this.tanggalProduksi = '',
    required this.tanggalPenerimaan,
    required this.status,
    this.catatan = '',
    this.totalItem = 0,
    this.totalKuantitasDiterima = 0.0,
    this.createdAt,
    this.items = const [],
  });

  factory PenerimaanModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<PenerimaanItemModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .map((item) => PenerimaanItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return PenerimaanModel(
      id: int.tryParse('${json['id']}') ?? 0,
      nomorPenerimaan: json['nomor_penerimaan']?.toString() ?? '',
      hasilProduksiId: int.tryParse('${json['hasil_produksi_id']}') ?? 0,
      nomorProduksi: json['nomor_produksi']?.toString() ?? '',
      tanggalProduksi: json['tanggal_produksi']?.toString() ?? '',
      tanggalPenerimaan: json['tanggal_penerimaan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      catatan: json['catatan']?.toString() ?? '',
      totalItem: int.tryParse('${json['total_item']}') ?? itemsList.length,
      totalKuantitasDiterima:
          double.tryParse('${json['total_kuantitas_diterima']}') ??
              itemsList.fold(0.0, (sum, item) => sum + item.jumlahDiterima),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      items: itemsList,
    );
  }
}
