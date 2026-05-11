import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/service_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddPromoPage extends StatefulWidget {
  const AddPromoPage({super.key});

  @override
  State<AddPromoPage> createState() => _AddPromoPageState();
}

class _AddPromoPageState extends State<AddPromoPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  bool _loading = false;
  bool _isPromoActive = true;
  
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ServiceController _serviceController = ServiceController();

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() => _imageFile = picked);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil gambar: $e")),
        );
      }
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        setState(() {
          if (isStart) {
            _startDate = pickedDate;
            _startTime = pickedTime;
          } else {
            _endDate = pickedDate;
            _endTime = pickedTime;
          }
        });
      }
    }
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return "Pilih Waktu";
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  Future<void> _savePromo() async {
    if (_titleController.text.isEmpty || 
        _priceController.text.isEmpty || 
        _startDate == null || 
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap lengkapi semua data")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
      final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute);

      String? uploadedUrl;
      if (_imageFile != null) {
        try {
          final bytes = await _imageFile!.readAsBytes();
          final ext = _imageFile!.name.split('.').last;
          final fileName = 'promo_${DateTime.now().millisecondsSinceEpoch}.$ext';
          uploadedUrl = await _serviceController.uploadImage(bytes, fileName, 'promos');
        } catch (uploadError) {
          debugPrint("Upload process failed: $uploadError");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Gagal upload gambar: $uploadError. Pastikan bucket 'treatments' sudah ada.")),
            );
          }
          // Continue saving without image if upload fails, or return if you want to force image
        }
      }

      final supabase = Supabase.instance.client;

      // 1. Dapatkan ID kategori 'Promo'
      final catResult = await supabase
          .from('categories')
          .select('id')
          .eq('name', 'Promo')
          .maybeSingle();
      
      int? promoCategoryId = catResult?['id'];

      // 2. Insert ke tabel promos (untuk manajemen promo/banner)
      final Map<String, dynamic> promoData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'start_at': start.toIso8601String(),
        'end_at': end.toIso8601String(),
        'is_active': _isPromoActive,
      };
      
      try {
        if (uploadedUrl != null) promoData['image_url'] = uploadedUrl;
        await supabase.from('promos').insert(promoData);
      } catch (e) {
        if (e.toString().contains("image_url")) {
          promoData.remove('image_url');
          await supabase.from('promos').insert(promoData);
        } else {
          rethrow;
        }
      }

      // 3. Insert ke tabel treatments & treatment_details agar muncul di daftar layanan
      if (promoCategoryId != null) {
        final Map<String, dynamic> treatData = {
          'name': _titleController.text,
          'category_id': promoCategoryId,
          'is_promo': true,
          'promo_type': 'Fixed',
          'promo_value': double.tryParse(_priceController.text) ?? 0.0,
        };
        
        int? treatmentId;
        try {
          if (uploadedUrl != null) treatData['image'] = uploadedUrl;
          final res = await supabase.from('treatments').insert(treatData).select('id').single();
          treatmentId = res['id'];
        } catch (e) {
          treatData.remove('image');
          final res = await supabase.from('treatments').insert(treatData).select('id').single();
          treatmentId = res['id'];
        }

        final Map<String, dynamic> detailData = {
          'treatment_id': treatmentId,
          'name': _titleController.text,
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'duration': 60,
          'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : 'Promo: ${_titleController.text}',
        };

        try {
          if (uploadedUrl != null) detailData['image_url'] = uploadedUrl;
          await supabase.from('treatment_details').insert(detailData);
        } catch (e) {
          if (e.toString().contains("image_url")) {
            detailData.remove('image_url');
            await supabase.from('treatment_details').insert(detailData);
          } else {
            rethrow;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Promo berhasil ditambahkan ke Layanan!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error saving promo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan promo: $e")),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Tambah Promo Baru",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    
                    // Banner Preview
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _imageFile != null 
                            ? (kIsWeb 
                                ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                                : Image.file(
                                    File(_imageFile!.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, _, __) => const Icon(Icons.error),
                                  ))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: primaryColor, size: 40),
                                  const SizedBox(height: 8),
                                  Text("Klik untuk upload banner", style: TextStyle(color: mutedText, fontSize: 13)),
                                ],
                              ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Inputs
                    _fieldLabel("JUDUL PROMO"),
                    const SizedBox(height: 8),
                    _textField(controller: _titleController, hint: "e.g. Ramadhan Sale 50%"),

                    const SizedBox(height: 20),
                    _fieldLabel("ISI TREATMENT (BUNDLING)"),
                    const SizedBox(height: 8),
                    _textField(controller: _descriptionController, hint: "e.g. Haircut + Creambath + Wash", maxLines: 3),

                    const SizedBox(height: 20),
                    _fieldLabel("HARGA PROMO (RP)"),
                    const SizedBox(height: 8),
                    _textField(controller: _priceController, hint: "99000", numeric: true),

                    const SizedBox(height: 24),

                    // Date Pickers
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel("STARTS"),
                              const SizedBox(height: 8),
                              _dateBox(
                                text: _formatDateTime(_startDate, _startTime),
                                icon: Icons.calendar_today_outlined,
                                onTap: () => _selectDateTime(context, true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel("ENDS"),
                              const SizedBox(height: 8),
                              _dateBox(
                                text: _formatDateTime(_endDate, _endTime),
                                icon: Icons.event_available_outlined,
                                onTap: () => _selectDateTime(context, false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Status Switch
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flash_on, color: primaryColor, size: 20),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Status Promo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text("Aktfkan agar muncul di halaman promo", style: TextStyle(color: mutedText, fontSize: 12)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPromoActive,
                            onChanged: (val) => setState(() => _isPromoActive = val),
                            activeColor: primaryColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        onPressed: _loading ? null : _savePromo,
                        child: _loading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Buat Promo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedText, letterSpacing: 1.0));

  Widget _textField({required TextEditingController controller, required String hint, bool numeric = false, Function(String)? onChanged, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : [],
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: mutedText.withOpacity(0.5), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _dateBox({required String text, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(color: text == "Pilih Waktu" ? mutedText : Colors.black, fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}
