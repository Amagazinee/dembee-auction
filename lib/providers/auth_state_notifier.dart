import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_service.dart';

/// GoRouter-д auth өөрчлөлтийг мэдэгдэх
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    if (!FirebaseService.isInitialized) return;

    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  StreamSubscription<User?>? _subscription;

  User? get currentUser {
    if (!FirebaseService.isInitialized) return null;
    return FirebaseAuth.instance.currentUser;
  }

  bool get isLoggedIn => currentUser != null;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
