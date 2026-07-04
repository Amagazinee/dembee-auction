import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../firebase_options.dart';

/// Firebase-ийг нэг удаа аюулгүй эхлүүлнэ
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!isConfigured) {
      throw const ConfigException(
        'Firebase тохируулагдаагүй байна. flutterfire configure ажиллуулна уу.',
      );
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
    } on UnsupportedError catch (e) {
      throw ConfigException(
        'Firebase энэ платформ дээр тохируулагдаагүй байна: $e',
      );
    } catch (e) {
      throw ConfigException(
        'Firebase эхлүүлэхэд алдаа гарлаа. '
        'flutterfire configure ажиллуулсан эсэхээ шалгана уу.\n$e',
      );
    }
  }

  /// Одоогийн платформ (Android / Web / iOS) дээр Firebase тохируулагдсан эсэх
  static bool get isConfigured {
    try {
      return !_hasPlaceholder(DefaultFirebaseOptions.currentPlatform);
    } catch (_) {
      return false;
    }
  }

  static bool _hasPlaceholder(FirebaseOptions options) {
    const markers = ['YOUR_API_KEY', 'YOUR_APP_ID', 'YOUR_PROJECT_ID'];
    final values = [options.apiKey, options.appId, options.projectId];
    return values.any(
      (value) => markers.any((marker) => value.contains(marker)),
    );
  }

  static String get platformSetupHint {
    if (kIsWeb) {
      return 'Та Chrome (Web) дээр ажиллуулж байна.\n'
          'flutterfire configure ажиллуулахдаа **Web** платформыг сонгоно уу.';
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'flutterfire configure ажиллуулахдаа **iOS** платформыг сонгоно уу.'
        : 'flutterfire configure ажиллуулахдаа **Android** платформыг сонгоно уу.';
  }
}
