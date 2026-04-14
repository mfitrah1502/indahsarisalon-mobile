import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'manage_services_page.dart';
import 'home_page.dart';
import 'booking_list_page.dart';
import 'report_page.dart';
import 'settings_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Color darkBlue = const Color(0xFF02365A);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  bool isLoading = true;
  List<Map<String, dynamic>> todayNotifications = [];
  List<Map<String, dynamic>> earlierNotifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final supabase = Supabase.instance.client;

    try {
      final List data = await supabase
          .from('notifikasi')
          .select()
          .order('created_at', ascending: false);

      final now = DateTime.now();
      List<Map<String, dynamic>> today = [];
      List<Map<String, dynamic>> earlier = [];

      for (var row in data) {
        final date = DateTime.parse(row['created_at']).toLocal();
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          today.add(row as Map<String, dynamic>);
        } else {
          earlier.add(row as Map<String, dynamic>);
        }
      }

      if (mounted) {
        setState(() {
          todayNotifications = today;
          earlierNotifications = earlier;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading notifications: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> markAllAsRead() async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('notifikasi').update({'is_read': true}).neq('is_read', true);
      _fetchNotifications();
    } catch (e) {
      debugPrint("Error updating notifications: $e");
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} mins ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} hours ago";
    } else {
      return "${diff.inDays} days ago";
    }
  }

  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains("booking")) return Icons.calendar_today_outlined;
    if (t.contains("promo")) return Icons.local_offer_outlined;
    if (t.contains("payment")) return Icons.payments_outlined;
    if (t.contains("reminder")) return Icons.alarm_rounded;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    int unreadCount = 0;
    for (var n in todayNotifications) { if (n['is_read'] == false) unreadCount++; }
    for (var n in earlierNotifications) { if (n['is_read'] == false) unreadCount++; }

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
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.arrow_back, color: darkBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Notifications",
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Subheader
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    unreadCount > 0 ? "You have $unreadCount new updates" : "No new updates",
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (unreadCount > 0)
                    GestureDetector(
                      onTap: markAllAsRead,
                      child: Text(
                        "Mark all as read",
                        style: TextStyle(
                          color: darkBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notifications List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (todayNotifications.isNotEmpty) ...[
                            const Text(
                              "TODAY",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (var notif in todayNotifications) ...[
                              _buildNotificationCard(
                                title: notif['title'],
                                timeText: _getTimeAgo(DateTime.parse(notif['created_at']).toLocal()),
                                description: notif['message'],
                                iconData: _getIconForTitle(notif['title']),
                                iconBgColor: const Color(0xFFE4F0F9),
                                iconColor: darkBlue,
                                isUnread: notif['is_read'] == false,
                                showButton: notif['title'].toString().toLowerCase().contains('booking'),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],

                          if (earlierNotifications.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              "EARLIER",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (var notif in earlierNotifications) ...[
                              _buildNotificationCard(
                                title: notif['title'],
                                timeText: _getTimeAgo(DateTime.parse(notif['created_at']).toLocal()),
                                description: notif['message'],
                                iconData: _getIconForTitle(notif['title']),
                                iconBgColor: const Color(0xFFDEE3E8),
                                iconColor: const Color(0xFF5A6A7D),
                                isUnread: notif['is_read'] == false,
                                showButton: false,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],

                          if (todayNotifications.isEmpty && earlierNotifications.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text("No notifications yet.", style: TextStyle(color: mutedText)),
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

      // Bottom Navigation Bar
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

  Widget _buildNotificationCard({
    required String title,
    required String timeText,
    required String description,
    required IconData iconData,
    required Color iconBgColor,
    required Color iconColor,
    required bool isUnread,
    required bool showButton,
  }) {
    Color cardBg = isUnread ? Colors.white : const Color(0xFFF1F4F8);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          timeText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: darkBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
                if (showButton) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "View Detail",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
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
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: mutedText,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: mutedText,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
