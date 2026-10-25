import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/barang_controller.dart';
import '../../models/barang_model.dart';

/// Halaman Form Tambah / Edit Data Master Barang
class BarangFormScreen extends StatefulWidget {
  final BarangModel? barangToEdit;

  const BarangFormScreen({super.key, this.barangToEdit});

  @override
  State<BarangFormScreen> createState() => _BarangFormScreenState();
}

class _BarangFormScreenState extends State<BarangFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kodeController = TextEditingController();
  final _namaController = TextEditingController();
  final _satuanController = TextEditingController();

  bool get isEditing => widget.barangToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _kodeController.text = widget.barangToEdit!.kodeBarang;
      _namaController.text = widget.barangToEdit!.namaBarang;
      _satuanController.text = widget.barangToEdit!.satuan;
    }
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _satuanController.dispose();
    super.dispose();
  }

  Future<void> _submit(BarangController controller) async {
    if (!_formKey.currentState!.validate()) return;

    bool success;
    if (isEditing) {
      success = await controller.updateBarang(
        id: widget.barangToEdit!.id,
        namaBarang: _namaController.text.trim(),
        satuan: _satuanController.text.trim(),
      );
    } else {
      success = await controller.createBarang(
        kodeBarang: _kodeController.text.trim(),
        namaBarang: _namaController.text.trim(),
        satuan: _satuanController.text.trim(),
      );
    }

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BarangController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Data Barang' : 'Tambah Master Barang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: Colors.blue.shade50,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEditing
                              ? 'Kode barang bersifat permanen dan tidak dapat diubah.'
                              : 'Kode barang harus unik dan tidak boleh sama dengan barang lain.',
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Field Kode Barang
              TextFormField(
                controller: _kodeController,
                enabled: !isEditing,
                decoration: InputDecoration(
                  labelText: 'Kode Barang *',
                  hintText: 'Contoh: BRG-001',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                  filled: isEditing,
                  fillColor: isEditing ? Colors.grey.shade100 : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Kode barang wajib diisi';
                  }
                  if (val.trim().length > 50) {
                    return 'Kode barang maksimal 50 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Nama Barang
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang *',
                  hintText: 'Contoh: Pipa PVC AW 1/2 Inch',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama barang wajib diisi';
                  }
                  if (val.trim().length > 255) {
                    return 'Nama barang maksimal 255 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Satuan
              TextFormField(
                controller: _satuanController,
                decoration: const InputDecoration(
                  labelText: 'Satuan Barang *',
                  hintText: 'Contoh: batang, pcs, box, kg',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Satuan barang wajib diisi';
                  }
                  if (val.trim().length > 50) {
                    return 'Satuan maksimal 50 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Tombol Simpan
              Obx(() => ElevatedButton.icon(
                    onPressed: controller.isLoading.value ? null : () => _submit(controller),
                    icon: controller.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      controller.isLoading.value
                          ? 'Menyimpan...'
                          : (isEditing ? 'Perbarui Barang' : 'Simpan Barang'),
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
}
