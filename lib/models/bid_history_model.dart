import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';

class BidHistoryModel {
  const BidHistoryModel({
    required this.id,
    required this.auctionId,
    required this.userUid,
    required this.userName,
    required this.amount,
    required this.createdAt,
    this.newPrice,
  });

  final String id;
  final String auctionId;
  final String userUid;
  final String userName;
  final int amount;
  final int? newPrice;
  final DateTime createdAt;

  factory BidHistoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return BidHistoryModel(
      id: doc.id,
      auctionId: data[FirestoreFields.auctionId] as String? ?? '',
      userUid: data[FirestoreFields.userUid] as String? ?? '',
      userName: data[FirestoreFields.userName] as String? ?? '',
      amount: (data[FirestoreFields.amount] as num?)?.toInt() ?? 0,
      newPrice: (data['newPrice'] as num?)?.toInt(),
      createdAt: _parseTimestamp(data[FirestoreFields.createdAt]),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
