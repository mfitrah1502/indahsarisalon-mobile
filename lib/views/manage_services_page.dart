import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../app_session.dart';
import '../controllers/service_controller.dart';
import '../models/service_model.dart';
import '../utils/popup_helper.dart';
import 'add_promo_page.dart';
import 'booking_list_page.dart';
import 'home_page.dart';
import 'report_page.dart';
import 'settings_page.dart';

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  bool get isDark => AppSession.isDarkMode;
  Color get primaryColor => const Color(0xFFD660A1);
  Color get buttonColor => const Color(0xFFB53D7C);
  Color get scaffoldBg => isDark ? const Color(0xFF1E293B) : const Color(0xFFF6F8FA);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get cardBg => isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get mainTextColor => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A);
  Color get inputBg => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0).withValues(alpha: 0.5);
  Color get inputBorderColor => isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  int _selectedIndex = 2;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  bool _loading = true;
  List<String> _categories = ['All'];
  List<ServiceModel> _services = [];
  final ServiceController _serviceController = ServiceController();

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final data = await _serviceController.fetchServicesAndCategories();
      if (mounted) {
        setState(() {
          _categories = data['categories'] as List<String>;
          _services = data['services'] as List<ServiceModel>;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching services: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ServiceModel> get _filteredServices {
    return _services.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          s.displayName.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q);
      final matchesCat =
          _selectedCategory == 'All' ||
          s.category.toLowerCase() == _selectedCategory.toLowerCase();

      // Hide inactive services (Soft Deleted)
      if (!s.isActive) return false;

      return matchesSearch && matchesCat;
    }).toList();
  }

  Future<void> _deleteService(ServiceModel service) async {
    PopupHelper.showConfirm(
      context,
      title: "Delete Service",
      message:
          "${"Are you sure you want to delete"} \"${service.displayName}\"?",
      onConfirm: () async {
        try {
          await _serviceController.deleteService(service.tdId);
          _fetchAll();
        } catch (e) {
          String errorMsg = "Failed to delete: $e";
          if (e.toString().contains("violates foreign key constraint")) {
            errorMsg =
                "This service cannot be deleted because it has booking history. Please contact admin to disable it via database.";
          }
          if (mounted) PopupHelper.showError(context, errorMsg);
        }
      },
    );
  }

  void _showPromoEditDialog(ServiceModel service) async {
    setState(() => _loading = true);
    final promo = await _serviceController.fetchPromoDetails(service.promoId!);
    setState(() => _loading = false);

    if (promo == null) return;

    DateTime startAt = DateTime.parse(promo['start_at']);
    DateTime endAt = DateTime.parse(promo['end_at']);
    bool isActive = promo['is_active'];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Edit Promo",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Status Switch
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: inputBorderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Status Promo",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: mainTextColor,
                                ),
                              ),
                              Text(
                                isActive ? "Aktif" : "Nonaktif",
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: isActive,
                            onChanged: (val) =>
                                setStateDialog(() => isActive = val),
                            activeThumbColor: primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Start Date
                    _fieldLabel("WAKTU MULAI"),
                    const SizedBox(height: 8),
                    _dateBox(
                      text: DateFormat('dd MMM yyyy, HH:mm').format(startAt),
                      icon: Icons.calendar_today,
                      onTap: () async {
                        final picked = await _selectDateTimeQuick(ctx, startAt);
                        if (picked != null) {
                          setStateDialog(() => startAt = picked);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // End Date
                    _fieldLabel("WAKTU SELESAI"),
                    const SizedBox(height: 8),
                    _dateBox(
                      text: DateFormat('dd MMM yyyy, HH:mm').format(endAt),
                      icon: Icons.calendar_today,
                      onTap: () async {
                        final picked = await _selectDateTimeQuick(ctx, endAt);
                        if (picked != null) {
                          setStateDialog(() => endAt = picked);
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _serviceController.updatePromoStatus(
                            promoId: service.promoId!,
                            isActive: isActive,
                            startAt: startAt,
                            endAt: endAt,
                          );
                          _fetchAll();
                        },
                        child: Text(
                          "Save Changes",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _selectDateTimeQuick(
    BuildContext context,
    DateTime initial,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: const Color(0xFFD660A1),
                  onPrimary: Colors.white,
                  surface: cardBg,
                  onSurface: mainTextColor,
                )
              : ColorScheme.light(
                  primary: const Color(0xFFD660A1),
                  onPrimary: Colors.white,
                  onSurface: const Color(0xFFD660A1),
                ),
        ),
        child: child!,
      ),
    );

    if (date != null) {
      if (!context.mounted) return null;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
        initialEntryMode: TimePickerEntryMode.input, // Text input, no dial
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: const Color(0xFFD660A1),
                    onPrimary: Colors.white,
                    surface: cardBg,
                    onSurface: mainTextColor,
                  )
                : ColorScheme.light(
                    primary: const Color(0xFFD660A1),
                    onPrimary: Colors.white,
                    onSurface: const Color(0xFFD660A1),
                  ),
          ),
          child: child!,
        ),
      );
      if (time != null) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }
    return null;
  }

  Widget _dateBox({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: inputBorderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mainTextColor,
                ),
              ),
            ),
            Icon(Icons.edit, size: 14, color: mutedText),
          ],
        ),
      ),
    );
  }

  void _showServiceDialog({ServiceModel? service}) {
    if (service?.isPromo == true && service?.promoId != null) {
      _showPromoEditDialog(service!);
      return;
    }

    final isEdit = service != null;
    final nameController = TextEditingController(
      text: isEdit ? service.detailName : '',
    );
    final treatmentController = TextEditingController(
      text: isEdit ? service.treatmentName : '',
    );
    final priceController = TextEditingController(
      text: isEdit ? service.price.toString() : '',
    );
    final durationController = TextEditingController(
      text: isEdit ? service.duration.toString() : '',
    );
    String selectedCategory = isEdit
        ? service.category
        : (_categories.length > 1 ? _categories[1] : 'All');

    XFile? dialogImage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEdit ? "Edit Service" : "Add New Service",
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEdit
                            ? "Update service details"
                            : "Create new service for clients",
                        style: TextStyle(color: mutedText, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Image Picker
                      GestureDetector(
                        onTap: () async {
                          try {
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                            );
                            if (picked != null) {
                              setStateDialog(() => dialogImage = picked);
                            }
                          } catch (e) {
                            debugPrint("Error picking image: $e");
                            if (ctx.mounted) {
                              PopupHelper.showError(
                                ctx,
                                "Failed to capture image: $e",
                              );
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: inputBorderColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: dialogImage != null
                                ? (kIsWeb
                                      ? Image.network(
                                          dialogImage!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(dialogImage!.path),
                                          fit: BoxFit.cover,
                                        ))
                                : (isEdit && service.imageUrl != null)
                                ? Image.network(
                                    service.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        Icon(Icons.add_a_photo, size: 30, color: primaryColor),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        color: primaryColor,
                                        size: 30,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Add Service Photo",
                                        style: TextStyle(
                                          color: mutedText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Treatment Name
                      _fieldLabel("TREATMENT NAME / SERVICE CATEGORY"),
                      const SizedBox(height: 8),
                      _textField(
                        controller: treatmentController,
                        hint: "e.g. Grey Hair Colouring",
                      ),

                      const SizedBox(height: 16),
                      // Detail Name (Variant)
                      _fieldLabel("DETAIL NAME / VARIANT"),
                      const SizedBox(height: 8),
                      _textField(
                        controller: nameController,
                        hint: "e.g. Short, Medium, Long (optional)",
                      ),

                      const SizedBox(height: 16),
                      // Category Dropdown
                      _fieldLabel("CATEGORY"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: cardBg,
                            value: _categories.contains(selectedCategory)
                                ? selectedCategory
                                : (_categories.length > 1
                                      ? _categories[1]
                                      : _categories[0]),
                            isExpanded: true,
                            icon: Icon(Icons.expand_more, color: mutedText),
                            items: _categories.where((c) => c != 'All').map((
                              String v,
                            ) {
                              return DropdownMenuItem(
                                value: v,
                                child: Text(
                                  v,
                                  style: TextStyle(fontSize: 14, color: mainTextColor),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setStateDialog(() => selectedCategory = v!),
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
                                _fieldLabel("PRICE (Rp)"),
                                const SizedBox(height: 8),
                                _textField(
                                  controller: priceController,
                                  hint: "150000",
                                  numeric: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel("DURATION (MINUTES)"),
                                const SizedBox(height: 8),
                                _textField(
                                  controller: durationController,
                                  hint: "60",
                                  numeric: true,
                                ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            if (treatmentController.text.isEmpty &&
                                nameController.text.isEmpty) {
                              return;
                            }
                            Navigator.pop(ctx);

                            String? imageUrl;
                            if (dialogImage != null) {
                              final bytes = await dialogImage!.readAsBytes();
                              final ext = dialogImage!.name.split('.').last;
                              final fileName =
                                  'svc_${DateTime.now().millisecondsSinceEpoch}.$ext';
                              imageUrl = await _serviceController.uploadImage(
                                bytes,
                                fileName,
                                'services',
                              );
                            }

                            await _saveService(
                              isEdit: isEdit,
                              existingService: service,
                              treatmentName: treatmentController.text,
                              detailName: nameController.text,
                              category: selectedCategory,
                              price: int.tryParse(priceController.text) ?? 0,
                              duration:
                                  int.tryParse(durationController.text) ?? 0,
                              imageUrl: imageUrl,
                            );
                          },
                          child: Text(
                            isEdit ? "Save Changes" : "Add Service",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: mutedText,
      letterSpacing: 0.5,
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool numeric = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : [],
      style: TextStyle(color: mainTextColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: mutedText.withValues(alpha: 0.6), fontSize: 14),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Future<void> _saveService({
    required bool isEdit,
    ServiceModel? existingService,
    required String treatmentName,
    required String detailName,
    required String category,
    required int price,
    required int duration,
    String? imageUrl,
  }) async {
    try {
      await _serviceController.saveService(
        isEdit: isEdit,
        existingService: existingService,
        treatmentName: treatmentName,
        detailName: detailName,
        category: category,
        price: price,
        duration: duration,
        imageUrl: imageUrl,
      );
      _fetchAll();
    } catch (e) {
      debugPrint('Error saving service: $e');
      if (mounted) PopupHelper.showError(context, "Failed to save: $e");
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Center(
                child: Text(
                  "Manage Services",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(color: mainTextColor),
                        decoration: InputDecoration(
                          icon: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.search,
                              color: mutedText,
                              size: 20,
                            ),
                          ),
                          hintText: "Search services...",
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
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final isSelected = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : inputBorderColor,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? (isDark ? const Color(0xFF0F172A) : Colors.white) : mutedText,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add Service Button
                    if (AppSession.userRole == 'owner') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                          ),
                          onPressed: () => _showServiceDialog(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Add New Service",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Add Promo Button
                    if (AppSession.userRole == 'owner') ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD660A1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddPromoPage(),
                              ),
                            );
                            if (updated == true && mounted) _fetchAll();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                color: const Color(0xFFD660A1),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Add Promo",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD660A1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Count
                    Text(
                      "${filtered.length}${" services"}",
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Services List
                    _loading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                "No services.",
                                style: TextStyle(color: mutedText),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final svc = filtered[index];
                              final price = svc.price;
                              final dur = svc.duration;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Category Icon / Service Image
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE4F0FA),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: svc.imageUrl != null
                                            ? Image.network(
                                                svc.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    Icon(
                                                      Icons.content_cut_rounded,
                                                      size: 20,
                                                      color: primaryColor,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.content_cut_rounded,
                                                size: 20,
                                                color: primaryColor,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            svc.displayName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            svc.category,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: mutedText,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              if (dur > 0) ...[
                                                Icon(
                                                  Icons.access_time_outlined,
                                                  size: 13,
                                                  color: mutedText,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  "$dur${" min"}",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: mutedText,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                              ],
                                              Text(
                                                _currency.format(price),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (AppSession.userRole == 'owner')
                                      Column(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showServiceDialog(
                                              service: svc,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Icons.edit_outlined,
                                                color: primaryColor,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () => _deleteService(svc),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Color(0xFFDC2626),
                                                size: 16,
                                              ),
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
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
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
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (r) => false,
          );
        } else if (index == 1) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BookingListPage()),
            (r) => false,
          );
        } else if (index == 3) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ReportPage()),
            (r) => false,
          );
        } else if (index == 4) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
            (r) => false,
          );
        } else {
          setState(() => _selectedIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? primaryColor : mutedText, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isSelected ? primaryColor : mutedText,
              letterSpacing: 0.5,
            ),
          ),
        const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
