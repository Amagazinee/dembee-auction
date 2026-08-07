import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_state_notifier.dart';
import '../services/firebase_service.dart';
import '../screens/admin/admin_add_auction_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/auction/auction_detail_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/topup/topup_screen.dart';
import '../screens/profile/delete_account_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/faq_screen.dart';
import '../screens/profile/feedback_screen.dart';
import '../screens/profile/help_screen.dart';
import '../screens/profile/legal_screens.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/purchases_screen.dart';
import '../screens/profile/transactions_screen.dart';
import '../screens/setup/setup_screen.dart';
import '../screens/splash/splash_screen.dart';

class AppRouter {
  AppRouter({required AuthStateNotifier authNotifier})
      : router = GoRouter(
          initialLocation: '/',
          refreshListenable: authNotifier,
          redirect: (context, state) {
            if (!FirebaseService.isInitialized) {
              final location = state.matchedLocation;
              if (location != '/' && location != '/setup') {
                return '/setup';
              }
              return null;
            }

            final isLoggedIn = authNotifier.isLoggedIn;
            final location = state.matchedLocation;

            final publicRoutes = [
              '/',
              '/login',
              '/register',
              '/reset-password',
              '/setup',
            ];
            final isPublic = publicRoutes.contains(location);

            if (!isLoggedIn && !isPublic) return '/login';
            if (isLoggedIn && (location == '/login' || location == '/register')) {
              return '/home';
            }

            return null;
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SplashScreen(),
            ),
            GoRoute(
              path: '/setup',
              builder: (context, state) => const SetupScreen(),
            ),
            GoRoute(
              path: '/login',
              pageBuilder: (context, state) => _heroFadePage(
                state: state,
                child: const LoginScreen(),
              ),
            ),
            GoRoute(
              path: '/register',
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/reset-password',
              builder: (context, state) {
                final oobCode = state.uri.queryParameters['oobCode'];
                return ResetPasswordScreen(oobCode: oobCode);
              },
            ),
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => _heroFadePage(
                state: state,
                child: const HomeScreen(),
              ),
            ),
            GoRoute(
              path: '/topup',
              builder: (context, state) => const TopUpScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/purchases',
              builder: (context, state) => const PurchasesScreen(),
            ),
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
            ),
            GoRoute(
              path: '/edit-profile',
              builder: (context, state) => const EditProfileScreen(),
            ),
            GoRoute(
              path: '/delete-account',
              builder: (context, state) => const DeleteAccountScreen(),
            ),
            GoRoute(
              path: '/help',
              builder: (context, state) => const HelpScreen(),
            ),
            GoRoute(
              path: '/faq',
              builder: (context, state) => const FaqScreen(),
            ),
            GoRoute(
              path: '/feedback',
              builder: (context, state) => const FeedbackScreen(),
            ),
            GoRoute(
              path: '/privacy',
              builder: (context, state) => const PrivacyScreen(),
            ),
            GoRoute(
              path: '/terms',
              builder: (context, state) => const TermsScreen(),
            ),
            GoRoute(
              path: '/admin/add-auction',
              builder: (context, state) => const AdminAddAuctionScreen(),
            ),
            GoRoute(
              path: '/admin',
              builder: (context, state) {
                final tab =
                    int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
                return AdminDashboardScreen(initialTab: tab);
              },
            ),
            GoRoute(
              path: '/auction/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return AuctionDetailScreen(auctionId: id);
              },
            ),
          ],
        );

  final GoRouter router;
}

Page<void> _heroFadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
  );
}
