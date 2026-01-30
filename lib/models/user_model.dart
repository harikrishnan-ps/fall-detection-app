import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { person, caregiver }

class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'] ?? '',
    );
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final List<String> linkedUsers; // UIDs of linked caregivers/persons
  final List<EmergencyContact> emergencyContacts;
  final String phoneNumber;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.linkedUsers = const [],
    this.emergencyContacts = const [],
    this.phoneNumber = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role == UserRole.person ? 'person' : 'caregiver',
      'linkedUsers': linkedUsers,
      'emergencyContacts': emergencyContacts.map((c) => c.toMap()).toList(),
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'caregiver' ? UserRole.caregiver : UserRole.person,
      linkedUsers: List<String>.from(map['linkedUsers'] ?? []),
      emergencyContacts: (map['emergencyContacts'] as List?)
              ?.map((c) => EmergencyContact.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      phoneNumber: map['phoneNumber'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    List<String>? linkedUsers,
    List<EmergencyContact>? emergencyContacts,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      linkedUsers: linkedUsers ?? this.linkedUsers,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
