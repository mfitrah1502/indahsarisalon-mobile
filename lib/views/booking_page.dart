import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/booking_controller.dart';
import 'home_page.dart';
import 'customer_list_page.dart';
import 'settings_page.dart';
import 'select_services_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'report_page.dart';
import 'payment_details_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/popup_helper.dart';
import '../app_session.dart';

class BookingPage extends StatefulWidget {
  final DateTime selectedDate;
  final int stylistId;
  final String stylistName;
  final String? stylistAvatar;
  final int totalDuration;
  final List<Map<String, dynamic>> selectedServices;
  final int totalPrice;

  const BookingPage({
    super.key,
    required this.selectedDate,
    required this.stylistId,
    required this.stylistName,
    this.stylistAvatar,
    required this.totalDuration,
    required this.selectedServices,
    required this.totalPrice,
    this.isRescheduling = false,
    this.rescheduleBookingId,
  });

  final bool isRescheduling;
  final int? rescheduleBookingId;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  int _selectedTimeIndex = -1;
  int _selectedIndex = 1;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  bool _loadingTimes = true;
  List<String> _times = [];

  final BookingController _bookingController = BookingController();

  List<Map<String, dynamic>> _finalServices = [];
  int _finalTotalPrice = 0;
  bool _isColourCircleApplied = false;

  int _effectiveDuration = 0;

  @override
  void initState() {
    super.initState();
    _finalServices = List<Map<String, dynamic>>.from(
      widget.selectedServices.map((e) => Map<String, dynamic>.from(e)),
    );
    _finalTotalPrice = widget.totalPrice;
    _effectiveDuration = widget.totalDuration;
    // Rule: Coloring & Pelurusan minimal 4 jam (240 menit), Hair Colouring khusus 7 jam (420 menit)
    bool isLongService = false;
    bool isHairColouring = false;
    final longKeywords = [
      'color',
      'warna',
      'pelurusan',
      'smoothing',
      'relaxing',
      'rebonding',
    ];
    final colorKeywords = ['color', 'warna', 'pewarnaan'];

    for (var s in widget.selectedServices) {
      final tName = (s['treatment_name'] ?? '').toString().toLowerCase();
      final dName = (s['detail_name'] ?? '').toString().toLowerCase();
      final cat = (s['category'] ?? '').toString().toLowerCase();
      if (longKeywords.any(
        (k) => tName.contains(k) || dName.contains(k) || cat.contains(k),
      )) {
        isLongService = true;
      }
      if (colorKeywords.any(
        (k) => tName.contains(k) || dName.contains(k) || cat.contains(k),
      )) {
        isHairColouring = true;
      }
    }

    if (isHairColouring) {
      _effectiveDuration = 420; // 7 jam
    } else if (isLongService && _effectiveDuration < 240) {
      _effectiveDuration = 240;
    }

    if (widget.isRescheduling) {
      _nameCtrl.text = widget.selectedServices[0]['customer_name'] ?? '';
      _phoneCtrl.text = widget.selectedServices[0]['customer_phone'] ?? '';
      _emailCtrl.text = widget.selectedServices[0]['customer_email'] ?? '';
    } else {
      _fetchLoggedInCustomerProfile();
    }

    _fetchAvailableTimes();
  }

  Future<void> _fetchLoggedInCustomerProfile() async {
    if (AppSession.userId != null && AppSession.userRole?.toLowerCase() == 'pelanggan') {
      try {
        final res = await Supabase.instance.client
            .from('users')
            .select('name, email, phone, is_colour_circle, colour_circle_expired_at')
            .eq('id', AppSession.userId!)
            .single();

        if (mounted) {
          setState(() {
            if (_nameCtrl.text.isEmpty) _nameCtrl.text = res['name'] ?? '';
            if (_emailCtrl.text.isEmpty) _emailCtrl.text = res['email'] ?? '';
            if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = res['phone'] ?? '';

            bool isCc = res['is_colour_circle'] == true;
            DateTime? exp = res['colour_circle_expired_at'] != null
                ? DateTime.tryParse(res['colour_circle_expired_at'])
                : null;
            _isColourCircleApplied = isCc && (exp == null || exp.isAfter(DateTime.now()));
            _recalculatePrice();
          });
        }
      } catch (e) {
        debugPrint('Error fetching logged in profile: $e');
      }
    }
  }

  void _recalculatePrice() {
    int total = 0;
    _finalServices = List<Map<String, dynamic>>.from(
      widget.selectedServices.map((e) {
        final s = Map<String, dynamic>.from(e);
        num price = s['adjusted_price'] ?? s['price'];

        if (_isColourCircleApplied) {
          String cat = (s['category'] ?? '').toString().toLowerCase();
          String tName = (s['treatment_name'] ?? '').toString().toLowerCase();
          if (cat.contains('color') || tName.contains('color')) {
            price = price * 0.65; // 35% discount
            s['adjusted_price'] = price;
            s['is_colour_circle_discount'] = true;
          }
        } else {
          s['is_colour_circle_discount'] = false;
          s['adjusted_price'] = widget.selectedServices.firstWhere(
            (w) => w['td_id'] == s['td_id'],
          )['adjusted_price'];
        }
        total += price.toInt();
        return s;
      }),
    );
    _finalTotalPrice = total;
  }

  Future<void> _fetchAvailableTimes() async {
    setState(() {
      _loadingTimes = true;
      _selectedTimeIndex = -1;
    });

    try {
      final selectedDate = widget.selectedDate;

      final slots = await _bookingController.getAvailableTimeSlots(
        date: selectedDate,
        stylistId: widget.stylistId,
        totalDuration: _effectiveDuration,
      );

      // Rule: Chemical services max booking 16:00
      // Keywords: pewarnaan, permanent blow, blue fire, relaxing, smoothing, coloring, pelurusan
      final chemicalKeywords = [
        'pewarnaan',
        'color',
        'warna',
        'permanent blow',
        'blue fire',
        'relaxing',
        'smoothing',
        'pelurusan',
        'rebonding',
      ];
      bool isChemical = false;
      bool isHairColouring = false;
      for (var s in widget.selectedServices) {
        final tName = (s['treatment_name'] ?? '').toString().toLowerCase();
        final dName = (s['detail_name'] ?? '').toString().toLowerCase();
        final cat = (s['category'] ?? '').toString().toLowerCase();
        if (chemicalKeywords.any(
          (k) => tName.contains(k) || dName.contains(k) || cat.contains(k),
        )) {
          isChemical = true;
        }
        if (['color', 'warna', 'pewarnaan'].any(
          (k) => tName.contains(k) || dName.contains(k) || cat.contains(k),
        )) {
          isHairColouring = true;
        }
      }

      List<String> filteredSlots = slots;
      if (isHairColouring) {
        filteredSlots = slots.where((t) {
          final hour = int.parse(t.split(':')[0]);
          final minute = int.parse(t.split(':')[1]);
          // Hanya bisa di 09:00, 09:30, 10:00, 10:30
          if (hour == 9) return true;
          if (hour == 10 && (minute == 0 || minute == 30)) return true;
          return false;
        }).toList();
      } else if (isChemical) {
        filteredSlots = slots.where((t) {
          final hour = int.parse(t.split(':')[0]);
          final minute = int.parse(t.split(':')[1]);
          // Max booking is 16:00 (cannot start after 16:00)
          if (hour > 16) return false;
          if (hour == 16 && minute > 0) return false;
          return true;
        }).toList();
      }

      if (mounted) {
        setState(() {
          _times = filteredSlots;
          _loadingTimes = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching times: $e");
      if (mounted) {
        setState(() {
          _times = [];
          _loadingTimes = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardBg = Colors.white;
    final Color darkText = const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: darkText, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Schedule",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Complete booking details & time",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFCBD5E1).withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFF1F5F9),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              image: widget.stylistAvatar != null && widget.stylistAvatar!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(widget.stylistAvatar!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: widget.stylistAvatar == null || widget.stylistAvatar!.isEmpty
                                ? Icon(Icons.person_rounded, color: primaryColor, size: 28)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "STYLIST",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.stylistName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.schedule_rounded, size: 18, color: mutedText),
                                const SizedBox(height: 4),
                                Text(
                                  "${_effectiveDuration}m",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form Data Diri
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Customer Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: darkText,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerListPage(
                                  isSelectionMode: true,
                                ),
                              ),
                            );
                            if (result != null && result is Map<String, dynamic>) {
                              setState(() {
                                _nameCtrl.text = result['name'] ?? '';
                                _phoneCtrl.text = result['phone'] ?? '';
                                _emailCtrl.text = result['email'] ?? '';

                                bool isCc = result['is_colour_circle'] == true;
                                DateTime? exp = result['colour_circle_expired_at'] != null
                                    ? DateTime.tryParse(result['colour_circle_expired_at'])
                                    : null;
                                _isColourCircleApplied = isCc && exp != null && exp.isAfter(DateTime.now());
                                _recalculatePrice();
                              });
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: buttonColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.contact_phone_rounded, size: 14, color: buttonColor),
                                const SizedBox(width: 4),
                                Text(
                                  "From Contacts",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: buttonColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameCtrl,
                            label: "Full Name",
                            icon: Icons.person_rounded,
                            validator: (v) => v == null || v.trim().isEmpty ? "Name is required" : null,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _phoneCtrl,
                            label: "WhatsApp / Phone Number",
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Phone number is required";
                              if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) return "Phone number must be numeric";
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _emailCtrl,
                            label: "Email",
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Email is required";
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return "Email format is invalid";
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Select Time
                    Text(
                      "Select Visit Time",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Choose the time that suits you best",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mutedText),
                    ),
                    const SizedBox(height: 24),

                    if (_loadingTimes)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: primaryColor),
                        ),
                      )
                    else if (_times.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.event_busy_rounded, color: Color(0xFFEF4444), size: 36),
                            const SizedBox(height: 12),
                            const Text(
                              "No available schedule or not enough time for the selected treatment duration.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          _buildTimeSection(
                            "Morning",
                            Icons.wb_twilight_rounded,
                            _times.asMap().entries.where((e) => int.parse(e.value.split(':')[0]) < 12).toList(),
                          ),
                          _buildTimeSection(
                            "Afternoon",
                            Icons.wb_sunny_rounded,
                            _times.asMap().entries.where((e) => int.parse(e.value.split(':')[0]) >= 12 && int.parse(e.value.split(':')[0]) < 15).toList(),
                          ),
                          _buildTimeSection(
                            "Evening",
                            Icons.nights_stay_rounded,
                            _times.asMap().entries.where((e) => int.parse(e.value.split(':')[0]) >= 15).toList(),
                          ),
                        ],
                      ),

                    const SizedBox(height: 48),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _selectedTimeIndex == -1
                              ? []
                              : [
                                  BoxShadow(
                                    color: buttonColor.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            disabledBackgroundColor: const Color(0xFFCBD5E1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                          ),
                          onPressed: _selectedTimeIndex == -1
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    final time = _times[_selectedTimeIndex];
                                    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
                                    final reservationDatetime = "$dateStr $time:00";

                                    if (widget.isRescheduling && widget.rescheduleBookingId != null) {
                                      setState(() => _loadingTimes = true);
                                      try {
                                        await Supabase.instance.client
                                            .from('bookings')
                                            .update({
                                              'reservation_datetime': reservationDatetime,
                                              'customer_name': _nameCtrl.text,
                                              'customer_phone': _phoneCtrl.text,
                                              'customer_email': _emailCtrl.text,
                                            })
                                            .eq('id', widget.rescheduleBookingId!);

                                        if (mounted) {
                                          PopupHelper.showSuccess(
                                            context,
                                            "Schedule has been successfully changed!",
                                            onConfirm: () {
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(builder: (_) => const BookingListPage()),
                                                (route) => false,
                                              );
                                            },
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          PopupHelper.showError(context, "Failed to reschedule: $e");
                                          setState(() => _loadingTimes = false);
                                        }
                                      }
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaymentDetailsPage(
                                            reservationDatetime: reservationDatetime,
                                            stylistId: widget.stylistId,
                                            stylistName: widget.stylistName,
                                            totalPrice: _finalTotalPrice,
                                            customerName: _nameCtrl.text,
                                            customerPhone: _phoneCtrl.text,
                                            customerEmail: _emailCtrl.text,
                                            selectedServices: _finalServices,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: Text(
                            _selectedTimeIndex == -1 ? "Select Time" : "Continue to Payment",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, -8),
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
              _buildNavItem(1, "BOOKING", Icons.calendar_today_rounded),
              _buildNavItem(2, "SERVICES", Icons.content_cut_rounded),
              _buildNavItem(3, "REPORT", Icons.bar_chart_rounded),
              _buildNavItem(4, "SETTINGS", Icons.settings_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: mutedText, fontWeight: FontWeight.w500, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        prefixIcon: Icon(icon, color: mutedText.withOpacity(0.7), size: 22),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildTimeSection(String title, IconData icon, List<MapEntry<int, String>> slots) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: primaryColor),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: slots.map((entry) {
            final index = entry.key;
            final time = entry.value;
            final isSelected = index == _selectedTimeIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedTimeIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                    width: isSelected ? 0 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? primaryColor : mutedText.withOpacity(0.5), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? primaryColor : mutedText.withOpacity(0.5),
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
      ),
    );
  }
}
