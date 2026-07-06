import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/formatters.dart';
import '../models/auction_model.dart';
import '../models/bid_history_model.dart';
import '../theme/app_theme.dart';
import 'bid_history_table.dart';
import 'countdown_timer_widget.dart';
import 'dual_timer.dart';
import 'phase_bar.dart';

/// Figma AuctionCard — идэвхтэй + дууссан хоёуланг дэмжинэ
class AuctionCard extends StatelessWidget {
  const AuctionCard({
    super.key,
    required this.auction,
    required this.bidBalance,
    this.tick,
    this.isBidding = false,
    this.recentBids = const [],
    this.currentUserUid,
    this.myBidCount = 0,
    this.onQuickBid,
    this.onOpen,
    this.expanded = false,
  });

  final AuctionModel auction;
  final int bidBalance;
  final DateTime? tick;
  final bool isBidding;
  final List<BidHistoryModel> recentBids;
  final String? currentUserUid;
  final int myBidCount;
  final VoidCallback? onQuickBid;
  final VoidCallback? onOpen;
  final bool expanded;

  bool get _isFinished => auction.isClosed || auction.hasEnded;
  bool get _isScheduled => auction.isPending;

  bool _canQuickBid(DateTime now) =>
      auction.isBiddable(now) && bidBalance > 0 && !isBidding;

  int get _savings {
    final retail = auction.retailValue;
    if (retail == null || retail <= auction.price) return 0;
    return retail - auction.price;
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _FinishedCard(auction: auction, onOpen: onOpen);

    final now = tick ?? DateTime.now();

    if (_isScheduled) {
      return _ScheduledCard(
        auction: auction,
        tick: now,
        onOpen: onOpen,
      );
    }

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
              _ActiveImage(auction: auction),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.title,
                      maxLines: expanded ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headingStyle.copyWith(
                        fontSize: expanded ? 16 : 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PhaseBar(
                      compact: !expanded,
                      currentPhase: auction.currentPhase,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ОДООГИЙН ҮНЭ',
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 9,
                                  color: AppTheme.mutedForeground,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                formatPrice(auction.price),
                                style: AppTheme.monoStyle.copyWith(
                                  fontSize: expanded ? 24 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF22C55E),
                                ),
                              ),
                              if (_savings > 0)
                                Text(
                                  formatSavings(_savings),
                                  style: AppTheme.bodyStyle.copyWith(
                                    fontSize: 9,
                                    color: const Color(0xFF22C55E),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${formatNumber(auction.totalBids)} нийт санал',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 9,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DualTimer(
                      compact: !expanded,
                      tick: tick,
                      gradient: true,
                      winCountdownEndsAt: auction.effectiveWinCountdownEndsAt,
                      resetLabel: auction.winCountdownResetLabel,
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Үе үргэлжлэх:',
                                  style: AppTheme.bodyStyle.copyWith(
                                    fontSize: 9,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                                CountdownTimerWidget(
                                  endsAt: auction.effectivePhaseEndsAt,
                                  tick: tick,
                                  style: AppTheme.monoStyle.copyWith(
                                    fontSize: 10,
                                    color: tick != null &&
                                            isUrgentCountdown(
                                              auction.effectivePhaseEndsAt
                                                  .difference(tick!),
                                            )
                                        ? AppTheme.destructive
                                        : AppTheme.foreground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Сүүлийн санал:',
                                  style: AppTheme.bodyStyle.copyWith(
                                    fontSize: 9,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                                Text(
                                  auction.lastBidder != null
                                      ? maskName(auction.lastBidder!)
                                      : '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppTheme.bodyStyle.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                        auction.lastBidder != null
                            ? 'Сүүлийн: ${maskName(auction.lastBidder!)}'
                            : 'Санал байхгүй',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 9,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Text(
                          '+₮${auction.lastBidAmount > 0 ? auction.lastBidAmount : 1}/санал',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 9,
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$myBidCount миний санал',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 9,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: expanded ? 44 : 36,
                      child: ElevatedButton.icon(
                        onPressed: expanded
                            ? (_canQuickBid(now) ? onQuickBid : null)
                            : (onOpen ?? () => context.go('/auction/${auction.id}')),
                        icon: isBidding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryForeground,
                                ),
                              )
                            : Icon(
                                expanded ? Icons.gavel : Icons.arrow_forward,
                                size: 16,
                              ),
                        label: Text(
                          bidBalance == 0
                              ? 'Санал дууссан'
                              : expanded
                                  ? 'Санал илгээх -1'
                                  : 'Нээх →',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: expanded ? 13 : 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.primaryForeground,
                          disabledBackgroundColor: AppTheme.muted,
                        ),
                      ),
                    ),
                    if (expanded && recentBids.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      BidHistoryTable(
                        bids: recentBids,
                        currentUserUid: currentUserUid,
                        compact: true,
                        maxRows: expanded ? 5 : 2,
                      ),
                    ],
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

class _ActiveImage extends StatelessWidget {
  const _ActiveImage({required this.auction});

  final AuctionModel auction;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (auction.image != null && auction.image!.isNotEmpty)
            Image.network(
              auction.image!,
              fit: BoxFit.cover,
              cacheWidth: 400,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => const _Placeholder(),
            )
          else
            const _Placeholder(),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${auction.currentPhase}-р үе',
                style: AppTheme.monoStyle.copyWith(
                  fontSize: 10,
                  color: const Color(0xFF60A5FA),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledCard extends StatelessWidget {
  const _ScheduledCard({
    required this.auction,
    required this.tick,
    this.onOpen,
  });

  final AuctionModel auction;
  final DateTime tick;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final startsAt = auction.startsAt ?? tick;
    final remaining = startsAt.difference(tick);

    return Material(
      color: AppTheme.card,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: onOpen ?? () => context.go('/auction/${auction.id}'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ActiveImage(auction: auction),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headingStyle.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2A3A),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ЭХЛЭХ ЦАГ',
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 9,
                              letterSpacing: 1,
                              color: const Color(0xFF60A5FA),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatScheduledStart(startsAt),
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            remaining.isNegative
                                ? 'Тун удахгүй эхлэнэ...'
                                : formatPhaseCountdown(remaining),
                            style: AppTheme.monoStyle.copyWith(
                              fontSize: 14,
                              color: const Color(0xFF93C5FD),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onOpen,
                      child: const Text('Дэлгэрэнгүй харах'),
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

class _FinishedCard extends StatelessWidget {
  const _FinishedCard({required this.auction, this.onOpen});

  final AuctionModel auction;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final savings = auction.retailValue != null
        ? (auction.retailValue! -
            (auction.finalPrice ?? auction.price))
        : 0;

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
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (auction.image != null && auction.image!.isNotEmpty)
                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.black54,
                          BlendMode.darken,
                        ),
                        child: Image.network(
                          auction.image!,
                          fit: BoxFit.cover,
                          cacheWidth: 400,
                          errorBuilder: (_, __, ___) => const _Placeholder(),
                        ),
                      )
                    else
                      const _Placeholder(),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ЯЛАГЧ ТОДОРХОЙЛОГДЛОО',
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 10,
                              letterSpacing: 1,
                              color: AppTheme.primary,
                            ),
                          ),
                          if (auction.winnerName != null)
                            Text(
                              auction.winnerName!,
                              style: AppTheme.headingStyle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.title,
                      style: AppTheme.headingStyle.copyWith(fontSize: 13),
                    ),
                    if (auction.winnerName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ялагч: ${auction.winnerName!}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    PhaseBar(
                      compact: true,
                      currentPhase: auction.currentPhase,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(auction.finalPrice ?? auction.price),
                          style: AppTheme.monoStyle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${formatNumber(auction.totalBids)} нийт санал',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 9,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    if (savings > 0)
                      Text(
                        formatSavings(savings),
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 9,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onOpen,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                      child: const Text('Дуудлага дууссан'),
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

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.secondary,
      child: Center(
        child: Icon(Icons.image_outlined, color: AppTheme.mutedForeground),
      ),
    );
  }
}
