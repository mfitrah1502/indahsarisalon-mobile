import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int _selectedIndex = 1;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  
  bool _loadingCategories = true;
  bool _loadingServices = true;
  List<String> _categories = ['All'];
  
  /// Each entry: { td_id, title, category, category_id, duration, price (num), selected, adjusted_price (num?) }
  List<Map<String, dynamic>> _allServices = [];

  // Date Fields
  int _selectedDateIndex = 0;
  late final List<Map<String, dynamic>> _dates;

  // Stylist Fields
  int _selectedStylistIndex = -1;
  bool _loadingStylists = true;
  List<Map<String, dynamic>> _stylists = [];

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
      const dayNames = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
      return {
        "day": dayNames[d.weekday - 1],
        "date": d.day.toString(),
        "fullDate": "${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}",
        "rawDate": d,
      };
    });
  }

  Future<void> _fetchStylists() async {
    setState(() => _loadingStylists = true);
    try {
      final selectedDate = _dates[_selectedDateIndex]["rawDate"] as DateTime;
      final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}";

      // Get active users
      final userData = await Supabase.instance.client
          .from('users')
          .select('id, name, type, role, kategori, status, avatar')
          .eq('type', 'karyawan')
          .eq('status', 'aktif');
          
      // Get absensi for date
      final absensiData = await Supabase.instance.client
          .from('absensi')
          .select('user_id, status')
          .eq('tanggal', dateStr);

      final offUserIds = <int>{};
      for (var row in absensiData) {
        if (row['status'] == 'off') {
          offUserIds.add(row['user_id'] as int);
        }
      }
      
      final availableStylists = (userData as List<dynamic>)
          .where((u) => !offUserIds.contains(u['id']))
          .map((u) => Map<String,dynamic>.from(u)).toList();
      
      if (mounted) {
        setState(() {
          _stylists = availableStylists;
          _selectedStylistIndex = -1; // Reset selection when date changes
          _loadingStylists = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stylists: $e');
      if (mounted) setState(() => _loadingStylists = false);
    }
  }

  Future<void> _fetchCategoriesAndServices() async {
    try {
      final catData = await Supabase.instance.client
          .from('categories')
          .select('id, name')
          .order('name');

      final svcData = await Supabase.instance.client
          .from('treatment_details')
          .select('id, name, duration, price, treatment_id, has_stylist_price, price_senior, price_junior, is_promo, promo_type, promo_value, treatments(id, name, category_id, is_promo, promo_type, promo_value, categories(id, name))')
          .order('id');

      if (!mounted) return;

      final cats = ['All', ...List<Map<String, dynamic>>.from(catData)
          .map((c) => c['name'] as String)];

      final services = List<Map<String, dynamic>>.from(svcData).map((td) {
        final treatment = td['treatments'] as Map<String, dynamic>?;
        final category = treatment?['categories'] as Map<String, dynamic>?;

        final bool parentPromo = treatment?['is_promo'] == true;
        final bool detailPromo = td['is_promo'] == true;
        final bool isPromoActive = parentPromo || detailPromo;

        final String rawType = parentPromo 
            ? (treatment?['promo_type'] ?? 'percentage') 
            : (td['promo_type'] ?? 'percentage');
        
        // Let's keep fixed as fixed, and nominal/percentage as is.
        final String mobileType = (rawType == 'fixed') ? 'fixed' : ((rawType == 'nominal') ? 'nominal' : 'persen');
        
        final dynamic rawPromoValue = parentPromo 
            ? (treatment?['promo_value'] ?? 0) 
            : (td['promo_value'] ?? 0);
        final num effectivePromoValue = num.tryParse(rawPromoValue.toString()) ?? 0;

        return {
          'td_id': td['id'],
          'treatment_id': td['treatment_id'],
          'detail_name': td['name'] ?? '',
          'treatment_name': treatment?['name'] ?? '',
          'category': category?['name'] ?? '',
          'duration': td['duration'] ?? 0,
          'price': num.tryParse(td['price']?.toString() ?? '0') ?? 0,
          'has_stylist_price': td['has_stylist_price'] == true,
          'price_senior': num.tryParse(td['price_senior']?.toString() ?? '0') ?? 0,
          'price_junior': num.tryParse(td['price_junior']?.toString() ?? '0') ?? 0,
          'is_promo': isPromoActive,
          'promo_type': mobileType,
          'promo_value': effectivePromoValue,
          'selected': false,
          'adjusted_price': null,
        };
      }).toList();

      setState(() {
        _categories = cats;
        _allServices = services;
        _loadingCategories = false;
        _loadingServices = false;
      });
    } catch (e) {
      debugPrint('Error fetching services: $e');
      if (mounted) setState(() { _loadingCategories = false; _loadingServices = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    return _allServices.where((s) {
      final matchesCat = _selectedCategory == 'All' ||
          s['category'].toString().toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = s['treatment_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['detail_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get _selectedServices =>
      _allServices.where((s) => s['selected'] == true).toList();

  num _getDynamicPrice(Map<String, dynamic> service) {
    if (service['adjusted_price'] != null) return service['adjusted_price'] as num;

    num base = service['price'] ?? 0;
    if (_selectedStylistIndex != -1) {
      final stylist = _stylists[_selectedStylistIndex];
      final level = (stylist['kategori'] ?? '').toString().toLowerCase();
      if (service['has_stylist_price'] == true) {
        if (level.contains('senior')) {
          base = service['price_senior'] ?? 0;
        } else if (level.contains('junior')) {
          base = service['price_junior'] ?? 0;
        }
      }
    }

    num discounted = base;
    if (service['is_promo'] == true) {
      final pType = service['promo_type'];
      final pValue = service['promo_value'] ?? 0;
      if (pType == 'fixed' || pType == 'nominal') {
        discounted = base - pValue;
      } else {
        discounted = base * (1 - pValue / 100);
      }
    }
    return discounted < 0 ? 0 : discounted;
  }

  num get _totalPrice => _selectedServices.fold(0, (sum, s) => sum + _getDynamicPrice(s));

  int get _totalMins => _selectedServices.fold(0, (sum, s) =>
      sum + (s['duration'] as num).toInt());

  Future<void> _showPriceDialog(Map<String, dynamic> service) async {
    // Determine the base price based on stylist level (without promo first, or just use the calculated one)
    num levelBase = service['price'] ?? 0;
    String levelLabel = "";
    if (_selectedStylistIndex != -1) {
      final stylist = _stylists[_selectedStylistIndex];
      final level = (stylist['kategori'] ?? '').toString().toLowerCase();
      if (service['has_stylist_price'] == true) {
        if (level.contains('senior')) {
          levelBase = service['price_senior'] ?? 0;
          levelLabel = " (Senior)";
        } else if (level.contains('junior')) {
          levelBase = service['price_junior'] ?? 0;
          levelLabel = " (Junior)";
        }
      }
    }

    // However, the user might want the price AFTER promo as the default suggested standard
    num suggestedPrice = levelBase;
    if (service['is_promo'] == true) {
      final pType = service['promo_type'];
      final pValue = service['promo_value'] ?? 0;
      if (pType == 'fixed' || pType == 'nominal') {
        suggestedPrice = levelBase - pValue;
      } else {
        suggestedPrice = levelBase * (1 - pValue / 100);
      }
    }
    if (suggestedPrice < 0) suggestedPrice = 0;

    final TextEditingController manualController = TextEditingController(
      text: (service['adjusted_price'] ?? suggestedPrice).toString(),
    );
    num? chosenPrice = service['adjusted_price'] ?? suggestedPrice;

    final displayTitle = service['treatment_name'] == service['detail_name'] || service['detail_name'].toString().isEmpty
        ? service['treatment_name']
        : "${service['treatment_name']} - ${service['detail_name']}";

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
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(displayTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 4),
                  Text("Pilih atau sesuaikan harga layanan", style: TextStyle(color: mutedText, fontSize: 13)),
                  const SizedBox(height: 20),

                  Text("HARGA STANDAR$levelLabel", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedText, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setSheet(() { chosenPrice = suggestedPrice; manualController.text = suggestedPrice.toString(); });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: chosenPrice == suggestedPrice ? (service['is_promo'] == true ? Colors.green.withOpacity(0.08) : primaryColor.withOpacity(0.08)) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: chosenPrice == suggestedPrice ? (service['is_promo'] == true ? const Color(0xFF16A34A) : primaryColor) : const Color(0xFFE2E8F0),
                          width: chosenPrice == suggestedPrice ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (service['is_promo'] == true && levelBase != suggestedPrice) ...[
                                Text(
                                  _currencyFormat.format(levelBase),
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _currencyFormat.format(suggestedPrice),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: service['is_promo'] == true ? const Color(0xFF16A34A) : primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (chosenPrice == suggestedPrice)
                            Icon(Icons.check_circle, color: service['is_promo'] == true ? const Color(0xFF16A34A) : primaryColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text("INPUT HARGA MANUAL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedText, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: manualController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      setSheet(() { chosenPrice = int.tryParse(v) ?? 0; });
                    },
                    decoration: InputDecoration(
                      prefixText: "Rp  ",
                      prefixStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final finalPrice = int.tryParse(manualController.text) ?? (chosenPrice ?? suggestedPrice);
                        final idx = _allServices.indexWhere((s) => s['td_id'] == service['td_id']);
                        if (idx != -1) {
                          setState(() {
                            _allServices[idx]['adjusted_price'] = finalPrice;
                            _allServices[idx]['selected'] = true;
                          });
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text("Tambahkan ke Booking", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context, MaterialPageRoute(builder: (_) => const BookingListPage()), (r) => false),
                    child: Icon(Icons.arrow_back, color: primaryColor, size: 28),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 28.0),
                        child: Text(
                          "New Booking",
                          style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
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
                          "Pilih Tanggal",
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
                            separatorBuilder: (context, _) => const SizedBox(width: 12),
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
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryColor : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _dates[index]["day"]!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white70 : mutedText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _dates[index]["date"]!,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
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
                              "Pilih Stylist",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              "${_stylists.length} tersedia",
                              style: TextStyle(fontSize: 13, color: mutedText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_loadingStylists)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ))
                        else if (_stylists.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Belum ada stylist yang terdaftar.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: mutedText, fontSize: 14),
                            ),
                          )
                        else
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _stylists.length,
                              separatorBuilder: (context, _) => const SizedBox(width: 20),
                              itemBuilder: (context, index) {
                                final isSelected = index == _selectedStylistIndex;
                                final stylist = _stylists[index];
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedStylistIndex = index),
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              border: isSelected 
                                                  ? Border.all(color: primaryColor, width: 2) 
                                                  : null,
                                              color: const Color(0xFFE2E8F0),
                                            ),
                                            child: const Icon(Icons.person, color: Color(0xFF94A3B8), size: 30),
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              bottom: -2,
                                              right: -2,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: scaffoldBg, width: 2),
                                                ),
                                                child: const Icon(Icons.check, color: Colors.white, size: 8),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        stylist['name'] ?? '-',
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? primaryColor : const Color(0xFF1E293B),
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (stylist['kategori'] != null)
                                        Text(
                                          (stylist['kategori'] ?? '').toString().toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? primaryColor.withOpacity(0.7) : mutedText.withOpacity(0.6),
                                            letterSpacing: 0.5,
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
                          "Pilih Layanan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0).withOpacity(0.5),
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

                        // Category Chips
                        if (_loadingCategories)
                          const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                        else
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
                        const SizedBox(height: 20),

                        // Services List
                        if (_loadingServices)
                          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                        else if (filtered.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text("Tidak ada layanan ditemukan.", style: TextStyle(color: mutedText)),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              if (index == filtered.length) return const SizedBox(height: 120);
                              final service = filtered[index];
                              final isSelected = service['selected'] == true;
                              final displayTitle = service['treatment_name'] == service['detail_name'] || service['detail_name'].toString().isEmpty
                                  ? service['treatment_name']
                                  : "${service['treatment_name']} - ${service['detail_name']}";

                              // Calculate price based on selected stylist
                              num basePrice = service['price'] ?? 0;
                              bool isRange = false;
                              num minP = 0;
                              num maxP = 0;
                              String stylistLevelLabel = "";

                              if (_selectedStylistIndex != -1) {
                                final stylist = _stylists[_selectedStylistIndex];
                                final level = (stylist['kategori'] ?? '').toString().toLowerCase();
                                if (service['has_stylist_price'] == true) {
                                  if (level.contains('senior')) {
                                    basePrice = service['price_senior'] ?? 0;
                                    stylistLevelLabel = " (Senior)";
                                  } else if (level.contains('junior')) {
                                    basePrice = service['price_junior'] ?? 0;
                                    stylistLevelLabel = " (Junior)";
                                  }
                                }
                              } else {
                                if (service['has_stylist_price'] == true) {
                                  isRange = true;
                                  final pSr = (service['price_senior'] as num? ?? 0).toInt();
                                  final pJr = (service['price_junior'] as num? ?? 0).toInt();
                                  minP = pSr < pJr ? pSr : pJr;
                                  maxP = pSr > pJr ? pSr : pJr;
                                }
                              }

                              num discountedPrice = basePrice;
                              final bool isPromo = service['is_promo'] == true;
                              if (isPromo) {
                                final pType = service['promo_type'];
                                final pValue = service['promo_value'] ?? 0;
                                if (pType == 'fixed' || pType == 'nominal') {
                                  discountedPrice = basePrice - pValue;
                                } else {
                                  discountedPrice = basePrice * (1 - pValue / 100);
                                }
                              }
                              if (discountedPrice < 0) discountedPrice = 0;

                              final displayPrice = _getDynamicPrice(service);
                              final dur = (service['duration'] as num).toInt();

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor.withOpacity(0.04) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? primaryColor.withOpacity(0.3) : Colors.transparent,
                                    width: isSelected ? 1.5 : 0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                          if (isPromo)
                                            Text(
                                              "Promo",
                                              style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.bold),
                                            ),
                                          Text(
                                            service['category'],
                                            style: TextStyle(fontSize: 11, color: mutedText, letterSpacing: 0.3),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_outlined, size: 13, color: mutedText),
                                              const SizedBox(width: 4),
                                              Text(
                                                dur > 0 ? "$dur Menit" : "- Menit",
                                                style: TextStyle(color: mutedText, fontSize: 12),
                                              ),
                                              const SizedBox(width: 10),
                                              if (isRange)
                                                Text(
                                                  "${_currencyFormat.format(minP)} - ${_currencyFormat.format(maxP)}",
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                )
                                              else ...[
                                                if (isPromo && service['adjusted_price'] == null) ...[
                                                  Text(
                                                    _currencyFormat.format(basePrice),
                                                    style: TextStyle(
                                                      color: mutedText,
                                                      fontSize: 11,
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                Text(
                                                  _currencyFormat.format(displayPrice),
                                                  style: TextStyle(
                                                    color: isPromo && service['adjusted_price'] == null ? const Color(0xFF16A34A) : primaryColor,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                              if (service['adjusted_price'] != null &&
                                                  service['adjusted_price'] != service['price']) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFBF0D8),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text("custom", style: TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.bold)),
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
                                          if (service['has_stylist_price'] == true && _selectedStylistIndex == -1) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Silakan pilih Stylist terlebih dahulu untuk melihat harga layanan ini."),
                                                backgroundColor: Color(0xFFEAB308),
                                                behavior: SnackBarBehavior.floating,
                                              )
                                            );
                                            return;
                                          }
                                          await _showPriceDialog(service);
                                        } else {
                                          final idx = _allServices.indexWhere((s) => s['td_id'] == service['td_id']);
                                          if (idx != -1) {
                                            setState(() {
                                              _allServices[idx]['selected'] = false;
                                              _allServices[idx]['adjusted_price'] = null;
                                            });
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? primaryColor : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isSelected ? Icons.check : Icons.add,
                                          color: isSelected ? Colors.white : primaryColor,
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
                      bottom: 24, left: 24, right: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${selected.length} layanan dipilih",
                                      style: TextStyle(color: mutedText, fontSize: 13),
                                    ),
                                    if (_totalMins > 0) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time_filled, size: 14, color: primaryColor),
                                          const SizedBox(width: 4),
                                          Text("$_totalMins mnt", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _currencyFormat.format(_totalPrice),
                                  style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                disabledBackgroundColor: const Color(0xFFCBD5E1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.15),
                              ),
                              onPressed: _selectedStylistIndex == -1 ? null : () {
                                final selectedStylist = _stylists[_selectedStylistIndex];
                                
                                // Ensure each selected service has its correct dynamic price
                                final processedServices = selected.map((s) {
                                  final copy = Map<String, dynamic>.from(s);
                                  copy['adjusted_price'] = _getDynamicPrice(s);
                                  return copy;
                                }).toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => BookingPage(
                                        selectedDate: _dates[_selectedDateIndex]["rawDate"] as DateTime,
                                        stylistId: selectedStylist['id'],
                                        stylistName: selectedStylist['name'] ?? '',
                                        totalDuration: _totalMins,
                                        selectedServices: processedServices,
                                        totalPrice: _totalPrice.toInt(),
                                      ),
                                  ),
                                );
                              },
                              child: Text(
                                _selectedStylistIndex == -1 ? "Pilih Stylist di Atas" : "Lanjut ke Jadwal", 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
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
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
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
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false);
        } else if (index == 1) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BookingListPage()), (r) => false);
        } else if (index == 2) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ManageServicesPage()), (r) => false);
        } else if (index == 3) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ReportPage()), (r) => false);
        } else if (index == 4) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SettingsPage()), (r) => false);
        }
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
