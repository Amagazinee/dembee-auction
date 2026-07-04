import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
    this.role = 'user',
    this.bidBalance = 0,
  });

  final String uid;
  final String name;
  final String phone;
  final String email;
  final DateTime createdAt;
  final String role;
  final int bidBalance;

  bool get isAdmin => role == 'admin';
  bool get hasCredits => bidBalance > 0;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      uid: doc.id,
      name: data[FirestoreFields.name] as String? ?? '',
      phone: data[FirestoreFields.phone] as String? ?? '',
      email: data[FirestoreFields.email] as String? ?? '',
      createdAt: _parseTimestamp(data[FirestoreFields.createdAt]),
      role: data[FirestoreFields.role] as String? ?? 'user',
      bidBalance: (data[FirestoreFields.bidBalance] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      FirestoreFields.name: name,
      FirestoreFields.phone: phone,
      FirestoreFields.email: email,
      FirestoreFields.createdAt: Timestamp.fromDate(createdAt),
      FirestoreFields.role: role,
      FirestoreFields.bidBalance: bidBalance,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email,
      createdAt: createdAt,
      role: role,
      bidBalance: bidBalance,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
