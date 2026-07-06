import 'dart:async';

import 'package:flutter/material.dart';

import '../models/auction_model.dart';
import '../services/auction_service.dart';

/// Идэвхтэй дуудлагын lifecycle-ийг секунд бүр шалгана (CF deploy хийгээгүй үед).
class AuctionLifecycleRunner extends StatefulWidget {
  const AuctionLifecycleRunner({
    super.key,
    required this.auctions,
    required this.service,
    required this.child,
  });

  final List<AuctionModel> auctions;
  final AuctionService service;
  final Widget child;

  @override
  State<AuctionLifecycleRunner> createState() => _AuctionLifecycleRunnerState();
}

class _AuctionLifecycleRunnerState extends State<AuctionLifecycleRunner> {
  Timer? _timer;
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    final now = DateTime.now();
    for (final auction in widget.auctions) {
      if (!auction.isActive || auction.hasEnded) continue;
      if (!auction.lifecycleCheckDue(now)) continue;
      if (_processing.contains(auction.id)) continue;

      _processing.add(auction.id);
      try {
        await widget.service.processAuctionLifecycleIfDue(auction.id);
      } finally {
        _processing.remove(auction.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
