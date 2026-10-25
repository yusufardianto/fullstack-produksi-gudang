import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/barang_model.dart';
import '../models/produksi_model.dart';
import '../models/penerimaan_model.dart';
import '../models/stok_model.dart';

/// Service untuk menangani seluruh komunikasi HTTP ke backend Express.js.
class ApiService {
  /// Base URL backend.
  /// Otomatis mendeteksi Android Emulator (10.0.2.2) vs Web/Desktop (localhost).
  /// Dapat diubah sewaktu-waktu sesuai kebutuhan IP jaringan.
  static String baseUrl = _resolveDefaultBaseUrl();

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api';
      }
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  /// Timeout standar untuk request HTTP (10 detik)
  static const Duration _timeout = Duration(seconds: 10);

  /// Header default format JSON
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ===========================================================================
  // HELPER INTERNAL: PARSING RESPONS & ERROR HANDLING
  // ===========================================================================

  /// Memproses respons HTTP dan memverifikasi status kode & field `success`.
  static dynamic _processResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Format respons dari server tidak valid (Status HTTP: ${response.statusCode})',
      );
    }

    // Jika HTTP status bukan 2xx atau success == false
    final isHttpSuccess = response.statusCode >= 200 && response.statusCode < 300;
    final isApiSuccess = body['success'] == true;

    if (!isHttpSuccess || !isApiSuccess) {
      String errorMessage = body['message']?.toString() ?? 'Terjadi kesalahan pada server';

      // Jika ada rincian array validasi express-validator
      if (body['errors'] is List && (body['errors'] as List).isNotEmpty) {
        final errorList = body['errors'] as List;
        final details = errorList
            .map((e) => e is Map ? e['message']?.toString() : e.toString())
            .where((msg) => msg != null && msg.isNotEmpty)
            .join(', ');
        if (details.isNotEmpty) {
          errorMessage = '$errorMessage: $details';
        }
      }

      throw Exception(errorMessage);
    }

    return body['data'];
  }

  /// Membungkus eksekusi HTTP dengan penanganan koneksi & timeout yang ramah
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SocketException {
      throw Exception(
        'Gagal terhubung ke server ($baseUrl). Pastikan backend Express & database MySQL sudah aktif.',
      );
    } on TimeoutException {
      throw Exception(
        'Koneksi ke server timeout (waktu tunggu habis). Periksa koneksi backend Anda.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Kendala komunikasi jaringan: ${e.message}. Pastikan URL server benar.',
      );
    } catch (e) {
      // Re-throw exception yang sudah diformat
      rethrow;
    }
  }

  // ===========================================================================
  // 1. HEALTH CHECK
  // ===========================================================================

  static Future<bool> checkHealth() async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/health');
      final res = await http.get(uri).timeout(_timeout);
      final data = _processResponse(res);
      return data != null && data['status'] == 'OK';
    });
  }

  // ===========================================================================
  // 2. MODUL MASTER BARANG
  // ===========================================================================

  /// Mengambil daftar seluruh barang (opsional filter search atau is_active)
  static Future<List<BarangModel>> getBarang({String? search, bool? isActive}) async {
    return _guard(() async {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive ? '1' : '0';
      }

      final uri = Uri.parse('$baseUrl/barang').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = _processResponse(res) as List;
      return data.map((item) => BarangModel.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// Mengambil detail satu barang berdasarkan ID
  static Future<BarangModel> getBarangById(int id) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/barang/$id');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return BarangModel.fromJson(data);
    });
  }

  /// Menambah master barang baru
  static Future<BarangModel> createBarang({
    required String kodeBarang,
    required String namaBarang,
    required String satuan,
  }) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/barang');
      final payload = jsonEncode({
        'kode_barang': kodeBarang.trim(),
        'nama_barang': namaBarang.trim(),
        'satuan': satuan.trim(),
      });
      final res = await http.post(uri, headers: _headers, body: payload).timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return BarangModel.fromJson(data);
    });
  }

  /// Mengubah nama dan satuan barang
  static Future<BarangModel> updateBarang({
    required int id,
    required String namaBarang,
    required String satuan,
  }) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/barang/$id');
      final payload = jsonEncode({
        'nama_barang': namaBarang.trim(),
        'satuan': satuan.trim(),
      });
      final res = await http.put(uri, headers: _headers, body: payload).timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return BarangModel.fromJson(data);
    });
  }

  /// Mengubah status aktif/nonaktif barang
  static Future<BarangModel> toggleStatusBarang({
    required int id,
    required bool isActive,
  }) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/barang/$id/status');
      final payload = jsonEncode({'is_active': isActive});
      final res = await http.patch(uri, headers: _headers, body: payload).timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return BarangModel.fromJson(data);
    });
  }

  // ===========================================================================
  // 3. MODUL HASIL PRODUKSI
  // ===========================================================================

  /// Mengambil daftar hasil produksi (opsional filter status & search)
  static Future<List<ProduksiModel>> getProduksi({String? status, String? search}) async {
    return _guard(() async {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/produksi').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = _processResponse(res) as List;
      return data.map((item) => ProduksiModel.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// Mengambil detail satu hasil produksi beserta item-itemnya
  static Future<ProduksiModel> getProduksiById(int id) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/produksi/$id');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return ProduksiModel.fromJson(data);
    });
  }

  /// Membuat transaksi hasil produksi baru
  static Future<ProduksiModel> createProduksi({
    String? nomorProduksi,
    required String tanggalProduksi,
    String? catatan,
    required List<Map<String, dynamic>> items,
  }) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/produksi');
      final payloadMap = <String, dynamic>{
        'tanggal_produksi': tanggalProduksi,
        'items': items,
      };
      if (nomorProduksi != null && nomorProduksi.trim().isNotEmpty) {
        payloadMap['nomor_produksi'] = nomorProduksi.trim();
      }
      if (catatan != null && catatan.trim().isNotEmpty) {
        payloadMap['catatan'] = catatan.trim();
      }

      final res = await http
          .post(uri, headers: _headers, body: jsonEncode(payloadMap))
          .timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return ProduksiModel.fromJson(data);
    });
  }

  /// Mengubah status hasil produksi ('completed' atau 'cancelled')
  static Future<ProduksiModel> updateStatusProduksi({
    required int id,
    required String status,
  }) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/produksi/$id/status');
      final payload = jsonEncode({'status': status});
      final res = await http.patch(uri, headers: _headers, body: payload).timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return ProduksiModel.fromJson(data);
    });
  }

  // ===========================================================================
  // 4. MODUL PENERIMAAN GUDANG
  // ===========================================================================

  /// Mengambil daftar transaksi penerimaan barang di gudang
  static Future<List<PenerimaanModel>> getPenerimaan({String? status, String? search}) async {
    return _guard(() async {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/penerimaan').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = _processResponse(res) as List;
      return data.map((item) => PenerimaanModel.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// Mengambil detail satu penerimaan gudang beserta daftar itemnya
  static Future<PenerimaanModel> getPenerimaanById(int id) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/penerimaan/$id');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return PenerimaanModel.fromJson(data);
    });
  }

  /// Mencatat transaksi penerimaan baru dari hasil produksi yang sudah completed
  static Future<PenerimaanModel> createPenerimaan({
    String? nomorPenerimaan,
    required int hasilProduksiId,
    required String tanggalPenerimaan,
    String? catatan,
    List<Map<String, dynamic>>? items,
  }) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/penerimaan');
      final payloadMap = <String, dynamic>{
        'hasil_produksi_id': hasilProduksiId,
        'tanggal_penerimaan': tanggalPenerimaan,
      };
      if (nomorPenerimaan != null && nomorPenerimaan.trim().isNotEmpty) {
        payloadMap['nomor_penerimaan'] = nomorPenerimaan.trim();
      }
      if (catatan != null && catatan.trim().isNotEmpty) {
        payloadMap['catatan'] = catatan.trim();
      }
      if (items != null && items.isNotEmpty) {
        payloadMap['items'] = items;
      }

      final res = await http
          .post(uri, headers: _headers, body: jsonEncode(payloadMap))
          .timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return PenerimaanModel.fromJson(data);
    });
  }

  /// Mengubah status penerimaan ('confirmed' atau 'cancelled')
  static Future<PenerimaanModel> updateStatusPenerimaan({
    required int id,
    required String status,
  }) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/penerimaan/$id/status');
      final payload = jsonEncode({'status': status});
      final res = await http.patch(uri, headers: _headers, body: payload).timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return PenerimaanModel.fromJson(data);
    });
  }

  // ===========================================================================
  // 5. MODUL STOK & MUTASI GUDANG
  // ===========================================================================

  /// Mengambil ringkasan saldo stok seluruh barang
  static Future<List<StokModel>> getStok({String? search}) async {
    return _guard(() async {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/stok').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = _processResponse(res) as List;
      return data.map((item) => StokModel.fromJson(item as Map<String, dynamic>)).toList();
    });
  }

  /// Mengambil detail stok barang tertentu beserta kartu audit mutasi
  static Future<StokDetailModel> getStokByBarangId(int barangId) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/stok/$barangId');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      final data = _processResponse(res) as Map<String, dynamic>;
      return StokDetailModel.fromJson(data);
    });
  }
}
