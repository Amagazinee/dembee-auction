import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
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

  CollectionReference<Map<String, dynamic>> get _history =>
      _firestore.collection(AppConstants.auctionHistoryCollection);

  /// Бүх auction-ийг realtime унших
  Stream<List<AuctionModel>> watchAuctions() {
    return _auctions.snapshots().map((snapshot) {
      final list = snapshot.docs.map(AuctionModel.fromFirestore).toList();
      list.sort((a, b) => b.endsAt.compareTo(a.endsAt));
      return list;
    });
  }

  /// Нэг auction-ийг realtime унших
  Stream<AuctionModel?> watchAuction(String docId) {
    return _auctions.doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AuctionModel.fromFirestore(doc);
    });
  }

  /// Тухайн auction-ийн саналын түүх
  Stream<List<BidHistoryModel>> watchBidHistory(String auctionId) {
    return _history
        .where(FirestoreFields.auctionId, isEqualTo: auctionId)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(BidHistoryModel.fromFirestore).toList(),
        );
  }

  /// Хэрэглэгчийн саналын түүх
  Stream<List<BidHistoryModel>> watchUserBids(String userUid) {
    return _history
        .where(FirestoreFields.userUid, isEqualTo: userUid)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(BidHistoryModel.fromFirestore).toList(),
        );
  }

  /// Хэрэглэгчийн ялсан auction-ууд
  Stream<List<AuctionModel>> watchWonAuctions(String userUid) {
    return _auctions
        .where(FirestoreFields.winnerUid, isEqualTo: userUid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AuctionModel.fromFirestore).toList(),
        );
  }

  /// Цаг дууссан auction-ийг хааж, ялагчийг тодорхойлох
  Future<void> closeAuctionIfExpired(String auctionId) async {
    final docRef = _auctions.doc(auctionId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final status = data[FirestoreFields.status] as String? ?? '';
        if (status != AppConstants.statusActive) return;

        final endsAt = (data[FirestoreFields.endsAt] as Timestamp?)?.toDate();
        if (endsAt == null || DateTime.now().isBefore(endsAt)) return;

        final price = (data[FirestoreFields.price] as num?)?.toInt() ?? 0;
        final lastBidUid = data[FirestoreFields.lastBidUid] as String?;
        final lastBidder = data[FirestoreFields.lastBidder] as String?;

        final updateData = <String, dynamic>{
          FirestoreFields.status: AppConstants.statusClosed,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
          FirestoreFields.finalPrice: price,
        };

        if (lastBidUid != null && lastBidder != null) {
          updateData[FirestoreFields.winnerUid] = lastBidUid;
          updateData[FirestoreFields.winnerName] = lastBidder;
        }

        transaction.update(docRef, updateData);
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Дуудлага хаахад алдаа: ${e.message}');
    }
  }

  /// Санал өгөх (+1 – +5) + түүх бичих
  Future<void> placeBid({
    required String auctionId,
    required int bidAmount,
    required String bidderName,
    required String bidderUid,
  }) async {
    if (!AppConstants.bidIncrements.contains(bidAmount)) {
      throw const FirestoreException('Зөвхөн +1 – +5 санал өгөх боломжтой');
    }

    final docRef = _auctions.doc(auctionId);
    final historyRef = _history.doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw const FirestoreException('Дуудлага олдсонгүй');
        }

        final data = snapshot.data()!;
        final status = data[FirestoreFields.status] as String? ?? '';
        final endsAt = (data[FirestoreFields.endsAt] as Timestamp?)?.toDate();
        final currentPrice = (data[FirestoreFields.price] as num?)?.toInt() ?? 0;

        if (status != AppConstants.statusActive) {
          throw const FirestoreException('Дуудлага идэвхгүй байна');
        }

        if (endsAt != null && DateTime.now().isAfter(endsAt)) {
          throw const FirestoreException('Дуудлага дууссан байна');
        }

        final newPrice = currentPrice + bidAmount;

        transaction.update(docRef, {
          FirestoreFields.price: newPrice,
          FirestoreFields.lastBidder: bidderName,
          FirestoreFields.lastBidUid: bidderUid,
          FirestoreFields.lastBidAmount: bidAmount,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        });

        transaction.set(historyRef, {
          FirestoreFields.auctionId: auctionId,
          FirestoreFields.userUid: bidderUid,
          FirestoreFields.userName: bidderName,
          FirestoreFields.amount: bidAmount,
          'newPrice': newPrice,
          FirestoreFields.createdAt: FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Санал өгөхөд алдаа: ${e.message}');
    }
  }
}
