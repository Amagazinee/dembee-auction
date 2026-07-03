import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/mock_notifications.dart';
import '../models/user_model.dart';
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
    this.onAddAuction,
  });

  final int bidBalance;
  final UserModel? user;
  final bool showAdminBadge;
  final bool showAddAuction;
  final VoidCallback? onAddAuction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final initial = user?.name.isNotEmpty == true
        ? user!.name[0].toUpperCase()
        : 'C';
    final unread = MockNotifications.unreadCount;

    return AppBar(
      backgroundColor: AppTheme.background,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.border),
      ),
      title: Row(
        children: [
          const DembeeLogo(size: 28, textSize: 16),
          if (showAdminBadge) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'АДМИН',
                style: AppTheme.monoStyle.copyWith(fontSize: 9),
              ),
            ),
          ],
          if (showAddAuction) ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAddAuction,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Шинэ дуудлага нэмэх'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
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
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  '$bidBalance санал',
                  style: AppTheme.monoStyle.copyWith(fontSize: 12),
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
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
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
