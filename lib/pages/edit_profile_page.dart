import 'package:flutter/material.dart';
import '../app_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (AppSession.userId != null) {
      try {
        final userData = await Supabase.instance.client
            .from('users')
            .select('name, username, email, phone, address')
            .eq('id', AppSession.userId!)
            .maybeSingle();

        if (userData != null) {
          _fullNameController.text = userData['name']?.toString() ?? AppSession.userName ?? '';
          _usernameController.text = userData['username']?.toString() ?? '';
          _emailController.text = userData['email']?.toString() ?? '';
          _phoneController.text = userData['phone']?.toString() ?? '';
          _addressController.text = userData['address']?.toString() ?? '';
        } else {
          _fullNameController.text = AppSession.userName ?? '';
        }
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
        _fullNameController.text = AppSession.userName ?? '';
      }
    } else {
      _fullNameController.text = AppSession.userName ?? '';
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
                  const SizedBox(width: 16),
                  Text(
                    "Edit Profile",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    
                    // Profile Image
                    Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            image: const DecorationImage(
                              image: NetworkImage("https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80"), // using stock avatar image
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: scaffoldBg, width: 3),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _fullNameController.text.isNotEmpty ? _fullNameController.text : "User",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Member since Oct 2023",
                      style: TextStyle(
                        fontSize: 14,
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Forms
                    _buildInputField("FULL NAME", _fullNameController, Icons.person_outline),
                    const SizedBox(height: 20),
                    _buildInputField("USERNAME", _usernameController, Icons.alternate_email),
                    const SizedBox(height: 20),
                    _buildInputField("EMAIL ADDRESS", _emailController, Icons.email_outlined),
                    const SizedBox(height: 20),
                    _buildInputField("PHONE NUMBER", _phoneController, Icons.phone_outlined),
                    const SizedBox(height: 20),
                    _buildInputField("HOME ADDRESS", _addressController, Icons.location_on_outlined, maxLines: 2),
                    
                    const SizedBox(height: 48),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          // save logic
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Discard Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626), // red color
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "DISCARD CHANGES",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
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
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: mutedText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: Icon(icon, color: mutedText.withOpacity(0.5), size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
