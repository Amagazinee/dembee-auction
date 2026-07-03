import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/countdown_timer_widget.dart';
import '../../widgets/dembee_app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auctionService = AuctionService();
    final creditsService = CreditsService();

    return StreamBuilder(
      stream: creditsService.watchCurrentUser(),
      builder: (context, userSnapshot) {
        final bidBalance = userSnapshot.data?.bidBalance ?? 0;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: DembeeAppBar(bidBalance: bidBalance),
          body: StreamBuilder<List<AuctionModel>>(
            stream: auctionService.watchAuctions(),
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
                return const Center(
                  child: Text(
                    'Одоогоор дуудлага байхгүй байна',
                    style: TextStyle(color: AppTheme.mutedForeground),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {},
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: auctions.length,
                  itemBuilder: (context, index) {
                    return _AuctionCard(auction: auctions[index]);
                  },
                ),
              );
            },
          ),
          floatingActionButton: bidBalance == 0
              ? FloatingActionButton.extended(
                  onPressed: () => context.go('/topup'),
                  icon: const Icon(Icons.bolt),
                  label: const Text('Санал авах'),
                )
              : null,
        );
      },
    );
  }
}

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({required this.auction});

  final AuctionModel auction;

  bool get _isFinished => auction.isClosed || auction.hasEnded;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: () => context.go('/auction/${auction.id}'),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      auction.title,
                      style: AppTheme.headingStyle.copyWith(fontSize: 16),
                    ),
                  ),
                  if (_isFinished)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.destructive.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Дууссан',
                        style: TextStyle(
                          color: AppTheme.destructive,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatPrice(auction.price),
                    style: AppTheme.monoStyle.copyWith(fontSize: 20),
                  ),
                  CountdownTimerWidget(endsAt: auction.endsAt),
                ],
              ),
              if (auction.lastBidder != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Сүүлийн санал: ${auction.lastBidder} (+${auction.lastBidAmount}₮)',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
