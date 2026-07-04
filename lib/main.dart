import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_constants.dart';
import 'core/errors/app_exception.dart';
import 'providers/auth_state_notifier.dart';
import 'routes/app_router.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Эмулятор/сүлжээ алдаатай үед Google Fonts татахгүй — системийн фонт ашиглана
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.fraunces(),
      GoogleFonts.manrope(),
      GoogleFonts.jetBrainsMono(),
    ]).timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Font ачаалах алдаа (fallback фонт): $e');
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  final authNotifier = AuthStateNotifier();

  try {
    await FirebaseService.initialize();
    authNotifier.attach();
  } on ConfigException catch (e) {
    debugPrint('Firebase config алдаа: ${e.message}');
  }

  final appRouter = AppRouter(authNotifier: authNotifier);

  runApp(DembeeApp(router: appRouter.router));
}

class DembeeApp extends StatelessWidget {
  const DembeeApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
