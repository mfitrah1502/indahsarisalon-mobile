import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final Color primaryColor = const Color(0xFFD660A1);
  final Color buttonColor = const Color(0xFFB53D7C);
  final Color scaffoldBg = const Color(0xFFF6F8FA);
  final Color mutedText = const Color(0xFF64748B);
  final Color fieldBg = const Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Check if username or email exists
      final checkUser = await supabase
          .from('users')
          .select('id')
          .or('username.eq.${_usernameCtrl.text.trim()},email.eq.${_emailCtrl.text.trim()}')
          .maybeSingle();

      if (checkUser != null) {
        throw Exception("Username or Email already registered");
      }

      // 2. Insert new user
      final hashedPassword = BCrypt.hashpw(_passwordCtrl.text.trim(), BCrypt.gensalt());
      
      await supabase.from('users').insert({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'password': hashedPassword,
        'role': 'admin',
        'status': 'aktif',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Admin account created successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Create Account",
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Join our community and book your next appointment easily.",
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                // White Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("FULL NAME"),
                        _buildTextField(_nameCtrl, "Jane Doe", validator: (v) {
                          if (v == null || v.isEmpty) return "Full Name is required";
                          return null;
                        }),
                        const SizedBox(height: 20),
                        
                        _buildFieldLabel("PHONE NUMBER"),
                        _buildTextField(_phoneCtrl, "+1 (555) 000-0000", keyboardType: TextInputType.phone, validator: (v) {
                          if (v == null || v.isEmpty) return "Phone Number is required";
                          return null;
                        }),
                        const SizedBox(height: 20),
                        
                        _buildFieldLabel("EMAIL"),
                        _buildTextField(_emailCtrl, "jane@example.com", keyboardType: TextInputType.emailAddress, validator: (v) {
                          if (v == null || v.isEmpty) return "Email is required";
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return "Enter a valid email";
                          return null;
                        }),
                        const SizedBox(height: 20),
                        
                        _buildFieldLabel("ADDRESS"),
                        _buildTextField(_addressCtrl, "123 Salon Way, Beauty City", validator: (v) {
                          if (v == null || v.isEmpty) return "Address is required";
                          return null;
                        }),
                        const SizedBox(height: 32),
                        
                        const Divider(),
                        const SizedBox(height: 24),
                        
                        _buildFieldLabel("USERNAME"),
                        _buildTextField(_usernameCtrl, "janedoe88", validator: (v) {
                          if (v == null || v.isEmpty) return "Username is required";
                          return null;
                        }),
                        const SizedBox(height: 20),
                        
                        _buildFieldLabel("PASSWORD"),
                        _buildTextField(
                          _passwordCtrl, 
                          "••••••••", 
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: mutedText, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Password is required";
                            if (v.length < 6) return "Password must be at least 6 characters";
                            return null;
                          }
                        ),
                        const SizedBox(height: 48),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: _isLoading ? null : _handleCreateAccount,
                            child: const Text("Save", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: primaryColor.withOpacity(0.7),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, 
    {
      bool obscureText = false, 
      TextInputType? keyboardType,
      Widget? suffixIcon,
      String? Function(String?)? validator,
    }
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: primaryColor.withOpacity(0.3)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9).withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.1), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
