import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/auction_phases.dart';
import '../core/constants/firestore_fields.dart';

class AuctionModel {
  const AuctionModel({
    required this.id,
    required this.title,
    required this.price,
    required this.endsAt,
    required this.status,
    this.image,
    this.retailValue,
    this.description,
    this.category,
    this.bidIncrement = 1,
    this.lastBidder,
    this.lastBidUid,
    this.lastBidAmount = 0,
    this.updatedAt,
    this.winnerUid,
    this.winnerName,
    this.finalPrice,
    this.phase = 1,
    this.phaseStartedAt,
    this.totalBids = 0,
    this.winCountdownEndsAt,
  });

  final String id;
  final String title;
  final int price;
  final DateTime endsAt;
  final String status;
  final String? image;
  final int? retailValue;
  final String? description;
  final String? category;
  final int bidIncrement;
  final String? lastBidder;
  final String? lastBidUid;
  final int lastBidAmount;
  final DateTime? updatedAt;
  final String? winnerUid;
  final String? winnerName;
  final int? finalPrice;
  final int phase;
  final DateTime? phaseStartedAt;
  final int totalBids;
  final DateTime? winCountdownEndsAt;

  bool get isActive => status == AppConstants.statusActive;
  bool get isClosed => status == AppConstants.statusClosed;
  bool get hasEnded => DateTime.now().isAfter(endsAt);

  Duration get remaining => endsAt.difference(DateTime.now());

  int get currentPhase => phase.clamp(1, AuctionPhases.totalPhases);

  AuctionPhaseConfig get phaseConfig => AuctionPhases.forPhase(currentPhase);

  /// Firestore-д байхгүй бол үеийн тохиргооноос тооцно
  DateTime get effectiveWinCountdownEndsAt {
    if (winCountdownEndsAt != null) return winCountdownEndsAt!;
    return DateTime.now().add(phaseConfig.winCountdown);
  }

  String get winCountdownResetLabel {
    final mins = phaseConfig.winCountdownSeconds ~/ 60;
    final secs = phaseConfig.winCountdownSeconds % 60;
    final timeLabel = mins > 0
        ? '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
        : '00:${secs.toString().padLeft(2, '0')}';
    return 'санал бүрт $timeLabel-с дахин эхэлнэ';
  }

  factory AuctionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AuctionModel(
      id: doc.id,
      title: data[FirestoreFields.title] as String? ?? '',
      price: (data[FirestoreFields.price] as num?)?.toInt() ?? 0,
      endsAt: _parseTimestamp(data[FirestoreFields.endsAt]),
      status: data[FirestoreFields.status] as String? ?? AppConstants.statusPending,
      image: data[FirestoreFields.image] as String?,
      retailValue: (data[FirestoreFields.retailValue] as num?)?.toInt(),
      description: data[FirestoreFields.description] as String?,
      category: data[FirestoreFields.category] as String?,
      bidIncrement:
          (data[FirestoreFields.bidIncrement] as num?)?.toInt() ?? 1,
      lastBidder: data[FirestoreFields.lastBidder] as String?,
      lastBidUid: data[FirestoreFields.lastBidUid] as String?,
      lastBidAmount: (data[FirestoreFields.lastBidAmount] as num?)?.toInt() ?? 0,
      updatedAt: _parseTimestampOptional(data[FirestoreFields.updatedAt]),
      winnerUid: data[FirestoreFields.winnerUid] as String?,
      winnerName: data[FirestoreFields.winnerName] as String?,
      finalPrice: (data[FirestoreFields.finalPrice] as num?)?.toInt(),
      phase: (data[FirestoreFields.phase] as num?)?.toInt() ?? 1,
      phaseStartedAt: _parseTimestampOptional(data[FirestoreFields.phaseStartedAt]),
      totalBids: (data[FirestoreFields.totalBids] as num?)?.toInt() ?? 0,
      winCountdownEndsAt:
          _parseTimestampOptional(data[FirestoreFields.winCountdownEndsAt]),
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
