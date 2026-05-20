import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'report_page.dart';
import '../app_session.dart';
import 'receipt_page.dart';
import '../utils/popup_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'booking_page.dart';
import '../controllers/loyalty_controller.dart';
import '../utils/loyalty_constants.dart';

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  int _selectedIndex = 1;
  bool _updating = false;

  String get _status => widget.booking['status'] as String? ?? 'pending';

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'berhasil':
      case 'success':
        return const Color(0xFF16A34A);
      case 'dibatalkan':
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFEA580C);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'berhasil':
      case 'success':
        return const Color(0xFFDCFCE7);
      case 'dibatalkan':
      case 'cancelled':
        return const Color(0xFFFEE2E2);
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

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final date = DateFormat('EEEE, d MMMM yyyy', 'en').format(dt);
      final time = DateFormat('HH:mm').format(dt);
      return "$date\n$time WIB";
    } catch (_) {
      return raw;
    }
  }

  String _translatePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'tunai':
        return 'Cash';
      case 'transfer':
        return 'Bank Transfer';
      default:
        return method;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', widget.booking['id']);

      if (newStatus.toLowerCase() == 'success') {
        final amount = widget.booking['total_price'] ?? 0;
        final result = await LoyaltyController.processBookingCompletion(
          amount: amount as num,
          userId: widget.booking['user_id'] as int?,
          customerPhone: widget.booking['customer_phone'] as String?,
          customerEmail: widget.booking['customer_email'] as String?,
        );
        if (result != null && result['upgraded'] == true) {
          _showTierUpgradeDialog(result['new_tier'] as String);
          return; // Don't pop immediately so they can see the dialog
        }
      }

      try {
        final userId = AppSession.userId;
        if (userId != null) {
          String statusText = newStatus.toLowerCase() == 'success'
              ? 'Completed'
              : (newStatus.toLowerCase() == 'cancelled'
                    ? 'Cancelled'
                    : newStatus);
          String formattedDt = widget.booking['datetime'] ?? '';
          try {
            final dt = DateTime.parse(formattedDt).toLocal();
            final date = DateFormat('d MMMM yyyy', 'en').format(dt);
            final time = DateFormat('HH:mm').format(dt);
            formattedDt = "$date at $time WIB";
          } catch (_) {}

          await Supabase.instance.client.from('notifikasi').insert({
            'user_id': userId,
            'title': 'Booking Status Updated',
            'message': 'Booking schedule \n$formattedDt status is $statusText.',
            'booking_id': widget.booking['id'],
          });
        }
      } catch (e) {
        debugPrint('Failed to send Notification: $e');
      }

      if (mounted) {
        Navigator.pop(
          context,
          true,
        ); // Pop back to list page to trigger _fetchBookings
      }
    } catch (e) {
      debugPrint('Error updating booking: $e');
      if (mounted) {
        setState(() => _updating = false);
        PopupHelper.showError(context, "Failed to update: $e");
      }
    }
  }

  void _showTierUpgradeDialog(String tier) {
    final String groupUrl = LoyaltyConstants.groupLinkForTier(tier);
    final String customerName = widget.booking['customer_name'] ?? 'Customer';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.stars, color: primaryColor),
            const SizedBox(width: 10),
            Text(
              '$tier Member! 🎉',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hai $customerName, kamu telah memasuki $tier Member! '
              'Please join our available $tier group.',
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Link Grup $tier:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              groupUrl,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: Text('Nanti Saja', style: TextStyle(color: mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final uri = Uri.parse(groupUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context, true);
              }
            },
            child: const Text(
              'Gabung Grup',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking() async {
    PopupHelper.showConfirm(
      context,
      title: "Cancel Booking?",
      message: "Cancelled bookings cannot be restored.",
      onConfirm: () async {
        await _updateStatus('dibatalkan');
      },
    );
  }

  Future<void> _rescheduleBooking() async {
    // We need to extract the services in the format expected by BookingPage
    final details = widget.booking['full_details'] as List<dynamic>? ?? [];
    List<Map<String, dynamic>> services = [];
    int totalDuration = 0;

    for (var d in details) {
      final td = d['treatment_details'] as Map<String, dynamic>?;
      if (td != null) {
        services.add({
          'td_id': d['treatment_detail_id'],
          'name': td['name'],
          'treatment_name': td['treatments']?['name'],
          'price': d['price'],
          'adjusted_price': d['price'],
          'treatment_id': td['treatment_id'],
          'customer_name': widget.booking['customer_name'],
          'customer_phone': widget.booking['customer_phone'],
          'customer_email': widget.booking['customer_email'],
        });
        totalDuration += (td['duration'] as num?)?.toInt() ?? 0;
      }
    }

    if (services.isEmpty) {
      PopupHelper.showError(
        context,
        "Data layanan tidak lengkap untuk reschedule.",
      );
      return;
    }

    final String stylistName = widget.booking['stylist'] ?? 'Stylist';
    final int stylistId = widget.booking['stylist_id'] ?? 0;

    if (stylistId == 0) {
      PopupHelper.showError(context, "ID Stylist tidak ditemukan.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(
          selectedDate: DateTime.now(),
          stylistId: stylistId,
          stylistName: stylistName,
          totalDuration: totalDuration,
          selectedServices: services,
          totalPrice: (widget.booking['total_price'] as num).toInt(),
          isRescheduling: true,
          rescheduleBookingId: widget.booking['id'],
        ),
      ),
    ).then((val) {
      if (val == true) {
        Navigator.pop(context, true);
      }
    });
  }

  Future<void> _sendWhatsAppReminder() async {
    final String phone = widget.booking['customer_phone'] ?? '';
    if (phone == '-' || phone.isEmpty) {
      PopupHelper.showError(context, "Nomor telepon pelanggan tidak tersedia.");
      return;
    }

    // Clean phone number
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('62')) {
      cleanPhone = '62$cleanPhone';
    }

    final String time = widget.booking['datetime'].toString().substring(11, 16);
    final String message =
        "Halo ${widget.booking['customer_name']}, ini reminder dari *Indah Sari Salon*. 🌸\n\n"
        "Treatment Anda dijadwalkan pukul *$time WIB*. Apakah ada perubahan jadwal atau konfirmasi kehadiran? \n\n"
        "Terima kasih!";

    final url =
        "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      PopupHelper.showError(context, "Failed to open WhatsApp.");
    }
  }

  Future<void> _broadcastToGroup() async {
    final datetimeRaw =
        widget.booking['datetime'] ??
        widget.booking['reservation_datetime'] ??
        '';
    final String date = datetimeRaw.toString().substring(0, 10);
    final String time = datetimeRaw.toString().substring(11, 16);

    // Extract services
    final details = widget.booking['full_details'] as List<dynamic>? ?? [];
    String servicesStr = "";
    if (details.isNotEmpty) {
      servicesStr = details
          .map((d) => d['treatment_details']?['name'] ?? '')
          .where((s) => s.isNotEmpty)
          .join(", ");
    } else {
      final s = widget.booking['services'];
      if (s is List)
        servicesStr = s.join(", ");
      else if (s is String)
        servicesStr = s;
    }

    final String message =
        "*BOOKING BARU - INDAH SARI SALON*\n\n"
        "📍 *Stylist:* ${widget.booking['stylist'] ?? 'Stylist'}\n"
        "👤 *Customer:* ${widget.booking['customer_name'] ?? 'Customer'}\n"
        "📅 *Jadwal:* $date | $time WIB\n"
        "💇 *Treatment:* $servicesStr\n\n"
        "_Mohon bersiap sebelum jam booking. Terima kasih!_";

    try {
      // Use Share.share which automatically "pastes" the message into the text box
      // when the user selects a contact or group in WhatsApp.
      await Share.share(message);
    } catch (e) {
      debugPrint("Error broadcasting: $e");
      // Fallback to clipboard if sharing fails
      await Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        PopupHelper.showInfo(context, "Pesan disalin ke clipboard.");
      }
    }
  }

  Future<void> _showReceipt() async {
    final TextEditingController amountController = TextEditingController();

    final String storedMethod = widget.booking['payment_method'] ?? 'Cash';
    final bool isCash =
        storedMethod.toLowerCase() == 'cash' ||
        storedMethod.toLowerCase() == 'tunai';

    // Default amount paid = total price
    final totalPrice = (widget.booking['total_price'] as num?)?.toDouble() ?? 0;
    amountController.text = totalPrice.toInt().toString();

    Map<String, dynamic>? result;

    if (isCash) {
      // For Cash, we still need to know how much they paid to calculate change
      result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cash Payment',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter amount received:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: primaryColor,
                  ),
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
                  labelText: 'Amount Paid',
                  labelStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: mutedText,
                      side: const BorderSide(
                        color: Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: mutedText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final double amt =
                          double.tryParse(amountController.text) ?? totalPrice;
                      Navigator.pop(context, {
                        'amount': amt,
                        'method': storedMethod,
                      });
                    },
                    child: const Text(
                      'Show Receipt',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // For QRIS/Transfer, we assume they paid exactly the total price
      result = {'amount': totalPrice, 'method': storedMethod};
    }

    if (result != null && mounted) {
      final double amountPaid = result['amount'];
      final String paymentMethod = result['method'];

      // Get individual prices from rawData['full_details']
      List<dynamic> fullDetails =
          widget.booking['rawData']?['full_details'] ??
          widget.booking['full_details'] ??
          [];
      final List<Map<String, dynamic>> services = [];

      // If fullDetails is empty, try to fetch it dynamically from Supabase
      if (fullDetails.isEmpty) {
        try {
          final supabase = Supabase.instance.client;
          fullDetails = await supabase
              .from('booking_details')
              .select(
                'price, treatment_detail_id, treatment_details(name, price, treatment_id, treatments(name))',
              )
              .eq('booking_id', widget.booking['id']);
        } catch (e) {
          debugPrint("Error fetching details dynamically: $e");
        }
      }

      if (fullDetails.isNotEmpty) {
        for (final d in fullDetails) {
          final td = d['treatment_details'] as Map<String, dynamic>?;
          final t = td?['treatments'] as Map<String, dynamic>?;
          final tName = t?['name'] ?? '';
          final dName = td?['name'] ?? '';
          // Priority: price from booking_details, then fallback to current treatment price
          final price =
              (d['price'] as num?)?.toDouble() ??
              (td?['price'] as num?)?.toDouble() ??
              0;

          String displayName = (tName == dName || dName.isEmpty)
              ? tName
              : "$tName - $dName";
          services.add({'name': displayName, 'price': price});
        }
      } else {
        // Fallback to simple services list
        final servicesRaw =
            (widget.booking['services'] as List<dynamic>? ?? []);
        for (var s in servicesRaw) {
          services.add({
            'name': s.toString(),
            'price': servicesRaw.length == 1 ? totalPrice : 0,
          });
        }
      }

      // Final check: if we have only one service and its price is 0, but we have a totalPrice
      if (services.length == 1 &&
          (services[0]['price'] == 0 || services[0]['price'] == null) &&
          totalPrice > 0) {
        services[0]['price'] = totalPrice;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptPage(
            transactionId: '#IS2-${widget.booking['id']}',
            transactionDate:
                DateTime.tryParse(widget.booking['datetime'] ?? '') ??
                DateTime.now(),
            services: services,
            paymentMethod: paymentMethod,
            amountPaid: amountPaid,
            discountAmount: 0,
            discountPercentage: 0,
            totalOverride: totalPrice,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final datetimeRaw = booking['datetime'] as String? ?? '';
    final totalPrice = (booking['total_price'] as num?)?.toDouble() ?? 0;

    final fullDetails = (booking['rawData']?['full_details'] as List<dynamic>?) ?? (booking['full_details'] as List<dynamic>?) ?? [];
    List<Map<String, dynamic>> richServices = [];
    if (fullDetails.isNotEmpty) {
      for (final d in fullDetails) {
        final td = d['treatment_details'] as Map<String, dynamic>?;
        final t = td?['treatments'] as Map<String, dynamic>?;
        final tName = t?['name'] ?? '';
        final dName = td?['name'] ?? '';
        final imageUrl = td?['image_url'] ?? t?['image'];
        String displayName = (tName == dName || dName.isEmpty) ? tName : "$tName - $dName";
        richServices.add({'name': displayName, 'image': imageUrl});
      }
    } else {
      final services = (booking['services'] as List<dynamic>? ?? []);
      for (var s in services) {
        richServices.add({'name': s.toString(), 'image': null});
      }
    }

    String? headerImageUrl;
    for (var s in richServices) {
      if (s['image'] != null && s['image'].toString().isNotEmpty) {
        headerImageUrl = s['image'].toString();
        break;
      }
    }

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
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookingListPage(),
                      ),
                      (r) => false,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Booking Details",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg(_status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: _statusColor(_status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Status: ${_statusText(_status)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _statusColor(_status),
                            ),
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header image area
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              gradient: headerImageUrl == null ? LinearGradient(
                                colors: [primaryColor, const Color(0xFF1B547A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ) : null,
                              image: headerImageUrl != null ? DecorationImage(
                                image: NetworkImage(headerImageUrl),
                                fit: BoxFit.cover,
                              ) : null,
                            ),
                            child: headerImageUrl == null ? const Center(
                              child: Icon(
                                Icons.content_cut,
                                size: 64,
                                color: Colors.white30,
                              ),
                            ) : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "SERVICES",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: mutedText,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...richServices.map(
                                  (s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 18,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            s['name'],
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TIME",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: mutedText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      color: primaryColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatDateTime(datetimeRaw),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          height: 1.4,
                                        ),
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
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TOTAL / METODE",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: mutedText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currency.format(totalPrice),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _translatePaymentMethod(
                                    widget.booking['payment_method'] ?? 'Cash',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: mutedText,
                                  ),
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFFE4F0FA),
                              image: (booking['stylist_avatar'] != null && booking['stylist_avatar'].toString().isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(booking['stylist_avatar']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (booking['stylist_avatar'] == null || booking['stylist_avatar'].toString().isEmpty)
                                ? Icon(
                                    Icons.person,
                                    color: primaryColor,
                                    size: 28,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['stylist'] ?? '-',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  "Stylist",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (_) => const Icon(
                                Icons.star,
                                color: Color(0xFFFBBF24),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Customer Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CUSTOMER INFORMATION",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: mutedText,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  booking['customer_name'] != null &&
                                          booking['customer_name'] != '-'
                                      ? booking['customer_name']
                                      : 'Customer',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  booking['customer_phone'] != null &&
                                          booking['customer_phone'] != '-'
                                      ? booking['customer_phone']
                                      : 'No phone number',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: mutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  booking['customer_email'] != null &&
                                          booking['customer_email'] != '-'
                                      ? booking['customer_email']
                                      : '-',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: mutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons based on status
                    if (_status.toLowerCase() == 'pending') ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sendWhatsAppReminder,
                              icon: const Icon(Icons.chat, size: 18),
                              label: const Text(
                                "WhatsApp",
                                style: TextStyle(fontSize: 11),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _broadcastToGroup,
                              icon: const Icon(
                                Icons.group_add_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                "Broadcast",
                                style: TextStyle(fontSize: 11),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _rescheduleBooking,
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                "Reschedule",
                                style: TextStyle(fontSize: 11),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 4,
                          ),
                          onPressed: _updating
                              ? null
                              : () => _updateStatus('success'),
                          child: _updating
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  "Mark as Done",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: _updating ? null : _cancelBooking,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Cancel Booking",
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
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
                          "This booking is already ${_statusText(_status)}.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _statusColor(_status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_status.toLowerCase() != 'cancelled') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _showReceipt,
                            icon: Icon(Icons.receipt_long, color: primaryColor),
                            label: Text(
                              "View Receipt",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
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
        if (index == 0)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (r) => false,
          );
        else if (index == 1)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BookingListPage()),
            (r) => false,
          );
        else if (index == 2)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ManageServicesPage()),
            (r) => false,
          );
        else if (index == 3)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ReportPage()),
            (r) => false,
          );
        else if (index == 4)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
            (r) => false,
          );
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
