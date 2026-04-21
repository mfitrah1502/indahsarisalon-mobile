import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'booking_list_page.dart';
import 'settings_page.dart';
import 'report_page.dart';

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int _selectedIndex = 2;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  bool _loading = true;
  List<String> _categories = ['All'];
  // Each: { td_id, treatment_id, treatment_name, detail_name, display_name, category, duration, price }
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final catData = await Supabase.instance.client
          .from('categories')
          .select('id, name')
          .order('name');

      final svcData = await Supabase.instance.client
          .from('treatment_details')
          .select('id, name, duration, price, treatment_id, treatments(id, name, category_id, categories(id, name))')
          .order('id');

      final cats = ['All', ...List<Map<String, dynamic>>.from(catData).map((c) => c['name'] as String)];

      final services = List<Map<String, dynamic>>.from(svcData).map((td) {
        final treatment = td['treatments'] as Map<String, dynamic>?;
        final category = treatment?['categories'] as Map<String, dynamic>?;
        final treatmentName = treatment?['name'] ?? '';
        final detailName = td['name'] ?? '';
        final displayName = (treatmentName == detailName || detailName.isEmpty)
            ? treatmentName
            : "$treatmentName - $detailName";
        return {
          'td_id': td['id'],
          'treatment_id': td['treatment_id'],
          'treatment_name': treatmentName,
          'detail_name': detailName,
          'display_name': displayName,
          'category': category?['name'] ?? '',
          'duration': td['duration'] ?? 0,
          'price': td['price'] ?? 0,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _categories = cats;
          _services = services;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching services: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    return _services.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = s['display_name'].toString().toLowerCase().contains(q) ||
          s['category'].toString().toLowerCase().contains(q);
      final matchesCat = _selectedCategory == 'All' ||
          s['category'].toString().toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCat;
    }).toList();
  }

  Future<void> _deleteService(Map<String, dynamic> service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Hapus Layanan", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin menghapus \"${service['display_name']}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('treatment_details')
            .delete()
            .eq('id', service['td_id']);
        _fetchAll();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _showServiceDialog({Map<String, dynamic>? service}) {
    final isEdit = service != null;
    final nameController = TextEditingController(text: isEdit ? service['detail_name'] : '');
    final treatmentController = TextEditingController(text: isEdit ? service['treatment_name'] : '');
    final priceController = TextEditingController(text: isEdit ? (service['price'] as num).toInt().toString() : '');
    final durationController = TextEditingController(text: isEdit ? (service['duration'] as num).toInt().toString() : '');
    String selectedCategory = isEdit ? service['category'] : (_categories.length > 1 ? _categories[1] : 'All');

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: StatefulBuilder(
                builder: (ctx, setStateDialog) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEdit ? "Edit Layanan" : "Tambah Layanan Baru",
                        style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEdit ? "Perbarui detail layanan" : "Buat layanan baru untuk klien",
                        style: TextStyle(color: mutedText, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Treatment Name
                      _fieldLabel("NAMA TREATMENT / KATEGORI LAYANAN"),
                      const SizedBox(height: 8),
                      _textField(controller: treatmentController, hint: "e.g. Colouring Uban"),

                      const SizedBox(height: 16),
                      // Detail Name (Variant)
                      _fieldLabel("NAMA DETAIL / VARIAN"),
                      const SizedBox(height: 8),
                      _textField(controller: nameController, hint: "e.g. Short, Medium, Long (boleh kosong)"),

                      const SizedBox(height: 16),
                      // Category Dropdown
                      _fieldLabel("KATEGORI"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _categories.contains(selectedCategory) ? selectedCategory : (_categories.length > 1 ? _categories[1] : _categories[0]),
                            isExpanded: true,
                            icon: Icon(Icons.expand_more, color: mutedText),
                            items: _categories.where((c) => c != 'All').map((String v) {
                              return DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14)));
                            }).toList(),
                            onChanged: (v) => setStateDialog(() => selectedCategory = v!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel("HARGA (Rp)"),
                                const SizedBox(height: 8),
                                _textField(controller: priceController, hint: "150000", numeric: true),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel("DURASI (MENIT)"),
                                const SizedBox(height: 8),
                                _textField(controller: durationController, hint: "60", numeric: true),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            if (treatmentController.text.isEmpty && nameController.text.isEmpty) return;
                            Navigator.pop(ctx);
                            await _saveService(
                              isEdit: isEdit,
                              existingService: service,
                              treatmentName: treatmentController.text,
                              detailName: nameController.text,
                              category: selectedCategory,
                              price: int.tryParse(priceController.text) ?? 0,
                              duration: int.tryParse(durationController.text) ?? 0,
                            );
                          },
                          child: Text(
                            isEdit ? "Simpan Perubahan" : "Tambah Layanan",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text("Batal", style: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fieldLabel(String text) => Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedText, letterSpacing: 0.5));

  Widget _textField({required TextEditingController controller, required String hint, bool numeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: mutedText.withOpacity(0.6), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFE2E8F0).withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _saveService({
    required bool isEdit,
    Map<String, dynamic>? existingService,
    required String treatmentName,
    required String detailName,
    required String category,
    required int price,
    required int duration,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      // Get or create category
      final catResult = await supabase.from('categories').select('id').eq('name', category).maybeSingle();
      int catId;
      if (catResult != null) {
        catId = catResult['id'];
      } else {
        final newCat = await supabase.from('categories').insert({'name': category}).select('id').single();
        catId = newCat['id'];
      }

      if (isEdit && existingService != null) {
        // Update treatment detail
        await supabase.from('treatment_details').update({
          'name': detailName.isEmpty ? treatmentName : detailName,
          'price': price,
          'duration': duration,
        }).eq('id', existingService['td_id']);

        // Also update the treatment name if changed
        await supabase.from('treatments').update({
          'name': treatmentName,
          'category_id': catId,
        }).eq('id', existingService['treatment_id']);
      } else {
        // Get or create treatment
        final treatmentResult = await supabase.from('treatments')
            .select('id').eq('name', treatmentName).eq('category_id', catId).maybeSingle();
        int treatmentId;
        if (treatmentResult != null) {
          treatmentId = treatmentResult['id'];
        } else {
          final newTreatment = await supabase.from('treatments').insert({
            'name': treatmentName,
            'category_id': catId,
          }).select('id').single();
          treatmentId = newTreatment['id'];
        }

        // Create new treatment detail
        await supabase.from('treatment_details').insert({
          'treatment_id': treatmentId,
          'name': detailName.isEmpty ? treatmentName : detailName,
          'price': price,
          'duration': duration,
        });
      }

      _fetchAll();
    } catch (e) {
      debugPrint('Error saving service: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredServices;

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
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false),
                    child: Icon(Icons.arrow_back, color: primaryColor, size: 28),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 28.0),
                        child: Text("Kelola Layanan", style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
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
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          icon: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.search, color: mutedText, size: 20),
                          ),
                          hintText: "Cari layanan...",
                          hintStyle: TextStyle(color: mutedText, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Filters
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final isSelected = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? primaryColor : const Color(0xFFE2E8F0)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : mutedText,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                        onPressed: () => _showServiceDialog(),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text("Tambah Layanan Baru", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Count
                    Text(
                      "${filtered.length} layanan",
                      style: TextStyle(fontSize: 13, color: mutedText, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),

                    // Services List
                    _loading
                        ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                        : filtered.isEmpty
                            ? Center(child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text("Tidak ada layanan.", style: TextStyle(color: mutedText)),
                              ))
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, index) {
                                  final svc = filtered[index];
                                  final price = (svc['price'] as num).toInt();
                                  final dur = (svc['duration'] as num).toInt();

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Category Icon
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE4F0FA),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.content_cut_rounded, size: 20, color: primaryColor),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                svc['display_name'],
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(svc['category'], style: TextStyle(fontSize: 11, color: mutedText)),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  if (dur > 0) ...[
                                                    Icon(Icons.access_time_outlined, size: 13, color: mutedText),
                                                    const SizedBox(width: 3),
                                                    Text("$dur mnt", style: TextStyle(fontSize: 12, color: mutedText)),
                                                    const SizedBox(width: 10),
                                                  ],
                                                  Text(
                                                    _currency.format(price),
                                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: primaryColor),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showServiceDialog(service: svc),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                                child: Icon(Icons.edit_outlined, color: primaryColor, size: 16),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () => _deleteService(svc),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                                                child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, "HOME", Icons.home_filled),
              _buildNavItem(1, "BOOKING", Icons.calendar_today_outlined),
              _buildNavItem(2, "SERVICES", Icons.content_cut_rounded),
              _buildNavItem(3, "REPORT", Icons.bar_chart_rounded),
              _buildNavItem(4, "SETTINGS", Icons.settings_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false);
        else if (index == 1) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BookingListPage()), (r) => false);
        else if (index == 3) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ReportPage()), (r) => false);
        else if (index == 4) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SettingsPage()), (r) => false);
        else setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? primaryColor : mutedText, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isSelected ? primaryColor : mutedText, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
