import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../app_session.dart';
import '../utils/popup_helper.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool get isDark => AppSession.isDarkMode;
  Color get primaryColor => const Color(0xFFD660A1);
  Color get buttonColor => const Color(0xFFB53D7C);
  Color get scaffoldBg => isDark ? const Color(0xFF1E293B) : const Color(0xFFF6F8FA);
  Color get mutedText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get cardBg => isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get mainTextColor => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B);
  Color get inputBg => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0).withValues(alpha: 0.6);
  Color get borderCol => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0).withValues(alpha: 0.6);

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

  // Owner custom profile fields
  final TextEditingController _tentangController = TextEditingController();
  final TextEditingController _nomorStrController = TextEditingController();
  final TextEditingController _nomorSipController = TextEditingController();
  final TextEditingController _tempatPraktikController = TextEditingController();
  final TextEditingController _tahunMulaiPraktikController = TextEditingController();
  final TextEditingController _pendidikan1Controller = TextEditingController();
  final TextEditingController _pendidikan2Controller = TextEditingController();
  final TextEditingController _pendidikan3Controller = TextEditingController();
  final TextEditingController _pengalaman1Controller = TextEditingController();
  final TextEditingController _pengalaman2Controller = TextEditingController();
  final TextEditingController _pengalaman3Controller = TextEditingController();
  final TextEditingController _pengalaman4Controller = TextEditingController();
  final TextEditingController _pengalaman5Controller = TextEditingController();
  final TextEditingController _keanggotaan1Controller = TextEditingController();
  final TextEditingController _keanggotaan2Controller = TextEditingController();
  final TextEditingController _sertifikasi1Controller = TextEditingController();
  final TextEditingController _sertifikasi2Controller = TextEditingController();
  final TextEditingController _sertifikasi3Controller = TextEditingController();
  final TextEditingController _sertifikasi4Controller = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthPlaceController.dispose();
    _emergencyContactController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    _lastEducationController.dispose();
    
    _tentangController.dispose();
    _nomorStrController.dispose();
    _nomorSipController.dispose();
    _tempatPraktikController.dispose();
    _tahunMulaiPraktikController.dispose();
    _pendidikan1Controller.dispose();
    _pendidikan2Controller.dispose();
    _pendidikan3Controller.dispose();
    _pengalaman1Controller.dispose();
    _pengalaman2Controller.dispose();
    _pengalaman3Controller.dispose();
    _pengalaman4Controller.dispose();
    _pengalaman5Controller.dispose();
    _keanggotaan1Controller.dispose();
    _keanggotaan2Controller.dispose();
    _sertifikasi1Controller.dispose();
    _sertifikasi2Controller.dispose();
    _sertifikasi3Controller.dispose();
    _sertifikasi4Controller.dispose();
    
    super.dispose();
  }

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

          // Parse owner profile JSON data
          final ownerProfile = data['owner_profile'] as Map<String, dynamic>? ?? {};
          _tentangController.text = ownerProfile['tentang'] ?? '';
          _nomorStrController.text = ownerProfile['nomor_str'] ?? ownerProfile['kredensial'] ?? '';
          _nomorSipController.text = ownerProfile['nomor_sip'] ?? ownerProfile['izin_praktek'] ?? '';
          _tempatPraktikController.text = ownerProfile['tempat_praktik'] ?? ownerProfile['layanan_utama'] ?? '';
          _tahunMulaiPraktikController.text = ownerProfile['tahun_mulai_praktik'] ?? ownerProfile['lokasi_praktik'] ?? '';
          _pendidikan1Controller.text = ownerProfile['pendidikan_1'] ?? '';
          _pendidikan2Controller.text = ownerProfile['pendidikan_2'] ?? '';
          _pendidikan3Controller.text = ownerProfile['pendidikan_3'] ?? '';
          _pengalaman1Controller.text = ownerProfile['pengalaman_1'] ?? '';
          _pengalaman2Controller.text = ownerProfile['pengalaman_2'] ?? '';
          _pengalaman3Controller.text = ownerProfile['pengalaman_3'] ?? '';
          _pengalaman4Controller.text = ownerProfile['pengalaman_4'] ?? '';
          _pengalaman5Controller.text = ownerProfile['pengalaman_5'] ?? '';
          _keanggotaan1Controller.text = ownerProfile['keanggotaan_1'] ?? '';
          _keanggotaan2Controller.text = ownerProfile['keanggotaan_2'] ?? '';
          _sertifikasi1Controller.text = ownerProfile['sertifikasi_1'] ?? '';
          _sertifikasi2Controller.text = ownerProfile['sertifikasi_2'] ?? '';
          _sertifikasi3Controller.text = ownerProfile['sertifikasi_3'] ?? '';
          _sertifikasi4Controller.text = ownerProfile['sertifikasi_4'] ?? '';

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

      final Map<String, dynamic> ownerProfileData = {
        'tentang': _tentangController.text,
        'nomor_str': _nomorStrController.text,
        'nomor_sip': _nomorSipController.text,
        'tempat_praktik': _tempatPraktikController.text,
        'tahun_mulai_praktik': _tahunMulaiPraktikController.text,
        'pendidikan_1': _pendidikan1Controller.text,
        'pendidikan_2': _pendidikan2Controller.text,
        'pendidikan_3': _pendidikan3Controller.text,
        'pengalaman_1': _pengalaman1Controller.text,
        'pengalaman_2': _pengalaman2Controller.text,
        'pengalaman_3': _pengalaman3Controller.text,
        'pengalaman_4': _pengalaman4Controller.text,
        'pengalaman_5': _pengalaman5Controller.text,
        'keanggotaan_1': _keanggotaan1Controller.text,
        'keanggotaan_2': _keanggotaan2Controller.text,
        'sertifikasi_1': _sertifikasi1Controller.text,
        'sertifikasi_2': _sertifikasi2Controller.text,
        'sertifikasi_3': _sertifikasi3Controller.text,
        'sertifikasi_4': _sertifikasi4Controller.text,
      };

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
            if (AppSession.userRole?.toLowerCase() == 'owner') 'owner_profile': ownerProfileData,
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
          "Profile updated successfully!",
          onConfirm: () {
            Navigator.pop(context, true); // Return true to indicate update
          },
        );
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      if (mounted) {
        PopupHelper.showError(context, "Failed to update profile");
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
        PopupHelper.showError(context, "Failed to pick image");
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
        PopupHelper.showError(context, "Failed to upload image");
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
                                  color: cardBg,
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

                          // Forms - menampilkan field sesuai peran pengguna
                          if (AppSession.userRole?.toLowerCase() == 'owner') ...[
                            _buildInputField('FULL NAME', _fullNameController, Icons.person_outline),
                            const SizedBox(height: 20),
                            _buildInputField('ABOUT ME', _tentangController, Icons.info_outline, maxLines: 3),
                            const SizedBox(height: 20),
                            _buildInputField('USERNAME', _usernameController, Icons.alternate_email),
                            const SizedBox(height: 20),
                            _buildInputField('EMAIL ADDRESS', _emailController, Icons.email_outlined),
                            const SizedBox(height: 20),
                            _buildInputField('PHONE NUMBER', _phoneController, Icons.phone_outlined),
                            
                            // 2. Credentials & Practice Permit
                            _buildSectionCard(
                              title: 'CREDENTIALS & LICENSE TO PRACTICE',
                              icon: Icons.assignment_ind_outlined,
                              children: [
                                _buildInputField('STR NUMBER (CREDENTIALS)', _nomorStrController, Icons.badge_outlined),
                                const SizedBox(height: 20),
                                _buildInputField('SIP NUMBER (PRACTICE PERMIT)', _nomorSipController, Icons.verified_user_outlined),
                              ],
                            ),
                            
                            // 3. Practice Information
                            _buildSectionCard(
                              title: 'PRACTICE INFORMATION',
                              icon: Icons.business_outlined,
                              children: [
                                _buildInputField('PRACTICE PLACE', _tempatPraktikController, Icons.map_outlined),
                                const SizedBox(height: 20),
                                _buildInputField('YEAR OF STARTING PRACTICE', _tahunMulaiPraktikController, Icons.calendar_today_outlined),
                              ],
                            ),
                            
                            // 4. Education
                            _buildSectionCard(
                              title: 'EDUCATION',
                              icon: Icons.school_outlined,
                              children: [
                                _buildInputField('EDUCATION 1 (BACHELOR/DIPLOMA)', _pendidikan1Controller, Icons.school_outlined),
                                const SizedBox(height: 20),
                                _buildInputField('EDUCATION 2 (MASTER/SPECIALIZATION)', _pendidikan2Controller, Icons.history_edu_outlined),
                                const SizedBox(height: 20),
                                _buildInputField('EDUCATION 3 (OTHER TRAINING)', _pendidikan3Controller, Icons.workspace_premium_outlined),
                              ],
                            ),
                            
                            // 5. Work Experience
                            _buildSectionCard(
                              title: 'WORK EXPERIENCE',
                              icon: Icons.work_history_outlined,
                              children: [
                                _buildInputField('EXPERIENCE 1 (LATEST)', _pengalaman1Controller, Icons.work_outline),
                                const SizedBox(height: 20),
                                _buildInputField('EXPERIENCE 2', _pengalaman2Controller, Icons.work_outline),
                                const SizedBox(height: 20),
                                _buildInputField('EXPERIENCE 3', _pengalaman3Controller, Icons.work_outline),
                                const SizedBox(height: 20),
                                _buildInputField('EXPERIENCE 4', _pengalaman4Controller, Icons.work_outline),
                                const SizedBox(height: 20),
                                _buildInputField('EXPERIENCE 5', _pengalaman5Controller, Icons.work_outline),
                              ],
                            ),
                            
                            // 6. Professional Membership
                            _buildSectionCard(
                              title: 'PROFESSIONAL MEMBERSHIP',
                              icon: Icons.groups_outlined,
                              children: [
                                _buildInputField('ORGANIZATION / MEMBERSHIP 1', _keanggotaan1Controller, Icons.card_membership_outlined),
                                const SizedBox(height: 20),
                                _buildInputField('ORGANIZATION / MEMBERSHIP 2', _keanggotaan2Controller, Icons.groups_outlined),
                              ],
                            ),
                            
                            // 7. Professional Certification
                            _buildSectionCard(
                              title: 'PROFESSIONAL CERTIFICATION',
                              icon: Icons.verified_outlined,
                              children: [
                                _buildInputField('CERTIFICATION 1 (LATEST)', _sertifikasi1Controller, Icons.bookmark_added_outlined),
                                const SizedBox(height: 20),
                                _buildInputField('CERTIFICATION 2', _sertifikasi2Controller, Icons.bookmark_added_outlined),
                                const SizedBox(height: 20),
                                _buildInputField('CERTIFICATION 3', _sertifikasi3Controller, Icons.bookmark_added_outlined),
                                const SizedBox(height: 20),
                                _buildInputField('CERTIFICATION 4', _sertifikasi4Controller, Icons.bookmark_added_outlined),
                              ],
                            ),
                          ] else ...[
                            // Full fields for admin or other roles
                            _buildInputField('FULL NAME', _fullNameController, Icons.person_outline),
                            const SizedBox(height: 20),
                            _buildInputField('NICKNAME', _nicknameController, Icons.face_outlined),
                            const SizedBox(height: 20),
                            _buildInputField('USERNAME', _usernameController, Icons.alternate_email),
                            const SizedBox(height: 20),
                            _buildInputField('EMAIL ADDRESS', _emailController, Icons.email_outlined),
                            const SizedBox(height: 20),
                            _buildInputField('PHONE NUMBER', _phoneController, Icons.phone_outlined),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField('PLACE OF BIRTH', _birthPlaceController, Icons.location_city),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDatePickerField('DATE OF BIRTH', _selectedBirthDate),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildGenderField(),
                            const SizedBox(height: 20),
                            _buildInputField('HOME ADDRESS', _addressController, Icons.location_on_outlined, maxLines: 2),
                            const SizedBox(height: 20),
                            _buildInputField('EMERGENCY CONTACT', _emergencyContactController, Icons.contact_emergency_outlined),
                            const SizedBox(height: 20),
                            _buildInputField('BANK ACCOUNT NAME', _bankAccountNameController, Icons.account_balance_wallet_outlined),
                            const SizedBox(height: 20),
                            _buildInputField('BANK ACCOUNT NUMBER', _bankAccountNumberController, Icons.numbers_outlined),
                            const SizedBox(height: 20),
                            _buildInputField('LAST EDUCATION', _lastEducationController, Icons.school_outlined),
                          ],

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
                                  title: "Discard Changes?",
                                  message:
                                      "Are you sure you want to discard your changes?"
                                          ,
                                  onConfirm: () {
                                    Navigator.pop(context);
                                  },
                                );
                              },
                              child: Text(
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
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date == null
                        ? "Select Date"
                        : "${date.day}/${date.month}/${date.year}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: date == null
                          ? mutedText.withValues(alpha: 0.5)
                          : mainTextColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: mutedText.withValues(alpha: 0.5),
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
          "GENDER",
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
            _buildChoiceChip("Male", _selectedGender == "Laki-laki", (
              val,
            ) {
              setState(() => _selectedGender = "Laki-laki");
            }),
            const SizedBox(width: 12),
            _buildChoiceChip("Female", _selectedGender == "Perempuan", (
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
      selectedColor: primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : mutedText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: inputBg,
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
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: const Color(0xFFD660A1),
                    onPrimary: Colors.white,
                    surface: cardBg,
                    onSurface: mainTextColor,
                  )
                : ColorScheme.light(
                    primary: const Color(0xFFD660A1),
                    onPrimary: Colors.white,
                    onSurface: const Color(0xFFD660A1),
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
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: mainTextColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: Icon(
                icon,
                color: mutedText.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: borderCol,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
