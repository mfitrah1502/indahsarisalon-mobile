import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'booking_list_page.dart';
import 'manage_team_page.dart';
import 'manage_services_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'create_account_page.dart';
import 'auth_page.dart';
import '../app_session.dart';
import '../controllers/auth_controller.dart';
import 'report_page.dart';
import '../utils/popup_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/loyalty_constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool get isDarkMode => AppSession.isDarkMode; // synced with global theme
  int _selectedIndex = 4; // Settings is active
  String _currentTier = 'None';

  @override
  void initState() {
    super.initState();
    _fetchMembership();
  }

  Future<void> _fetchMembership() async {
    if (AppSession.userId != null) {
      try {
        final res = await Supabase.instance.client
            .from('users')
            .select('membership_tier')
            .eq('id', AppSession.userId!)
            .single();
        if (mounted) {
          setState(() {
            _currentTier = res['membership_tier'] ?? 'None';
            AppSession.userTier = _currentTier;
          });
        }
      } catch (e) {
        debugPrint('Error fetching membership: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainTextColor = const Color(0xFFD660A1);
    final Color scaffoldBg = isDarkMode
        ? const Color(0xFF1E293B)
        : const Color(0xFFF5F8FA);
    final Color mutedText = isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final Color cardBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final Color optionBg = isDarkMode
        ? const Color(0xFF334155)
        : const Color(0xFFF8FAFC);
    final Color iconBoxBg = isDarkMode
        ? const Color(0xFF475569)
        : const Color(0xFFEDF2F7);
    final Color activeNavBg = isDarkMode
        ? const Color(0xFF38BDF8)
        : const Color(0xFFD660A1);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar / Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Center(
                child: Text(
                  "Settings",
                  style: TextStyle(
                    color: mainTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDarkMode ? 0.2 : 0.02,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar with edit button
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: optionBg,
                              image: DecorationImage(
                                image:
                                    (AppSession.userAvatar != null &&
                                        AppSession.userAvatar!.isNotEmpty)
                                    ? NetworkImage(AppSession.userAvatar!)
                                    : const NetworkImage(
                                            'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                                          )
                                          as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                            child:
                                (AppSession.userAvatar != null &&
                                    AppSession.userAvatar!.isNotEmpty)
                                ? null
                                : Icon(
                                    Icons.person,
                                    color: mainTextColor,
                                    size: 40,
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "${AppSession.userName}",
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: mainTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${AppSession.userEmail}",
                            style: TextStyle(color: mutedText, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // MEMBERSHIP SECTION
                    if (AppSession.userRole?.toLowerCase() == 'pelanggan') ...[
                      Text(
                        "MEMBERSHIP",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDarkMode
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF8B98A5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _currentTier != 'None'
                              ? mainTextColor.withOpacity(0.1)
                              : (isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _currentTier != 'None'
                                ? mainTextColor.withOpacity(0.3)
                                : (isDarkMode
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _currentTier != 'None'
                                  ? Icons.stars
                                  : Icons.stars_outlined,
                              color: _currentTier != 'None'
                                  ? mainTextColor
                                  : mutedText,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _currentTier != 'None'
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$_currentTier Member",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: mainTextColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "You are our exclusive member.",
                                          style: TextStyle(
                                            color: mutedText,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "No membership yet",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: mutedText,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Make transactions to earn a tier.",
                                          style: TextStyle(
                                            color: mutedText,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            if (_currentTier != 'None')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () async {
                                  final uri = Uri.parse(
                                    LoyaltyConstants.groupLinkForTier(
                                      _currentTier,
                                    ),
                                  );
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                child: const Text(
                                  "WA Group",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ACCOUNT PREFERENCES
                    Text(
                      "ACCOUNT PREFERENCES",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDarkMode
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF8B98A5),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: optionBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildSettingTile(
                            icon: Icons.person_outline,
                            title: "Edit Profile",
                            mainTextColor: mainTextColor,
                            iconBoxBg: iconBoxBg,
                            mutedTextColor: mutedText,
                            onTap: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                              if (updated == true && mounted) setState(() {});
                            },
                          ),
                          if (AppSession.userRole == 'owner')
                            _buildSettingTile(
                              icon: Icons.groups_outlined,
                              title: "Manage Team",
                              mainTextColor: mainTextColor,
                              iconBoxBg: iconBoxBg,
                              mutedTextColor: mutedText,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ManageTeamPage(),
                                  ),
                                );
                              },
                            ),
                          _buildSettingTile(
                            icon: Icons.lock_outline,
                            title: "Change Password",
                            mainTextColor: mainTextColor,
                            iconBoxBg: iconBoxBg,
                            mutedTextColor: mutedText,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangePasswordPage(),
                                ),
                              );
                            },
                          ),
                          if (AppSession.userRole == 'owner')
                            _buildSettingTile(
                              icon: Icons.person_add_alt,
                              title: "Add Another Account",
                              mainTextColor: mainTextColor,
                              iconBoxBg: iconBoxBg,
                              mutedTextColor: mutedText,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateAccountPage(),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SYSTEM
                    Text(
                      "SYSTEM",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDarkMode
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF8B98A5),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: optionBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildSettingTile(
                            icon: Icons.dark_mode_outlined,
                            title: "Dark Mode",
                            mainTextColor: mainTextColor,
                            iconBoxBg: iconBoxBg,
                            mutedTextColor: mutedText,
                            trailing: CupertinoSwitch(
                              value: isDarkMode,
                              activeColor: activeNavBg,
                              onChanged: (val) {
                                  // Update global theme state
                                  AppSession.isDarkMode = val;
                                  setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // LOGOUT
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF451A1A)
                            : const Color(0xFFFDF4F4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _buildSettingTile(
                        icon: Icons.logout,
                        title: "Logout",
                        mainTextColor: mainTextColor,
                        iconBoxBg: iconBoxBg,
                        mutedTextColor: mutedText,
                        titleColor: const Color(
                          0xFFEF4444,
                        ), // Light Red for dark mode / text red
                        iconBgOverride: isDarkMode
                            ? const Color(0xFF7F1D1D)
                            : const Color(0xFFFEE2E2),
                        iconColor: const Color(0xFFEF4444),
                        hideArrow: true,
                        onTap: () {
                          PopupHelper.showConfirm(
                            context,
                            title: "Logout",
                            message: "Are you sure you want to log out?",
                            onConfirm: () async {
                              await AuthController().logout();
                              if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AuthPage(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 48),
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
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
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
              _buildNavItem(
                0,
                "HOME",
                Icons.home_filled,
                activeNavBg,
                mutedText,
              ),
              _buildNavItem(
                1,
                "BOOKING",
                Icons.calendar_today_outlined,
                activeNavBg,
                mutedText,
              ),
              _buildNavItem(
                2,
                "SERVICES",
                Icons.content_cut_rounded,
                activeNavBg,
                mutedText,
              ),
              _buildNavItem(
                3,
                "REPORT",
                Icons.bar_chart_rounded,
                activeNavBg,
                mutedText,
              ),
              _buildNavItem(
                4,
                "SETTINGS",
                Icons.settings,
                activeNavBg,
                mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Color mainTextColor,
    required Color iconBoxBg,
    Color? mutedTextColor,
    Color? titleColor,
    Color? iconBgOverride,
    Color? iconColor,
    Widget? trailing,
    bool hideArrow = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgOverride ?? iconBoxBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? mainTextColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? mainTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else if (!hideArrow)
              Icon(Icons.arrow_forward_ios, size: 14, color: mutedTextColor ?? Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData icon, [
    Color? activeNavBgColor,
    Color? mutedTextColor,
  ]) {
    final isSelected = _selectedIndex == index;
    final selectedColor = activeNavBgColor ?? Colors.blue;
    final unselectedColor = mutedTextColor ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          // Navigate to Home Page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else if (index == 1) {
          // Navigate to Booking List Page
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
            color: isSelected ? selectedColor : unselectedColor,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isSelected ? selectedColor : unselectedColor,
              letterSpacing: 0.5,
            ),
          ),
        const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isSelected ? selectedColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
