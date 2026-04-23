import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../app_session.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'report_page.dart';
import '../utils/midtrans_helper.dart';
import 'package:url_launcher/url_launcher.dart';



class PaymentDetailsPage extends StatefulWidget {
  final int stylistId;
  final String stylistName;
  final String reservationDatetime;
  final List<Map<String, dynamic>> selectedServices;
  final int totalPrice;
  final String customerName;
  final String customerPhone;
  final String customerEmail;

  const PaymentDetailsPage({
    super.key,
    required this.stylistId,
    required this.stylistName,
    required this.reservationDatetime,
    required this.selectedServices,
    required this.totalPrice,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
  });

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int _selectedPaymentIndex = 2; // Default: Cash at Salon
  int _selectedIndex = 1;
  bool _processing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {"title": "Transfer Bank", "subtitle": "Konfirmasi manual", "icon": Icons.account_balance_outlined},
    {"title": "E-Wallet", "subtitle": "GoPay, OVO, Dana", "icon": Icons.account_balance_wallet_outlined},
    {"title": "Cash di Salon", "subtitle": "Bayar setelah layanan", "icon": Icons.money},
  ];

  Future<void> _confirmBooking() async {
    setState(() => _processing = true);
    final supabase = Supabase.instance.client;

    try {
      // Get user_id from current session
      final userId = AppSession.userId;
      if (userId == null) {
        throw Exception('Sesi tidak ditemukan. Silakan login ulang.');
      }
      
      // Safely get first treatment_id (must not be null)
      int? treatmentId;
      for (final svc in widget.selectedServices) {
        if (svc['treatment_id'] != null) {
          treatmentId = svc['treatment_id'] as int;
          break;
        }
      }
      if (treatmentId == null) {
        throw Exception("treatment_id tidak ditemukan. Silakan coba booking ulang.");
      }

      // Determine payment status (Staff + Cash = Paid immediately)
      String paymentStatus = (_selectedPaymentIndex == 2) ? 'paid' : 'unpaid';
      if (AppSession.userRole?.toLowerCase() == 'admin' || AppSession.userRole?.toLowerCase() == 'karyawan') {
        if (_selectedPaymentIndex == 2) { // 2 is Cash
          paymentStatus = 'paid';
        }
      }
      final bookingInsert = await supabase.from('bookings').insert({
        'user_id': userId,
        'stylist_id': widget.stylistId,
        'treatment_id': treatmentId,
        'reservation_datetime': widget.reservationDatetime,
        'total_price': widget.totalPrice,
        'status': 'pending',
        'payment_status': paymentStatus,
        'payment_method': _selectedPaymentIndex == 2 ? 'cash' : (_selectedPaymentIndex == 0 ? 'transfer' : 'midtrans'),
        'customer_name': widget.customerName,
        'customer_phone': widget.customerPhone,
        'customer_email': widget.customerEmail,
      }).select('id').single();

      final bookingId = bookingInsert['id'];

      // Insert booking_details for each service
      for (final svc in widget.selectedServices) {
        final price = svc['adjusted_price'] ?? svc['price'];
        await supabase.from('booking_details').insert({
          'booking_id': bookingId,
          'treatment_detail_id': svc['td_id'],
          'stylist_id': widget.stylistId,
          'price': price,
        });
      }

      try {
        await supabase.from('notifikasi').insert({
          'user_id': userId,
          'title': 'Booking Berhasil',
          'message': 'Booking untuk jadwal ${widget.reservationDatetime.substring(0, 16)} dengan stylist ${widget.stylistName} telah berhasil dibuat.',
        });
      } catch (e) {
        debugPrint('Failed to insert notification: $e');
      }

      if (!mounted) return;

      if (!mounted) return;

      // Handle Midtrans ONLY for E-Wallet (Index 1)
      if (_selectedPaymentIndex == 1) {
        try {
          final redirectUrl = await MidtransHelper.createTransaction(
            orderId: "BOOKING-$bookingId-${DateTime.now().millisecondsSinceEpoch}",
            grossAmount: widget.totalPrice,
            customerName: widget.customerName,
            customerEmail: widget.customerEmail,
            customerPhone: widget.customerPhone,
          );
          
          if (redirectUrl != null) {
            final uri = Uri.parse(redirectUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        } catch (e) {
          debugPrint("Midtrans Error: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Gagal membuka halaman pembayaran Midtrans: $e"), backgroundColor: Colors.orange),
            );
          }
        }

        if (!mounted) return;
        
        // Redirect to Booking List Page after launching Midtrans
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BookingListPage()),
          (route) => false,
        );
      } else {
        // For Bank Transfer or Cash, show the Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: const Color(0xFFE4F0FA), shape: BoxShape.circle),
                  child: Icon(Icons.check, color: primaryColor, size: 36),
                ),
                const SizedBox(height: 16),
                Text("Booking Berhasil!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                const SizedBox(height: 8),
                Text(
                  "Jadwal dengan ${widget.stylistName} telah tersimpan.\n${widget.reservationDatetime.substring(0, 16).replaceFirst(' ', ' | ')}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedText, fontSize: 13),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingListPage()),
                      (route) => false,
                    );
                  },
                  child: const Text("Lihat Daftar Booking", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      debugPrint('Booking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan booking: $e"), backgroundColor: Colors.red),
        );
        setState(() => _processing = false);
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
                        padding: const EdgeInsets.only(right: 44.0),
                        child: Text(
                          "Detail Pembayaran",
                          style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
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
                    // Booking Summary Title
                    Text("RINGKASAN BOOKING", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: mutedText)),
                    const SizedBox(height: 12),

                    // Booking Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stylist
                          Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFE4F0FA)),
                                child: Icon(Icons.person, color: primaryColor, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("STYLIST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: mutedText)),
                                  const SizedBox(height: 2),
                                  Text(widget.stylistName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Date-time Row
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 14, color: mutedText),
                              const SizedBox(width: 8),
                              Text(
                                widget.reservationDatetime.substring(0, 16).replaceFirst(' ', ' • '),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Divider(color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 12),

                          // Services list
                          ...widget.selectedServices.map((svc) {
                            final title = svc['treatment_name'] == svc['detail_name'] || (svc['detail_name'] ?? '').toString().isEmpty
                                ? svc['treatment_name']
                                : "${svc['treatment_name']} - ${svc['detail_name']}";
                            
                            final price = svc['adjusted_price'] ?? svc['price'];
                            final originalPrice = svc['price'] ?? 0;
                            final bool isPromo = svc['is_promo'] == true;
                            final bool isManuallyAdjusted = svc['adjusted_price'] != null;
                            
                            final dur = (svc['duration'] as num?)?.toInt() ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time_outlined, size: 12, color: mutedText),
                                            const SizedBox(width: 4),
                                            Text(
                                              dur > 0 ? "$dur Menit" : "- Menit",
                                              style: TextStyle(color: mutedText, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isPromo && !isManuallyAdjusted && originalPrice != price)
                                        Text(
                                          _currencyFormat.format(originalPrice),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: mutedText,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      Text(
                                        _currencyFormat.format(price),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: (isPromo && !isManuallyAdjusted) ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),

                          const Divider(color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                              Text(_currencyFormat.format(widget.totalPrice), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryColor)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Payment Method
                    Text("METODE PEMBAYARAN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: mutedText)),
                    const SizedBox(height: 12),

                    Column(
                      children: List.generate(_paymentMethods.length, (index) {
                        final method = _paymentMethods[index];
                        final isSelected = _selectedPaymentIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedPaymentIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFFF4F7F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0).withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(method["icon"], size: 20, color: primaryColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(method["title"], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
                                      Text(method["subtitle"], style: TextStyle(fontSize: 12, color: mutedText)),
                                    ],
                                  ),
                                ),
                                isSelected
                                    ? Icon(Icons.circle, color: primaryColor, size: 22)
                                    : const Icon(Icons.radio_button_unchecked, color: Color(0xFFCBD5E1), size: 22),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Total Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("TOTAL PEMBAYARAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: mutedText)),
                              const SizedBox(height: 4),
                              Text(_currencyFormat.format(widget.totalPrice), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor, height: 1.0)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_user, size: 12, color: Color(0xFFEA580C)),
                                SizedBox(width: 4),
                                Text("SECURE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFFEA580C))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 6,
                        ),
                        onPressed: _processing ? null : _confirmBooking,
                        child: _processing
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text("KONFIRMASI BOOKING", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
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
          Icon(icon, color: isSelected ? primaryColor : mutedText, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isSelected ? primaryColor : mutedText, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
