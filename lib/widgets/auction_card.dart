import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/formatters.dart';
import '../models/auction_model.dart';
import '../theme/app_theme.dart';
import 'dual_timer.dart';
import 'phase_bar.dart';

/// Figma AuctionCard — grid дээрх дуудлагын карт
class AuctionCard extends StatelessWidget {
  const AuctionCard({
    super.key,
    required this.auction,
    required this.bidBalance,
    this.tick,
    this.isBidding = false,
    this.onQuickBid,
    this.onOpen,
  });

  final AuctionModel auction;
  final int bidBalance;
  final DateTime? tick;
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
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: onOpen ?? () => context.go('/auction/${auction.id}'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AuctionImage(
                imageUrl: auction.image,
                isFinished: _isFinished,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      auction.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headingStyle.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(auction.price),
                      style: AppTheme.monoStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PhaseBar(
                      compact: true,
                      currentPhase: auction.currentPhase,
                    ),
                    const SizedBox(height: 6),
                    DualTimer(
                      compact: true,
                      tick: tick,
                      winCountdownEndsAt: auction.effectiveWinCountdownEndsAt,
                      resetLabel: auction.winCountdownResetLabel,
                    ),
                    const SizedBox(height: 4),
                    Text(
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
                    const SizedBox(height: 8),
                    if (!_isFinished)
                      SizedBox(
                        width: double.infinity,
                        height: 32,
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
                                  width: 14,
                                  height: 14,
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
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
                            fontSize: 10,
                            color: AppTheme.destructive,
                          ),
                        ),
                      ),
                  ],
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
      aspectRatio: 1.25,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheWidth: 300,
              errorBuilder: (_, __, ___) => const _PlaceholderImage(),
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
                  fontSize: 11,
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
    return const ColoredBox(
      color: AppTheme.secondary,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 28,
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }
}
