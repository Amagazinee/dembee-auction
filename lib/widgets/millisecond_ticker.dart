import 'dart:async';

import 'package:flutter/material.dart';

/// 50ms тутамд rebuild — долио/миллисекунд тооллого
class MillisecondTicker extends StatefulWidget {
  const MillisecondTicker({super.key, required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<MillisecondTicker> createState() => _MillisecondTickerState();
}

class _MillisecondTickerState extends State<MillisecondTicker> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
