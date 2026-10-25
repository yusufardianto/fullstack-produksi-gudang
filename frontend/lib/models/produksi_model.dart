/// Model detail barang di dalam satu transaksi hasil produksi
class ProduksiItemModel {
  final int? id;
  final int barangId;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final double jumlah;

  ProduksiItemModel({
    this.id,
    required this.barangId,
    this.kodeBarang = '',
    this.namaBarang = '',
    this.satuan = '',
    required this.jumlah,
  });

  factory ProduksiItemModel.fromJson(Map<String, dynamic> json) {
    return ProduksiItemModel(
      id: json['id'] != null ? int.tryParse('${json['id']}') : null,
      barangId: int.tryParse('${json['barang_id']}') ?? 0,
      kodeBarang: json['kode_barang']?.toString() ?? '',
      namaBarang: json['nama_barang']?.toString() ?? '',
      satuan: json['satuan']?.toString() ?? '',
      jumlah: double.tryParse('${json['jumlah']}') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barang_id': barangId,
      'jumlah': jumlah,
    };
  }
}

/// Model transaksi Hasil Produksi (Header & Daftar Detail)
class ProduksiModel {
  final int id;
  final String nomorProduksi;
  final String tanggalProduksi;
  final String status; // 'draft', 'completed', 'cancelled'
  final String catatan;
  final int totalItem;
  final double totalKuantitas;
  final DateTime? createdAt;
  final List<ProduksiItemModel> items;

  ProduksiModel({
    required this.id,
    required this.nomorProduksi,
    required this.tanggalProduksi,
    required this.status,
    this.catatan = '',
    this.totalItem = 0,
    this.totalKuantitas = 0.0,
    this.createdAt,
    this.items = const [],
  });

  factory ProduksiModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<ProduksiItemModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .map((item) => ProduksiItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ProduksiModel(
      id: int.tryParse('${json['id']}') ?? 0,
      nomorProduksi: json['nomor_produksi']?.toString() ?? '',
      tanggalProduksi: json['tanggal_produksi']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      catatan: json['catatan']?.toString() ?? '',
      totalItem: int.tryParse('${json['total_item']}') ?? itemsList.length,
      totalKuantitas: double.tryParse('${json['total_kuantitas']}') ??
          itemsList.fold(0.0, (sum, item) => sum + item.jumlah),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      items: itemsList,
    );
  }
}
