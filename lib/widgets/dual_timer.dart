import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../theme/app_theme.dart';

/// Figma DualTimer — ялагч тодрох тооллого
class DualTimer extends StatefulWidget {
  const DualTimer({
    super.key,
    required this.winCountdownEndsAt,
    this.resetLabel = 'санал бүрт 30:00-с дахин эхэлнэ',
    this.compact = false,
  });

  final DateTime winCountdownEndsAt;
  final String resetLabel;
  final bool compact;

  @override
  State<DualTimer> createState() => _DualTimerState();
}

class _DualTimerState extends State<DualTimer> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.winCountdownEndsAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.winCountdownEndsAt.difference(DateTime.now());
      });
    });
  }

  @override
  void didUpdateWidget(DualTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.winCountdownEndsAt != widget.winCountdownEndsAt) {
      _remaining = widget.winCountdownEndsAt.difference(DateTime.now());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining.isNegative;
    final compact = widget.compact;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 8 : 12,
        horizontal: compact ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            isExpired ? 'ЯЛАГЧ ТОДОРЛОО' : 'ЯЛАГЧ ТОДОРЛОХ',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: compact ? 8 : 10,
              letterSpacing: 1.2,
              color: const Color(0xFF60A5FA),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            isExpired ? '00:00' : formatDuration(_remaining),
            style: AppTheme.monoStyle.copyWith(
              fontSize: compact ? 18 : 28,
              color: const Color(0xFF93C5FD),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              widget.resetLabel,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 9,
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
