import 'package:flutter/material.dart';
import '../models/booking_list_model.dart';
import '../controllers/booking_list_controller.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'select_services_page.dart';
import 'booking_details_page.dart';
import 'manage_services_page.dart';
import 'report_page.dart';
import '../utils/popup_helper.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF8FAFC);
  final Color mutedText = const Color(0xFF64748B);
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int _selectedIndex = 1;
  bool _loading = true;
  List<BookingListModel> _bookings = [];
  List<BookingListModel> _filteredBookings = [];
  final TextEditingController _searchController = TextEditingController();
  final BookingListController _bookingListController = BookingListController();

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _loading = true);
    try {
      final data = await _bookingListController.fetchBookings();
      if (mounted) {
        setState(() {
          _bookings = data;
          _filteredBookings = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, List<BookingListModel>> _getGroupedBookings() {
    Map<String, List<BookingListModel>> groups = {};
    for (var b in _filteredBookings) {
      final createdAtStr = b.createdAt;
      if (createdAtStr == null) continue;
      
      final date = DateTime.parse(createdAtStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final itemDate = DateTime(date.year, date.month, date.day);

      String groupKey;
      if (itemDate == today) {
        groupKey = "Today";
      } else if (itemDate == yesterday) {
        groupKey = "Yesterday";
      } else {
        groupKey = DateFormat('EEEE, d MMMM yyyy', 'en').format(itemDate);
      }

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      groups[groupKey]!.add(b);
    }
    return groups;
  }

  void _filterBookings(String query) {
    if (query.isEmpty) {
      setState(() => _filteredBookings = _bookings);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredBookings = _bookings.where((b) {
        final custName = b.customerName.toLowerCase();
        final stylName = b.stylist.toLowerCase();
        final phone = b.customerPhone.toLowerCase();
        final email = b.customerEmail.toLowerCase();
        return custName.contains(lowerQuery) || stylName.contains(lowerQuery) ||
               phone.contains(lowerQuery) || email.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _deleteAllBookings() async {
    PopupHelper.showConfirm(
      context,
      title: "Delete All Bookings?",
      message: "This action will permanently delete all bookings from the database. Continue?",
      onConfirm: () async {
        setState(() => _loading = true);
        try {
          await _bookingListController.deleteAllBookings();
          _fetchBookings();
        } catch (e) {
          debugPrint("Error deleting: $e");
          if (mounted) setState(() => _loading = false);
        }
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'berhasil':
      case 'success':
        return const Color(0xFF059669);
      case 'dibatalkan':
      case 'cancelled':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFFEA580C); // pending/upcoming
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'berhasil':
      case 'success':
        return const Color(0xFFD1FAE5);
      case 'dibatalkan':
      case 'cancelled':
        return const Color(0xFFFFE4E6);
      default:
        return const Color(0xFFFFEDD5);
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'berhasil':
      case 'success':
        return 'SUCCESS';
      case 'dibatalkan':
      case 'cancelled':
        return 'CANCELLED';
      default:
        return 'PENDING';
    }
  }

  String _formatDateOnly(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatTimeOnly(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedBookings = _getGroupedBookings();

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Booking List",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Manage your appointments",
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      child: GestureDetector(
                        onTap: _fetchBookings,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: primaryColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Icon(Icons.refresh_rounded, color: primaryColor, size: 20),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: _bookings.isEmpty ? null : _deleteAllBookings,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _bookings.isEmpty ? const Color(0xFFF1F5F9) : const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (_bookings.isNotEmpty)
                                BoxShadow(color: Colors.red.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Icon(Icons.delete_outline_rounded, color: _bookings.isEmpty ? Colors.grey : const Color(0xFFE11D48), size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Modern Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterBookings,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    icon: Icon(Icons.search_rounded, color: primaryColor.withValues(alpha: 0.6), size: 22),
                    hintText: 'Search by Name or Stylist...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  if (_loading)
                    Center(child: CircularProgressIndicator(color: primaryColor))
                  else
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SCHEDULE OVERVIEW",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: primaryColor),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Your Appointments",
                                    style: const TextStyle(color: Color(0xFF1E293B), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${_filteredBookings.length} total", 
                                  style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          if (_filteredBookings.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 60.0),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.05), blurRadius: 20)],
                                      ),
                                      child: Icon(Icons.event_busy_rounded, size: 56, color: primaryColor.withValues(alpha: 0.4)),
                                    ),
                                    const SizedBox(height: 20),
                                    Text("No bookings yet.", style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Text("Press the + button to create a new booking.", style: TextStyle(color: mutedText, fontSize: 14)),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...groupedBookings.entries.map((entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF334155),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...entry.value.map((booking) {
                                    final status = booking.status;
                                    final services = booking.services;
                                    final serviceLabel = services.take(2).join(", ") + (services.length > 2 ? " +${services.length - 2}${" others"}" : "");

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BookingDetailsPage(booking: booking.toMap()),
                                            ),
                                          ).then((_) => _fetchBookings()); // Refresh on return
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                                            boxShadow: [
                                              BoxShadow(color: primaryColor.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  // Stylist avatar
                                                  Container(
                                                    width: 54, height: 54,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(16),
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          primaryColor.withValues(alpha: 0.1),
                                                          primaryColor.withValues(alpha: 0.02),
                                                        ]
                                                      ),
                                                      border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        booking.customerName != '-' ? booking.customerName[0].toUpperCase() : "C",
                                                        style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w800),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          booking.customerName != '-' ? booking.customerName : "Customer",
                                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          serviceLabel,
                                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.content_cut_rounded, size: 12, color: mutedText),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              booking.stylist,
                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: mutedText),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1.5),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF8FAFC),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.calendar_month_rounded, size: 12, color: primaryColor),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              _formatDateOnly(booking.datetime),
                                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF8FAFC),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.access_time_rounded, size: 12, color: primaryColor),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              _formatTimeOnly(booking.datetime),
                                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: _statusBg(status),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      _statusText(status),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 0.5,
                                                        color: _statusColor(status),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            }).toList(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),

                  // Floating Action Button - New Booking
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SelectServicesPage()),
                        ).then((_) => _fetchBookings()); // Auto-refresh after booking
                      },
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, buttonColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                      ),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, -8))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, "HOME", Icons.home_filled),
              _buildNavItem(1, "BOOKING", Icons.calendar_month_rounded),
              _buildNavItem(2, "SERVICES", Icons.content_cut_rounded),
              _buildNavItem(3, "REPORT", Icons.bar_chart_rounded),
              _buildNavItem(4, "SETTINGS", Icons.settings_rounded),
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
        else if (index == 2) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ManageServicesPage()), (r) => false);
        else if (index == 3) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ReportPage()), (r) => false);
        else if (index == 4) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SettingsPage()), (r) => false);
        else setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? primaryColor : const Color(0xFF94A3B8), size: 28),
          const SizedBox(height: 6),
          Text(
            label, 
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w800, 
              color: isSelected ? primaryColor : const Color(0xFF94A3B8), 
              letterSpacing: 0.5
            )
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

