import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Header: лого + саналын үлдэгдэл
class DembeeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DembeeAppBar({
    super.key,
    required this.bidBalance,
    this.onProfile,
    this.onNotifications,
  });

  final int bidBalance;
  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.background,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Logo(),
          const SizedBox(width: 8),
          Text(
            'AUCTION',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 14,
              letterSpacing: 2,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
      actions: [
        InkWell(
          onTap: () => context.go('/topup'),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.destructive.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  '$bidBalance санал',
                  style: AppTheme.monoStyle.copyWith(fontSize: 12),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.add, size: 14, color: AppTheme.primary),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onNotifications,
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: onProfile ?? () => context.go('/profile'),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: 28,
      errorBuilder: (_, __, ___) => Text(
        'ДЭМБЭЭ',
        style: AppTheme.headingStyle.copyWith(
          fontSize: 18,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
