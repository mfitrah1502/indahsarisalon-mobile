import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/schedule_helper.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'select_services_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'report_page.dart';
import 'payment_details_page.dart';

class BookingPage extends StatefulWidget {
  final int stylistId;
  final String stylistName;
  final int totalDuration;
  final List<Map<String, dynamic>> selectedServices;
  final int totalPrice;

  const BookingPage({
    super.key,
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
  final Color darkBlue = const Color(0xFF02365A);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;
  int _selectedIndex = 1;

  late final List<Map<String, dynamic>> _dates;
  bool _loadingTimes = true;
  List<String> _times = [];

  @override
  void initState() {
    super.initState();
    _buildDates();
    _fetchAvailableTimes();
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

  Future<void> _fetchAvailableTimes() async {
    setState(() {
      _loadingTimes = true;
      _selectedTimeIndex = -1;
    });

    try {
      final selectedDate = _dates[_selectedDateIndex]["rawDate"] as DateTime;
      
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
                    child: Icon(Icons.arrow_back, color: darkBlue, size: 28),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 28.0),
                        child: Text(
                          "Pilih Jadwal",
                          style: TextStyle(
                            color: darkBlue,
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
                            child: Icon(Icons.person, color: darkBlue, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("STYLIST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: mutedText)),
                                const SizedBox(height: 2),
                                Text(widget.stylistName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkBlue)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("DURASI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: mutedText)),
                              const SizedBox(height: 2),
                              Text("${widget.totalDuration} Menit", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkBlue)),
                            ],
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Select Date
                    Text(
                      "Pilih Tanggal",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
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
                                _fetchAvailableTimes();
                              }
                            },
                            child: Container(
                              width: 65,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? darkBlue : Colors.white,
                                borderRadius: BorderRadius.circular(16),
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

                    // Select Time
                    Text(
                      "Pilih Jam",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
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
                                color: isSelected ? darkBlue : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? darkBlue : const Color(0xFFE2E8F0),
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
                          backgroundColor: darkBlue,
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                        ),
                        onPressed: _selectedTimeIndex == -1 ? null : () {
                          final selectedDate = _dates[_selectedDateIndex];
                          final selectedTime = _times[_selectedTimeIndex];
                          final dateTimeStr = "${selectedDate['fullDate']} $selectedTime:00";

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentDetailsPage(
                                stylistId: widget.stylistId,
                                stylistName: widget.stylistName,
                                reservationDatetime: dateTimeStr,
                                selectedServices: widget.selectedServices,
                                totalPrice: widget.totalPrice,
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
          Icon(icon, color: isSelected ? darkBlue : mutedText, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isSelected ? darkBlue : mutedText, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
