import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../models/bid_history_model.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auction_card.dart';
import '../../widgets/bid_history_table.dart';
import '../../widgets/dembee_app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/how_it_works_panel.dart';
import '../../widgets/live_bid_feed.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/second_ticker.dart';

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
          appBar: DembeeAppBar(
            bidBalance: bidBalance,
            user: user,
            showAdminBadge: user?.isAdmin ?? false,
          ),
          body: StreamBuilder<AuctionModel?>(
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
                  final myCount = bids
                      .where((b) => b.userUid == user?.uid)
                      .length;
                  final canBid = auction.isActive &&
                      !auction.hasEnded &&
                      bidBalance > 0;

                  return SecondTicker(
                    builder: (context, now) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 900;

                          final main = SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuctionCard(
                                  auction: auction,
                                  bidBalance: bidBalance,
                                  tick: now,
                                  expanded: true,
                                  isBidding: _isBidding,
                                  recentBids: bids,
                                  currentUserUid: user?.uid,
                                  myBidCount: myCount,
                                  onQuickBid: canBid
                                      ? () => _placeBid(auction, 1)
                                      : null,
                                ),
                                if (canBid) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Үлдсэн санал: $bidBalance (-1 бүр)',
                                    textAlign: TextAlign.center,
                                    style: AppTheme.monoStyle.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children:
                                        AppConstants.bidIncrements.map((a) {
                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _isBidding
                                                ? null
                                                : () =>
                                                    _placeBid(auction, a),
                                            child: Text('+$a₮'),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                if (_bidError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      _bidError!,
                                      style: const TextStyle(
                                        color: AppTheme.destructive,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                BidHistoryTable(
                                  bids: bids,
                                  currentUserUid: user?.uid,
                                  maxRows: 10,
                                ),
                                if (!wide) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 260,
                                    child: StreamBuilder<List<AuctionModel>>(
                                      stream:
                                          _auctionService.watchAuctions(),
                                      builder: (context, allSnap) {
                                        return LiveBidFeed(
                                          auctions: allSnap.data ?? [],
                                          recentBids: bids,
                                        );
                                      },
                                    ),
                                  ),
                                  HowItWorksPanel(),
                                ],
                              ],
                            ),
                          );

                          if (!wide) return main;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: main),
                              SizedBox(
                                width: 280,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    16,
                                    16,
                                    16,
                                  ),
                                  child: StreamBuilder<List<AuctionModel>>(
                                    stream: _auctionService.watchAuctions(),
                                    builder: (context, allSnap) {
                                      return Column(
                                        children: [
                                          Expanded(
                                            child: LiveBidFeed(
                                              auctions: allSnap.data ?? [],
                                              recentBids: bids,
                                            ),
                                          ),
                                          HowItWorksPanel(),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
