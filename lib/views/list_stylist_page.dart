import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../controllers/user_controller.dart';
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
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  // Active index 4 (SETTINGS) mirrors what we have in manage_team_page.dart
  int _selectedIndex = 4;

  String _searchQuery = '';
  final UserController _userController = UserController();

  List<UserModel> _allStylists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStylists();
  }

  Future<void> _fetchStylists() async {
    try {
      final data = await _userController.fetchAllStylists();
          
      if (mounted) {
        setState(() {
          _allStylists = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stylists: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStylists = _allStylists.where((stylist) {
      final query = _searchQuery.toLowerCase();
      return stylist.name.toLowerCase().contains(query) ||
             stylist.email.toLowerCase().contains(query);
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
                        child: Icon(Icons.arrow_back, color: primaryColor, size: 28),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        "${widget.role}s",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
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
                                Icon(Icons.add, color: primaryColor, size: 22),
                                const SizedBox(width: 4),
                                Text(
                                  "Add New",
                                  style: TextStyle(
                                    color: primaryColor,
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
                      if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                      else if (filteredStylists.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text("Belum ada data ${widget.role}.", style: TextStyle(color: mutedText)),
                          ),
                        )
                      else
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
                                      color: const Color(0xFFF1F5F9),
                                      image: stylist.avatar != null && stylist.avatar!.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(stylist.avatar!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: stylist.avatar == null || stylist.avatar!.isEmpty
                                        ? const Icon(Icons.person, color: Color(0xFF94A3B8), size: 32)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Text details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stylist.name.isNotEmpty ? stylist.name : '-',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          stylist.email.isNotEmpty ? stylist.email : '-',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Edit Icon
                                  GestureDetector(
                                    onTap: () => _showAddStylistModal(stylist: stylist),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  
                                  // Delete Icon
                                  GestureDetector(
                                    onTap: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: Text("Hapus Stylist", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                          content: Text("Yakin ingin menghapus ${stylist.name} dari tim?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text("Hapus", style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true && stylist.id != null) {
                                        try {
                                          await _userController.deleteStylist(stylist.id!);
                                          _fetchStylists();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stylist berhasil dihapus')));
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus stylist: $e')));
                                          }
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFDC2626),
                                        size: 20,
                                      ),
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

  void _showAddStylistModal({UserModel? stylist}) {
    final isEdit = stylist != null;
    final nameController = TextEditingController(text: isEdit ? stylist.name : '');
    final emailController = TextEditingController(text: isEdit ? stylist.email : '');

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
                          child: Icon(Icons.close, color: primaryColor, size: 24),
                        ),
                        Text(
                          isEdit ? "Update Stylist" : "Add Stylist",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (nameController.text.isNotEmpty) {
                              final emailValue = emailController.text.trim().isEmpty 
                                  ? "${DateTime.now().millisecondsSinceEpoch}@example.com" 
                                  : emailController.text.trim();
                                  
                              final dataPayload = {
                                "name": nameController.text.trim(),
                                "email": emailValue,
                                "kategori": 'stylist',
                                "type": 'karyawan',
                                "role": 'karyawan',
                                "status": "aktif",
                                "username": nameController.text.trim().replaceAll(' ', '').toLowerCase() + DateTime.now().millisecondsSinceEpoch.toString().substring(8),
                                "password": "password",
                              };
                              
                              try {
                                await _userController.saveStylist(dataPayload, id: stylist?.id);
                                _fetchStylists();
                              } catch (e) {
                                debugPrint("Error saving stylist: $e");
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save data: $e')));
                              }
                            }
                            if (mounted) Navigator.pop(context);
                          },
                          child: Text(
                            "Save",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
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
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(16),
                                      image: (isEdit && stylist.avatar != null && stylist.avatar!.isNotEmpty)
                                          ? DecorationImage(
                                              image: NetworkImage(stylist.avatar!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: (!isEdit || stylist.avatar == null || stylist.avatar!.isEmpty)
                                        ? const Icon(Icons.person, color: Color(0xFF94A3B8), size: 48)
                                        : null,
                                  ),
                              Transform.translate(
                                offset: const Offset(8, 8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
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
