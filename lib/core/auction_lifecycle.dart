import 'package:cloud_firestore/cloud_firestore.dart';

import 'constants/app_constants.dart';
import 'constants/auction_phases.dart';
import 'constants/firestore_fields.dart';

/// Дуудлагын lifecycle үр дүн
class AuctionLifecycleResult {
  const AuctionLifecycleResult({this.updates, this.action});

  final Map<String, dynamic>? updates;
  final String? action;
}

/// Нэг дуудлагын lifecycle шалгах (Cloud Functions-тай ижил дүрэм).
///
/// - winCountdownEndsAt дууссан + санал байвал → ялагч тодорхойлно
/// - winCountdownEndsAt дууссан + санал байхгүй → дараагийн үе
/// - 1–7-р үеийн хугацаа түрүүлж дуусвал → дараагийн үе (ялагчгүй)
/// - 8-р үеийн хугацаа дуусвал → сүүлийн санал өгсөн хүн ялагч
AuctionLifecycleResult evaluateAuctionLifecycle(
  Map<String, dynamic> data,
  DateTime now,
) {
  final status = data[FirestoreFields.status] as String? ?? '';
  if (status != AppConstants.statusActive) {
    return const AuctionLifecycleResult();
  }

  final phase = ((data[FirestoreFields.phase] as num?)?.toInt() ?? 1)
      .clamp(1, AuctionPhases.totalPhases);
  final config = AuctionPhases.forPhase(phase);
  final winEndsAt = _parseTimestamp(data[FirestoreFields.winCountdownEndsAt]);
  final phaseStartedAt = _parseTimestamp(data[FirestoreFields.phaseStartedAt]);
  final lastBidUid = data[FirestoreFields.lastBidUid] as String?;
  final lastBidder = data[FirestoreFields.lastBidder] as String?;
  final price = (data[FirestoreFields.price] as num?)?.toInt() ?? 0;

  if (winEndsAt != null && !now.isBefore(winEndsAt)) {
    if (lastBidUid != null && lastBidUid.isNotEmpty) {
      return AuctionLifecycleResult(
        action: 'winner',
        updates: {
          FirestoreFields.status: AppConstants.statusClosed,
          FirestoreFields.winnerUid: lastBidUid,
          FirestoreFields.winnerName: lastBidder ?? '',
          FirestoreFields.finalPrice: price,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        },
      );
    }
    return _buildPhaseAdvance(phase, now);
  }

  if (phaseStartedAt != null) {
    final phaseEndsAt = phaseStartedAt.add(config.duration);
    if (!now.isBefore(phaseEndsAt)) {
      if (phase < AuctionPhases.totalPhases) {
        return _buildPhaseAdvance(phase, now);
      }
      if (lastBidUid != null && lastBidUid.isNotEmpty) {
        return AuctionLifecycleResult(
          action: 'winner',
          updates: {
            FirestoreFields.status: AppConstants.statusClosed,
            FirestoreFields.winnerUid: lastBidUid,
            FirestoreFields.winnerName: lastBidder ?? '',
            FirestoreFields.finalPrice: price,
            FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
          },
        );
      }
      return AuctionLifecycleResult(
        action: 'winner',
        updates: {
          FirestoreFields.status: AppConstants.statusClosed,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        },
      );
    }
  }

  return const AuctionLifecycleResult();
}

AuctionLifecycleResult _buildPhaseAdvance(int currentPhase, DateTime now) {
  final nextPhase =
      (currentPhase + 1).clamp(1, AuctionPhases.totalPhases);
  final nextConfig = AuctionPhases.forPhase(nextPhase);

  return AuctionLifecycleResult(
    action: 'phase_advance',
    updates: {
      FirestoreFields.phase: nextPhase,
      FirestoreFields.phaseStartedAt: Timestamp.fromDate(now),
      FirestoreFields.winCountdownEndsAt: Timestamp.fromDate(
        now.add(nextConfig.winCountdown),
      ),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    },
  );
}

DateTime? _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

/// Lifecycle шалгах шаардлагатай эсэх (идэвхтэй + аль нэг тооллого дууссан)
bool auctionLifecycleCheckDue(Map<String, dynamic> data, DateTime now) {
  final status = data[FirestoreFields.status] as String? ?? '';
  if (status != AppConstants.statusActive) return false;

  final phase = ((data[FirestoreFields.phase] as num?)?.toInt() ?? 1)
      .clamp(1, AuctionPhases.totalPhases);
  final config = AuctionPhases.forPhase(phase);
  final winEndsAt = _parseTimestamp(data[FirestoreFields.winCountdownEndsAt]);
  final phaseStartedAt = _parseTimestamp(data[FirestoreFields.phaseStartedAt]);

  if (winEndsAt != null && !now.isBefore(winEndsAt)) return true;

  if (phaseStartedAt != null) {
    final phaseEndsAt = phaseStartedAt.add(config.duration);
    if (!now.isBefore(phaseEndsAt)) return true;
  }

  return false;
}
