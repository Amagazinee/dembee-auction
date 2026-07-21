import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/bid_packages.dart';
import '../core/constants/firestore_fields.dart';

class PurchaseModel {
  const PurchaseModel({
    required this.id,
    required this.userUid,
    required this.packageId,
    required this.bidCount,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.refundedAt,
  });

  final String id;
  final String userUid;
  final String packageId;
  final int bidCount;
  final int amount;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final DateTime? refundedAt;

  bool get isCompleted => status == 'completed';
  bool get isRefunded => status == 'refunded';

  factory PurchaseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PurchaseModel(
      id: doc.id,
      userUid: data[FirestoreFields.userUid] as String? ?? '',
      packageId: data[FirestoreFields.packageId] as String? ?? '',
      bidCount: (data[FirestoreFields.bidCount] as num?)?.toInt() ?? 0,
      amount: (data[FirestoreFields.amount] as num?)?.toInt() ?? 0,
      paymentMethod: data[FirestoreFields.paymentMethod] as String? ?? 'test',
      status: data[FirestoreFields.purchaseStatus] as String? ?? 'completed',
      createdAt: _parseTimestamp(data[FirestoreFields.createdAt]),
      refundedAt: _parseOptionalTimestamp(data[FirestoreFields.refundedAt]),
    );
  }

  String get packageLabel {
    for (final pkg in BidPackages.all) {
      if (pkg.id == packageId) return '${pkg.amount} санал';
    }
    return '$bidCount санал';
  }

  String get paymentLabel => switch (paymentMethod) {
        'qpay' => 'QPay',
        'golomt' => 'Golomt Bank',
        'khan' => 'Khan Bank',
        'tdb' => 'TDB',
        'test' => 'Туршилт',
        _ => paymentMethod,
      };

  String get statusLabel => switch (status) {
        'completed' => 'Амжилттай',
        'pending' => 'Хүлээгдэж буй',
        'failed' => 'Амжилтгүй',
        'refunded' => 'Буцаагдсан',
        _ => status,
      };

  bool get isPending => status == 'pending';

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _parseOptionalTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
