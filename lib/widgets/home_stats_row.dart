import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Figma дээд 4 статистик карт
class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({
    super.key,
    required this.activeCount,
    required this.maxPhase,
    required this.totalBids,
    required this.myBids,
  });

  final int activeCount;
  final int maxPhase;
  final int totalBids;
  final int myBids;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossCount = constraints.maxWidth > 500 ? 4 : 2;
          return GridView.count(
            crossAxisCount: crossCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: crossCount == 4 ? 2.2 : 2.5,
            children: [
              _StatCard(
                value: '$activeCount',
                label: 'Идэвхтэй',
                color: AppTheme.primary,
              ),
              _StatCard(
                value: '$maxPhase',
                label: '${maxPhase > 0 ? maxPhase : 8}-р үе',
                color: const Color(0xFFE03E3E),
              ),
              _StatCard(
                value: _formatCompact(totalBids),
                label: 'Нийт санал',
                color: const Color(0xFF60A5FA),
              ),
              _StatCard(
                value: '$myBids',
                label: 'Миний санал',
                color: const Color(0xFF22C55E),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatCompact(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)},${(n % 1000).toString().padLeft(3, '0')}';
    return '$n';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTheme.monoStyle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 11,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
