import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/mock_notifications.dart';
import '../models/notification_model.dart';
import '../theme/app_theme.dart';

/// Figma Мэдэгдэл — баруун талын panel
class NotifDrawer extends StatelessWidget {
  const NotifDrawer({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final items = MockNotifications.items;
    final unread = items.where((n) => !n.read).length;

    return Material(
      color: AppTheme.popover,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Мэдэгдэл',
                          style: AppTheme.headingStyle.copyWith(fontSize: 18),
                        ),
                        Text(
                          '$unread уншаагүй',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 12,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Бүгдийг уншсанд тооцох',
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 11,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.border, indent: 56),
                itemBuilder: (context, index) {
                  return _NotifTile(notification: items[index]);
                },
              ),
            ),
            const Divider(height: 1, color: AppTheme.border),
            TextButton(
              onPressed: () {},
              child: Text(
                'Бүгдийг устгах',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notification});

  final AppNotification notification;

  IconData get _icon {
    switch (notification.kind) {
      case 'winner':
        return Icons.emoji_events_outlined;
      case 'new_auction':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (notification.kind) {
      case 'winner':
        return AppTheme.primary;
      case 'new_auction':
        return const Color(0xFF60A5FA);
      default:
        return AppTheme.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 22, color: _iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.timeAgo,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 10,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.read)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

/// Overlay-ээр мэдэгдэл нээх
void showNotifPanel(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Мэдэгдэл',
    barrierColor: Colors.black54,
    pageBuilder: (context, _, __) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(280, 380),
          height: double.infinity,
          child: NotifDrawer(onClose: () => Navigator.of(context).pop()),
        ),
      );
    },
    transitionBuilder: (context, anim, _, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}
