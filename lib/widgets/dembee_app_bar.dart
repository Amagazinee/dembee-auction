import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/app_navigation.dart';
import '../models/user_model.dart';
import '../providers/notification_notifier.dart';
import '../theme/app_theme.dart';
import 'dembee_logo.dart';
import 'notif_drawer.dart';
import 'user_menu_drawer.dart';

/// Figma Header — лого, АДМИН badge, санал, мэдэгдэл, avatar
class DembeeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DembeeAppBar({
    super.key,
    required this.bidBalance,
    this.user,
    this.showAdminBadge = false,
    this.showAddAuction = false,
    this.showHomeButton = false,
    this.onAddAuction,
    this.logoHeroTag,
  });

  final int bidBalance;
  final UserModel? user;
  final bool showAdminBadge;
  final bool showAddAuction;
  final bool showHomeButton;
  final VoidCallback? onAddAuction;
  final Object? logoHeroTag;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final initial = user?.name.isNotEmpty == true
        ? user!.name[0].toUpperCase()
        : 'C';

    return AppBar(
      backgroundColor: AppTheme.background,
      automaticallyImplyLeading: false,
      leading: showHomeButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Буцах',
              onPressed: () => popOrGoHome(context),
            )
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.border),
      ),
      title: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final reservedActions = (showHomeButton ? 48.0 : 0) + 130 + 96;
          final reservedLeading = showHomeButton ? 56.0 : 16.0;
          final titleWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : (screenWidth - reservedLeading - reservedActions)
                  .clamp(72.0, screenWidth * 0.42);
          final compact = showHomeButton || titleWidth < 220;
          final iconOnly = showHomeButton && titleWidth < 150;

          return SizedBox(
            width: titleWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: showHomeButton ? null : () => context.go('/home'),
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DembeeLogo(
                      size: compact ? 24 : 28,
                      textSize: compact ? 12 : 16,
                      compact: compact,
                      showText: !iconOnly,
                      heroTag: logoHeroTag,
                    ),
                    if (showAdminBadge) ...[
                      SizedBox(width: compact ? 4 : 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 5 : 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primary),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'АДМИН',
                          style: AppTheme.monoStyle.copyWith(
                            fontSize: compact ? 7 : 9,
                          ),
                        ),
                      ),
                    ],
                    if (showAddAuction) ...[
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: onAddAuction,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Шинэ дуудлага нэмэх'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        InkWell(
          onTap: () {
            final location = GoRouterState.of(context).uri.path;
            if (location != '/topup') {
              context.push('/topup');
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.symmetric(
              horizontal: showHomeButton ? 8 : 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  showHomeButton ? '$bidBalance' : '$bidBalance санал',
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: showHomeButton ? 11 : 12,
                  ),
                ),
                const SizedBox(width: 2),
                const Text('+', style: TextStyle(color: AppTheme.primary)),
              ],
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => showNotifPanel(context),
            ),
            ListenableBuilder(
              listenable: NotificationNotifier.instance,
              builder: (context, _) {
                final unread = NotificationNotifier.instance.unreadCount;
                if (unread <= 0) return const SizedBox.shrink();

                return Positioned(
                  right: 8,
                  top: 8,
                  child: IgnorePointer(
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppTheme.destructive,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unread',
                        style: AppTheme.monoStyle.copyWith(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: user != null
                ? () => showUserMenuPanel(context, user!)
                : () => context.go('/profile'),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.35),
              child: Text(
                initial,
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
