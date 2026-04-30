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
    );
  }
}
