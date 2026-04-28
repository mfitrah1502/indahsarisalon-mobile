import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'select_services_page.dart';
import 'booking_details_page.dart';
import 'manage_services_page.dart';
import 'report_page.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int _selectedIndex = 1;
  bool _loading = true;
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _loading = true);
    try {
      // Fetch bookings with stylist name and customer info (if user_id present)
      final data = await Supabase.instance.client
          .from('bookings')
          .select('id, created_at, reservation_datetime, total_price, status, customer_name, customer_phone, customer_email, user_id, stylist_id, users!bookings_stylist_id_fkey(name), customer:users!bookings_user_id_fkey(phone, email)')
          .order('created_at', ascending: false); // Order by creation date DESC

      // For each booking, fetch service names from booking_details
      final List<Map<String, dynamic>> enriched = [];
      for (final row in data) {
        final bookingId = row['id'];
        final details = await Supabase.instance.client
            .from('booking_details')
            .select('treatment_detail_id, treatment_details(name, treatment_id, treatments(name))')
            .eq('booking_id', bookingId);

        List<String> serviceNames = [];
        for (final d in details) {
          final td = d['treatment_details'] as Map<String, dynamic>?;
          final t = td?['treatments'] as Map<String, dynamic>?;
          final tName = t?['name'] ?? '';
          final dName = td?['name'] ?? '';
          if (tName == dName || dName.isEmpty) {
            serviceNames.add(tName);
          } else {
            serviceNames.add("$tName - $dName");
          }
        }

        dynamic stylistData = row['users'];
        String stylistName = 'Unknown';
        if (stylistData != null) {
          if (stylistData is Map) {
            stylistName = stylistData['name'] ?? 'Unknown';
          } else if (stylistData is List && stylistData.isNotEmpty) {
            stylistName = stylistData[0]['name'] ?? 'Unknown';
          }
        }

        // Fallback for phone and email from the users table (customer:users!bookings_user_id_fkey)
        Map<String, dynamic>? linkedCustomer = row['customer'] as Map<String, dynamic>?;
        String finalPhone = row['customer_phone'] ?? '-';
        String finalEmail = row['customer_email'] ?? '-';

        if ((finalPhone == '-' || finalPhone == 'null') && linkedCustomer != null) {
          finalPhone = linkedCustomer['phone'] ?? '-';
        }
        if ((finalEmail == '-' || finalEmail == 'null') && linkedCustomer != null) {
          finalEmail = linkedCustomer['email'] ?? '-';
        }

        enriched.add({
          'id': bookingId,
          'created_at': row['created_at'],
          'stylist': stylistName,
          'services': serviceNames.isEmpty ? ['Booking #$bookingId'] : serviceNames,
          'datetime': row['reservation_datetime'],
          'total_price': row['total_price'],
          'status': row['status'] ?? 'pending',
          'customer_name': row['customer_name'] ?? '-',
          'customer_phone': finalPhone,
          'customer_email': finalEmail,
        });
      }

      if (mounted) {
        setState(() {
          _bookings = enriched;
          _filteredBookings = enriched;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, List<Map<String, dynamic>>> _getGroupedBookings() {
    Map<String, List<Map<String, dynamic>>> groups = {};
    for (var b in _filteredBookings) {
      final createdAtStr = b['created_at'] as String?;
      if (createdAtStr == null) continue;
      
      final date = DateTime.parse(createdAtStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final itemDate = DateTime(date.year, date.month, date.day);

      String groupKey;
      if (itemDate == today) {
        groupKey = "Hari Ini";
      } else if (itemDate == yesterday) {
        groupKey = "Kemarin";
      } else {
        groupKey = DateFormat('EEEE, d MMMM yyyy', 'id').format(itemDate);
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
        final custName = (b['customer_name'] ?? '').toString().toLowerCase();
        final stylName = (b['stylist'] ?? '').toString().toLowerCase();
        final phone = (b['customer_phone'] ?? '').toString().toLowerCase();
        final email = (b['customer_email'] ?? '').toString().toLowerCase();
        return custName.contains(lowerQuery) || stylName.contains(lowerQuery) ||
               phone.contains(lowerQuery) || email.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _deleteAllBookings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Semua Booking?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Tindakan ini akan menghapus permanen seluruh daftar booking dari database. Lanjutkan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await Supabase.instance.client.from('booking_details').delete().neq('id', 0);
        await Supabase.instance.client.from('bookings').delete().neq('id', 0);
        _fetchBookings();

      } catch (e) {
        debugPrint("Error deleting: $e");
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'berhasil': return const Color(0xFF16A34A);
      case 'dibatalkan': return const Color(0xFFDC2626);
      default: return const Color(0xFFEA580C); // pending/upcoming
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'berhasil': return const Color(0xFFDCFCE7);
      case 'dibatalkan': return const Color(0xFFFEE2E2);
      default: return const Color(0xFFFFEDD5);
    }
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final date = DateFormat('d MMM yyyy').format(dt);
      final time = DateFormat('HH:mm').format(dt);
      return "$date • $time";
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
                      child: Text(
                        "Daftar Booking", 
                        style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  // Actions Right
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _fetchBookings,
                        child: Icon(Icons.refresh, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _bookings.isEmpty ? null : _deleteAllBookings,
                        child: Icon(Icons.delete_outline, color: _bookings.isEmpty ? Colors.grey : Colors.red, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterBookings,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Color(0xFF64748B)),
                    hintText: 'Cari by Nama atau Stylist...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "SCHEDULE OVERVIEW",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: mutedText),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Your Appointments",
                                style: TextStyle(color: primaryColor, fontSize: 26, fontWeight: FontWeight.w900),
                              ),
                              Text("${_filteredBookings.length} total", style: TextStyle(color: mutedText, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (_filteredBookings.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 80.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 56, color: const Color(0xFFCBD5E1)),
                                    const SizedBox(height: 16),
                                    Text("Belum ada booking.", style: TextStyle(color: mutedText, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Text("Tekan tombol + untuk buat booking baru.", style: TextStyle(color: mutedText, fontSize: 13)),
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
                                    padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: primaryColor,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...entry.value.map((booking) {
                                    final status = booking['status'] as String;
                                    final services = booking['services'] as List<String>;
                                    final serviceLabel = services.take(2).join(", ") + (services.length > 2 ? " +${services.length - 2} lainnya" : "");

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BookingDetailsPage(booking: booking),
                                            ),
                                          ).then((_) => _fetchBookings()); // Refresh on return
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Stylist avatar
                                                  Container(
                                                    width: 50, height: 50,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      color: const Color(0xFFE4F0FA),
                                                    ),
                                                    child: Icon(Icons.person, color: primaryColor, size: 28),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          booking['customer_name'] != '-' ? "${booking['customer_name']}" : "Pelanggan",
                                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          serviceLabel,
                                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          "dengan ${booking['stylist']}",
                                                          style: TextStyle(fontSize: 12, color: mutedText),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: _statusBg(status),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      status.toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 0.5,
                                                        color: _statusColor(status),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 14),
                                              const Divider(color: Color(0xFFF1F5F9), height: 1),
                                              const SizedBox(height: 14),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.calendar_today_outlined, size: 13, color: mutedText),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _formatDateTime(booking['datetime']),
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    _currency.format((booking['total_price'] as num).toDouble()),
                                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: primaryColor),
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

                  // FAB - New Booking
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
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
        if (index == 0) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false);
        else if (index == 2) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ManageServicesPage()), (r) => false);
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
