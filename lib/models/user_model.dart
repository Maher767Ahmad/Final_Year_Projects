class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final List<String> approvedSubjects;
  final String status;
  final String? idCardUrl;
  final String? profilePicture;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.approvedSubjects,
    required this.status,
    this.idCardUrl,
    this.profilePicture,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name'],
      email: json['email'],
      role: json['role'],
      department: json['department'],
      approvedSubjects: List<String>.from(json['approved_subjects'] ?? []),
      status: json['status'],
      idCardUrl: json['id_card_url'],
      profilePicture: json['profile_picture'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'approved_subjects': approvedSubjects,
      'status': status,
      'id_card_url': idCardUrl,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isApproved => status == 'approved';
  bool get isTeacher => role == 'Teacher Admin';
  bool get isStudent => role == 'Student';
  bool get isSuperAdmin => role == 'Super Admin';
}
