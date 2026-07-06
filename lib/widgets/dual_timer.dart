import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../theme/app_theme.dart';

/// Figma DualTimer — ялагч тодорхойлох тооллого
class DualTimer extends StatefulWidget {
  const DualTimer({
    super.key,
    required this.winCountdownEndsAt,
    this.resetLabel = 'санал бүрт 30:00-с дахин эхэлнэ',
    this.compact = false,
    this.tick,
    this.gradient = false,
  });

  final DateTime winCountdownEndsAt;
  final String resetLabel;
  final bool compact;
  final DateTime? tick;
  final bool gradient;

  @override
  State<DualTimer> createState() => _DualTimerState();
}

class _DualTimerState extends State<DualTimer> {
  Duration _remaining = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.winCountdownEndsAt.difference(DateTime.now());
    if (widget.tick == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _remaining = widget.winCountdownEndsAt.difference(DateTime.now());
        });
      });
    }
  }

  @override
  void didUpdateWidget(DualTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.winCountdownEndsAt != widget.winCountdownEndsAt) {
      _remaining = widget.winCountdownEndsAt.difference(
        widget.tick ?? DateTime.now(),
      );
    }
    if (widget.tick != null) {
      _timer?.cancel();
      _timer = null;
    } else if (oldWidget.tick != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _remaining = widget.winCountdownEndsAt.difference(DateTime.now());
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.tick != null
        ? widget.winCountdownEndsAt.difference(widget.tick!)
        : _remaining;
    final isExpired = remaining.isNegative;
    final isUrgent = isUrgentCountdown(remaining);
    final compact = widget.compact;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 6 : 12,
        horizontal: compact ? 8 : 16,
      ),
      decoration: BoxDecoration(
        gradient: widget.gradient
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7C2D12), Color(0xFF1A1A20)],
              )
            : null,
        color: widget.gradient ? null : const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isUrgent && !isExpired
              ? AppTheme.destructive
              : widget.gradient
                  ? const Color(0xFFF97316).withValues(alpha: 0.5)
                  : const Color(0xFF2563EB).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isExpired ? 'ЯЛАГЧ ТОДОРХОЙЛОГДЛОО' : 'ЯЛАГЧ ТОДОРХОЙЛОХ',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: compact ? 8 : 10,
              letterSpacing: 1.2,
              color: isUrgent && !isExpired
                  ? AppTheme.destructive
                  : widget.gradient
                      ? const Color(0xFFFDBA74)
                      : const Color(0xFF60A5FA),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            isExpired ? '00:00' : formatDuration(remaining),
            style: AppTheme.monoStyle.copyWith(
              fontSize: compact ? 16 : 28,
              color: isExpired
                  ? AppTheme.primary
                  : isUrgent
                      ? AppTheme.destructive
                      : widget.gradient
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF93C5FD),
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
