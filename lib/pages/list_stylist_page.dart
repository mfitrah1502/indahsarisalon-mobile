import 'package:flutter/material.dart';
import 'home_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'settings_page.dart';

class ListStylistPage extends StatefulWidget {
  final String role;
  
  const ListStylistPage({super.key, required this.role});

  @override
  State<ListStylistPage> createState() => _ListStylistPageState();
}

class _ListStylistPageState extends State<ListStylistPage> {
  final Color darkBlue = const Color(0xFF02365A);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  // Active index 4 (SETTINGS) mirrors what we have in manage_team_page.dart
  int _selectedIndex = 4;

  String _searchQuery = '';

  final List<Map<String, String>> _allStylists = [
    {
      "name": "Maya",
      "email": "maya.stylist@indahsari.com",
      "role": "Senior Stylist",
      "image": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=256&q=80",
    },
    {
      "name": "Alex",
      "email": "alex.color@indahsari.com",
      "role": "Junior Stylist",
      "image": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=256&q=80",
    },
    {
      "name": "Sophia",
      "email": "sophia.spa@indahsari.com",
      "role": "Senior Stylist",
      "image": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?ixlib=rb-4.0.3&auto=format&fit=crop&w=256&q=80",
    },
    {
      "name": "David",
      "email": "david.cuts@indahsari.com",
      "role": "Junior Stylist",
      "image": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=256&q=80",
    },
    {
      "name": "Elena",
      "email": "elena.nails@indahsari.com",
      "role": "Senior Stylist",
      "image": "https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=256&q=80",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredStylists = _allStylists.where((stylist) {
      if (stylist['role'] != widget.role) return false;
      final query = _searchQuery.toLowerCase();
      return stylist["name"]!.toLowerCase().contains(query) ||
             stylist["email"]!.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Arrow
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back, color: darkBlue, size: 28),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        "${widget.role}s",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: darkBlue,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Manage your dedicated salon team members and their profile settings.",
                        style: TextStyle(
                          fontSize: 15,
                          color: mutedText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Search and Add New Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0), // Light grey input background
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
                                  hintText: "Search member",
                                  hintStyle: TextStyle(
                                    color: mutedText.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              _showAddStylistModal();
                            },
                            child: Row(
                              children: [
                                Icon(Icons.add, color: darkBlue, size: 22),
                                const SizedBox(width: 4),
                                Text(
                                  "Add New",
                                  style: TextStyle(
                                    color: darkBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // List of Stylists
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredStylists.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final stylist = filteredStylists[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
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
                              children: [
                                // Avatar
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(stylist['image']!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Text details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stylist['name']!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: darkBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        stylist['email']!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Menu Icon
                                GestureDetector(
                                  onTap: () => _showAddStylistModal(stylist: stylist),
                                  child: Icon(
                                    Icons.more_vert,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 100), // padding for bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar
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

  void _showAddStylistModal({Map<String, String>? stylist}) {
    final isEdit = stylist != null;
    String selectedRole = isEdit && stylist.containsKey('role') ? stylist['role']! : 'Junior Stylist';
    final nameController = TextEditingController(text: isEdit ? stylist['name'] : '');
    final emailController = TextEditingController(text: isEdit ? stylist['email'] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: scaffoldBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.close, color: darkBlue, size: 24),
                        ),
                        Text(
                          isEdit ? "Update Stylist" : "Add Stylist",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (nameController.text.isNotEmpty) {
                              setState(() {
                                if (isEdit) {
                                  final index = _allStylists.indexOf(stylist);
                                  if (index != -1) {
                                    _allStylists[index] = {
                                      "name": nameController.text.trim(),
                                      "email": emailController.text.trim(),
                                      "role": selectedRole,
                                      "image": stylist['image']!,
                                    };
                                  }
                                } else {
                                  _allStylists.add({
                                    "name": nameController.text.trim(),
                                    "email": emailController.text.trim(),
                                    "role": selectedRole,
                                    "image": "https://cdn-icons-png.flaticon.com/512/3135/3135715.png", // generic thumbnail
                                  });
                                }
                              });
                            }
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Save",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Photo Area
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA1C6C8), // Light greenish-blue placeholder
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: NetworkImage(isEdit && stylist.containsKey('image') ? stylist['image']! : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png'), // generic avatar
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(8, 8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: darkBlue,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: scaffoldBg, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "UPLOAD STYLIST PHOTO",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Form Details
                          _buildTextFieldLabel("FULL NAME"),
                          _buildTextField("e.g. Julianne Smith", nameController),
                          const SizedBox(height: 20),
                          
                          _buildTextFieldLabel("EMAIL ADDRESS"),
                          _buildTextField("julianne@salon.com", emailController),
                          const SizedBox(height: 20),
                          
                          _buildTextFieldLabel("PHONE NUMBER"),
                          _buildTextField("+1 (555) 000-0000"),
                          const SizedBox(height: 20),
                          
                          _buildTextFieldLabel("PROFESSIONAL ROLE"),
                          // Segmented Control
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        selectedRole = 'Junior Stylist';
                                      });
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selectedRole == 'Junior Stylist' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: selectedRole == 'Junior Stylist'
                                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                            : null,
                                      ),
                                      child: Text(
                                        "Junior Stylist",
                                        style: TextStyle(
                                          fontWeight: selectedRole == 'Junior Stylist' ? FontWeight.bold : FontWeight.w600,
                                          color: selectedRole == 'Junior Stylist' ? darkBlue : mutedText,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        selectedRole = 'Senior Stylist';
                                      });
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selectedRole == 'Senior Stylist' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: selectedRole == 'Senior Stylist'
                                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                            : null,
                                      ),
                                      child: Text(
                                        "Senior Stylist",
                                        style: TextStyle(
                                          fontWeight: selectedRole == 'Senior Stylist' ? FontWeight.bold : FontWeight.w600,
                                          color: selectedRole == 'Senior Stylist' ? darkBlue : mutedText,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildTextFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, [TextEditingController? controller]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF64748B).withOpacity(0.6),
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
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
