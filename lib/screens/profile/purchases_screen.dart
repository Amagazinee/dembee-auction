import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/profile_sub_page_scaffold.dart';

/// Ялсан барааны түүх — удахгүй
class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileSubPageScaffold(
      title: 'Худалдан авалтын түүх',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: 48, color: AppTheme.mutedForeground),
              const SizedBox(height: 16),
              Text(
                'Ялсан барааны түүх',
                style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Дуудлага ялсан барааны түүх удахгүй нэмэгдэнэ',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.mutedForeground,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
