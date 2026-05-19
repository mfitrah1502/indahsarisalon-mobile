import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../controllers/user_controller.dart';
import '../models/service_model.dart';
import '../controllers/service_controller.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'booking_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'report_page.dart';

class SelectServicesPage extends StatefulWidget {
  const SelectServicesPage({super.key});

  @override
  State<SelectServicesPage> createState() => _SelectServicesPageState();
}

class _SelectServicesPageState extends State<SelectServicesPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF4F7F9);
  final Color mutedText = const Color(0xFF64748B);
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  int _selectedIndex = 1;
  String _selectedCategory = 'All';
  String _selectedStaffCategory = 'All';
  String _searchQuery = '';

  bool _loadingCategories = true;
  bool _loadingServices = true;
  List<String> _categories = ['All'];

  List<Map<String, dynamic>> _allServices = [];
  final ServiceController _serviceController = ServiceController();

  // Date Fields
  int _selectedDateIndex = 0;
  late final List<Map<String, dynamic>> _dates;

  // Stylist Fields
  int _selectedStylistIndex = -1;
  bool _loadingStylists = true;
  List<UserModel> _stylists = [];
  final UserController _userController = UserController();

  @override
  void initState() {
    super.initState();
    _buildDates();
    _fetchStylists();
    _fetchCategoriesAndServices();
  }

  void _buildDates() {
    final now = DateTime.now();
    _dates = List.generate(7, (i) {
      final d = now.add(Duration(days: i));
      const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      return {
        "day": dayNames[d.weekday - 1],
        "date": d.day.toString(),
        "fullDate":
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
        "rawDate": d,
      };
    });
  }

  String _normalizePosition(String? pos) {
    if (pos == null) return '';
    final p = pos.toLowerCase().trim();
    if (p == 'hairstylist' ||
        p == 'hair stylist' ||
        p == 'senior hair technician specialist' ||
        p == 'creative stylist') {
      return 'hairstylist';
    }
    if (p == 'beautician' || p == 'senior beautician') {
      return 'beautician';
    }
    if (p == 'therapist' ||
        p == 'senior therapist' ||
        p == 'junior therapist') {
      return 'therapist';
    }
    return p;
  }

  Future<void> _fetchStylists() async {
    setState(() => _loadingStylists = true);
    try {
      final selectedDate = _dates[_selectedDateIndex]["rawDate"] as DateTime;
      final availableStylists = await _userController.fetchAvailableStylists(
        selectedDate,
      );

      if (mounted) {
        setState(() {
          _stylists = availableStylists.where((u) {
            final norm = _normalizePosition(u.position);
            return norm == 'hairstylist' ||
                norm == 'beautician' ||
                norm == 'therapist';
          }).toList();
          _selectedStylistIndex = -1; // Reset selection when date changes
          _loadingStylists = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stylists: $e');
      if (mounted) setState(() => _loadingStylists = false);
    }
  }

  List<String> _getQualifiedPositions(ServiceModel service) {
    final category = service.category.toLowerCase().trim();
    final name = (service.treatmentName + " " + service.detailName).toLowerCase();
    
    if (category == 'haircut' || category == 'hair coloring') {
      return ['hairstylist'];
    }
    if (category == 'facial') {
      return ['beautician'];
    }
    if (category == 'nail treatment' || category == 'hair ritual') {
      return ['therapist'];
    }
    
    // Fallback / Promo category check by keywords in category or name
    if (category == 'promo' || category == 'all') {
      if (name.contains('cut') || name.contains('color') || name.contains('warna') || name.contains('cat ') || name.contains('smoothing') || name.contains('chemical') || name.contains('styling') || name.contains('blow')) {
        return ['hairstylist'];
      }
      if (name.contains('facial') || name.contains('face') || name.contains('wajah') || name.contains('masker wajah') || name.contains('treatment wajah')) {
        return ['beautician'];
      }
      if (name.contains('nail') || name.contains('pedi') || name.contains('mani') || name.contains('kuku') || name.contains('body') || name.contains('massage') || name.contains('spa') || name.contains('ritual') || name.contains('creambath') || name.contains('hair treatment')) {
        return ['therapist'];
      }
    }
    
    // Default to all active positions if we can't determine
    return ['hairstylist', 'beautician', 'therapist'];
  }

  String _formatRoleName(String role) {
    if (role == 'hairstylist') return 'Hair Stylist';
    if (role == 'beautician') return 'Beautician';
    if (role == 'therapist') return 'Therapist';
    return role;
  }

  Set<String> _getIntersectionOfRequiredPositions(List<ServiceModel> selectedAndNewServices) {
    if (selectedAndNewServices.isEmpty) return {'hairstylist', 'beautician', 'therapist'};
    
    Set<String> intersection = _getQualifiedPositions(selectedAndNewServices.first).toSet();
    for (int i = 1; i < selectedAndNewServices.length; i++) {
      final positions = _getQualifiedPositions(selectedAndNewServices[i]).toSet();
      intersection = intersection.intersection(positions);
    }
    return intersection;
  }

  String? _checkServiceConflict(ServiceModel newService) {
    final selected = _selectedServices.map((s) => s['service'] as ServiceModel).toList();
    
    // 1. Check if there's a stylist selected first
    if (_selectedStylistIndex != -1) {
      final stylist = _filteredStylists[_selectedStylistIndex];
      final normalizedStylistPos = _normalizePosition(stylist.position);
      final qualified = _getQualifiedPositions(newService);
      if (!qualified.contains(normalizedStylistPos)) {
        final requiredRoles = qualified.map((r) => _formatRoleName(r)).join(' or ');
        return _getStylistConflictMessage(stylist.name, _formatRoleName(normalizedStylistPos), requiredRoles);
      }
    }
    
    // 2. Check if the new service conflicts with other already selected services
    final allServicesWithNew = [...selected, newService];
    final intersection = _getIntersectionOfRequiredPositions(allServicesWithNew);
    if (intersection.isEmpty) {
      final newServiceRoles = _getQualifiedPositions(newService).map((r) => _formatRoleName(r)).join(' or ');
      return _getRoleConflictMessage(newServiceRoles);
    }
    
    return null; // No conflict
  }

  bool _isServiceCompatibleWithStaffCategory(ServiceModel service, String staffCategory) {
    if (staffCategory == 'All') return true;
    final cat = service.category.toLowerCase();
    final tName = service.treatmentName.toLowerCase();
    final dName = service.detailName.toLowerCase();

    if (staffCategory == 'hairstylist') {
      final matchesHairCut = cat.contains('cut') || tName.contains('cut') || dName.contains('cut');
      final matchesChemical = cat.contains('color') || tName.contains('color') || dName.contains('color') ||
                              cat.contains('colour') || tName.contains('colour') || dName.contains('colour') ||
                              cat.contains('chemical') || tName.contains('chemical') || dName.contains('chemical') ||
                              cat.contains('smoothing') || tName.contains('smoothing') || dName.contains('smoothing') ||
                              tName.contains('relaxing') || dName.contains('relaxing') ||
                              tName.contains('rebonding') || dName.contains('rebonding');
      return matchesHairCut || matchesChemical;
    } else if (staffCategory == 'beautician') {
      return cat.contains('face') || tName.contains('face') || dName.contains('face') ||
             cat.contains('facial') || tName.contains('facial') || dName.contains('facial');
    } else if (staffCategory == 'therapist') {
      final matchesBody = cat.contains('body') || tName.contains('body') || dName.contains('body');
      final matchesNail = cat.contains('nail') || tName.contains('nail') || dName.contains('nail') ||
                          tName.contains('pedi') || dName.contains('pedi') ||
                          tName.contains('mani') || dName.contains('mani');
      final matchesHairRitual = cat.contains('ritual') || tName.contains('ritual') || dName.contains('ritual') ||
                                tName.contains('creambath') || dName.contains('creambath') ||
                                tName.contains('spa') || dName.contains('spa');
      return matchesBody || matchesNail || matchesHairRitual;
    }
    return true;
  }

  List<UserModel> get _filteredStylists {
    if (_selectedStaffCategory == 'All') {
      return _stylists;
    }
    return _stylists.where((u) {
      final normalizedPos = _normalizePosition(u.position);
      return normalizedPos == _selectedStaffCategory.toLowerCase();
    }).toList();
  }

  String? _checkStylistConflict(UserModel stylist) {
    final selected = _selectedServices.map((s) => s['service'] as ServiceModel).toList();
    if (selected.isEmpty) return null;
    
    final normalizedStylistPos = _normalizePosition(stylist.position);
    
    for (var svc in selected) {
      final qualified = _getQualifiedPositions(svc);
      if (!qualified.contains(normalizedStylistPos)) {
        final requiredRoles = qualified.map((r) => _formatRoleName(r)).join(' or ');
        return _getStylistConflictForServiceMessage(stylist.name, _formatRoleName(normalizedStylistPos), svc.displayName, requiredRoles);
      }
    }
    return null;
  }

  void _showConflictWarning(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: primaryColor, size: 28),
            const SizedBox(width: 10),
            Text(
              "Role Mismatch",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Close",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStylistConflictMessage(String stylistName, String stylistRole, String requiredRoles) {
    return "Stylist Conflict: You selected $stylistName ($stylistRole), but this service requires a $requiredRoles. Please change the stylist or book this service separately.";
  }

  String _getRoleConflictMessage(String newServiceRoles) {
    return "Role Conflict: This service requires a $newServiceRoles, which conflicts with other selected services. Please book services requiring different roles separately.";
  }

  String _getStylistConflictForServiceMessage(String stylistName, String stylistRole, String serviceName, String requiredRoles) {
    return "Stylist Conflict: $stylistName ($stylistRole) is not qualified to perform $serviceName which requires a $requiredRoles. Please select a qualified stylist or book this service separately.";
  }

  Future<void> _fetchCategoriesAndServices() async {
    try {
      final data = await _serviceController.fetchServicesAndCategories();

      if (!mounted) return;

      final cats = data['categories'] as List<String>;
      final servicesData = data['services'] as List<ServiceModel>;

      final services = servicesData.map((s) {
        return {'service': s, 'selected': false, 'adjusted_price': null};
      }).toList();

      setState(() {
        _categories = cats;
        _allServices = services;
        _loadingCategories = false;
        _loadingServices = false;
      });
    } catch (e) {
      debugPrint('Error fetching services: $e');
      if (mounted)
        setState(() {
          _loadingCategories = false;
          _loadingServices = false;
        });
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    return _allServices.where((item) {
      final ServiceModel s = item['service'];

      // Filter out inactive services (Soft Deleted)
      if (!s.isActive) return false;

      // Filter by staff category compatibility
      if (!_isServiceCompatibleWithStaffCategory(s, _selectedStaffCategory)) {
        return false;
      }

      final matchesCat =
          _selectedCategory == 'All' ||
          s.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch =
          s.treatmentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.detailName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get _selectedServices =>
      _allServices.where((s) => s['selected'] == true).toList();

  num get _totalPrice => _selectedServices.fold(0, (sum, item) {
    final ServiceModel svc = item['service'];
    return sum + ((item['adjusted_price'] ?? svc.price) as num);
  });

  int get _totalMins {
    int sum = 0;
    bool isLongService = false;
    bool isHairColouring = false;
    final longKeywords = ['color', 'warna', 'pelurusan', 'smoothing', 'relaxing', 'rebonding'];
    final colorKeywords = ['color', 'warna', 'pewarnaan'];

    for (var item in _selectedServices) {
      final ServiceModel svc = item['service'];
      final tName = svc.treatmentName.toLowerCase();
      final dName = svc.detailName.toLowerCase();
      final cat = svc.category.toLowerCase();

      if (longKeywords.any((k) => tName.contains(k) || dName.contains(k) || cat.contains(k))) {
        isLongService = true;
      }
      if (colorKeywords.any((k) => tName.contains(k) || dName.contains(k) || cat.contains(k))) {
        isHairColouring = true;
      }
      sum += svc.duration;
    }

    if (isHairColouring) return 420;
    if (isLongService && sum < 240) return 240;
    return sum;
  }

  Future<void> _showPriceDialog(Map<String, dynamic> item) async {
    final ServiceModel service = item['service'];
    final basePrice = service.price;
    final TextEditingController manualController = TextEditingController(
      text: (item['adjusted_price'] ?? service.price).toString(),
    );
    num? chosenPrice = item['adjusted_price'] ?? service.price;

    final displayTitle =
        service.treatmentName == service.detailName ||
            service.detailName.isEmpty
        ? service.treatmentName
        : "${service.treatmentName} - ${service.detailName}";

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Choose or adjust service price",
                    style: TextStyle(color: mutedText, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  if (basePrice > 0) ...[
                    Text(
                      "STANDARD PRICE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: mutedText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setSheet(() {
                          chosenPrice = basePrice;
                          manualController.text = basePrice.toString();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: chosenPrice == basePrice
                              ? primaryColor.withOpacity(0.08)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: chosenPrice == basePrice
                                ? primaryColor
                                : const Color(0xFFE2E8F0),
                            width: chosenPrice == basePrice ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _currencyFormat.format(basePrice),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 16,
                              ),
                            ),
                            if (chosenPrice == basePrice)
                              Icon(
                                Icons.check_circle,
                                color: primaryColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    "MANUAL PRICE INPUT",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: manualController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      setSheet(() {
                        chosenPrice = int.tryParse(v) ?? 0;
                      });
                    },
                    decoration: InputDecoration(
                      prefixText: "Rp  ",
                      prefixStyle: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: "0",
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final finalPrice =
                            int.tryParse(manualController.text) ??
                            (chosenPrice ?? basePrice);
                        final idx = _allServices.indexWhere(
                          (s) =>
                              (s['service'] as ServiceModel).tdId ==
                              service.tdId,
                        );
                        if (idx != -1) {
                          setState(() {
                            _allServices[idx]['adjusted_price'] = finalPrice;
                            _allServices[idx]['selected'] = true;
                          });
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        "Add to Booking",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredServices;
    final selected = _selectedServices;

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
                  "New Booking",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Select Date
                        Text(
                          "Select Date",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _dates.length,
                            separatorBuilder: (context, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedDateIndex;
                              return GestureDetector(
                                onTap: () {
                                  if (_selectedDateIndex != index) {
                                    setState(() => _selectedDateIndex = index);
                                    _fetchStylists();
                                  }
                                },
                                child: Container(
                                  width: 65,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _dates[index]["day"]!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white70
                                              : mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _dates[index]["date"]!,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Select Stylist
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Select Stylist",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              "${_filteredStylists.length} available",
                              style: TextStyle(fontSize: 13, color: mutedText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Kategori Staff Chips
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildStaffCategoryChip('All', 'All Staff', Icons.people_outline),
                              const SizedBox(width: 8),
                              _buildStaffCategoryChip('hairstylist', 'Hair Stylist', Icons.content_cut),
                              const SizedBox(width: 8),
                              _buildStaffCategoryChip('beautician', 'Beautician', Icons.face),
                              const SizedBox(width: 8),
                              _buildStaffCategoryChip('therapist', 'Therapist', Icons.spa),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_loadingStylists)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_filteredStylists.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "No stylists registered yet.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: mutedText, fontSize: 14),
                            ),
                          )
                        else
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filteredStylists.length,
                              separatorBuilder: (context, _) =>
                                  const SizedBox(width: 20),
                              itemBuilder: (context, index) {
                                final isSelected =
                                    index == _selectedStylistIndex;
                                final stylist = _filteredStylists[index];
                                return GestureDetector(
                                  onTap: () {
                                    final conflict = _checkStylistConflict(stylist);
                                    if (conflict != null) {
                                      _showConflictWarning(conflict);
                                      return;
                                    }
                                    setState(() => _selectedStylistIndex = index);
                                  },
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: isSelected
                                                  ? Border.all(
                                                      color: primaryColor,
                                                      width: 2,
                                                    )
                                                  : null,
                                              color: const Color(0xFFE2E8F0),
                                              image:
                                                  stylist.avatar != null &&
                                                      stylist.avatar!.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        stylist.avatar!,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child:
                                                stylist.avatar == null ||
                                                    stylist.avatar!.isEmpty
                                                ? const Icon(
                                                    Icons.person,
                                                    color: Color(0xFF94A3B8),
                                                    size: 30,
                                                  )
                                                : null,
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              bottom: -2,
                                              right: -2,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: scaffoldBg,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 8,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          stylist.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? primaryColor
                                                : mutedText,
                                            fontSize: 11,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 28),

                        Text(
                          "Select Service",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
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
                              hintStyle: TextStyle(
                                color: mutedText,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category Chips
                        if (_loadingCategories)
                          const SizedBox(
                            height: 36,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
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
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryColor
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : mutedText,
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
                        const SizedBox(height: 20),

                        // Services List
                        if (_loadingServices)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (filtered.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                "No services found.",
                                style: TextStyle(color: mutedText),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              if (index == filtered.length)
                                return const SizedBox(height: 120);
                              final item = filtered[index];
                              final ServiceModel service = item['service'];
                              final isSelected = item['selected'] == true;
                              final displayTitle =
                                  service.treatmentName == service.detailName ||
                                      service.detailName.isEmpty
                                  ? service.treatmentName
                                  : "${service.treatmentName} - ${service.detailName}";
                              final displayPrice =
                                  item['adjusted_price'] ?? service.price;
                              int dur = service.duration;
                              final tNameLower = service.treatmentName.toLowerCase();
                              final dNameLower = service.detailName.toLowerCase();
                              final catLower = service.category.toLowerCase();
                              final colorKeywords = ['color', 'warna', 'pewarnaan'];
                              
                              if (colorKeywords.any((k) => tNameLower.contains(k) || dNameLower.contains(k) || catLower.contains(k))) {
                                dur = 420;
                              }

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.withOpacity(0.04)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.3)
                                        : Colors.transparent,
                                    width: isSelected ? 1.5 : 0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Service Image
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: service.imageUrl != null
                                            ? Image.network(
                                                service.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(
                                                      Icons.image_outlined,
                                                      color: mutedText,
                                                      size: 20,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.image_outlined,
                                                color: mutedText,
                                                size: 20,
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
                                            displayTitle,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            service.category,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: mutedText,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_outlined,
                                                size: 13,
                                                color: mutedText,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                dur > 0
                                                    ? "$dur${" Minutes"}"
                                                    : "- Minutes",
                                                style: TextStyle(
                                                  color: mutedText,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                _currencyFormat.format(
                                                  displayPrice,
                                                ),
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              if (item['adjusted_price'] !=
                                                      null &&
                                                  item['adjusted_price'] !=
                                                      service.price) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFFBF0D8,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    "custom",
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF92400E),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () async {
                                        if (!isSelected) {
                                          final conflict = _checkServiceConflict(service);
                                          if (conflict != null) {
                                            _showConflictWarning(conflict);
                                            return;
                                          }
                                          await _showPriceDialog(item);
                                        } else {
                                          final idx = _allServices.indexWhere(
                                            (s) =>
                                                (s['service'] as ServiceModel)
                                                    .tdId ==
                                                service.tdId,
                                          );
                                          if (idx != -1) {
                                            setState(() {
                                              _allServices[idx]['selected'] =
                                                  false;
                                              _allServices[idx]['adjusted_price'] =
                                                  null;
                                            });
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          isSelected ? Icons.check : Icons.add,
                                          color: isSelected
                                              ? Colors.white
                                              : primaryColor,
                                          size: 20,
                                        ),
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

                  // Floating Summary + Continue
                  if (selected.isNotEmpty)
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${selected.length}${" services selected"}",
                                      style: TextStyle(
                                        color: mutedText,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (_totalMins > 0) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_filled,
                                            size: 14,
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "$_totalMins mnt",
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _currencyFormat.format(_totalPrice),
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                disabledBackgroundColor: const Color(
                                  0xFFCBD5E1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.15),
                              ),
                              onPressed: _selectedStylistIndex == -1
                                  ? null
                                  : () {
                                      final selectedStylist =
                                          _filteredStylists[_selectedStylistIndex];
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookingPage(
                                            selectedDate:
                                                _dates[_selectedDateIndex]["rawDate"]
                                                    as DateTime,
                                            stylistId: selectedStylist.id,
                                            stylistName: selectedStylist.name,
                                            stylistAvatar:
                                                selectedStylist.avatar,
                                            totalDuration: _totalMins,
                                            selectedServices: selected.map((s) {
                                              final svc =
                                                  s['service'] as ServiceModel;
                                              return {
                                                'td_id': svc.tdId,
                                                'treatment_id': svc.treatmentId,
                                                'detail_name': svc.detailName,
                                                'treatment_name':
                                                    svc.treatmentName,
                                                'category': svc.category,
                                                'duration': svc.duration,
                                                'price': svc.price,
                                                'selected': s['selected'],
                                                'adjusted_price':
                                                    s['adjusted_price'],
                                              };
                                            }).toList(),
                                            totalPrice: _totalPrice.toInt(),
                                          ),
                                        ),
                                      );
                                    },
                              child: Text(
                                _selectedStylistIndex == -1
                                    ? "Select Stylist Above"
                                    : "Continue to Schedule",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              _buildNavItem(1, "BOOKING", Icons.calendar_today),
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
        } else if (index == 2) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ManageServicesPage()),
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
        ],
      ),
    );
  }

  Widget _buildStaffCategoryChip(String categoryValue, String label, IconData icon) {
    final isSelected = _selectedStaffCategory == categoryValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStaffCategory = categoryValue;
          _selectedStylistIndex = -1; // Reset selection when category changes
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
