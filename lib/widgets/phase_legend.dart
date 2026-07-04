import 'package:flutter/material.dart';

import '../core/constants/auction_phases.dart';
import '../theme/app_theme.dart';

/// Figma "ҮЕ ДЭС ДАРАА · ЯЛАГЧ ТОДРОХ ХУГАЦАА" ribbon
class PhaseLegend extends StatelessWidget {
  const PhaseLegend({super.key, this.embedded = false});

  final bool embedded;

  static const List<Color> _colors = [
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: embedded
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: embedded ? Colors.transparent : AppTheme.card,
        borderRadius: BorderRadius.circular(4),
        border: embedded ? null : Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ҮЕ ДЭС ДАРАА · ЯЛАГЧ ТОДРОХ ХУГАЦАА',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 10,
              letterSpacing: 1,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(AuctionPhases.totalPhases, (i) {
              final config = AuctionPhases.configs[i];
              final secs = config.winCountdownSeconds;
              final label = _formatWinTime(secs);
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: i < AuctionPhases.totalPhases - 1 ? 3 : 0,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: _colors[i],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: AppTheme.monoStyle.copyWith(fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatWinTime(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s > 0
          ? '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
          : '${m.toString().padLeft(2, '0')}:00';
    }
    return '$seconds';
  }
}
