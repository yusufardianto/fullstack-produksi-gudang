import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/penerimaan_controller.dart';
import '../../models/produksi_model.dart';
import '../../services/api_service.dart';

/// Halaman Form Pencatatan Penerimaan Barang di Gudang
class PenerimaanFormScreen extends StatefulWidget {
  final ProduksiModel? preselectedProduksi;

  const PenerimaanFormScreen({super.key, this.preselectedProduksi});

  @override
  State<PenerimaanFormScreen> createState() => _PenerimaanFormScreenState();
}

class _PenerimaanItemEntry {
  final int barangId;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final double maxJumlah;
  final TextEditingController jumlahController;

  _PenerimaanItemEntry({
    required this.barangId,
    required this.kodeBarang,
    required this.namaBarang,
    required this.satuan,
    required this.maxJumlah,
    required double initialJumlah,
  }) : jumlahController = TextEditingController(text: initialJumlah.toStringAsFixed(0));
}

class _PenerimaanFormScreenState extends State<PenerimaanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomorController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _catatanController = TextEditingController();

  List<ProduksiModel> _completedProduksiList = [];
  bool _isLoadingProduksi = false;
  ProduksiModel? _selectedProduksi;

  List<_PenerimaanItemEntry> _items = [];
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tanggalController.text =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    _initProduksi();
  }

  Future<void> _initProduksi() async {
    setState(() => _isLoadingProduksi = true);
    try {
      if (widget.preselectedProduksi != null) {
        _selectedProduksi = widget.preselectedProduksi;
        _completedProduksiList = [_selectedProduksi!];
        await _loadProduksiItems(_selectedProduksi!.id);
      } else {
        // Ambil daftar produksi yang berstatus 'completed'
        final list = await ApiService.getProduksi(status: 'completed');
        setState(() {
          _completedProduksiList = list;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Gagal Memuat Produksi',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLoadingProduksi = false);
    }
  }

  Future<void> _loadProduksiItems(int produksiId) async {
    setState(() => _isLoadingItems = true);
    try {
      final detail = await ApiService.getProduksiById(produksiId);
      for (var item in _items) {
        item.jumlahController.dispose();
      }
      _items = detail.items.map((i) {
        return _PenerimaanItemEntry(
          barangId: i.barangId,
          kodeBarang: i.kodeBarang,
          namaBarang: i.namaBarang,
          satuan: i.satuan,
          maxJumlah: i.jumlah,
          initialJumlah: i.jumlah,
        );
      }).toList();
    } catch (e) {
      Get.snackbar(
        'Gagal Memuat Item Produksi',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLoadingItems = false);
    }
  }

  @override
  void dispose() {
    _nomorController.dispose();
    _tanggalController.dispose();
    _catatanController.dispose();
    for (var item in _items) {
      item.jumlahController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _tanggalController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit(PenerimaanController controller) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProduksi == null) {
      Get.snackbar(
        'Validasi Gagal',
        'Silakan pilih referensi hasil produksi yang telah berstatus completed',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_items.isEmpty) {
      Get.snackbar(
        'Validasi Gagal',
        'Item barang hasil produksi tidak ditemukan atau kosong',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final itemsPayload = <Map<String, dynamic>>[];
    for (final entry in _items) {
      final qty = double.tryParse(entry.jumlahController.text.trim()) ?? 0;
      if (qty <= 0) {
        Get.snackbar(
          'Validasi Gagal',
          'Jumlah diterima untuk ${entry.namaBarang} harus lebih dari 0',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      itemsPayload.add({
        'barang_id': entry.barangId,
        'jumlah_diterima': qty,
      });
    }

    final success = await controller.createPenerimaan(
      nomorPenerimaan: _nomorController.text.trim().isEmpty ? null : _nomorController.text.trim(),
      hasilProduksiId: _selectedProduksi!.id,
      tanggalPenerimaan: _tanggalController.text.trim(),
      catatan: _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
      items: itemsPayload,
    );

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final penerimaanController = Get.find<PenerimaanController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Penerimaan Gudang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Surat Tanda Terima
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Surat Penerimaan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Pilih Hasil Produksi (Hanya yang Status 'completed')
                      if (_isLoadingProduksi)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: LinearProgressIndicator(),
                        )
                      else if (_completedProduksiList.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade400),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.amber),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Belum ada hasil produksi dengan status "completed". Selesaikan transaksi produksi terlebih dahulu.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<ProduksiModel>(
                          value: _selectedProduksi,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Referensi Hasil Produksi (Completed) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.assignment),
                          ),
                          items: _completedProduksiList.map((p) {
                            return DropdownMenuItem<ProduksiModel>(
                              value: p,
                              child: Text(
                                '${p.nomorProduksi} (${p.tanggalProduksi}) - ${p.totalItem} item',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: widget.preselectedProduksi != null
                              ? null
                              : (val) {
                                  setState(() => _selectedProduksi = val);
                                  if (val != null) {
                                    _loadProduksiItems(val.id);
                                  }
                                },
                        ),
                      const SizedBox(height: 14),

                      // Nomor Penerimaan (Opsional)
                      TextFormField(
                        controller: _nomorController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Penerimaan (Opsional)',
                          hintText: 'Biarkan kosong untuk generate otomatis (RCV-...)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt_long),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tanggal Penerimaan
                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Tanggal Penerimaan *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: _pickDate,
                          ),
                        ),
                        onTap: _pickDate,
                        validator: (val) => val == null || val.isEmpty ? 'Tanggal wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Catatan
                      TextFormField(
                        controller: _catatanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Serah Terima (Opsional)',
                          hintText: 'Misal: Diterima utuh di gudang barang jadi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rincian Item Fisik Masuk
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kuantitas Fisik Barang Diterima',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Anda dapat menyesuaikan jumlah fisik yang diterima sesuai hasil hitungan di gudang.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Divider(height: 20),

                      if (_isLoadingItems)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              _selectedProduksi == null
                                  ? 'Pilih referensi hasil produksi di atas untuk memuat item.'
                                  : 'Tidak ada item dalam produksi ini.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final entry = _items[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.teal.shade50,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.teal.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.namaBarang,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          'Diproduksi: ${entry.maxJumlah.toStringAsFixed(0)} ${entry.satuan}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: entry.jumlahController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Diterima',
                                        suffixText: entry.satuan,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (val) {
                                        final n = double.tryParse(val ?? '');
                                        if (n == null || n <= 0) return 'Harus > 0';
                                        if (n > entry.maxJumlah) return 'Maks ${entry.maxJumlah}';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Submit
              Obx(() => ElevatedButton.icon(
                    onPressed: penerimaanController.isLoading.value
                        ? null
                        : () => _submit(penerimaanController),
                    icon: penerimaanController.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      penerimaanController.isLoading.value
                          ? 'Menyimpan Penerimaan...'
                          : 'Simpan Dokumen Penerimaan (Draft)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
