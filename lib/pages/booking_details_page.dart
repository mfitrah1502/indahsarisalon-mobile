import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'report_page.dart';
import '../app_session.dart';

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final Color darkBlue = const Color(0xFF02365A);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int _selectedIndex = 1;
  bool _updating = false;

  String get _status => widget.booking['status'] as String? ?? 'pending';

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'berhasil': return const Color(0xFF16A34A);
      case 'dibatalkan': return const Color(0xFFDC2626);
      default: return const Color(0xFFEA580C);
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
      final date = DateFormat('EEEE, d MMMM yyyy', 'id').format(dt);
      final time = DateFormat('HH:mm').format(dt);
      return "$date\n$time WIB";
    } catch (_) {
      return raw;
    }
  }

    Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', widget.booking['id']);
      
      try {
        final userId = AppSession.userId;
        if (userId != null) {
          String statusText = newStatus.toLowerCase() == 'berhasil' ? 'Telah Selesai' : (newStatus.toLowerCase() == 'dibatalkan' ? 'Telah Dibatalkan' : newStatus);
          await Supabase.instance.client.from('notifikasi').insert({
            'user_id': userId,
            'title': 'Status Booking Diperbarui',
            'message': 'Booking dengan jadwal \n${widget.booking['datetime']} statusnya $statusText.',
          });
        }
      } catch (e) {
        debugPrint('Gagal mengirim Notifikasi: $e');
      }

      if (mounted) {
        Navigator.pop(context, true); // Pop back to list page to trigger _fetchBookings
      }
    } catch (e) {
      debugPrint('Error updating booking: $e');
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memperbarui: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Batalkan Booking?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Booking yang dibatalkan tidak dapat dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Tidak")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) await _updateStatus('dibatalkan'); // Cancel status
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final services = (booking['services'] as List<String>? ?? []);
    final datetimeRaw = booking['datetime'] as String? ?? '';
    final totalPrice = (booking['total_price'] as num?)?.toDouble() ?? 0;

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
                    child: Icon(Icons.arrow_back, color: darkBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text("Detail Booking", style: TextStyle(color: darkBlue, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _statusBg(_status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: _statusColor(_status)),
                          const SizedBox(width: 8),
                          Text(
                            "Status: ${_status.toUpperCase()}",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _statusColor(_status)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Main Detail Card
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header image area
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: darkBlue,
                              gradient: LinearGradient(
                                colors: [darkBlue, const Color(0xFF1B547A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.content_cut, size: 64, color: Colors.white30),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("LAYANAN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedText, letterSpacing: 0.8)),
                                const SizedBox(height: 8),
                                ...services.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, size: 16, color: darkBlue),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(s, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: darkBlue))),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date & Time + Stylist row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("WAKTU", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: mutedText)),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.calendar_today_outlined, color: darkBlue, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatDateTime(datetimeRaw),
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkBlue, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("TOTAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: mutedText)),
                                const SizedBox(height: 8),
                                Text(
                                  _currency.format(totalPrice),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: darkBlue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stylist Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFFE4F0FA),
                            ),
                            child: Icon(Icons.person, color: darkBlue, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking['stylist'] ?? '-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue)),
                                Text("Stylist", style: TextStyle(fontSize: 13, color: mutedText)),
                              ],
                            ),
                          ),
                          Row(children: List.generate(5, (_) => const Icon(Icons.star, color: Color(0xFFFBBF24), size: 16))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons based on status
                    if (_status.toLowerCase() == 'pending') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 4,
                          ),
                          onPressed: _updating ? null : () => _updateStatus('berhasil'),
                          child: _updating
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text("Mark as Done", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: _updating ? null : _cancelBooking,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Cancel Booking", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _statusBg(_status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Booking ini sudah berstatus ${_status.toUpperCase()}.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _statusColor(_status), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),
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
        else if (index == 1) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BookingListPage()), (r) => false);
        else if (index == 2) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ManageServicesPage()), (r) => false);
        else if (index == 3) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ReportPage()), (r) => false);
        else if (index == 4) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SettingsPage()), (r) => false);
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
