import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/auction_phases.dart';
import '../core/constants/firestore_fields.dart';
import '../core/errors/app_exception.dart';
import '../models/auction_model.dart';
import '../models/bid_history_model.dart';

class AuctionService {
  AuctionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _auctions =>
      _firestore.collection(AppConstants.auctionsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _history =>
      _firestore.collection(AppConstants.auctionHistoryCollection);

  Stream<List<AuctionModel>> watchAuctions() {
    return _auctions.snapshots().map((snapshot) {
      final list = snapshot.docs.map(AuctionModel.fromFirestore).toList();
      list.sort((a, b) => b.endsAt.compareTo(a.endsAt));
      return list;
    });
  }

  /// Хэрэглэгчийн ялсан дуудлага худалдаанууд
  Stream<List<AuctionModel>> watchWonAuctions() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _auctions
        .where(FirestoreFields.winnerUid, isEqualTo: uid)
        .orderBy(FirestoreFields.endsAt, descending: true)
        .snapshots()
        .map((s) => s.docs.map(AuctionModel.fromFirestore).toList());
  }

  Stream<AuctionModel?> watchAuction(String docId) {
    return _auctions.doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AuctionModel.fromFirestore(doc);
    });
  }

  Stream<List<BidHistoryModel>> watchBidHistory(String auctionId) {
    return _history
        .where(FirestoreFields.auctionId, isEqualTo: auctionId)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .limit(20)
        .snapshots()
        .map(
          (s) => s.docs.map(BidHistoryModel.fromFirestore).toList(),
        );
  }

  Stream<List<BidHistoryModel>> watchRecentBids({int limit = 10}) {
    return _history
        .orderBy(FirestoreFields.createdAt, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map(BidHistoryModel.fromFirestore).toList(),
        );
  }

  Stream<List<BidHistoryModel>> watchUserBids(String userUid) {
    return _history
        .where(FirestoreFields.userUid, isEqualTo: userUid)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map(BidHistoryModel.fromFirestore).toList(),
        );
  }

  /// Санал өгөх: 1 кредит хасах + үнэ ₮1–₮5 нэмэх
  Future<void> placeBid({
    required String auctionId,
    required int bidAmount,
    required String bidderName,
    required String bidderUid,
  }) async {
    if (!AppConstants.bidIncrements.contains(bidAmount)) {
      throw const FirestoreException('Зөвхөн +1 – +5 санал өгөх боломжтой');
    }

    final auctionRef = _auctions.doc(auctionId);
    final userRef = _users.doc(bidderUid);
    final historyRef = _history.doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        final auctionSnap = await transaction.get(auctionRef);

        if (!userSnap.exists) {
          throw const FirestoreException('Хэрэглэгчийн профайл олдсонгүй');
        }
        if (!auctionSnap.exists) {
          throw const FirestoreException('Дуудлага олдсонгүй');
        }

        final balance =
            (userSnap.data()![FirestoreFields.bidBalance] as num?)?.toInt() ?? 0;
        if (balance < 1) {
          throw const FirestoreException(
            'Санал дууссан байна. Санал багц аваарай.',
          );
        }

        final data = auctionSnap.data()!;
        final status = data[FirestoreFields.status] as String? ?? '';
        final endsAt = (data[FirestoreFields.endsAt] as Timestamp?)?.toDate();

        if (status != AppConstants.statusActive) {
          throw const FirestoreException('Дуудлага идэвхгүй байна');
        }
        if (endsAt != null && DateTime.now().isAfter(endsAt)) {
          throw const FirestoreException('Дуудлага дууссан байна');
        }

        final currentPrice = (data[FirestoreFields.price] as num?)?.toInt() ?? 0;
        final currentPhase =
            (data[FirestoreFields.phase] as num?)?.toInt() ?? 1;
        final totalBids =
            (data[FirestoreFields.totalBids] as num?)?.toInt() ?? 0;
        final phaseConfig = AuctionPhases.forPhase(currentPhase);
        final winReset = DateTime.now().add(phaseConfig.winCountdown);

        final newPrice = currentPrice + bidAmount;

        transaction.update(userRef, {
          FirestoreFields.bidBalance: balance - 1,
        });

        transaction.update(auctionRef, {
          FirestoreFields.price: newPrice,
          FirestoreFields.lastBidder: bidderName,
          FirestoreFields.lastBidUid: bidderUid,
          FirestoreFields.lastBidAmount: bidAmount,
          FirestoreFields.totalBids: totalBids + 1,
          FirestoreFields.phase: currentPhase,
          FirestoreFields.winCountdownEndsAt: Timestamp.fromDate(winReset),
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        });

        transaction.set(historyRef, {
          FirestoreFields.auctionId: auctionId,
          FirestoreFields.userUid: bidderUid,
          FirestoreFields.userName: bidderName,
          FirestoreFields.amount: bidAmount,
          FirestoreFields.priceAfter: newPrice,
          FirestoreFields.createdAt: FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Санал өгөхөд алдаа: ${e.message}');
    }
  }
}
