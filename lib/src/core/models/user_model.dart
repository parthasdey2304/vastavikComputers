// Firestore User Model
class UserModel {
  final String uid;
  final String name;
  final String dateOfBirth;
  final String school;
  final String studentClass;
  final String board; // ICSE or CBSE
  final String preferredLanguage; // Java, Python, etc.
  final String role; // admin or student
  final bool isPremium;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.dateOfBirth,
    required this.school,
    required this.studentClass,
    required this.board,
    required this.preferredLanguage,
    this.role = 'student',
    this.isPremium = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'school': school,
      'studentClass': studentClass,
      'board': board,
      'preferredLanguage': preferredLanguage,
      'role': role,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      school: map['school'] ?? '',
      studentClass: map['studentClass'] ?? '',
      board: map['board'] ?? 'ICSE',
      preferredLanguage: map['preferredLanguage'] ?? 'Java',
      role: map['role'] ?? 'student',
      isPremium: map['isPremium'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? name,
    String? dateOfBirth,
    String? school,
    String? studentClass,
    String? board,
    String? preferredLanguage,
    String? role,
    bool? isPremium,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      school: school ?? this.school,
      studentClass: studentClass ?? this.studentClass,
      board: board ?? this.board,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      role: role ?? this.role,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt,
    );
  }
}
