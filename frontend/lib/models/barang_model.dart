/// Model untuk data Master Barang
class BarangModel {
  final int id;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final double stok;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BarangModel({
    required this.id,
    required this.kodeBarang,
    required this.namaBarang,
    required this.satuan,
    required this.stok,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  /// Mengubah JSON dari backend menjadi objek BarangModel
  factory BarangModel.fromJson(Map<String, dynamic> json) {
    return BarangModel(
      id: int.tryParse('${json['id']}') ?? 0,
      kodeBarang: json['kode_barang']?.toString() ?? '',
      namaBarang: json['nama_barang']?.toString() ?? '',
      satuan: json['satuan']?.toString() ?? '',
      stok: double.tryParse('${json['stok']}') ?? 0.0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Mengubah objek BarangModel menjadi JSON untuk dikirim ke backend
  Map<String, dynamic> toJson() {
    return {
      'kode_barang': kodeBarang,
      'nama_barang': namaBarang,
      'satuan': satuan,
    };
  }
}
