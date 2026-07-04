import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_service.dart';

/// GoRouter-д auth өөрчлөлтийг мэдэгдэх
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    instance = this;
    attach();
  }

  static AuthStateNotifier? instance;

  StreamSubscription<User?>? _subscription;

  /// Firebase амжилттай эхлсний дараа дуудах (Setup дэлгэцээс)
  void attach() {
    if (_subscription != null) return;
    if (!FirebaseService.isInitialized) return;

    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  User? get currentUser {
    if (!FirebaseService.isInitialized) return null;
    return FirebaseAuth.instance.currentUser;
  }

  bool get isLoggedIn => currentUser != null;

  @override
  void dispose() {
    if (instance == this) instance = null;
    _subscription?.cancel();
    super.dispose();
  }
}
