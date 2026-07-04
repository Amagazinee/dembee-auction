import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/firestore_fields.dart';
import '../core/errors/app_exception.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    User? createdUser;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      createdUser = credential.user;
      if (createdUser == null) {
        throw const AuthException('Хэрэглэгч үүсгэж чадсангүй');
      }

      final profile = UserModel(
        uid: createdUser.uid,
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(createdUser.uid)
          .set(profile.toFirestore());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } on FirebaseException catch (e) {
      await _rollbackAuthUser(createdUser);
      throw FirestoreException(_mapFirestoreError(e));
    } catch (e) {
      await _rollbackAuthUser(createdUser);
      if (e is AppException) rethrow;
      throw AuthException('Бүртгэл үүсгэхэд алдаа гарлаа: $e');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final profile = await getCurrentUserProfile();
      if (profile == null) {
        await _auth.signOut();
        throw const AuthException(
          'Бүртгэлийн мэдээлэл олдсонгүй. Өмнөх бүртгэл бүрэн дуусаагүй байж магадгүй. '
          'Firebase Console → Authentication дээрээс энэ имэйлийг устгаад дахин бүртгүүлнэ үү.',
        );
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } on FirebaseException catch (e) {
      await _auth.signOut();
      throw FirestoreException(_mapFirestoreError(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> _rollbackAuthUser(User? user) async {
    if (user == null) return;

    try {
      await user.delete();
    } catch (_) {
      // Auth хэрэглэгчийг устгаж чадаагүй — дараагийн оролдлогод
      // email-already-in-use гарч магадгүй.
    }
  }

  String _mapAuthError(String code) {
    return switch (code) {
      'email-already-in-use' =>
        'Энэ имэйл аль хэдийн бүртгэлтэй байна. Нэвтрэх эсвэл өөр имэйл ашиглана уу',
      'invalid-email' => 'Имэйл буруу байна',
      'weak-password' => 'Нууц үг хэтэрхий богино байна (6+ тэмдэгт)',
      'user-not-found' => 'Хэрэглэгч олдсонгүй',
      'wrong-password' => 'Нууц үг буруу байна',
      'invalid-credential' => 'Имэйл эсвэл нууц үг буруу байна',
      'too-many-requests' => 'Хэт олон удаа оролдлоо. Түр хүлээнэ үү',
      'operation-not-allowed' =>
        'Имэйл/нууц үгээр нэвтрэх идэвхгүй байна. Firebase Console → Authentication → Email/Password идэвхжүүлнэ үү',
      'network-request-failed' => 'Сүлжээний алдаа. Интернэт холболтоо шалгана уу',
      _ when code.contains('api-key-not-valid') =>
        'Firebase API түлхүүр буруу байна. Терминалд flutterfire configure ажиллуулаад '
        '${kIsWeb ? "Web" : "энэ"} платформыг сонгож, аппыг дахин ажиллуулна уу',
      _ => 'Нэвтрэх алдаа: $code',
    };
  }

  String _mapFirestoreError(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' =>
        'Firestore зөвшөөрөлгүй. Firebase Console → Firestore → Rules хэсэгт firebase/firestore.rules файлыг тавьсан эсэхээ шалгана уу',
      'unavailable' => 'Firestore түр хүрэхгүй байна. Дахин оролдоно уу',
      _ => 'Firestore алдаа: ${e.message ?? e.code}',
    };
  }
}
