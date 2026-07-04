import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dembee_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (!FirebaseService.isConfigured || !FirebaseService.isInitialized) {
      context.go('/setup');
      return;
    }

    final isLoggedIn = FirebaseService.isInitialized &&
        FirebaseAuth.instance.currentUser != null;
    context.go(isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DembeeLogoLarge(size: 100),
            const SizedBox(height: 16),
            Text(
              'Онлайн дуудлага худалдаа',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppTheme.gold),
          ],
        ),
      ),
    );
  }
}
