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

  /// Админ — бүх амжилттай санал багц худалдан авалт
  Stream<List<PurchaseModel>> watchAllCompletedPurchases() {
    return _purchases.snapshots().map((s) {
      final list = s.docs
          .map(PurchaseModel.fromFirestore)
          .where((p) => p.status == 'completed')
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
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

  /// Туршилт — төлбөргүй багц худалдан авах (QPay холбогдоогүй)
  Future<void> purchasePackageTest(BidPackage package) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Нэвтэрнэ үү');

    final userRef = _users.doc(uid);
    final purchaseRef = _purchases.doc();

    try {
      await _firestore.runTransaction((transaction) async {
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
}
