import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';
import '../core/utils/formatters.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.read = false,
    this.createdAt,
    this.auctionId,
  });

  final String id;
  final String kind; // winner | new_auction | topup | phase
  final String title;
  final String body;
  final String timeAgo;
  final bool read;
  final DateTime? createdAt;
  final String? auctionId;

  AppNotification copyWith({
    String? id,
    String? kind,
    String? title,
    String? body,
    String? timeAgo,
    bool? read,
    DateTime? createdAt,
    String? auctionId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      timeAgo: timeAgo ?? this.timeAgo,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      auctionId: auctionId ?? this.auctionId,
    );
  }

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAt = _parseTimestamp(data[FirestoreFields.createdAt]);
    return AppNotification(
      id: doc.id,
      kind: data[FirestoreFields.kind] as String? ?? 'general',
      title: data[FirestoreFields.title] as String? ?? '',
      body: data[FirestoreFields.body] as String? ?? '',
      timeAgo: createdAt != null ? formatTimeAgo(createdAt) : 'одоо',
      read: data[FirestoreFields.read] as bool? ?? false,
      createdAt: createdAt,
      auctionId: data[FirestoreFields.auctionId] as String?,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
