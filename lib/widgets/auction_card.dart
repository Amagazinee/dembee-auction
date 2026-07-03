import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/formatters.dart';
import '../models/auction_model.dart';
import '../theme/app_theme.dart';
import 'countdown_timer_widget.dart';
import 'dual_timer.dart';
import 'phase_bar.dart';

/// Figma AuctionCard — grid дээрх дуудлагын карт
class AuctionCard extends StatelessWidget {
  const AuctionCard({
    super.key,
    required this.auction,
    required this.bidBalance,
    this.isBidding = false,
    this.onQuickBid,
    this.onOpen,
  });

  final AuctionModel auction;
  final int bidBalance;
  final bool isBidding;
  final VoidCallback? onQuickBid;
  final VoidCallback? onOpen;

  bool get _isFinished => auction.isClosed || auction.hasEnded;
  bool get _canQuickBid =>
      auction.isActive && !auction.hasEnded && bidBalance > 0 && !isBidding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: onOpen ?? () => context.go('/auction/${auction.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AuctionImage(
                imageUrl: auction.image,
                isFinished: _isFinished,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auction.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.headingStyle.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatPrice(auction.price),
                        style: AppTheme.monoStyle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (auction.retailValue != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Зах зээлийн: ${formatPrice(auction.retailValue!)}',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 9,
                            color: AppTheme.mutedForeground,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      PhaseBar(currentPhase: auction.currentPhase),
                      const SizedBox(height: 8),
                      DualTimer(
                        compact: true,
                        winCountdownEndsAt: auction.effectiveWinCountdownEndsAt,
                        resetLabel: auction.winCountdownResetLabel,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              auction.lastBidder != null
                                  ? 'Сүүлийн: ${auction.lastBidder}'
                                  : 'Санал байхгүй',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 9,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                          Text(
                            '${formatNumber(auction.totalBids)} санал',
                            style: AppTheme.monoStyle.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (!_isFinished) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 10,
                              color: AppTheme.mutedForeground,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: CountdownTimerWidget(
                                endsAt: auction.endsAt,
                                style: AppTheme.monoStyle.copyWith(
                                  fontSize: 10,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: ElevatedButton(
                            onPressed: _canQuickBid ? onQuickBid : null,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: _canQuickBid
                                  ? AppTheme.primary
                                  : AppTheme.muted,
                              foregroundColor: _canQuickBid
                                  ? AppTheme.primaryForeground
                                  : AppTheme.mutedForeground,
                            ),
                            child: isBidding
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryForeground,
                                    ),
                                  )
                                : Text(
                                    bidBalance == 0
                                        ? 'Санал дууссан'
                                        : 'Санал илгээх -1',
                                    style: AppTheme.bodyStyle.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _canQuickBid
                                          ? AppTheme.primaryForeground
                                          : AppTheme.mutedForeground,
                                    ),
                                  ),
                          ),
                        ),
                      ] else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.destructive.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radius),
                          ),
                          child: Text(
                            auction.winnerName != null
                                ? '🏆 ${auction.winnerName}'
                                : 'Дууссан',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 11,
                              color: AppTheme.destructive,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuctionImage extends StatelessWidget {
  const _AuctionImage({
    required this.imageUrl,
    required this.isFinished,
  });

  final String? imageUrl;
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radius),
              ),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _PlaceholderImage(),
              ),
            )
          else
            const _PlaceholderImage(),
          if (isFinished)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Text(
                'ДУУССАН',
                style: AppTheme.monoStyle.copyWith(
                  fontSize: 12,
                  color: AppTheme.destructive,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 36,
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }
}
