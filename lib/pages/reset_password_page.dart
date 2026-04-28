import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF5F7FB);
  final Color inputBg = const Color(0xFFE2E4Eb);
  final Color mutedText = const Color(0xFF64748B);

  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirm = false;

  // Validation States
  bool _has8Chars = false;
  bool _hasUppercase = false;
  bool _hasSpecialSymbol = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final val = passwordController.text;
    setState(() {
      _has8Chars = val.length >= 8;
      _hasUppercase = val.contains(RegExp(r'[A-Z]'));
      _hasSpecialSymbol = val.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, color: primaryColor, size: 24),
                    ),
                    Text(
                      "Secure Reset",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 24), // Placeholder for balance
                  ],
                ),
                
                const SizedBox(height: 60),

                // Icon Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.history, 
                    color: primaryColor,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 32),

                // Text Content
                Text(
                  "Reset Password",
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Enter your new password below to regain access to your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Form Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "NEW PASSWORD",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4B5563),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: "••••••••",
                        hintStyle: const TextStyle(letterSpacing: 6),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: mutedText.withOpacity(0.5), size: 20,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        filled: true,
                        fillColor: inputBg.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "CONFIRM YOUR NEW PASSWORD",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4B5563),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmController,
                      obscureText: !_showConfirm,
                      decoration: InputDecoration(
                        hintText: "••••••••",
                        hintStyle: const TextStyle(letterSpacing: 6),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirm ? Icons.visibility : Icons.visibility_off,
                            color: mutedText.withOpacity(0.5), size: 20,
                          ),
                          onPressed: () => setState(() => _showConfirm = !_showConfirm),
                        ),
                        filled: true,
                        fillColor: inputBg.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Security Standards Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade300, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            "Security Standards",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem("At least 8 characters", _has8Chars),
                      _buildCheckItem("One uppercase letter", _hasUppercase),
                      _buildCheckItem("One special symbol", _hasSpecialSymbol),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    onPressed: (_has8Chars && _hasUppercase && _hasSpecialSymbol && !_isLoading) ? () async {
                      if (passwordController.text != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords do not match')),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);
                      try {
                        await Supabase.instance.client.auth.updateUser(
                          UserAttributes(password: passwordController.text),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password successfully updated!')),
                          );
                          // Since the user is authenticated from verifyOTP, 
                          // navigate back to AuthPage to determine routing (Home or Login)
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthPage()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating password: ${e.toString()}')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    } : null,
                    child: _isLoading 
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Save New Password",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.save_outlined, size: 18),
                            ],
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

  Widget _buildCheckItem(String label, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            color: isValid ? primaryColor : mutedText.withOpacity(0.4),
            size: 16,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isValid ? const Color(0xFF0F172A) : mutedText,
              fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
