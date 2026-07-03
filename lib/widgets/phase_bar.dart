import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Figma PhaseBar — 8 сегментийн progress
class PhaseBar extends StatelessWidget {
  const PhaseBar({
    super.key,
    required this.currentPhase,
    this.totalPhases = 8,
    this.compact = false,
  });

  final int currentPhase;
  final int totalPhases;
  final bool compact;

  static const List<Color> _segmentColors = [
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
    return Row(
      children: List.generate(totalPhases, (index) {
        final phaseNum = index + 1;
        final isActive = phaseNum == currentPhase;
        final isPast = phaseNum < currentPhase;
        final color = _segmentColors[index % _segmentColors.length];

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalPhases - 1 ? 4 : 0),
            height: compact ? 20 : 28,
            decoration: BoxDecoration(
              color: isActive || isPast
                  ? color.withValues(alpha: isActive ? 1 : 0.35)
                  : AppTheme.muted,
              borderRadius: BorderRadius.circular(2),
              border: isActive
                  ? Border.all(color: color, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$phaseNum',
              style: AppTheme.monoStyle.copyWith(
                fontSize: compact ? 8 : 10,
                color: isActive || isPast ? Colors.white : AppTheme.mutedForeground,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
