import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../models/auction_model.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auction_card.dart';
import '../../widgets/dembee_app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
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
        bidAmount: 1,
        bidderName: profile?.name ?? user.email ?? 'Хэрэглэгч',
        bidderUid: user.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${auction.title} — +1₮ санал илгээлээ'),
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
    return StreamBuilder(
      stream: _creditsService.watchCurrentUser(),
      builder: (context, userSnapshot) {
        final bidBalance = userSnapshot.data?.bidBalance ?? 0;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: DembeeAppBar(bidBalance: bidBalance),
          body: StreamBuilder<List<AuctionModel>>(
            stream: _auctionService.watchAuctions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Дуудлага ачаалж байна...');
              }

              if (snapshot.hasError) {
                return ErrorDisplayWidget(
                  message: 'Дуудлага уншихад алдаа гарлаа.\n${snapshot.error}',
                );
              }

              final auctions = snapshot.data ?? [];

              if (auctions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gavel_outlined,
                        size: 48,
                        color: AppTheme.mutedForeground.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Одоогоор дуудлага байхгүй байна',
                        style: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SecondTicker(
                builder: (context, now) {
                  return RefreshIndicator(
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.card,
                    onRefresh: () async {},
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  'Идэвхтэй дуудлага',
                                  style:
                                      AppTheme.headingStyle.copyWith(fontSize: 20),
                                ),
                                const Spacer(),
                                if (bidBalance == 0)
                                  TextButton.icon(
                                    onPressed: () => context.go('/topup'),
                                    icon: const Icon(Icons.bolt, size: 16),
                                    label: const Text('Санал авах'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 360,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final auction = auctions[index];
                                return AuctionCard(
                                  auction: auction,
                                  bidBalance: bidBalance,
                                  tick: now,
                                  isBidding: _biddingAuctionId == auction.id,
                                  onQuickBid: () => _quickBid(auction),
                                );
                              },
                              childCount: auctions.length,
                            ),
                          ),
                        ),
                      ],
                    ),
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
