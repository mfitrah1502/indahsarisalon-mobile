import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'auth_page.dart';
import 'reset_password_page.dart';
import '../utils/popup_helper.dart';
import '../app_session.dart';
import '../utils/email_helper.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool get isDark => AppSession.isDarkMode;
  Color get primaryColor => const Color(0xFFD660A1);
  Color get buttonColor => const Color(0xFFB53D7C);
  Color get scaffoldBg => isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F7FB);
  Color get inputBg => isDark ? const Color(0xFF334155) : const Color(0xFFE2E4Eb);
  Color get cardBg => isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get mainTextColor => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get borderCol => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  bool _isLoading = false;

  final List<TextEditingController> _otpControllers = List.generate(8, (index) => TextEditingController());
  bool _isVerifying = false;
  String _generatedOtp = "";

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
                // Header (No arrow back)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Recovery",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 80),

                // Icon Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.history, 
                    color: primaryColor,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 40),

                // Text Content
                Text(
                  "Forgot Password",
                  style: TextStyle(
                    color: mainTextColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Enter Your Email Or Phone Number To Reset Your Password Quickly",
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "USERNAME",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: mutedText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usernameController,
                        style: TextStyle(color: mainTextColor, fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person_outline, size: 20, color: mutedText),
                          hintText: "your_username",
                          hintStyle: TextStyle(
                            color: mutedText,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: inputBg.withValues(alpha: isDark ? 0.3 : 0.5),
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

                      Text(
                        "EMAIL ADDRESS",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: mutedText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        style: TextStyle(color: mainTextColor, fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined, size: 20, color: mutedText),
                          hintText: "name@example.com",
                          hintStyle: TextStyle(
                            color: mutedText,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: inputBg.withValues(alpha: isDark ? 0.3 : 0.5),
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

                      const SizedBox(height: 32),

                      // Send OTP Button
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
                            shadowColor: primaryColor.withValues(alpha: 0.3),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final email = emailController.text.trim();
                                  final username = usernameController.text.trim();

                                  if (username.isEmpty) {
                                      PopupHelper.showError(context, 'Please enter your username');
                                    return;
                                  }
                                  if (email.isEmpty) {
                                      PopupHelper.showError(context, 'Please enter your email');
                                    return;
                                  }

                                  setState(() => _isLoading = true);
                                  try {
                                    final user = await Supabase.instance.client
                                        .from('users')
                                        .select('id, email')
                                        .eq('username', username)
                                        .maybeSingle();

                                    if (!context.mounted) return;

                                    if (user == null) {
                                      PopupHelper.showError(context, 'Username tidak ditemukan');
                                      setState(() => _isLoading = false);
                                      return;
                                    }

                                    if (user['email'] != email) {
                                      PopupHelper.showError(context, 'Email tidak sesuai dengan username tersebut');
                                      setState(() => _isLoading = false);
                                      return;
                                    }

                                    // Generate OTP
                                    final random = Random();
                                    _generatedOtp = List.generate(8, (_) => random.nextInt(10)).join();
                                    
                                    // Send actual email
                                    await EmailHelper.sendOTPEmail(email, _generatedOtp);
                                    
                                    if (context.mounted) {
                                      PopupHelper.showSuccess(
                                        context, 
                                        'Kode OTP telah berhasil dikirim ke email Anda!',
                                        onConfirm: () {
                                          _showOTPDialog(context);
                                        }
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      PopupHelper.showError(context, 'Error: ${e.toString()}');
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Send OTP",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),

                // Bottom Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Remembered your password? ",
                      style: TextStyle(color: mutedText, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthPage()),
                        );
                      },
                      child: Text(
                        "Log In",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Bottom Label
                Text(
                  "SECURE AUTHENTICATION SYSTEM",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: mutedText.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOTPDialog(BuildContext context) {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isResending = false;
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            Future<void> verify() async {
              final otp = _otpControllers.map((c) => c.text).join();
              if (otp.length != 8) {
                if (dialogContext.mounted) {
                  PopupHelper.showError(dialogContext, 'Please enter a valid 8-digit OTP');
                }
                return;
              }

              setStateDialog(() => _isVerifying = true);
              try {
                await Future.delayed(const Duration(seconds: 1)); // Simulate network request
                
                if (otp != _generatedOtp) {
                  throw Exception("Kode OTP tidak valid.");
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => ResetPasswordPage(
                      email: emailController.text.trim(),
                      username: usernameController.text.trim(),
                    )),
                    (route) => route.isFirst,
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  PopupHelper.showError(dialogContext, 'Invalid OTP or error: ${e.toString()}');
                }
              } finally {
                if (dialogContext.mounted) {
                  setStateDialog(() => _isVerifying = false);
                }
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderCol, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shield Icon Container
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFD6E9FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.verified_user, color: isDark ? Colors.white : primaryColor, size: 32),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      "Verify Your Identity",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Please enter the 8-digit code sent to:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: mutedText,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      emailController.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // OTP Inputs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(8, (index) {
                        return SizedBox(
                          width: 32,
                          height: 48,
                          child: TextField(
                            controller: _otpControllers[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                if (index < 7) {
                                  FocusScope.of(ctx).nextFocus();
                                } else {
                                  // Auto-verify on last digit
                                  FocusScope.of(ctx).unfocus();
                                  verify();
                                }
                              } else if (value.isEmpty && index > 0) {
                                FocusScope.of(ctx).previousFocus();
                              }
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : primaryColor,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: primaryColor.withValues(alpha: 0.3),
                        ),
                        onPressed: _isVerifying ? null : verify,
                        child: _isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Verify", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Cancel Button
                    TextButton(
                      onPressed: () {
                        if (dialogContext.mounted) {
                          PopupHelper.showConfirm(
                            dialogContext,
                            title: "Cancel Verification?",
                            message: "Are you sure you want to cancel the OTP verification process?",
                            onConfirm: () {
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            },
                          );
                        }
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(color: borderCol),
                    const SizedBox(height: 12),

                    // Resend section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(color: mutedText, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: isResending ? null : () async {
                            setStateDialog(() => isResending = true);
                            try {
                              await Future.delayed(const Duration(seconds: 1));
                              final random = Random();
                              _generatedOtp = List.generate(8, (_) => random.nextInt(10)).join();
                              
                              // Send actual email
                              await EmailHelper.sendOTPEmail(emailController.text.trim(), _generatedOtp);
                              
                              if (context.mounted) {
                                PopupHelper.showSuccess(
                                  context, 
                                  'Kode OTP baru telah berhasil dikirim!', 
                                  onConfirm: () {
                                    // PopupHelper handles the pop
                                  }
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                PopupHelper.showError(context, 'Failed to resend OTP: ${e.toString()}');
                              }
                            } finally {
                              if (dialogContext.mounted) {
                                setStateDialog(() => isResending = false);
                              }
                            }
                          },
                          child: Text(
                            isResending ? "Resending..." : "Resend Code",
                            style: TextStyle(
                              color: isResending ? mutedText : primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
