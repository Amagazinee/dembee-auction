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

  /// Firebase тохируулагдсан эсэхийг шалгах
  static bool get isConfigured {
    const placeholder = 'YOUR_PROJECT_ID';
    return !DefaultFirebaseOptions.android.projectId.contains(placeholder);
  }
}
