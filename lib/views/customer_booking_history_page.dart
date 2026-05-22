import 'package:flutter/material.dart';
import '../models/booking_list_model.dart';
import '../controllers/booking_list_controller.dart';
import 'package:intl/intl.dart';
import 'booking_details_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/loyalty_constants.dart';
import '../app_session.dart';

class CustomerBookingHistoryPage extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerBookingHistoryPage({super.key, required this.customer});

  @override
  State<CustomerBookingHistoryPage> createState() =>
      _CustomerBookingHistoryPageState();
}

class _CustomerBookingHistoryPageState
    extends State<CustomerBookingHistoryPage> {
  bool get isDark => AppSession.isDarkMode;
  Color get primaryColor => const Color(0xFFD660A1);
  Color get scaffoldBg => isDark ? const Color(0xFF1E293B) : const Color(0xFFF6F8FA);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get cardBg => isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get mainTextColor => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A);
  Color get borderCol => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _loading = true;
  List<BookingListModel> _bookings = [];
  final BookingListController _bookingListController = BookingListController();

  @override
  void initState() {
    super.initState();
    _fetchCustomerBookings();
  }

  Future<void> _fetchCustomerBookings() async {
    setState(() => _loading = true);
    try {
      final allBookings = await _bookingListController.fetchBookings();
      final customerPhone =
          widget.customer['phone']?.toString().toLowerCase() ?? '';
      final customerEmail =
          widget.customer['email']?.toString().toLowerCase() ?? '';

      final filtered = allBookings.where((b) {
        return (customerPhone.isNotEmpty &&
                b.customerPhone.toLowerCase() == customerPhone) ||
            (customerEmail.isNotEmpty &&
                b.customerEmail.toLowerCase() == customerEmail);
      }).toList();

      if (mounted) {
        setState(() {
          _bookings = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching customer bookings: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // Determine tier from spend
  String _getTier() {
    final spend = widget.customer['spend'] as int? ?? 0;
    if (spend >= 3000000) return 'Platinum';
    if (spend >= 2000000) return 'Gold';
    if (spend >= 1000000) return 'Silver';
    return 'Reguler';
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Platinum':
        return isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
      case 'Gold':
        return const Color(0xFFEAB308);
      case 'Silver':
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      default:
        return mutedText;
    }
  }

  Color _getTierBg(String tier) {
    switch (tier) {
      case 'Platinum':
        return isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
      case 'Gold':
        return isDark ? const Color(0xFF78350F).withOpacity(0.3) : const Color(0xFFFEF9C3);
      case 'Silver':
        return isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      default:
        return isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier) {
      case 'Platinum':
        return Icons.workspace_premium;
      case 'Gold':
        return Icons.stars;
      case 'Silver':
        return Icons.star_half;
      default:
        return Icons.person;
    }
  }

  /// Opens WhatsApp to the customer's number with a tier-specific invite message
  Future<void> _inviteToWhatsApp(String tier) async {
    String phone = widget.customer['phone']?.toString() ?? '';
    if (phone.isEmpty || phone == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor HP pelanggan tidak tersedia.')),
      );
      return;
    }

    // Normalize phone
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('62')) {
      cleanPhone = '62$cleanPhone';
    }

    final String name = widget.customer['name'] ?? 'Pelanggan';
    final String groupLink = LoyaltyConstants.groupLinkForTier(tier);

    final String message =
        'Halo $name! 🌸\n\n'
        'Selamat, kamu telah menjadi *$tier Member* di *Indah Sari Salon*! 🎉\n\n'
        'Sebagai member eksklusif, kamu diundang untuk bergabung ke grup $tier kami:\n'
        '$groupLink\n\n'
        'Di sana kamu akan mendapatkan info promo eksklusif, tips kecantikan, dan banyak keuntungan lainnya.\n\n'
        'Terima kasih atas kepercayaan kamu! 💖';

    final Uri uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp.')),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'berhasil':
      case 'success':
        return isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
      case 'dibatalkan':
      case 'cancelled':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      default:
        return isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'berhasil':
      case 'success':
        return isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
      case 'dibatalkan':
      case 'cancelled':
        return isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
      default:
        return isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5);
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

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final date = DateFormat('d MMM yyyy').format(dt);
      final time = DateFormat('HH:mm').format(dt);
      return '$date • $time';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String tier = _getTier();
    final Color tierColor = _getTierColor(tier);
    final Color tierBg = _getTierBg(tier);
    final bool hasTier = tier != 'Reguler';

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking History',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.customer['name'],
                          style: TextStyle(color: mutedText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Membership Card (only if has tier) ──────────────────
            if (hasTier)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                ).copyWith(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tierBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tierColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      // Tier icon badge
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: tierColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTierIcon(tier),
                          color: tierColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Tier info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$tier Member',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: tierColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total spend: ${_currency.format(widget.customer['spend'])}',
                              style: TextStyle(fontSize: 12, color: mutedText),
                            ),
                          ],
                        ),
                      ),
                      // WA Invite button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text(
                          'Undang',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _inviteToWhatsApp(tier),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Booking History List ─────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _bookings.isEmpty
                  ? Center(
                      child: Text(
                        'No booking history for this customer.',
                        style: TextStyle(color: mutedText),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        final status = booking.status;
                        final services = booking.services;
                        final serviceLabel =
                            services.take(2).join(', ') +
                            (services.length > 2
                                ? ' +${services.length - 2}${'  others'}'
                                : '');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingDetailsPage(
                                    booking: booking.toMap(),
                                  ),
                                ),
                              ).then((_) => _fetchCustomerBookings());
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderCol, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE4F0FA),
                                        ),
                                        child: const Icon(
                                          Icons.content_cut,
                                          color: Color(0xFFD660A1),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              serviceLabel,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: mainTextColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${'with '}${booking.stylist}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: mutedText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusBg(status),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          _statusText(status),
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
                                  Divider(
                                    color: borderCol,
                                    height: 1,
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 13,
                                            color: mutedText,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatDateTime(booking.datetime),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _currency.format(
                                          booking.totalPrice.toDouble(),
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
