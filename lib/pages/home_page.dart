import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
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
  List<Map<String, dynamic>> _promos = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchPromos();
  }

  Future<void> _fetchPromos() async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await Supabase.instance.client
          .from('promos')
          .select()
          .eq('is_active', true)
          .lte('start_at', now)
          .gte('end_at', now)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _promos = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error fetching promos: $e");
    }
  }

  Future<void> _fetchDashboardData() async {
    final supabase = Supabase.instance.client;

    try {
      final now = DateTime.now();
      // Today bounds
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
      
      // Yesterday bounds
      final yesterdayStart = DateTime(now.year, now.month, now.day - 1).toIso8601String();
      final yesterdayEnd = DateTime(now.year, now.month, now.day - 1, 23, 59, 59).toIso8601String();

      // Fetch Today's bookingss
      final todayData = await supabase
          .from('bookings')
          .select('id, user_id, total_price, reservation_datetime')
          .gte('reservation_datetime', todayStart)
          .lte('reservation_datetime', todayEnd);

      // Fetch Yesterday's bookings
      final yesterdayData = await supabase
          .from('bookings')
          .select('id, user_id, total_price, reservation_datetime')
          .gte('reservation_datetime', yesterdayStart)
          .lte('reservation_datetime', yesterdayEnd);

      // Calculate Today Stats
      int tBookings = todayData.length;
      int tRev = 0;
      Set<int> tCustomers = {};
      for (var b in todayData) {
        tRev += (b['total_price'] as num?)?.toInt() ?? 0;
        final uId = (b['user_id'] as num?)?.toInt();
        if (uId != null) tCustomers.add(uId);
      }

      // Calculate Yesterday Stats
      int yBookings = yesterdayData.length;
      int yRev = 0;
      Set<int> yCustomers = {};
      for (var b in yesterdayData) {
        yRev += (b['total_price'] as num?)?.toInt() ?? 0;
        final uId = (b['user_id'] as num?)?.toInt();
        if (uId != null) yCustomers.add(uId);
      }

      // Calculate percentage increase
      double bInc = yBookings == 0 ? (tBookings > 0 ? 100 : 0) : ((tBookings - yBookings) / yBookings) * 100;
      double rInc = yRev == 0 ? (tRev > 0 ? 100 : 0) : ((tRev - yRev) / yRev) * 100;
      double cInc = yCustomers.isEmpty ? (tCustomers.isNotEmpty ? 100 : 0) : ((tCustomers.length - yCustomers.length) / yCustomers.length) * 100;

      if (mounted) {
        setState(() {
          todayBookings = tBookings;
          todayRevenue = tRev;
          todayCustomers = tCustomers.length;
          
          bookingsIncrease = bInc;
          revenueIncrease = rInc;
          customersIncrease = cInc;
          
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
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
    if (percentage > 0) return "+${percentage.toStringAsFixed(1)}% vs yesterday";
    if (percentage < 0) return "${percentage.toStringAsFixed(1)}% vs yesterday";
    return "Same as yesterday";
  }

  void _navigateToReport() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ReportPage()),
      (route) => false,
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
                    Row(
                      children: [
                        // Profile Avatar
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfilePage()),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE2E8F0),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF94A3B8),
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Hello, ${AppSession.userName}!",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                            );
                          },
                          icon: Icon(
                            Icons.notifications_none,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),

                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: mutedText, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Search bookings, customers...",
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Promo Section
                if (_promos.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "PENAWARAN SPESIAL",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF4B5563)),
                      ),
                      Text(
                        "Lihat Semua",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
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
                              image: p['image_url'] != null && p['image_url'].toString().isNotEmpty
                                ? DecorationImage(image: NetworkImage(p['image_url']), fit: BoxFit.cover)
                                : null,
                              gradient: p['image_url'] == null || p['image_url'].toString().isEmpty
                                ? LinearGradient(colors: [primaryColor, buttonColor])
                                : null,
                            ),
                            child: Stack(
                              children: [
                                if (p['image_url'] == null || p['image_url'].toString().isEmpty)
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
                                          p['title'] ?? "Promo Menarik",
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          formatCurrency((p['price'] as num?)?.toInt() ?? 0),
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
                  "TODAY, $todayFormatted",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Daily Overview",
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
                    onTap: _navigateToReport,
                    child: _buildStatCard(
                      title: "TOTAL BOOKINGS TODAY",
                      value: "$todayBookings",
                      increase: formatIncrease(bookingsIncrease),
                      iconData: Icons.calendar_today_rounded,
                      increaseColor: bookingsIncrease >= 0 ? primaryColor : Colors.red,
                      trendIcon: bookingsIncrease >= 0 ? Icons.trending_up : Icons.trending_down,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _navigateToReport,
                    child: _buildStatCard(
                      title: "TODAY'S REVENUE",
                      value: formatCurrency(todayRevenue),
                      increase: formatIncrease(revenueIncrease),
                      iconData: Icons.payments_outlined,
                      increaseColor: revenueIncrease >= 0 ? primaryColor : Colors.red,
                      trendIcon: revenueIncrease >= 0 ? Icons.trending_up : Icons.trending_down,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _navigateToReport,
                    child: _buildStatCard(
                      title: "NUMBER OF CUSTOMERS",
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

  void _showPromoDetail(Map<String, dynamic> promo) {
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
                image: promo['image_url'] != null && promo['image_url'].toString().isNotEmpty
                  ? DecorationImage(image: NetworkImage(promo['image_url']), fit: BoxFit.cover)
                  : null,
                color: primaryColor,
              ),
              child: promo['image_url'] == null || promo['image_url'].toString().isEmpty
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
                          promo['title'] ?? "Promo Detail",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text("Promo", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Dapatkan layanan ini hanya dengan harga:",
                    style: TextStyle(color: mutedText, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency((promo['price'] as num?)?.toInt() ?? 0),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  if (promo['description'] != null && promo['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Termasuk Treatment:",
                      style: TextStyle(color: mutedText, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promo['description'],
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
                        "Berlaku sampai: ${DateFormat('dd MMM yyyy').format(DateTime.parse(promo['end_at']))}",
                        style: TextStyle(color: mutedText, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final selectedCustomer = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerListPage(isSelectionMode: true),
                          ),
                        );

                        if (selectedCustomer != null && selectedCustomer is Map<String, dynamic>) {
                          String phone = selectedCustomer['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
                          
                          if (phone.isNotEmpty) {
                            // Convert standard 08... to 62... for WhatsApp
                            if (phone.startsWith('0')) {
                              phone = '62${phone.substring(1)}';
                            } else if (!phone.startsWith('62')) {
                              phone = '62$phone';
                            }

                            final message = "Halo ${selectedCustomer['name']}! Cek promo menarik ini di Indah Sari Salon: ${promo['title']} hanya dengan ${formatCurrency((promo['price'] as num?)?.toInt() ?? 0)}! Berlaku sampai ${DateFormat('dd MMM yyyy').format(DateTime.parse(promo['end_at']))}. Yuk booking sekarang!";
                            final url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
                            
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: const Text("Bagikan ke WhatsApp", style: TextStyle(fontWeight: FontWeight.bold)),
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
