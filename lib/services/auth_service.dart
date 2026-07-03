import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Хэрэглэгч үүсгэж чадсангүй');
      }

      final profile = UserModel(
        uid: user.uid,
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(profile.toFirestore());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } on FirebaseException catch (e) {
      throw FirestoreException('Firestore алдаа: ${e.message}');
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
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _mapAuthError(String code) {
    return switch (code) {
      'email-already-in-use' => 'Энэ имэйл аль хэдийн бүртгэлтэй байна',
      'invalid-email' => 'Имэйл буруу байна',
      'weak-password' => 'Нууц үг хэтэрхий богино байна (6+ тэмдэгт)',
      'user-not-found' => 'Хэрэглэгч олдсонгүй',
      'wrong-password' => 'Нууц үг буруу байна',
      'invalid-credential' => 'Имэйл эсвэл нууц үг буруу байна',
      'too-many-requests' => 'Хэт олон удаа оролдлоо. Түр хүлээнэ үү',
      _ => 'Нэвтрэх алдаа: $code',
    };
  }
}
