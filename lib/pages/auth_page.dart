import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'home_page.dart';
import '../app_session.dart';
import 'forgot_password_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF5F7FB);
  final Color inputBg = const Color(0xFFE2E4Eb);

  final username = TextEditingController();
  final password = TextEditingController();

  bool rememberMe = false;

  // 🔥 LOGIN FUNCTION (SUPABASE)
  Future login() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Query ke tabel users custom di public
      final user = await supabase
          .from('users')
          .select()
          .eq('username', username.text)
          .maybeSingle();

      if (!mounted) return;

      if (user != null) {
        // Cek kecocokan password karena tersimpan sebagai Bcrypt hash
        bool isPasswordCorrect = false;
        try {
          isPasswordCorrect = BCrypt.checkpw(password.text, user['password']);
        } catch (e) {
          debugPrint("Bcrypt Cek Error: $e");
        }

        if (isPasswordCorrect) {
          // Simpan sesi pengguna
          AppSession.userId = user['id'] as int;
          AppSession.userName = user['name'] as String? ?? '';
          AppSession.userRole = user['role'] as String? ?? '';

          // Berhasil login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login berhasil!")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Gagal login - Password salah
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Username atau password salah")),
          );
        }
      } else {
        // Gagal login - Username tidak ada
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username atau password salah")),
        );
      }
    } catch (e) {
      debugPrint("ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan saat memproses login")),
      );
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
                    color: const Color(0xFFE6E6E6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4A2C10),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "SECURE ACCESS",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFF4A4A4A),
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
                const Text(
                  "Access your personalized beauty\ndashboard and manage your upcoming\ntreatments.",
                  style: TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // FORM CARD
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // USERNAME
                      const Text(
                        "USERNAME",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4B5563),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: username,
                        decoration: InputDecoration(
                          hintText: "e.g. indah_sari",
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
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
                      const Text(
                        "PASSWORD",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4B5563),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 6,
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
                              fillColor: MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.selected)) {
                                  return primaryColor;
                                }
                                return inputBg; // Note: For unselected state, fillColor controls the inside. Checkbox border color usually relies on side property.
                              }),
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(color: inputBg, width: 2), // Remove default border
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Remember Me",
                            style: TextStyle(
                              color: Color(0xFF4B5563),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Isi semua field")),
                              );
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