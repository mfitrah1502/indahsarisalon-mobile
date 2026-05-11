class UserModel {
  final int id;
  final String username;
  final String name;
  final String role;
  final String email;
  final String password;
  final String type;
  final String status;
  final String? avatar;
  final String phone;
  final String address;
  
  // New Employee Fields
  final String? nickname;
  final String? birthPlace;
  final DateTime? birthDate;
  final String? gender;
  final String? position;
  final String? division;
  final DateTime? joinDate;
  final String? employmentStatus;
  final String? emergencyContact;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? lastEducation;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.email,
    required this.password,
    this.type = '',
    this.status = '',
    this.avatar,
    this.phone = '',
    this.address = '',
    this.nickname,
    this.birthPlace,
    this.birthDate,
    this.gender,
    this.position,
    this.division,
    this.joinDate,
    this.employmentStatus,
    this.emergencyContact,
    this.bankAccountName,
    this.bankAccountNumber,
    this.lastEducation,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      nickname: json['nickname'] as String?,
      birthPlace: json['birth_place'] as String?,
      birthDate: (json['birth_date'] != null && (json['birth_date'] as String).isNotEmpty) ? DateTime.parse(json['birth_date'] as String) : null,
      gender: json['gender'] as String?,
      position: json['position'] as String?,
      division: json['division'] as String?,
      joinDate: (json['join_date'] != null && (json['join_date'] as String).isNotEmpty) ? DateTime.parse(json['join_date'] as String) : null,
      employmentStatus: json['employment_status'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      lastEducation: json['last_education'] as String?,
    );
  }
}
