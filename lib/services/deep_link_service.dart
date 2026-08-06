import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/password_reset_link_parser.dart';

/// Имэйлийн нууц үг сэргээх холбоосоор апп нээх
class DeepLinkService {
  DeepLinkService({required GoRouter router}) : _router = router;

  final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  Future<void> initialize() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _handleUri(Uri uri) {
    if (!PasswordResetLinkParser.isPasswordResetLink(uri)) return;

    final oobCode = PasswordResetLinkParser.extractOobCode(uri);
    if (oobCode == null) return;

    _router.go(
      '/reset-password?oobCode=${Uri.encodeComponent(oobCode)}',
    );
  }
}
