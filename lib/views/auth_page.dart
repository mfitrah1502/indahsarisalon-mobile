import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'home_page.dart';
import 'forgot_password_page.dart';
import '../utils/popup_helper.dart';
import '../app_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool get isDark => AppSession.isDarkMode;
  Color get primaryColor => const Color(0xFFD660A1);
  Color get buttonColor => const Color(0xFFB53D7C);
  Color get scaffoldBg => isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F7FB);
  Color get inputBg => isDark ? const Color(0xFF334155) : const Color(0xFFE2E4Eb);
  Color get cardBg => isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get mainTextColor => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);
  Color get borderCol => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  final username = TextEditingController();
  final password = TextEditingController();

  bool rememberMe = false;
  bool _obscurePassword = true;

  final AuthController _authController = AuthController();

  // 🔥 LOGIN FUNCTION (SUPABASE)
  Future login() async {
    try {
      final success = await _authController.login(username.text, password.text);
      if (!mounted) return;

      if (success) {
        // Berhasil login
        if (AppSession.userRole == 'owner' || AppSession.userRole == 'admin') {

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('language', 'English');
        }

        if (!mounted) return;

        PopupHelper.showSuccess(context, "Login successful!", onConfirm: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        });
      } else {
        // Gagal login
        PopupHelper.showError(context, "Invalid username or password");
      }
    } catch (e) {
      if (!mounted) return;
      PopupHelper.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LOGO SECTION
                Row(
                  children: [
                    Icon(
                      Icons.spa_outlined, 
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Indah Sari Salon",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 50),

                // SECURE ACCESS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE6E6E6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white70 : const Color(0xFF4A2C10),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "SECURE ACCESS",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4A4A4A),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // LARGE TITLE
                Text(
                  "Welcome Back\nto Indah Sari\nSalon",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -1.0,
                  ),
                ),

                const SizedBox(height: 16),

                // SUBTITLE
                Text(
                  "Access your personalized beauty\ndashboard and manage your upcoming\ntreatments.",
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // FORM CARD
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // USERNAME
                      Text(
                        "USERNAME",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: mutedText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: username,
                        style: TextStyle(color: mainTextColor, fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "e.g. indah_sari",
                          hintStyle: TextStyle(
                            color: mutedText,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // PASSWORD
                      Text(
                        "PASSWORD",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: mutedText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: password,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: mainTextColor, fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          hintStyle: TextStyle(
                            color: mutedText,
                            letterSpacing: 6,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: mutedText,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // REMEMBER ME AND FORGOT PASSWORD
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: rememberMe,
                              onChanged: (v) => setState(() => rememberMe = v!),
                              fillColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return primaryColor;
                                }
                                return inputBg;
                              }),
                              checkColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(color: isDark ? const Color(0xFF475569) : inputBg, width: 2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Remember Me",
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (username.text.isEmpty || password.text.isEmpty) {
                              PopupHelper.showError(context, "Please Fill In All Fields");
                              return;
                            }
                            login();
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}