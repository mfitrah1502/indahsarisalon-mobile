import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'booking_page.dart';
import 'booking_list_page.dart';
import 'manage_team_page.dart';
import 'manage_services_page.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false; // Default to light mode
  int _selectedIndex = 4; // Settings is active
  String _selectedLanguage = 'English'; // Default Language

  @override
  Widget build(BuildContext context) {
    // Dynamic Dark/Light Colors
    final Color mainTextColor = isDarkMode ? Colors.white : const Color(0xFF02365A);
    final Color scaffoldBg = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF5F8FA);
    final Color mutedText = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color cardBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final Color optionBg = isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final Color iconBoxBg = isDarkMode ? const Color(0xFF475569) : const Color(0xFFEDF2F7);
    final Color activeNavBg = isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF02365A);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar / Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.arrow_back, color: mainTextColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Settings",
                    style: TextStyle(
                      color: mainTextColor,
                      fontSize: 24,
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
                            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar with edit button
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: const Color(0xFFE2E8F0),
                                  image: const DecorationImage(
                                    image: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'), // placeholder
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 40),
                              ),
                              Transform.translate(
                                offset: const Offset(8, 8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: activeNavBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: cardBg, width: 2),
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Jane Doe",
                            style: TextStyle(
                              color: mainTextColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "jane.doe@example.com",
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // ACCOUNT PREFERENCES
                    Text(
                      "ACCOUNT PREFERENCES",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF8B98A5),
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditProfilePage()),
                              );
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.groups_outlined,
                            title: "Manage Team",
                            mainTextColor: mainTextColor,
                            iconBoxBg: iconBoxBg,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ManageTeamPage()),
                              );
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.lock_outline,
                            title: "Change Password",
                            mainTextColor: mainTextColor,
                            iconBoxBg: iconBoxBg,
                            onTap: () {},
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
                        color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF8B98A5),
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
                            trailing: CupertinoSwitch(
                              value: isDarkMode,
                              activeColor: activeNavBg,
                              onChanged: (val) {
                                setState(() {
                                  isDarkMode = val;
                                });
                              },
                            ),
                          ),
                          _buildSettingTile(
                            icon: Icons.language,
                            title: "Language",
                            mainTextColor: mainTextColor,
                            iconBoxBg: iconBoxBg,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedLanguage,
                                  style: TextStyle(color: mutedText, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios, size: 14, color: mutedText),
                              ],
                            ),
                            onTap: () {
                              _showLanguagePicker(context);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // LOGOUT
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF451A1A) : const Color(0xFFFDF4F4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _buildSettingTile(
                        icon: Icons.logout,
                        title: "Logout",
                        mainTextColor: mainTextColor,
                        iconBoxBg: iconBoxBg,
                        titleColor: const Color(0xFFEF4444), // Light Red for dark mode / text red
                        iconBgOverride: isDarkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                        iconColor: const Color(0xFFEF4444),
                        hideArrow: true,
                        onTap: () {},
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
              _buildNavItem(0, "HOME", Icons.home_filled, activeNavBg, mutedText),
              _buildNavItem(1, "BOOKING", Icons.calendar_today_outlined, activeNavBg, mutedText),
              _buildNavItem(2, "SERVICES", Icons.content_cut_rounded, activeNavBg, mutedText),
              _buildNavItem(3, "REPORT", Icons.bar_chart_rounded, activeNavBg, mutedText),
              _buildNavItem(4, "SETTINGS", Icons.settings, activeNavBg, mutedText),
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
              child: Icon(
                icon,
                color: iconColor ?? mainTextColor,
                size: 20,
              ),
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
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "Select Language",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text("English", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
                trailing: _selectedLanguage == 'English' ? const Icon(Icons.check_circle, color: Color(0xFF02365A)) : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'English';
                  });
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text("Indonesia", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
                trailing: _selectedLanguage == 'Indonesia' ? const Icon(Icons.check_circle, color: Color(0xFF02365A)) : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'Indonesia';
                  });
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, [Color? activeNavBgColor, Color? mutedTextColor]) {
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
        ],
      ),
    );
  }
}
