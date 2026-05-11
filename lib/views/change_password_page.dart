import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import '../app_session.dart';
import '../utils/translations.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final currentPass = currentPasswordController.text;
    final newPass = newPasswordController.text;
    final confirmPass = confirmController.text;

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields'.tr)),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New passwords do not match'.tr)),
      );
      return;
    }

    if (newPass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 8 characters'.tr)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = AppSession.userId;
      if (userId == null) throw Exception("User not logged in");

      // Verify current password
      final userData = await Supabase.instance.client
          .from('users')
          .select('password')
          .eq('id', userId)
          .single();

      final isCurrentCorrect = BCrypt.checkpw(currentPass, userData['password']);
      if (!isCurrentCorrect) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current password is incorrect'.tr)),
        );
        return;
      }

      // Hash new password and update
      final hashedNewPassword = BCrypt.hashpw(newPass, BCrypt.gensalt());
      await Supabase.instance.client
          .from('users')
          .update({'password': hashedNewPassword})
          .eq('id', userId);

      // Try updating Supabase auth if it's linked
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPass),
        );
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password successfully updated!'.tr)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: ${e.toString()}'.tr)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // For Dark/Light theme, we use some dynamic colors if we want, but keeping it simple for now based on scaffoldBg
    // If the app supports dark mode everywhere, we should use Theme.of(context).brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentScaffoldBg = isDarkMode ? const Color(0xFF1E293B) : scaffoldBg;
    final currentMainText = isDarkMode ? Colors.white : primaryColor;

    return Scaffold(
      backgroundColor: currentScaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, color: currentMainText, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Change Password".tr,
                      style: TextStyle(
                        color: currentMainText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                Text(
                  "Create a new strong password that you don't use for other websites.".tr,
                  style: TextStyle(color: mutedText, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 32),

                // Form
                _buildPasswordField(
                  "CURRENT PASSWORD".tr, 
                  currentPasswordController, 
                  _showCurrent, 
                  () => setState(() => _showCurrent = !_showCurrent),
                  isDarkMode
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  "NEW PASSWORD".tr, 
                  newPasswordController, 
                  _showNew, 
                  () => setState(() => _showNew = !_showNew),
                  isDarkMode
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  "CONFIRM NEW PASSWORD".tr, 
                  confirmController, 
                  _showConfirm, 
                  () => setState(() => _showConfirm = !_showConfirm),
                  isDarkMode
                ),

                const SizedBox(height: 48),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _changePassword,
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                      "Update Password".tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool showPassword, VoidCallback onToggle, bool isDarkMode) {
    final inputBg = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0).withOpacity(0.6);
    final inputTextColor = isDarkMode ? Colors.white : const Color(0xFF1E293B);

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
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: !showPassword,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: inputTextColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                  color: mutedText.withOpacity(0.5), size: 20,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
