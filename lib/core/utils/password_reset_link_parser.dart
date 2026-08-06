/// Firebase Auth нууц үг сэргээх холбоос задлах
class PasswordResetLinkParser {
  PasswordResetLinkParser._();

  static String? extractOobCode(Uri uri) {
    final oobCode = uri.queryParameters['oobCode'];
    if (oobCode == null || oobCode.isEmpty) return null;

    final mode = uri.queryParameters['mode'];
    if (mode != null && mode != 'resetPassword') return null;

    return oobCode;
  }

  static bool isPasswordResetLink(Uri uri) {
    return extractOobCode(uri) != null;
  }
}
