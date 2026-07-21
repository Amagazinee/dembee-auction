import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_navigation.dart';
import '../theme/app_theme.dart';

/// Нүүр хуудас руу буцах товч
class GoHomeIconButton extends StatelessWidget {
  const GoHomeIconButton({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.home_outlined,
        size: compact ? 20 : 24,
      ),
      tooltip: 'Нүүр',
      color: AppTheme.foreground,
      onPressed: () => context.go('/home'),
    );
  }
}

/// Дэд хуудасны дээд мөр — буцах + гарчиг + нүүр
class SubPageTopBar extends StatelessWidget {
  const SubPageTopBar({
    super.key,
    required this.title,
    this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Буцах',
            onPressed: onBack ?? () => popOrGoHome(context),
          ),
          Expanded(
            child: Text(
              title,
              style: AppTheme.headingStyle.copyWith(fontSize: 20),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const GoHomeIconButton(compact: true),
        ],
      ),
    );
  }
}
