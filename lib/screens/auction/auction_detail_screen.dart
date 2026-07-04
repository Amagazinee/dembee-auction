import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../models/auction_model.dart';
import '../../models/bid_history_model.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auction_live_view.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/millisecond_ticker.dart';

/// Figma live дуудлага дэлгэц
class AuctionDetailScreen extends StatefulWidget {
  const AuctionDetailScreen({super.key, required this.auctionId});

  final String auctionId;

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final _auctionService = AuctionService();
  final _authService = AuthService();
  final _creditsService = CreditsService();
  bool _isBidding = false;
  String? _bidError;

  Future<void> _placeBid(AuctionModel auction, int amount) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      _isBidding = true;
      _bidError = null;
    });

    try {
      final profile = await _authService.getCurrentUserProfile();
      await _auctionService.placeBid(
        auctionId: auction.id,
        bidAmount: amount,
        bidderName: profile?.name ?? user.email ?? 'Хэрэглэгч',
        bidderUid: user.uid,
      );
    } on AppException catch (e) {
      setState(() => _bidError = e.message);
    } finally {
      if (mounted) setState(() => _isBidding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _creditsService.watchCurrentUser(),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final bidBalance = user?.bidBalance ?? 0;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            top: false,
            child: StreamBuilder<AuctionModel?>(
              stream: _auctionService.watchAuction(widget.auctionId),
              builder: (context, auctionSnap) {
                if (auctionSnap.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                if (auctionSnap.hasError || auctionSnap.data == null) {
                  return const ErrorDisplayWidget(
                    message: 'Дуудлага олдсонгүй',
                  );
                }

                final auction = auctionSnap.data!;

                return StreamBuilder<List<BidHistoryModel>>(
                  stream: _auctionService.watchBidHistory(widget.auctionId),
                  builder: (context, historySnap) {
                    final bids = historySnap.data ?? [];

                    return MillisecondTicker(
                      builder: (context, now) {
                        return AuctionLiveView(
                          auction: auction,
                          bids: bids,
                          bidBalance: bidBalance,
                          now: now,
                          currentUserUid: user?.uid,
                          isSubmitting: _isBidding,
                          errorMessage: _bidError,
                          onPlaceBid: (amount) => _placeBid(auction, amount),
                          onClose: () => context.pop(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
