import 'package:flutter/material.dart';
import '../models/booking_list_model.dart';
import '../controllers/booking_list_controller.dart';
import 'package:intl/intl.dart';
import 'booking_details_page.dart';
import '../utils/translations.dart';

class CustomerBookingHistoryPage extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerBookingHistoryPage({super.key, required this.customer});

  @override
  State<CustomerBookingHistoryPage> createState() => _CustomerBookingHistoryPageState();
}

class _CustomerBookingHistoryPageState extends State<CustomerBookingHistoryPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
      final customerPhone = widget.customer['phone']?.toString().toLowerCase() ?? '';
      final customerEmail = widget.customer['email']?.toString().toLowerCase() ?? '';
      
      final filtered = allBookings.where((b) {
        return (customerPhone.isNotEmpty && b.customerPhone.toLowerCase() == customerPhone) ||
               (customerEmail.isNotEmpty && b.customerEmail.toLowerCase() == customerEmail);
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
      final date = DateFormat('d MMM yyyy').format(dt);
      final time = DateFormat('HH:mm').format(dt);
      return "$date • $time";
    } catch (_) {
      return raw;
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Booking History".tr, 
                          style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)
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
            
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _bookings.isEmpty
                      ? Center(
                          child: Text("No booking history for this customer.".tr, style: TextStyle(color: mutedText)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            final status = booking.status;
                            final services = booking.services;
                            final serviceLabel = services.take(2).join(", ") + (services.length > 2 ? " +${services.length - 2}${" others".tr}" : "");

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingDetailsPage(booking: booking.toMap()),
                                    ),
                                  ).then((_) => _fetchCustomerBookings());
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
                                          Container(
                                            width: 50, height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: const Color(0xFFE4F0FA),
                                            ),
                                            child: Icon(Icons.content_cut, color: primaryColor, size: 28),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  serviceLabel,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "${"with ".tr}${booking.stylist}",
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
                                                _formatDateTime(booking.datetime),
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            _currency.format(booking.totalPrice.toDouble()),
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: primaryColor),
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
