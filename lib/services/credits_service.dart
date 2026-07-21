import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/bid_packages.dart';
import '../core/constants/firestore_fields.dart';
import '../core/errors/app_exception.dart';
import '../models/purchase_model.dart';
import '../models/user_model.dart';

class CreditsService {
  CreditsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _purchases =>
      _firestore.collection(AppConstants.purchasesCollection);

  /// Хэрэглэгчийн саналын үлдэгдэл realtime
  Stream<UserModel?> watchCurrentUser() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);

    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Худалдан авалтын түүх
  Stream<List<PurchaseModel>> watchUserPurchases() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _purchases
        .where(FirestoreFields.userUid, isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = s.docs.map(PurchaseModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Админ — бүх худалдан авалт (буцаагдсан орно)
  Stream<List<PurchaseModel>> watchAllPurchases() {
    return _purchases.snapshots().map((s) {
      final list = s.docs.map(PurchaseModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Админ — амжилттай санал багц худалдан авалт
  Stream<List<PurchaseModel>> watchAllCompletedPurchases() {
    return watchAllPurchases().map(
      (list) => list.where((p) => p.isCompleted).toList(),
    );
  }

  /// Админ — хэрэглэгчийн нэр/имэйл lookup
  Stream<Map<String, UserModel>> watchAllUsers() {
    return _users.snapshots().map((s) {
      return {
        for (final doc in s.docs) doc.id: UserModel.fromFirestore(doc),
      };
    });
  }

  /// Админ — бүх хэрэглэгчийн жагсаалт (шинэ бүртгэл эхэнд)
  Stream<List<UserModel>> watchAllUsersList() {
    return _users.snapshots().map((s) {
      final list = s.docs.map(UserModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Нэг худалдан авалтыг realtime хянах (QPay)
  Stream<PurchaseModel?> watchPurchase(String purchaseId) {
    return _purchases.doc(purchaseId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PurchaseModel.fromFirestore(doc);
    });
  }

  /// Туршилт — зөвхөн dev (Cloud Functions байхгүй үед)
  Future<void> purchasePackageTest(BidPackage package) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Нэвтэрнэ үү');

    final userRef = _users.doc(uid);
    final purchaseRef = _purchases.doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
          throw const FirestoreException('Хэрэглэгчийн профайл олдсонгүй');
        }
        if (userSnap.data()?[FirestoreFields.banned] == true) {
          throw const FirestoreException(
            'Таны бүртгэл түр хориглогдсон. Дэмжлэгтэй холбогдоно уу.',
          );
        }

        transaction.set(purchaseRef, {
          FirestoreFields.userUid: uid,
          FirestoreFields.packageId: package.id,
          FirestoreFields.bidCount: package.amount,
          FirestoreFields.amount: package.price,
          FirestoreFields.paymentMethod: 'test',
          FirestoreFields.purchaseStatus: 'completed',
          FirestoreFields.createdAt: FieldValue.serverTimestamp(),
        });

        transaction.update(userRef, {
          FirestoreFields.bidBalance: FieldValue.increment(package.amount),
        });
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Багц худалдан авахад алдаа: ${e.message}');
    }
  }

  /// Админ — хэрэглэгчийн саналын үлдэгдэл тохируулах
  Future<void> adminAdjustBidBalance({
    required String userUid,
    required int newBalance,
  }) async {
    if (newBalance < 0) {
      throw const FirestoreException('Саналын үлдэгдэл сөрөг байж болохгүй');
    }

    try {
      await _users.doc(userUid).update({
        FirestoreFields.bidBalance: newBalance,
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Санал засахад алдаа: ${e.message}');
    }
  }

  /// Админ — хэрэглэгчийг хориглох / сэргээх
  Future<void> adminSetUserBanned({
    required String userUid,
    required bool banned,
    String? reason,
  }) async {
    try {
      await _users.doc(userUid).update({
        FirestoreFields.banned: banned,
        FirestoreFields.bannedAt:
            banned ? FieldValue.serverTimestamp() : FieldValue.delete(),
        FirestoreFields.bannedReason:
            banned && reason != null && reason.trim().isNotEmpty
                ? reason.trim()
                : FieldValue.delete(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Хориглоход алдаа: ${e.message}');
    }
  }

  /// Админ — худалдан авалтыг буцаах (үлдсэн саналаас хасна)
  Future<void> adminRefundPurchase(String purchaseId) async {
    final purchaseRef = _purchases.doc(purchaseId);

    try {
      await _firestore.runTransaction((transaction) async {
        final purchaseSnap = await transaction.get(purchaseRef);
        if (!purchaseSnap.exists) {
          throw const FirestoreException('Гүйлгээ олдсонгүй');
        }

        final purchaseData = purchaseSnap.data()!;
        final status =
            purchaseData[FirestoreFields.purchaseStatus] as String? ?? '';
        if (status != 'completed') {
          throw const FirestoreException('Зөвхөн амжилттай гүйлгээг буцаана');
        }

        final userUid = purchaseData[FirestoreFields.userUid] as String? ?? '';
        final bidCount =
            (purchaseData[FirestoreFields.bidCount] as num?)?.toInt() ?? 0;
        final userRef = _users.doc(userUid);
        final userSnap = await transaction.get(userRef);

        if (userSnap.exists) {
          final balance =
              (userSnap.data()![FirestoreFields.bidBalance] as num?)?.toInt() ??
                  0;
          final deduct = bidCount > balance ? balance : bidCount;
          if (deduct > 0) {
            transaction.update(userRef, {
              FirestoreFields.bidBalance: balance - deduct,
            });
          }
        }

        transaction.update(purchaseRef, {
          FirestoreFields.purchaseStatus: 'refunded',
          FirestoreFields.refundedAt: FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Буцаалт хийхэд алдаа: ${e.message}');
    }
  }
}
