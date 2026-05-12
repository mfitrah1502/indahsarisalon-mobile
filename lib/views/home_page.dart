import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../controllers/loyalty_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:whatsapp_share/whatsapp_share.dart';
import 'dart:io';
import '../controllers/home_controller.dart';
import '../models/promo_model.dart';
import 'notifications_page.dart';
import 'booking_page.dart';
import 'settings_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'report_page.dart';
import 'edit_profile_page.dart';
import 'customer_list_page.dart';
import '../app_session.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/translations.dart';
import 'promo_list_page.dart';
import '../utils/popup_helper.dart';
import '../utils/loyalty_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  // States
  bool isLoading = true;
  int todayBookings = 0;
  int todayRevenue = 0;
  int todayCustomers = 0;

  num bookingsIncrease = 0;
  num revenueIncrease = 0;
  num customersIncrease = 0;
  List<PromoModel> _promos = [];

  bool _hasUnreadNotifications = false;
  RealtimeChannel? _notifChannel;

  final HomeController _homeController = HomeController();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchPromos();
    _checkUnreadNotifications();
    _setupRealtime();
    _checkLoyaltyRetention();
  }

  Future<void> _checkLoyaltyRetention() async {
    if (AppSession.userId != null) {
      try {
        await LoyaltyController.checkRetention(AppSession.userId!);
      } catch (e) {
        debugPrint("Error checking loyalty retention: $e");
      }
    }
  }

  @override
  void dispose() {
    _notifChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final res = await Supabase.instance.client
          .from('notifikasi')
          .select('id')
          .eq('is_read', false)
          .limit(1);
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = res.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error check unread: $e');
    }
  }

  void _setupRealtime() {
    _notifChannel = Supabase.instance.client
        .channel('public:notifikasi')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifikasi',
          callback: (payload) {
            _checkUnreadNotifications();
          },
        )
        .subscribe();
  }

  Future<void> _fetchPromos() async {
    try {
      final promos = await _homeController.fetchPromos(
        userTier: AppSession.userTier,
        userRole: AppSession.userRole,
      );
      if (mounted) {
        setState(() {
          _promos = promos;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final stats = await _homeController.fetchDashboardData();
      if (mounted) {
        setState(() {
          todayBookings = stats.todayBookings;
          todayRevenue = stats.todayRevenue;
          todayCustomers = stats.todayCustomers;
          bookingsIncrease = stats.bookingsIncrease;
          revenueIncrease = stats.revenueIncrease;
          customersIncrease = stats.customersIncrease;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String formatIncrease(num percentage) {
    if (percentage > 0) return "+${percentage.toStringAsFixed(1)}${" vs yesterday".tr}";
    if (percentage < 0) return "${percentage.toStringAsFixed(1)}${" vs yesterday".tr}";
    return "Same as yesterday".tr;
  }

  void _navigateToReport() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ReportPage()),
      (route) => false,
    );
  }

  void _navigateToBooking() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BookingListPage()),
      (route) => false,
    );
  }

  void _navigateToCustomers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat('MMMM d').format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Region
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Profile Avatar
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfilePage()),
                              );
                              if (result == true && mounted) {
                                setState(() {});
                              }
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE2E8F0),
                                image: (AppSession.userAvatar != null && AppSession.userAvatar!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(AppSession.userAvatar!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: (AppSession.userAvatar != null && AppSession.userAvatar!.isNotEmpty)
                                  ? null
                                  : const Icon(
                                      Icons.person,
                                      color: Color(0xFF94A3B8),
                                      size: 28,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "${"Hello,".tr} ${AppSession.userName}!",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CustomerListPage(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.people_outline,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsPage(),
                              ),
                            ).then((_) => _checkUnreadNotifications());
                          },
                          icon: Stack(
                            children: [
                              Icon(
                                Icons.notifications_none,
                                color: primaryColor,
                                size: 28,
                              ),
                              if (_hasUnreadNotifications)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),

                // Day, Date, and Time Section
                StreamBuilder<DateTime>(
                  stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                  builder: (context, snapshot) {
                    final now = snapshot.data ?? DateTime.now();
                    final dayFormat = DateFormat('EEEE', AppTranslations.currentLanguage == 'Indonesia' ? 'id_ID' : 'en_US');
                    final dateFormat = DateFormat('d MMMM yyyy', AppTranslations.currentLanguage == 'Indonesia' ? 'id_ID' : 'en_US');
                    final timeFormat = DateFormat('HH:mm');

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.pink.shade50.withOpacity(0.3)],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.calendar_month_outlined, color: primaryColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${dayFormat.format(now)}, ${dateFormat.format(now)}",
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeFormat.format(now),
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Promo Section
                if (_promos.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "SPECIAL OFFERS".tr,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF4B5563)),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoListPage()));
                        },
                        child: Text(
                          "See All".tr,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _promos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final p = _promos[index];
                        return GestureDetector(
                          onTap: () => _showPromoDetail(p),
                          child: Container(
                            width: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                ? DecorationImage(image: NetworkImage(p.imageUrl!), fit: BoxFit.cover)
                                : null,
                              gradient: p.imageUrl == null || p.imageUrl!.isEmpty
                                ? LinearGradient(colors: [primaryColor, buttonColor])
                                : null,
                            ),
                            child: Stack(
                              children: [
                                if (p.imageUrl == null || p.imageUrl!.isEmpty)
                                  const Center(child: Icon(Icons.star, color: Colors.white, size: 48)),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.title,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          formatCurrency(p.price),
                                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Title Section
                Text(
                  "${"TODAY, ".tr}$todayFormatted",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Daily Overview".tr,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 24),

                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Stat Cards
                  GestureDetector(
                    onTap: _navigateToBooking,
                    child: _buildStatCard(
                      title: "TOTAL BOOKINGS TODAY".tr,
                      value: "$todayBookings",
                      increase: formatIncrease(bookingsIncrease),
                      iconData: Icons.calendar_today_rounded,
                      increaseColor: bookingsIncrease >= 0 ? primaryColor : Colors.red,
                      trendIcon: bookingsIncrease >= 0 ? Icons.trending_up : Icons.trending_down,
                    ),
                  ),
                  if (AppSession.userRole == 'owner') ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _navigateToReport,
                      child: _buildStatCard(
                        title: "TODAY'S REVENUE".tr,
                        value: formatCurrency(todayRevenue),
                        increase: formatIncrease(revenueIncrease),
                        iconData: Icons.payments_outlined,
                        increaseColor: revenueIncrease >= 0 ? primaryColor : Colors.red,
                        trendIcon: revenueIncrease >= 0 ? Icons.trending_up : Icons.trending_down,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _navigateToCustomers,
                    child: _buildStatCard(
                      title: "NUMBER OF CUSTOMERS".tr,
                      value: "$todayCustomers",
                      increase: formatIncrease(customersIncrease),
                      iconData: Icons.people_outline_rounded,
                      increaseColor: customersIncrease >= 0 ? primaryColor : Colors.red,
                      trendIcon: customersIncrease >= 0 ? Icons.trending_up : Icons.trending_down,
                    ),
                  ),
                ],
                const SizedBox(height: 100), // padding for bottom nav
              ],
            ),
          ),
        ),
      ),
      
      // Custom Bottom Navigation Bar
      extendBody: true,
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
              _buildNavItem(1, "BOOKING", Icons.calendar_today_outlined),
              _buildNavItem(2, "SERVICES", Icons.content_cut_rounded),
              _buildNavItem(3, "REPORT", Icons.bar_chart_rounded),
              _buildNavItem(4, "SETTINGS", Icons.settings_outlined),
            ],
          ),
        ),
      ),
    );
  }

  void _showPromoDetail(PromoModel promo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image / Header
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                image: promo.imageUrl != null && promo.imageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(promo.imageUrl!), fit: BoxFit.cover)
                  : null,
                color: primaryColor,
              ),
              child: promo.imageUrl == null || promo.imageUrl!.isEmpty
                ? const Icon(Icons.local_offer, color: Colors.white, size: 80)
                : null,
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          promo.title,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text("Promo".tr, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Get this service only for:".tr,
                    style: TextStyle(color: mutedText, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(promo.price),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  if (promo.description != null && promo.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Included Treatments:".tr,
                      style: TextStyle(color: mutedText, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promo.description!,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: mutedText),
                      const SizedBox(width: 8),
                      Text(
                        "${"Valid until: ".tr}${DateFormat('dd MMM yyyy').format(promo.endAt)}",
                        style: TextStyle(color: mutedText, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF128C7E), // Darker WhatsApp Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _broadcastToWhatsAppGroup(promo),
                      icon: const Icon(Icons.forum_rounded),
                      label: Text("Broadcast ke Grup WhatsApp".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _broadcastToWhatsAppGroup(PromoModel promo) async {
    String groupLink = LoyaltyConstants.communityGroupLink;
    String targetLabel = "Komunitas Indah Sari";

    if (promo.targetAudience == 'silver') {
      groupLink = LoyaltyConstants.silverGroupLink;
      targetLabel = "Member Silver";
    } else if (promo.targetAudience == 'gold') {
      groupLink = LoyaltyConstants.goldGroupLink;
      targetLabel = "Member Gold";
    } else if (promo.targetAudience == 'platinum') {
      groupLink = LoyaltyConstants.platinumGroupLink;
      targetLabel = "Member Platinum";
    }

    String message = "Halo semuanya! 🌸\n\n"
        "Ada promo menarik khusus *${targetLabel}* di *Indah Sari Salon*: \n\n"
        "*${promo.title}* \n"
        "Hanya *${formatCurrency(promo.price)}*!\n\n"
        "Treatment: ${promo.description ?? '-'}\n"
        "Berlaku sampai: ${DateFormat('dd MMM yyyy').format(promo.endAt)}\n\n"
        "Yuk join grup untuk info lebih lanjut: $groupLink\n\n"
        "Booking sekarang lewat aplikasi atau hubungi kami langsung!";

    try {
      if (mounted) {
        PopupHelper.showInfo(context, "Menyiapkan broadcast untuk ${targetLabel}...");
      }

      if (promo.imageUrl != null && promo.imageUrl!.isNotEmpty) {
        final response = await http.get(Uri.parse(promo.imageUrl!));
        final bytes = response.bodyBytes;
        final temp = await getTemporaryDirectory();
        final path = '${temp.path}/promo_broadcast_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(path);
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(path)],
          text: message,
        );
      } else {
        await Share.share(message);
      }

      // After sharing, ask if they want to open the group directly
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Berhasil menyiapkan share. Buka grup ${targetLabel}?"),
                action: SnackBarAction(
                  label: "BUKA",
                  onPressed: () => launchUrl(Uri.parse(groupLink), mode: LaunchMode.externalApplication),
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Error broadcasting: $e");
      await Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        PopupHelper.showInfo(context, "Gagal sharing langsung. Pesan disalin ke clipboard.");
      }
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String increase,
    required IconData iconData,
    required Color increaseColor,
    required IconData trendIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32, // slightly smaller to fit Rp
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(trendIcon, color: increaseColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      increase,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: increaseColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            iconData,
            size: 64,
            color: const Color(0xFFF1F5F9), // Very light grey icon background
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BookingListPage()),
            (route) => false,
          );
        } else if (index == 2) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ManageServicesPage()),
            (route) => false,
          );
        } else if (index == 3) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ReportPage()),
            (route) => false,
          );
        } else if (index == 4) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
            (route) => false,
          );
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? primaryColor : mutedText,
            size: 26,
          ),
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
        ],
      ),
    );
  }
}
