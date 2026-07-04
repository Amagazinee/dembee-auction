import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../models/auction_model.dart';
import '../../models/bid_history_model.dart';
import '../../models/user_model.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auction_card.dart';
import '../../widgets/dembee_app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/home_stats_row.dart';
import '../../widgets/how_it_works_panel.dart';
import '../../widgets/live_bid_feed.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/phase_legend.dart';
import '../../widgets/second_ticker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auctionService = AuctionService();
  final _authService = AuthService();
  final _creditsService = CreditsService();
  String? _biddingAuctionId;

  Future<void> _quickBid(AuctionModel auction) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _biddingAuctionId = auction.id);

    try {
      final profile = await _authService.getCurrentUserProfile();
      await _auctionService.placeBid(
        auctionId: auction.id,
        bidAmount: auction.bidIncrement,
        bidderName: profile?.name ?? user.email ?? 'Хэрэглэгч',
        bidderUid: user.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${auction.title} — +${auction.bidIncrement}₮ санал илгээлээ',
            ),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _biddingAuctionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _creditsService.watchCurrentUser(),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final bidBalance = user?.bidBalance ?? 0;
        final isAdmin = user?.isAdmin ?? false;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: DembeeAppBar(
            bidBalance: bidBalance,
            user: user,
            showAdminBadge: isAdmin,
            showAddAuction: isAdmin,
            onAddAuction: () => context.push('/admin/add-auction'),
          ),
          body: StreamBuilder<List<AuctionModel>>(
            stream: _auctionService.watchAuctions(),
            builder: (context, auctionSnap) {
              if (auctionSnap.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Дуудлага ачаалж байна...');
              }
              if (auctionSnap.hasError) {
                return ErrorDisplayWidget(
                  message: 'Алдаа: ${auctionSnap.error}',
                );
              }

              final auctions = auctionSnap.data ?? [];
              final active = auctions.where((a) => a.isActive && !a.hasEnded);
              final totalBids =
                  auctions.fold<int>(0, (s, a) => s + a.totalBids);
              final maxPhase = active.isEmpty
                  ? 0
                  : active.map((a) => a.currentPhase).reduce(
                        (a, b) => a > b ? a : b,
                      );

              return StreamBuilder<List<BidHistoryModel>>(
                stream: _authService.currentUser != null
                    ? _auctionService.watchUserBids(
                        _authService.currentUser!.uid,
                      )
                    : Stream.value([]),
                builder: (context, myBidsSnap) {
                  final myBids = myBidsSnap.data ?? [];

                  return StreamBuilder<List<BidHistoryModel>>(
                    stream: _auctionService.watchRecentBids(),
                    builder: (context, recentSnap) {
                      final recentBids = recentSnap.data ?? [];

                      return SecondTicker(
                        builder: (context, now) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 900;
                              final crossCount =
                                  constraints.maxWidth >= 700 ? 2 : 1;

                              final mainContent = CustomScrollView(
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: HomeStatsRow(
                                      activeCount: active.length,
                                      maxPhase: maxPhase,
                                      totalBids: totalBids,
                                      myBids: myBids.length,
                                    ),
                                  ),
                                  const SliverToBoxAdapter(
                                    child: PhaseLegend(),
                                  ),
                                  if (auctions.isEmpty)
                                    const SliverFillRemaining(
                                      child: Center(
                                        child: Text(
                                          'Одоогоор дуудлага байхгүй',
                                          style: TextStyle(
                                            color: AppTheme.mutedForeground,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        0,
                                        12,
                                        16,
                                      ),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossCount,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          mainAxisExtent:
                                              crossCount == 1 ? 520 : 560,
                                        ),
                                        delegate:
                                            SliverChildBuilderDelegate(
                                          (context, index) {
                                            final auction = auctions[index];
                                            return AuctionCard(
                                              auction: auction,
                                              bidBalance: bidBalance,
                                              tick: now,
                                              expanded: crossCount == 1,
                                              isBidding:
                                                  _biddingAuctionId ==
                                                      auction.id,
                                              recentBids: recentBids
                                                  .where(
                                                    (b) =>
                                                        b.auctionId ==
                                                        auction.id,
                                                  )
                                                  .toList(),
                                              currentUserUid:
                                                  user?.uid,
                                              myBidCount: myBids
                                                  .where(
                                                    (b) =>
                                                        b.auctionId ==
                                                        auction.id,
                                                  )
                                                  .length,
                                              onQuickBid: () =>
                                                  _quickBid(auction),
                                            );
                                          },
                                          childCount: auctions.length,
                                        ),
                                      ),
                                    ),
                                  if (!wide)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              height: 280,
                                              child: LiveBidFeed(
                                                auctions: auctions,
                                                recentBids: recentBids,
                                              ),
                                            ),
                                            HowItWorksPanel(),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );

                              if (!wide) return mainContent;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: mainContent),
                                  SizedBox(
                                    width: 280,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        12,
                                        12,
                                        12,
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: LiveBidFeed(
                                              auctions: auctions,
                                              recentBids: recentBids,
                                            ),
                                          ),
                                          HowItWorksPanel(),
                                        ],
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
              );
            },
          ),
        );
      },
    );
  }
}
