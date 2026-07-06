import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/firestore_fields.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/formatters.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(AppConstants.notificationsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Stream<List<AppNotification>> watchUserNotifications(String userUid) {
    return _notifications
        .where(FirestoreFields.userUid, isEqualTo: userUid)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs.map(AppNotification.fromFirestore).toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({
        FirestoreFields.read: true,
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Мэдэгдэл шинэчлэхэд алдаа: ${e.message}');
    }
  }

  Future<void> markAllAsRead(String userUid) async {
    try {
      final snap = await _notifications
          .where(FirestoreFields.userUid, isEqualTo: userUid)
          .get();

      final unread =
          snap.docs.where((d) => d.data()[FirestoreFields.read] != true);
      if (unread.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unread) {
        batch.update(doc.reference, {FirestoreFields.read: true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreException('Мэдэгдэл шинэчлэхэд алдаа: ${e.message}');
    }
  }

  Future<void> deleteAllForUser(String userUid) async {
    try {
      final snap = await _notifications
          .where(FirestoreFields.userUid, isEqualTo: userUid)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreException('Мэдэгдэл устгахад алдаа: ${e.message}');
    }
  }

  /// Шинэ дуудлага — бүх хэрэглэгчид мэдэгдэл илгээнэ
  Future<void> notifyAllUsersNewAuction({
    required String auctionId,
    required String title,
    required DateTime startsAt,
  }) async {
    final usersSnap = await _users.get();
    if (usersSnap.docs.isEmpty) return;

    final now = DateTime.now();
    final scheduled = startsAt.isAfter(now.add(const Duration(minutes: 1)));
    final body = scheduled
        ? '$title — ${formatScheduledStart(startsAt)} эхлэнэ. Одоо оролцох бэлэн болно!'
        : '$title дуудлага худалдаанд орлоо. Одоо оролцох!';

    var batch = _firestore.batch();
    var ops = 0;

    for (final userDoc in usersSnap.docs) {
      final ref = _notifications.doc();
      batch.set(ref, {
        FirestoreFields.userUid: userDoc.id,
        FirestoreFields.kind: 'new_auction',
        FirestoreFields.title: '🆕 Шинэ дуудлага нэмэгдлээ',
        FirestoreFields.body: body,
        FirestoreFields.auctionId: auctionId,
        FirestoreFields.read: false,
        FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      });
      ops++;

      if (ops >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        ops = 0;
      }
    }

    if (ops > 0) {
      await batch.commit();
    }
  }
}
