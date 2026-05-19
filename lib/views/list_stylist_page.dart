import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../controllers/user_controller.dart';
import 'home_page.dart';
import 'booking_list_page.dart';
import 'manage_services_page.dart';
import 'settings_page.dart';
import 'report_page.dart';
import '../utils/popup_helper.dart';

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Arrow
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          color: primaryColor,
                          size: 28,
                        ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE2E8F0,
                                ), // Light grey input background
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  icon: Icon(
                                    Icons.search,
                                    color: mutedText,
                                    size: 20,
                                  ),
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
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (filteredStylists.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              "Belum ada data ${widget.role}.",
                              style: TextStyle(color: mutedText),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredStylists.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
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
                                      image:
                                          stylist.avatar != null &&
                                              stylist.avatar!.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                stylist.avatar!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child:
                                        stylist.avatar == null ||
                                            stylist.avatar!.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            color: Color(0xFF94A3B8),
                                            size: 32,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),

                                  // Text details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stylist.name.isNotEmpty
                                              ? stylist.name
                                              : '-',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        if (stylist.position != null &&
                                            stylist.position!.isNotEmpty)
                                          Text(
                                            "${stylist.position} ${stylist.division != null && stylist.division!.isNotEmpty ? '• ${stylist.division}' : ''}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: buttonColor.withOpacity(
                                                0.8,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          stylist.email.isNotEmpty
                                              ? stylist.email
                                              : '-',
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
                                    onTap: () =>
                                        _showAddStylistModal(stylist: stylist),
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
                                    onTap: () {
                                      PopupHelper.showConfirm(
                                        context,
                                        title: "Hapus Stylist",
                                        message:
                                            "Yakin ingin menghapus ${stylist.name} dari tim?",
                                        onConfirm: () async {
                                          if (stylist.id != null) {
                                            try {
                                              await _userController
                                                  .deleteStylist(stylist.id!);
                                              _fetchStylists();
                                              if (mounted) {
                                                PopupHelper.showSuccess(
                                                  context,
                                                  'Stylist berhasil dihapus',
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                PopupHelper.showError(
                                                  context,
                                                  'Failed to delete stylist: $e',
                                                );
                                              }
                                            }
                                          }
                                        },
                                      );
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
    final nameController = TextEditingController(
      text: isEdit ? stylist.name : '',
    );
    final nicknameController = TextEditingController(
      text: isEdit ? stylist.nickname : '',
    );
    final birthPlaceController = TextEditingController(
      text: isEdit ? stylist.birthPlace : '',
    );
    final emailController = TextEditingController(
      text: isEdit ? stylist.email : '',
    );
    final phoneController = TextEditingController(
      text: isEdit ? stylist.phone : '',
    );
    final addressController = TextEditingController(
      text: isEdit ? stylist.address : '',
    );
    final positionController = TextEditingController(
      text: isEdit ? stylist.position : '',
    );
    final divisionController = TextEditingController(
      text: isEdit ? stylist.division : '',
    );
    final emergencyContactController = TextEditingController(
      text: isEdit ? stylist.emergencyContact : '',
    );
    final bankAccountNameController = TextEditingController(
      text: isEdit ? stylist.bankAccountName : '',
    );
    final bankAccountNumberController = TextEditingController(
      text: isEdit ? stylist.bankAccountNumber : '',
    );
    final lastEducationController = TextEditingController(
      text: isEdit ? stylist.lastEducation : '',
    );

    DateTime? selectedBirthDate = stylist?.birthDate;
    DateTime? selectedJoinDate = stylist?.joinDate;
    String? selectedGender = stylist?.gender;
    String? selectedEmploymentStatus = stylist?.employmentStatus;
    String? selectedPosition = stylist?.position;
    String? selectedDivision = stylist?.division;

    File? selectedImage;
    String? avatarUrl = stylist?.avatar;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickAndUploadImage() async {
              try {
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image == null) return;

                setModalState(() {
                  selectedImage = File(image.path);
                  isUploading = true;
                });

                final fileExt = image.path.split('.').last;
                final fileName =
                    'stylist-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

                await Supabase.instance.client.storage
                    .from('avatars')
                    .upload(fileName, selectedImage!);

                final publicUrl = Supabase.instance.client.storage
                    .from('avatars')
                    .getPublicUrl(fileName);

                setModalState(() {
                  avatarUrl = publicUrl;
                  isUploading = false;
                });
              } catch (e) {
                setModalState(() => isUploading = false);
                debugPrint("Error uploading image: $e");
                if (mounted) {
                  PopupHelper.showError(context, "Failed to upload photo: $e");
                }
              }
            }

            Future<void> selectDate(
              BuildContext context,
              bool isBirthDate,
            ) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate:
                    (isBirthDate ? selectedBirthDate : selectedJoinDate) ??
                    DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime(2100),
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
                setModalState(() {
                  if (isBirthDate) {
                    selectedBirthDate = picked;
                  } else {
                    selectedJoinDate = picked;
                  }
                });
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: scaffoldBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        Text(
                          isEdit ? "Update Staff" : "Add Staff",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (nameController.text.isNotEmpty) {
                              final emailValue =
                                  emailController.text.trim().isEmpty
                                  ? "${DateTime.now().millisecondsSinceEpoch}@example.com"
                                  : emailController.text.trim();

                              final dataPayload = {
                                "name": nameController.text.trim(),
                                "nickname": nicknameController.text.trim(),
                                "birth_place": birthPlaceController.text.trim(),
                                "birth_date": selectedBirthDate
                                    ?.toIso8601String(),
                                "gender": selectedGender,
                                "address": addressController.text.trim(),
                                "phone": phoneController.text.trim(),
                                "email": emailValue,
                                "position": selectedPosition,
                                "division": selectedDivision,
                                "join_date": selectedJoinDate
                                    ?.toIso8601String(),
                                "employment_status": selectedEmploymentStatus,
                                "emergency_contact": emergencyContactController
                                    .text
                                    .trim(),
                                "bank_account_name": bankAccountNameController
                                    .text
                                    .trim(),
                                "bank_account_number":
                                    bankAccountNumberController.text.trim(),
                                "last_education": lastEducationController.text
                                    .trim(),
                                "kategori": widget.role.toLowerCase(),
                                "type": 'karyawan',
                                "role": 'karyawan',
                                "status": "aktif",
                              };

                              if (!isEdit) {
                                dataPayload["username"] =
                                    nameController.text
                                        .trim()
                                        .replaceAll(' ', '')
                                        .toLowerCase() +
                                    DateTime.now().millisecondsSinceEpoch
                                        .toString()
                                        .substring(8);
                                dataPayload["password"] = "password";
                              }

                              if (avatarUrl != null) {
                                dataPayload["avatar"] = avatarUrl!;
                              }

                              try {
                                await _userController.saveStylist(
                                  dataPayload,
                                  id: stylist?.id,
                                );
                                _fetchStylists();
                              } catch (e) {
                                debugPrint("Error saving stylist: $e");
                                PopupHelper.showError(
                                  context,
                                  'Failed to save data: $e',
                                );
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Photo Area
                          GestureDetector(
                            onTap: pickAndUploadImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(16),
                                    image: selectedImage != null
                                        ? DecorationImage(
                                            image: FileImage(selectedImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : (avatarUrl != null &&
                                              avatarUrl!.isNotEmpty)
                                        ? DecorationImage(
                                            image: NetworkImage(avatarUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child:
                                      (selectedImage == null &&
                                          (avatarUrl == null ||
                                              avatarUrl!.isEmpty))
                                      ? const Icon(
                                          Icons.person,
                                          color: Color(0xFF94A3B8),
                                          size: 48,
                                        )
                                      : null,
                                ),
                                Transform.translate(
                                  offset: const Offset(8, 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: scaffoldBg,
                                        width: 2,
                                      ),
                                    ),
                                    child: isUploading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "UPLOAD PHOTO",
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
                          _buildTextField(
                            "e.g. Julianne Smith",
                            nameController,
                          ),
                          const SizedBox(height: 20),

                          _buildTextFieldLabel("NICKNAME"),
                          _buildTextField("e.g. Julie", nicknameController),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildTextFieldLabel("PLACE OF BIRTH"),
                                    _buildTextField(
                                      "e.g. Jakarta",
                                      birthPlaceController,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildTextFieldLabel("DATE OF BIRTH"),
                                    _buildDatePickerField(
                                      selectedBirthDate == null
                                          ? "Select Date"
                                          : "${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}",
                                      () => selectDate(context, true),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildTextFieldLabel("GENDER"),
                          Row(
                            children: [
                              _buildChoiceChip(
                                "Male",
                                selectedGender == "Male",
                                (val) {
                                  setModalState(() => selectedGender = "Male");
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildChoiceChip(
                                "Female",
                                selectedGender == "Female",
                                (val) {
                                  setModalState(() => selectedGender = "Female");
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildTextFieldLabel("ADDRESS"),
                          _buildTextField(
                            "e.g. Jl. Melati No. 12",
                            addressController,
                          ),
                          const SizedBox(height: 20),

                          _buildTextFieldLabel("PHONE NUMBER"),
                          _buildTextField(
                            "e.g. 08123456789",
                            phoneController,
                            TextInputType.phone,
                          ),
                          const SizedBox(height: 20),

                          _buildTextFieldLabel("EMAIL ADDRESS"),
                          _buildTextField(
                            "julianne@salon.com",
                            emailController,
                            TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildTextFieldLabel("POSITION"),
                                    _buildDropdownField(
                                      selectedPosition ?? "Select Position",
                                      [
                                        "Client Relationship Manager",
                                        "Senior Hair Technician Specialist",
                                        "Senior Beautician",
                                        "Creative Stylist",
                                        "Senior Therapist",
                                        "Relationship Client",
                                        "Junior Therapist",
                                      ],
                                      (val) {
                                        setModalState(
                                          () => selectedPosition = val,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildTextFieldLabel("DIVISION"),
                                    _buildDropdownField(
                                      (selectedDivision == null || selectedDivision == "") ? "-" : selectedDivision!,
                                      ["-", "hair", "beauty"],
                                      (val) {
                                        setModalState(
                                          () => selectedDivision = (val == null || val == "-" || val == "") ? null : val,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildTextFieldLabel("JOIN DATE"),
                                    _buildDatePickerField(
                                      selectedJoinDate == null
                                          ? "Select Date"
                                          : "${selectedJoinDate!.day}/${selectedJoinDate!.month}/${selectedJoinDate!.year}",
                                      () => selectDate(context, false),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildTextFieldLabel("EMPLOYMENT STATUS"),
                                    _buildDropdownField(
                                      selectedEmploymentStatus ??
                                          "Select Status",
                                      ["TRAINING", "TETAP"],
                                      (val) {
                                        setModalState(
                                          () => selectedEmploymentStatus = val,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildTextFieldLabel("EMERGENCY CONTACT (NAME & PHONE)"),
                          _buildTextField(
                            "e.g. Budi (08123456789)",
                            emergencyContactController,
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildTextFieldLabel("BANK ACCOUNT NAME"),
                                    _buildTextField(
                                      "e.g. Julianne Smith",
                                      bankAccountNameController,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildTextFieldLabel("BANK ACCOUNT NUMBER"),
                                    _buildTextField(
                                      "e.g. 1234567890",
                                      bankAccountNumberController,
                                      TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildTextFieldLabel("LAST EDUCATION"),
                          _buildTextField(
                            "e.g. SMK Kecantikan",
                            lastEducationController,
                          ),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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

  Widget _buildTextField(
    String hint, [
    TextEditingController? controller,
    TextInputType? keyboardType,
  ]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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

  Widget _buildDatePickerField(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: text == "Select Date"
                ? const Color(0xFF64748B).withOpacity(0.6)
                : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
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

  Widget _buildDropdownField(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((item) => item.toLowerCase() == value.toLowerCase())
              ? items.firstWhere((item) => item.toLowerCase() == value.toLowerCase())
              : null,
          hint: Text(
            value,
            style: TextStyle(
              color: const Color(0xFF64748B).withOpacity(0.6),
              fontSize: 15,
            ),
          ),
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
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
        } else if (index == 3) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ReportPage()),
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
          Icon(icon, color: isSelected ? primaryColor : mutedText, size: 26),
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
