import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/barang_controller.dart';
import '../../controllers/produksi_controller.dart';
import '../../models/barang_model.dart';

/// Halaman Form Pembuatan Transaksi Hasil Produksi Baru
class ProduksiFormScreen extends StatefulWidget {
  const ProduksiFormScreen({super.key});

  @override
  State<ProduksiFormScreen> createState() => _ProduksiFormScreenState();
}

class _ItemEntry {
  BarangModel? barang;
  final TextEditingController jumlahController = TextEditingController();

  _ItemEntry({String jumlah = '1'}) {
    jumlahController.text = jumlah;
  }
}

class _ProduksiFormScreenState extends State<ProduksiFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomorController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _catatanController = TextEditingController();

  final List<_ItemEntry> _items = [];

  @override
  void initState() {
    super.initState();
    // Default tanggal hari ini (YYYY-MM-DD)
    final now = DateTime.now();
    _tanggalController.text =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Pastikan controller barang sudah aktif dan data termuat
    final barangController = Get.put(BarangController());
    if (barangController.barangList.isEmpty) {
      barangController.fetchBarang();
    }

    // Mulai dengan 1 baris item kosong
    _items.add(_ItemEntry());
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

  void _addItem() {
    setState(() {
      _items.add(_ItemEntry());
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
      Get.snackbar(
        'Perhatian',
        'Minimal harus ada 1 item barang yang diproduksi',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() {
      _items[index].jumlahController.dispose();
      _items.removeAt(index);
    });
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

  Future<void> _submit(ProduksiController controller) async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi kelengkapan item
    final selectedBarangIds = <int>{};
    final itemsPayload = <Map<String, dynamic>>[];

    for (int i = 0; i < _items.length; i++) {
      final entry = _items[i];
      if (entry.barang == null) {
        Get.snackbar(
          'Validasi Gagal',
          'Silakan pilih barang untuk baris ke-${i + 1}',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (selectedBarangIds.contains(entry.barang!.id)) {
        Get.snackbar(
          'Validasi Gagal',
          'Barang "${entry.barang!.namaBarang}" dipilih lebih dari satu kali',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      selectedBarangIds.add(entry.barang!.id);

      final qty = double.tryParse(entry.jumlahController.text.trim()) ?? 0;
      if (qty <= 0) {
        Get.snackbar(
          'Validasi Gagal',
          'Jumlah untuk "${entry.barang!.namaBarang}" harus lebih besar dari 0',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      itemsPayload.add({
        'barang_id': entry.barang!.id,
        'jumlah': qty,
      });
    }

    final success = await controller.createProduksi(
      nomorProduksi: _nomorController.text.trim().isEmpty ? null : _nomorController.text.trim(),
      tanggalProduksi: _tanggalController.text.trim(),
      catatan: _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
      items: itemsPayload,
    );

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final produksiController = Get.find<ProduksiController>();
    final barangController = Get.put(BarangController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Hasil Produksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Transaksi Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Header Transaksi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Nomor Produksi (Opsional)
                      TextFormField(
                        controller: _nomorController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Produksi (Opsional)',
                          hintText: 'Biarkan kosong untuk generate otomatis (PRD-...)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tanggal Produksi
                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Tanggal Produksi *',
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
                          labelText: 'Catatan Produksi (Opsional)',
                          hintText: 'Misal: Shift 1, Batch pencetakan mesin A',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rincian Item Barang
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Item Barang yang Diproduksi *',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Tambah Baris'),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      Obx(() {
                        final activeBarang =
                            barangController.barangList.where((b) => b.isActive).toList();

                        if (barangController.isLoading.value && activeBarang.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (activeBarang.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Tidak ada data barang aktif. Silakan tambahkan barang di modul Master Barang terlebih dahulu.',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        return Column(
                          children: List.generate(_items.length, (index) {
                            final entry = _items[index];
                            return _buildItemRow(index, entry, activeBarang);
                          }),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Submit
              Obx(() => ElevatedButton.icon(
                    onPressed: produksiController.isLoading.value
                        ? null
                        : () => _submit(produksiController),
                    icon: produksiController.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      produksiController.isLoading.value
                          ? 'Menyimpan Produksi...'
                          : 'Simpan Dokumen Produksi',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, _ItemEntry entry, List<BarangModel> activeBarang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '#${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              // Dropdown Barang
              Expanded(
                child: DropdownButtonFormField<BarangModel>(
                  value: entry.barang,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Barang',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: activeBarang.map((b) {
                    return DropdownMenuItem<BarangModel>(
                      value: b,
                      child: Text(
                        '${b.kodeBarang} - ${b.namaBarang}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      entry.barang = val;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Hapus Item',
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 28),
              Expanded(
                child: TextFormField(
                  controller: entry.jumlahController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Jumlah Produksi',
                    suffixText: entry.barang?.satuan ?? 'satuan',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    final n = double.tryParse(val ?? '');
                    if (n == null || n <= 0) {
                      return 'Harus > 0';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
