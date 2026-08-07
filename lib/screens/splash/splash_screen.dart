import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dembee_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _extrasOpacity;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _extrasOpacity = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    if (!FirebaseService.isConfigured || !FirebaseService.isInitialized) {
      context.replace('/setup');
      return;
    }

    await _fadeController.forward();
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final isLoggedIn = FirebaseService.isInitialized &&
        FirebaseAuth.instance.currentUser != null;
    context.replace(isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _extrasOpacity,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DembeeLogoLarge(
                  size: 100,
                  heroTag: AppConstants.dembeeLogoHeroTag,
                  wordmarkOpacity: _extrasOpacity.value,
                ),
                Opacity(
                  opacity: _extrasOpacity.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
              ],
            );
          },
        ),
      ),
    );
  }
}
