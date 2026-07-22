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

  /// Auth байгаа ч Firestore профайл байхгүй үед шинээр үүсгэнэ
  Future<UserModel> _ensureUserProfile({
    required String email,
    String name = '',
    String phone = '',
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Нэвтрээгүй байна');
    }

    final ref = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid);

    final existing = await ref.get();
    if (existing.exists) {
      return UserModel.fromFirestore(existing);
    }

    final profile = UserModel(
      uid: user.uid,
      name: name.isNotEmpty
          ? name
          : (user.displayName?.isNotEmpty == true
              ? user.displayName!
              : email.split('@').first),
      phone: phone,
      email: email,
      createdAt: DateTime.now(),
    );

    await ref.set(profile.toFirestore());
    return profile;
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

      final isSeedAdmin = AppConstants.isAdminSeedEmail(email);
      final profile = UserModel(
        uid: createdUser.uid,
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
        role: isSeedAdmin ? 'admin' : 'user',
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

      // Firestore профайл байхгүй бол үүсгэхийг оролдоно — амжилтгүй ч нэвтрэлтийг цуцлахгүй
      try {
        var profile = await getCurrentUserProfile();
        if (profile == null) {
          await _ensureUserProfile(email: email.trim());
        }
      } on FirebaseException catch (e) {
        debugPrint('Профайл шалгах/үүсгэх алдаа: ${e.code} ${e.message}');
      }

      await _promoteSeedAdminIfNeeded(profile);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Нэвтрээгүй байна');
    }

    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    if (trimmedName.isEmpty) {
      throw const AuthException('Нэр оруулна уу');
    }
    if (trimmedPhone.isEmpty) {
      throw const AuthException('Утасны дугаар оруулна уу');
    }

    try {
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
        FirestoreFields.name: trimmedName,
        FirestoreFields.phone: trimmedPhone,
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(_mapFirestoreError(e));
    }
  }

  Future<void> deleteAccount({required String password}) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Нэвтрээгүй байна');
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const AuthException('Имэйл олдсонгүй');
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .delete();

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } on FirebaseException catch (e) {
      throw FirestoreException(_mapFirestoreError(e));
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw const AuthException('И-мэйл хаягаа оруулна уу');
    }

    try {
      await _auth.sendPasswordResetEmail(email: trimmed);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    }
  }

  Future<void> _promoteSeedAdminIfNeeded(UserModel profile) async {
    final user = currentUser;
    if (user == null || profile.isAdmin) return;

    final email = user.email;
    if (email == null || !AppConstants.isAdminSeedEmail(email)) return;

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({FirestoreFields.role: 'admin'});
    } on FirebaseException catch (e) {
      debugPrint('Admin promote skipped: ${e.code}');
    }
  }

  Future<void> _rollbackAuthUser(User? user) async {
    if (user == null) return;

    try {
      await user.delete();
    } catch (_) {
      await _auth.signOut();
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
      'requires-recent-login' =>
        'Аюулгүй байдлын үүднээс дахин нэвтэрч, үйлдлээ давтана уу',
      'too-many-requests' => 'Хэт олон удаа оролдлоо. Түр хүлээнэ үү',
      'operation-not-allowed' =>
        'Имэйл/нууц үгээр нэвтрэх идэвхгүй. Firebase Console → Authentication → Email/Password идэвхжүүлнэ үү',
      'network-request-failed' => 'Сүлжээний алдаа. Интернэт холболтоо шалгана уу',
      _ when code.contains('api-key-not-valid') =>
        'Firebase API түлхүүр буруу. flutterfire configure ажиллуулаад '
        '${kIsWeb ? "Web" : "Android"} сонгож, аппыг дахин ажиллуулна уу',
      _ => 'Нэвтрэх алдаа: $code',
    };
  }

  String _mapFirestoreError(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' =>
        'Firestore зөвшөөрөлгүй. firebase/firestore.rules файлыг Console дээр Publish хийнэ үү',
      'unavailable' => 'Firestore түр хүрэхгүй байна. Дахин оролдоно уу',
      _ => 'Firestore алдаа: ${e.message ?? e.code}',
    };
  }
}
