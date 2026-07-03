import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';

class BidHistoryModel {
  const BidHistoryModel({
    required this.id,
    required this.auctionId,
    required this.userUid,
    required this.userName,
    required this.amount,
    required this.priceAfter,
    required this.createdAt,
    this.auctionTitle,
  });

  final String id;
  final String auctionId;
  final String userUid;
  final String userName;
  final int amount;
  final int priceAfter;
  final DateTime createdAt;
  final String? auctionTitle;

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
      priceAfter: (data[FirestoreFields.priceAfter] as num?)?.toInt() ??
          (data[FirestoreFields.price] as num?)?.toInt() ??
          0,
      createdAt: _parseTimestamp(data[FirestoreFields.createdAt]),
      auctionTitle: data[FirestoreFields.title] as String?,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '${diff.inSeconds}с';
    if (diff.inHours < 1) return '${diff.inMinutes}м';
    return '${diff.inHours}ц';
  }
}
