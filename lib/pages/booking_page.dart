import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/schedule_helper.dart';
import 'home_page.dart';
import 'customer_list_page.dart';
import 'settings_page.dart';
import 'select_services_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'report_page.dart';
import 'payment_details_page.dart';

class BookingPage extends StatefulWidget {
  final DateTime selectedDate;
  final int stylistId;
  final String stylistName;
  final int totalDuration;
  final List<Map<String, dynamic>> selectedServices;
  final int totalPrice;

  const BookingPage({
    super.key,
    required this.selectedDate,
    required this.stylistId,
    required this.stylistName,
    required this.totalDuration,
    required this.selectedServices,
    required this.totalPrice,
  });

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

  @override
  void initState() {
    super.initState();
    _fetchAvailableTimes();
  }

  Future<void> _fetchAvailableTimes() async {
    setState(() {
      _loadingTimes = true;
      _selectedTimeIndex = -1;
    });

    try {
      final selectedDate = widget.selectedDate;
      
      final slots = await ScheduleHelper.getAvailableTimeSlots(
        date: selectedDate,
        stylistId: widget.stylistId,
        totalDuration: widget.totalDuration,
      );

      if (mounted) {
        setState(() {
          _times = slots;
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
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 28.0),
                        child: Text(
                          "Pilih Jadwal",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                    // Info Band
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFE4F0FA)),
                            child: Icon(Icons.person, color: primaryColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("STYLIST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: mutedText)),
                                const SizedBox(height: 2),
                                Text(widget.stylistName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("DURASI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: mutedText)),
                              const SizedBox(height: 2),
                              Text("${widget.totalDuration} Menit", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                            ],
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Form Data Diri
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Informasi Pelanggan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerListPage(isSelectionMode: true),
                              ),
                            );
                            if (result != null && result is Map<String, dynamic>) {
                              setState(() {
                                _nameCtrl.text = result['name'] ?? '';
                                _phoneCtrl.text = result['phone'] ?? '';
                                _emailCtrl.text = result['email'] ?? '';
                              });
                            }
                          },
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text("Dari Daftar"),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: "Nama Lengkap",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              prefixIcon: Icon(Icons.person_outline, color: mutedText),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Nama harus diisi";
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            decoration: InputDecoration(
                              labelText: "Nomor WhatsApp / HP",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              prefixIcon: Icon(Icons.phone_outlined, color: mutedText),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Nomor HP harus diisi";
                              if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) return "Nomor telpon harus berupa angka";
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              labelText: "Email",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              prefixIcon: Icon(Icons.email_outlined, color: mutedText),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return "Email harus diisi";
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return "Format email tidak valid";
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Select Time
                    Text(
                      "Pilih Jam",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_loadingTimes)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ))
                    else if (_times.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.event_busy, color: const Color(0xFFEF4444), size: 32),
                            const SizedBox(height: 12),
                            Text(
                              "Tidak ada jadwal yang tersedia atau waktu tidak cukup untuk durasi treatment yang kamu pilih.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: const Color(0xFF991B1B), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _times.asMap().entries.map((entry) {
                          final index = entry.key;
                          final time = entry.value;
                          final isSelected = index == _selectedTimeIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTimeIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                time,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : mutedText,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 48),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                        ),
                        onPressed: _selectedTimeIndex == -1 ? null : () {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }
                          
                          final selectedDateStr = "${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2,'0')}-${widget.selectedDate.day.toString().padLeft(2,'0')}";
                          final selectedTime = _times[_selectedTimeIndex];
                          final dateTimeStr = "$selectedDateStr $selectedTime:00";

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentDetailsPage(
                                stylistId: widget.stylistId,
                                stylistName: widget.stylistName,
                                reservationDatetime: dateTimeStr,
                                selectedServices: widget.selectedServices,
                                totalPrice: widget.totalPrice,
                                customerName: _nameCtrl.text.trim(),
                                customerPhone: _phoneCtrl.text.trim(),
                                customerEmail: _emailCtrl.text.trim(),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          _selectedTimeIndex == -1
                              ? "Pilih Waktu"
                              : "Lanjut ke Pembayaran",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
