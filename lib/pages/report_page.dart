import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'settings_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final int _selectedIndex = 3; // 3 is Report
  final Color darkBlue = const Color(0xFF02365A);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  DateTimeRange? _dateRange;
  String _searchQuery = '';

  // Data State
  int totalCustomers = 0;
  int totalBookings = 0;
  int totalRevenue = 0;
  int peakRevenue = 0;
  List<Map<String, dynamic>> topServices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to this month
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });

    final supabase = Supabase.instance.client;

    try {
      final startStr = _dateRange!.start.toIso8601String();
      final endStr = _dateRange!.end.add(const Duration(days: 1)).toIso8601String(); // Include the end day fully

      // 1. Fetch Bookings
      final bookingsData = await supabase
          .from('bookings')
          .select('id, user_id, total_price, reservation_datetime, treatment_id')
          .gte('reservation_datetime', startStr)
          .lt('reservation_datetime', endStr);

      final List bookings = bookingsData;

      int rev = 0;
      Set<int> uniqueCustomers = {};
      Map<int, int> serviceRevenueMap = {};
      Map<int, int> serviceBookingsMap = {};
      
      // Calculate Peak Revenue dummy logic (max daily revenue in period)
      Map<String, int> dailyRevenues = {};

      for (var b in bookings) {
        final price = (b['total_price'] as num?)?.toInt() ?? 0;
        final tId = (b['treatment_id'] as num?)?.toInt();
        final uId = (b['user_id'] as num?)?.toInt();
        final bDate = DateTime.parse(b['reservation_datetime']).toLocal();
        final dateKey = "${bDate.year}-${bDate.month}-${bDate.day}";

        rev += price;
        if (uId != null) uniqueCustomers.add(uId);

        if (tId != null) {
          serviceRevenueMap[tId] = (serviceRevenueMap[tId] ?? 0) + price;
          serviceBookingsMap[tId] = (serviceBookingsMap[tId] ?? 0) + 1;
        }

        dailyRevenues[dateKey] = (dailyRevenues[dateKey] ?? 0) + price;
      }

      int pRev = 0;
      dailyRevenues.forEach((key, value) {
        if (value > pRev) pRev = value;
      });

      // 2. Fetch Treatments for names
      final treatmentsData = await supabase.from('treatments').select('id, name');
      final Map<int, String> tNames = {};
      for (var t in treatmentsData) {
        tNames[t['id'] as int] = t['name'] as String;
      }

      List<Map<String, dynamic>> servicesList = [];
      serviceRevenueMap.forEach((id, r) {
        servicesList.add({
          'id': id,
          'name': tNames[id] ?? 'Unknown Treatment',
          'revenue': r,
          'bookings': serviceBookingsMap[id] ?? 0,
        });
      });

      // Sort by highest revenue
      servicesList.sort((a, b) => (b['revenue'] as int).compareTo(a['revenue'] as int));

      if (mounted) {
        setState(() {
          totalBookings = bookings.length;
          totalRevenue = rev;
          totalCustomers = uniqueCustomers.length;
          peakRevenue = pRev;
          topServices = servicesList;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Report data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  String formatDateRange(DateTimeRange? range) {
    if (range == null) return "";
    final start = DateFormat('MMM d').format(range.start).toUpperCase();
    final end = DateFormat('MMM d').format(range.end).toUpperCase();
    return "$start - $end";
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: darkBlue,
            colorScheme: ColorScheme.light(primary: darkBlue),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Implement Search Filter on Top Services
    final filteredServices = topServices.where((service) {
      final name = service['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).take(3).toList(); // Only show Top 3 of filtered

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Centered Header (Removed drawer, profile, notifications)
                Center(
                  child: Text(
                    "Report",
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Functional Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: mutedText, size: 20),
                      hintText: "Search treatments in report...",
                      hintStyle: TextStyle(color: mutedText, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Functional Date Picker
                GestureDetector(
                  onTap: () => _pickDateRange(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.chevron_left, color: darkBlue, size: 20),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 14, color: darkBlue),
                            const SizedBox(width: 8),
                            Text(
                              formatDateRange(_dateRange),
                              style: TextStyle(
                                color: darkBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right, color: darkBlue, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Processing Indicator
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Performance Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Performance",
                        style: TextStyle(
                          color: darkBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "IN SELECTED RANGE",
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chart Card
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "PEAK DAILY REVENUE",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: mutedText,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(peakRevenue),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Mock Chart Area
                        SizedBox(
                          height: 80,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: ChartCurvePainter(
                              lineColor: darkBlue,
                              hasData: peakRevenue > 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stat cards
                  _buildHorizontalStatCard(
                    Icons.people_outline,
                    "TOTAL CUSTOMERS",
                    "$totalCustomers",
                  ),
                  const SizedBox(height: 12),
                  _buildHorizontalStatCard(
                    Icons.calendar_today_outlined,
                    "TOTAL BOOKINGS",
                    "$totalBookings",
                  ),
                  const SizedBox(height: 12),
                  _buildHorizontalStatCard(
                    Icons.payments_outlined,
                    "TOTAL REVENUE",
                    formatCurrency(totalRevenue),
                  ),
                  const SizedBox(height: 32),

                  // Top 3 Best Services Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(width: 24, height: 3, color: darkBlue),
                      const SizedBox(width: 8),
                      Text(
                        "Top Services by Revenue",
                        style: TextStyle(
                          color: darkBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Top 3 Items List
                  if (filteredServices.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text("No services found in this period.", style: TextStyle(color: mutedText)),
                      ),
                    ),
                  
                  for (int i = 0; i < filteredServices.length; i++) ...[
                    _buildTopServiceCard(
                      filteredServices[i]['name'],
                      "${filteredServices[i]['bookings']} bookings in this range",
                      formatCurrency(filteredServices[i]['revenue']),
                      (filteredServices[i]['revenue'] as int) / (filteredServices[0]['revenue'] as int == 0 ? 1 : filteredServices[0]['revenue'] as int),
                      _getDummyColor(i),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 24),

                  // Download Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        "DOWNLOAD REPORT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 100), // Spacing for bottom nav
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

  Color _getDummyColor(int index) {
    if (index == 0) return Colors.amber.shade200;
    if (index == 1) return Colors.green.shade200;
    if (index == 2) return Colors.brown.shade200;
    return Colors.grey.shade200;
  }

  Widget _buildHorizontalStatCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: darkBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: mutedText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServiceCard(String title, String subtitle, String amount, double progress, Color dummyImageColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: dummyImageColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: darkBlue,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.isNaN ? 0.0 : progress, // safety check
                  child: Container(
                    decoration: BoxDecoration(
                      color: darkBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else if (index == 1) {
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
        } else if (index == 4) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
            (route) => false,
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? darkBlue : mutedText,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isSelected ? darkBlue : mutedText,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ChartCurvePainter extends CustomPainter {
  final Color lineColor;
  final bool hasData;

  ChartCurvePainter({required this.lineColor, this.hasData = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = hasData ? lineColor : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (hasData) {
      path.moveTo(0, size.height * 0.7);
      // Create a smooth curve
      path.cubicTo(
        size.width * 0.2, size.height * 0.6,
        size.width * 0.4, size.height * 0.3,
        size.width * 0.7, size.height * 0.2,
      );
      path.quadraticBezierTo(
        size.width * 0.85, size.height * 0.15,
        size.width, size.height * 0.3,
      );
    } else {
      path.moveTo(0, size.height * 0.7);
      path.lineTo(size.width, size.height * 0.7);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
