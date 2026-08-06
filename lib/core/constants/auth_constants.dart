/// Firebase Auth / нууц үг сэргээх тохиргоо
class AuthConstants {
  AuthConstants._();

  static const String firebaseProjectId = 'dembee-auction';
  static const String androidPackageName = 'com.dembee.auction';
  static const String iosBundleId = 'com.dembee.auction';

  static String get authDomain => '$firebaseProjectId.firebaseapp.com';

  /// Firebase Auth continue URL — имэйлийн холбоосоор апп руу буцна
  static String get passwordResetContinueUrl =>
      'https://$authDomain/reset-password';
}
