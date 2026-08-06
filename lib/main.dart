import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_constants.dart';
import 'core/errors/app_exception.dart';
import 'providers/auth_state_notifier.dart';
import 'routes/app_router.dart';
import 'services/deep_link_service.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Фонтыг эхлээд татаж авах — emulator дээр гацахаас сэргийлнэ
  await GoogleFonts.pendingFonts([
    GoogleFonts.fraunces(),
    GoogleFonts.manrope(),
    GoogleFonts.jetBrainsMono(),
  ]);

  final authNotifier = AuthStateNotifier();

  try {
    await FirebaseService.initialize();
    authNotifier.attach();
  } on ConfigException catch (e) {
    debugPrint('Firebase config алдаа: ${e.message}');
  }

  final appRouter = AppRouter(authNotifier: authNotifier);
  final deepLinkService = DeepLinkService(router: appRouter.router);
  await deepLinkService.initialize();

  runApp(DembeeApp(
    router: appRouter.router,
    deepLinkService: deepLinkService,
  ));
}

class DembeeApp extends StatefulWidget {
  const DembeeApp({
    super.key,
    required this.router,
    required this.deepLinkService,
  });

  final GoRouter router;
  final DeepLinkService deepLinkService;

  @override
  State<DembeeApp> createState() => _DembeeAppState();
}

class _DembeeAppState extends State<DembeeApp> {
  @override
  void dispose() {
    widget.deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: widget.router,
    );
  }
}
