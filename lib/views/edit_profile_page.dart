import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../app_session.dart';
import '../utils/translations.dart';
import '../utils/popup_helper.dart';

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

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _bankAccountNameController =
      TextEditingController();
  final TextEditingController _bankAccountNumberController =
      TextEditingController();
  final TextEditingController _lastEducationController =
      TextEditingController();

  DateTime? _selectedBirthDate;
  String? _selectedGender;

  File? _selectedImage;
  String? _avatarUrl;
  bool _uploadingImage = false;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = AppSession.userId;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _fullNameController.text = data['name'] ?? '';
          _nicknameController.text = data['nickname'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _birthPlaceController.text = data['birth_place'] ?? '';
          _emergencyContactController.text = data['emergency_contact'] ?? '';
          _bankAccountNameController.text = data['bank_account_name'] ?? '';
          _bankAccountNumberController.text = data['bank_account_number'] ?? '';
          _lastEducationController.text = data['last_education'] ?? '';

          if (data['birth_date'] != null) {
            _selectedBirthDate = DateTime.parse(data['birth_date']);
          }
          _selectedGender = data['gender'];

          _avatarUrl = data['avatar'];
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _saving = true);
    try {
      final userId = AppSession.userId;
      if (userId == null) return;

      await Supabase.instance.client
          .from('users')
          .update({
            'name': _fullNameController.text,
            'nickname': _nicknameController.text,
            'username': _usernameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
            'birth_place': _birthPlaceController.text,
            'birth_date': _selectedBirthDate?.toIso8601String(),
            'gender': _selectedGender,
            'emergency_contact': _emergencyContactController.text,
            'bank_account_name': _bankAccountNameController.text,
            'bank_account_number': _bankAccountNumberController.text,
            'last_education': _lastEducationController.text,
            if (_avatarUrl != null) 'avatar': _avatarUrl,
          })
          .eq('id', userId);

      // Update AppSession
      AppSession.userName = _fullNameController.text;
      AppSession.userEmail = _emailController.text;
      if (_avatarUrl != null) AppSession.userAvatar = _avatarUrl;

      if (mounted) {
        PopupHelper.showSuccess(
          context,
          "Profile updated successfully!".tr,
          onConfirm: () {
            Navigator.pop(context, true); // Return true to indicate update
          },
        );
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      if (mounted) {
        PopupHelper.showError(context, "Failed to update profile".tr);
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        PopupHelper.showError(context, "Failed to pick image".tr);
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _uploadingImage = true);

    try {
      final userId = AppSession.userId;
      if (userId == null) return;

      final fileExt = _selectedImage!.path.split('.').last;
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, _selectedImage!);

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      setState(() {
        _avatarUrl = publicUrl;
        _uploadingImage = false;
      });
    } catch (e) {
      debugPrint("Error uploading image: $e");
      if (mounted) {
        setState(() => _uploadingImage = false);
        PopupHelper.showError(context, "Failed to upload image".tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Edit Profile".tr,
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
                    child: SingleChildScrollView(
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
                                  image: DecorationImage(
                                    image: _selectedImage != null
                                        ? FileImage(_selectedImage!)
                                              as ImageProvider
                                        : (_avatarUrl != null &&
                                              _avatarUrl!.isNotEmpty)
                                        ? NetworkImage(_avatarUrl!)
                                        : const NetworkImage(
                                            "https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80",
                                          ), // using stock avatar image
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -4,
                                right: -4,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: scaffoldBg,
                                        width: 3,
                                      ),
                                    ),
                                    child: _uploadingImage
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _fullNameController.text,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppSession.userRole?.toUpperCase() ?? 'USER',
                            style: TextStyle(
                              fontSize: 14,
                              color: mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Forms
                          _buildInputField(
                            "FULL NAME".tr,
                            _fullNameController,
                            Icons.person_outline,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            "NAMA PANGGILAN".tr,
                            _nicknameController,
                            Icons.face_outlined,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            "USERNAME".tr,
                            _usernameController,
                            Icons.alternate_email,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            "EMAIL ADDRESS".tr,
                            _emailController,
                            Icons.email_outlined,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            "PHONE NUMBER".tr,
                            _phoneController,
                            Icons.phone_outlined,
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  "TEMPAT LAHIR".tr,
                                  _birthPlaceController,
                                  Icons.location_city,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDatePickerField(
                                  "TANGGAL LAHIR".tr,
                                  _selectedBirthDate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildGenderField(),
                          const SizedBox(height: 20),

                          _buildInputField(
                            "HOME ADDRESS".tr,
                            _addressController,
                            Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),

                          _buildInputField(
                            "KONTAK DARURAT".tr,
                            _emergencyContactController,
                            Icons.contact_emergency_outlined,
                          ),
                          const SizedBox(height: 20),

                          _buildInputField(
                            "NAMA REKENING".tr,
                            _bankAccountNameController,
                            Icons.account_balance_wallet_outlined,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            "NOMOR REKENING".tr,
                            _bankAccountNumberController,
                            Icons.numbers_outlined,
                          ),
                          const SizedBox(height: 20),

                          _buildInputField(
                            "PENDIDIKAN TERAKHIR".tr,
                            _lastEducationController,
                            Icons.school_outlined,
                          ),

                          const SizedBox(height: 48),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _saving ? null : _updateProfile,
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Save Changes".tr,
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
                                foregroundColor: const Color(
                                  0xFFDC2626,
                                ), // red color
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              onPressed: () {
                                PopupHelper.showConfirm(
                                  context,
                                  title: "Discard Changes?".tr,
                                  message:
                                      "Are you sure you want to discard your changes?"
                                          .tr,
                                  onConfirm: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                              child: Text(
                                "DISCARD CHANGES".tr,
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

  Widget _buildDatePickerField(String label, DateTime? date) {
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
        GestureDetector(
          onTap: _selectBirthDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date == null
                        ? "Pilih Tanggal"
                        : "${date.day}/${date.month}/${date.year}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: date == null
                          ? mutedText.withOpacity(0.5)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: mutedText.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "JENIS KELAMIN".tr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: mutedText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildChoiceChip("Laki-laki", _selectedGender == "Laki-laki", (
              val,
            ) {
              setState(() => _selectedGender = "Laki-laki");
            }),
            const SizedBox(width: 12),
            _buildChoiceChip("Perempuan", _selectedGender == "Perempuan", (
              val,
            ) {
              setState(() => _selectedGender = "Perempuan");
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChip(
    String label,
    bool isSelected,
    Function(bool) onSelected,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : mutedText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFFE2E8F0).withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: Icon(
                icon,
                color: mutedText.withOpacity(0.5),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
