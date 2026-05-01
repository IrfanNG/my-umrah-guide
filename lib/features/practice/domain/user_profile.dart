import 'package:cloud_firestore/cloud_firestore.dart';

enum AbilityLevel {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case AbilityLevel.low:
        return 'Low mobility';
      case AbilityLevel.medium:
        return 'Moderate';
      case AbilityLevel.high:
        return 'Active';
    }
  }

  static AbilityLevel fromValue(String? value) {
    return AbilityLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => AbilityLevel.medium,
    );
  }
}

enum UserRole {
  user,
  admin;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.user,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    required this.age,
    required this.abilityLevel,
    required this.healthConditions,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final UserRole role;
  final int age;
  final AbilityLevel abilityLevel;
  final String healthConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isComplete => age > 0;
  String get ageGroup {
    if (age < 30) return '18-29';
    if (age < 45) return '30-44';
    if (age < 60) return '45-59';
    return '60+';
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = false}) {
    return {
      'uid': uid,
      'email': email,
      'role': role.name,
      'age': age,
      'ageGroup': ageGroup,
      'abilityLevel': abilityLevel.name,
      'healthConditions': healthConditions,
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserProfile(
      uid: data['uid'] as String? ?? doc.id,
      email: data['email'] as String? ?? '',
      role: UserRole.fromValue(data['role'] as String?),
      age: (data['age'] as num?)?.toInt() ?? 0,
      abilityLevel: AbilityLevel.fromValue(data['abilityLevel'] as String?),
      healthConditions: data['healthConditions'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
