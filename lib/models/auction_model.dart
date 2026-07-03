import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/firestore_fields.dart';

class AuctionModel {
  const AuctionModel({
    required this.id,
    required this.title,
    required this.price,
    required this.endsAt,
    required this.status,
    this.lastBidder,
    this.lastBidUid,
    this.lastBidAmount = 0,
    this.updatedAt,
    this.winnerUid,
    this.winnerName,
    this.finalPrice,
  });

  final String id;
  final String title;
  final int price;
  final DateTime endsAt;
  final String status;
  final String? lastBidder;
  final String? lastBidUid;
  final int lastBidAmount;
  final DateTime? updatedAt;
  final String? winnerUid;
  final String? winnerName;
  final int? finalPrice;

  bool get isActive => status == AppConstants.statusActive;
  bool get isClosed => status == AppConstants.statusClosed;
  bool get hasEnded => DateTime.now().isAfter(endsAt);

  Duration get remaining => endsAt.difference(DateTime.now());

  factory AuctionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AuctionModel(
      id: doc.id,
      title: data[FirestoreFields.title] as String? ?? '',
      price: (data[FirestoreFields.price] as num?)?.toInt() ?? 0,
      endsAt: _parseTimestamp(data[FirestoreFields.endsAt]),
      status: data[FirestoreFields.status] as String? ?? AppConstants.statusPending,
      lastBidder: data[FirestoreFields.lastBidder] as String?,
      lastBidUid: data[FirestoreFields.lastBidUid] as String?,
      lastBidAmount: (data[FirestoreFields.lastBidAmount] as num?)?.toInt() ?? 0,
      updatedAt: _parseTimestampOptional(data[FirestoreFields.updatedAt]),
      winnerUid: data[FirestoreFields.winnerUid] as String?,
      winnerName: data[FirestoreFields.winnerName] as String?,
      finalPrice: (data[FirestoreFields.finalPrice] as num?)?.toInt(),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _parseTimestampOptional(dynamic value) {
    if (value == null) return null;
    return _parseTimestamp(value);
  }
}
