import 'package:flutter_test/flutter_test.dart';

import 'package:dembee_app/core/utils/password_reset_link_parser.dart';

void main() {
  test('extracts oobCode from firebase auth action link', () {
    final uri = Uri.parse(
      'https://dembee-auction.firebaseapp.com/__/auth/action'
      '?apiKey=test&mode=resetPassword&oobCode=abc123&lang=mn',
    );

    expect(PasswordResetLinkParser.isPasswordResetLink(uri), isTrue);
    expect(PasswordResetLinkParser.extractOobCode(uri), 'abc123');
  });

  test('extracts oobCode from continue URL', () {
    final uri = Uri.parse(
      'https://dembee-auction.firebaseapp.com/reset-password'
      '?mode=resetPassword&oobCode=xyz789',
    );

    expect(PasswordResetLinkParser.isPasswordResetLink(uri), isTrue);
    expect(PasswordResetLinkParser.extractOobCode(uri), 'xyz789');
  });

  test('ignores non reset links', () {
    final uri = Uri.parse(
      'https://dembee-auction.firebaseapp.com/__/auth/action'
      '?mode=verifyEmail&oobCode=abc123',
    );

    expect(PasswordResetLinkParser.isPasswordResetLink(uri), isFalse);
    expect(PasswordResetLinkParser.extractOobCode(uri), isNull);
  });
}
