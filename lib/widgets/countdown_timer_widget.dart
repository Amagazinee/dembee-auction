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
  });

  final DateTime endsAt;
  final TextStyle? style;
  final VoidCallback? onFinished;

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late Duration _remaining;
  Timer? _timer;
  bool _finishedCalled = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endsAt.difference(DateTime.now());
    _startTimer();
  }

  @override
  void didUpdateWidget(CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) {
      _remaining = widget.endsAt.difference(DateTime.now());
      _finishedCalled = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = widget.endsAt.difference(DateTime.now());
      if (!mounted) return;

      setState(() => _remaining = remaining);

      if (remaining.isNegative && !_finishedCalled) {
        _finishedCalled = true;
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = _remaining.isNegative;
    final defaultStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: isFinished ? Colors.redAccent : AppTheme.gold,
          fontWeight: FontWeight.bold,
        );

    return Text(
      isFinished ? 'Дууссан' : formatDuration(_remaining),
      style: widget.style ?? defaultStyle,
    );
  }
}
