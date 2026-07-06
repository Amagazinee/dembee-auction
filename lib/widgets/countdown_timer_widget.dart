import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../theme/app_theme.dart';

/// Countdown timer widget — секунд бүр шинэчлэгдэнэ
class CountdownTimerWidget extends StatefulWidget {
  const CountdownTimerWidget({
    super.key,
    required this.endsAt,
    this.style,
    this.onFinished,
    this.tick,
  });

  final DateTime endsAt;
  final TextStyle? style;
  final VoidCallback? onFinished;
  /// Гаднаас өгвөл дотоод Timer ашиглахгүй (grid картын хувьд)
  final DateTime? tick;

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _finishedCalled = false;

  @override
  void initState() {
    super.initState();
    _syncRemaining(DateTime.now());
    if (widget.tick == null) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) {
      _finishedCalled = false;
    }
    if (widget.tick != null) {
      _timer?.cancel();
      _timer = null;
      _syncRemaining(widget.tick!);
    } else if (oldWidget.tick != null) {
      _startTimer();
    }
  }

  void _syncRemaining(DateTime now) {
    _remaining = widget.endsAt.difference(now);
    if (_remaining.isNegative && !_finishedCalled) {
      _finishedCalled = true;
      widget.onFinished?.call();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _syncRemaining(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        widget.tick != null ? widget.endsAt.difference(widget.tick!) : _remaining;
    final isFinished = remaining.isNegative;
    final isUrgent = isUrgentCountdown(remaining);
    final defaultStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: isFinished
              ? Colors.redAccent
              : isUrgent
                  ? AppTheme.destructive
                  : AppTheme.gold,
          fontWeight: FontWeight.bold,
        );

    return Text(
      isFinished ? 'Дууссан' : formatDuration(remaining),
      style: widget.style ?? defaultStyle,
    );
  }
}
