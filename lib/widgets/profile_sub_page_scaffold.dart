import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'go_home_button.dart';

import 'go_home_button.dart';

/// Figma дэд хуудас — буцах + гарчиг + нүүр
class ProfileSubPageScaffold extends StatelessWidget {
  const ProfileSubPageScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SubPageTopBar(title: title),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Figma тусламжийн карт
class SupportContactCard extends StatelessWidget {
  const SupportContactCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.monoStyle.copyWith(fontSize: 13),
                ),
                Text(
                  subtitle,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.foreground,
              side: const BorderSide(color: AppTheme.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
