import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/firestore_fields.dart';
import '../core/errors/app_exception.dart';
import '../models/auction_model.dart';

class AuctionService {
  AuctionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _auctions =>
      _firestore.collection(AppConstants.auctionsCollection);

  /// Бүх auction-ийг realtime унших
  Stream<List<AuctionModel>> watchAuctions() {
    return _auctions.snapshots().map(
          (snapshot) {
            final list = snapshot.docs
                .map(AuctionModel.fromFirestore)
                .toList();
            list.sort((a, b) => b.endsAt.compareTo(a.endsAt));
            return list;
          },
        );
  }

  /// Нэг auction-ийг realtime унших
  Stream<AuctionModel?> watchAuction(String docId) {
    return _auctions.doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AuctionModel.fromFirestore(doc);
    });
  }

  /// Санал өгөх (+1 – +5)
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

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw const FirestoreException('Дуудлага олдсонгүй');
        }

        final data = snapshot.data()!;
        final status = data[FirestoreFields.status] as String? ?? '';
        final endsAt = (data[FirestoreFields.endsAt] as Timestamp?)?.toDate();

        if (status != AppConstants.statusActive) {
          throw const FirestoreException('Дуудлага идэвхгүй байна');
        }

        if (endsAt != null && DateTime.now().isAfter(endsAt)) {
          throw const FirestoreException('Дуудлага дууссан байна');
        }

        transaction.update(docRef, {
          FirestoreFields.price: FieldValue.increment(bidAmount),
          FirestoreFields.lastBidder: bidderName,
          FirestoreFields.lastBidUid: bidderUid,
          FirestoreFields.lastBidAmount: bidAmount,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Санал өгөхөд алдаа: ${e.message}');
    }
  }
}
