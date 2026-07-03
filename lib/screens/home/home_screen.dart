import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/countdown_timer_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auctionService = AuctionService();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дуудлага худалдаа'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
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
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: auctions.length,
            itemBuilder: (context, index) {
              final auction = auctions[index];
              return _AuctionCard(
                auction: auction,
                auctionService: auctionService,
              );
            },
          );
        },
      ),
    );
  }
}

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({
    required this.auction,
    required this.auctionService,
  });

  final AuctionModel auction;
  final AuctionService auctionService;

  bool get _isFinished => auction.isClosed || auction.hasEnded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/auction/${auction.id}'),
        borderRadius: BorderRadius.circular(12),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (_isFinished)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Дууссан',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  CountdownTimerWidget(
                    endsAt: auction.endsAt,
                    onFinished: auction.isActive
                        ? () => auctionService.closeAuctionIfExpired(auction.id)
                        : null,
                  ),
                ],
              ),
              if (auction.lastBidder != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Сүүлийн санал: ${auction.lastBidder} (+${auction.lastBidAmount}₮)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ],
              if (auction.isClosed && auction.winnerName != null) ...[
                const SizedBox(height: 8),
                Text(
                  '🏆 ${auction.winnerName} — ${formatPrice(auction.finalPrice ?? auction.price)}',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 12,
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
