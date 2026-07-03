import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'dembee_logo.dart';

/// Figma UserMenuDrawer
class UserMenuDrawer extends StatelessWidget {
  const UserMenuDrawer({
    super.key,
    required this.user,
    required this.onClose,
  });

  final UserModel user;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final d = user.createdAt;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Material(
      color: AppTheme.popover,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const DembeeLogo(size: 28),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                    child: Text(
                      initial,
                      style: AppTheme.headingStyle.copyWith(
                        fontSize: 20,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTheme.bodyStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.email,
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 11,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                        Text(
                          user.phone,
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 11,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ҮЛДСЭН САНАЛ',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.bolt, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${user.bidBalance} санал',
                        style: AppTheme.monoStyle.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (user.isAdmin) ...[
              _SectionHeader('удирдлага'),
              _MenuItem(
                icon: Icons.shield_outlined,
                label: 'Админ самбар',
                badge: 'ADMIN',
                onTap: () {
                  onClose();
                  context.go('/admin');
                },
              ),
            ],
            _SectionHeader('данс'),
            _MenuItem(
              icon: Icons.bolt_outlined,
              label: 'Санал багц авах',
              onTap: () {
                onClose();
                context.go('/topup');
              },
            ),
            _MenuItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Худалдан авалтын түүх',
              badgeCount: 3,
              onTap: onClose,
            ),
            _MenuItem(
              icon: Icons.swap_horiz,
              label: 'Гүйлгээний түүх',
              onTap: onClose,
            ),
            _SectionHeader('дэмжлэг'),
            _MenuItem(
              icon: Icons.chat_bubble_outline,
              label: 'Санал хүсэлт',
              onTap: () {
                onClose();
                context.go('/feedback');
              },
            ),
            _MenuItem(
              icon: Icons.help_outline,
              label: 'Түгээмэл асуултууд',
              onTap: () {
                onClose();
                context.go('/faq');
              },
            ),
            _MenuItem(
              icon: Icons.headset_mic_outlined,
              label: 'Тусламж',
              onTap: () {
                onClose();
                context.go('/help');
              },
            ),
            _SectionHeader('нөхцөл'),
            _MenuItem(
              icon: Icons.shield_outlined,
              label: 'Нууцлалын бодлого',
              onTap: onClose,
            ),
            _MenuItem(
              icon: Icons.description_outlined,
              label: 'Үйлчилгээний нөхцөл',
              onTap: onClose,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Бүртгэлтэй: $dateStr',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 11,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ),
            _MenuItem(
              icon: Icons.delete_outline,
              label: 'Бүртгэл устгах',
              color: AppTheme.destructive,
              onTap: onClose,
            ),
            _MenuItem(
              icon: Icons.logout,
              label: 'Гарах',
              onTap: () async {
                onClose();
                await AuthService().logout();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text,
        style: AppTheme.bodyStyle.copyWith(
          fontSize: 10,
          letterSpacing: 1.5,
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeCount,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final int? badgeCount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppTheme.foreground;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 13,
                  color: textColor,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: AppTheme.monoStyle.copyWith(fontSize: 9),
                ),
              ),
            if (badgeCount != null)
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: 9,
                    color: AppTheme.primaryForeground,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: AppTheme.mutedForeground),
          ],
        ),
      ),
    );
  }
}

void showUserMenuPanel(BuildContext context, UserModel user) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Цэс',
    barrierColor: Colors.black54,
    pageBuilder: (context, _, __) {
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(280, 340),
          height: double.infinity,
          child: UserMenuDrawer(
            user: user,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim, _, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}
