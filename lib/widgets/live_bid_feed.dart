import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/auction_model.dart';
import '../models/bid_history_model.dart';
import '../theme/app_theme.dart';

/// Figma "Шууд дуудлага" sidebar
class LiveBidFeed extends StatelessWidget {
  const LiveBidFeed({
    super.key,
    required this.auctions,
    this.recentBids = const [],
  });

  final List<AuctionModel> auctions;
  final List<BidHistoryModel> recentBids;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Шууд дуудлага',
              style: AppTheme.headingStyle.copyWith(fontSize: 14),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: _buildItems(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItems() {
    if (recentBids.isNotEmpty) {
      return recentBids.take(8).map((bid) {
        final auction = auctions.cast<AuctionModel?>().firstWhere(
              (a) => a?.id == bid.auctionId,
              orElse: () => null,
            );
        return _FeedItem(
          phase: auction?.currentPhase ?? 1,
          userName: maskName(bid.userName),
          product: auction?.title ?? bid.auctionTitle ?? 'Дуудлага',
          price: bid.priceAfter,
          timeAgo: bid.timeAgo,
        );
      }).toList();
    }

    return auctions
        .where((a) => a.isActive && !a.hasEnded)
        .take(6)
        .map(
          (a) => _FeedItem(
            phase: a.currentPhase,
            userName: a.lastBidder != null ? maskName(a.lastBidder!) : '—',
            product: a.title,
            price: a.price,
            timeAgo: 'шинэ',
          ),
        )
        .toList();
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({
    required this.phase,
    required this.userName,
    required this.product,
    required this.price,
    required this.timeAgo,
  });

  final int phase;
  final String userName;
  final String product;
  final int price;
  final String timeAgo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$phase-р үе',
              style: AppTheme.monoStyle.copyWith(fontSize: 9),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  product,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPrice(price),
                style: AppTheme.monoStyle.copyWith(fontSize: 11),
              ),
              Text(
                timeAgo,
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 9,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Figma "ЯАЖ АЖИЛЛАДАГ?"
class HowItWorksPanel extends StatelessWidget {
  const HowItWorksPanel({super.key});

  static const _bullets = [
    'Санал багц худалдан авч санал аваарай',
    'Санал бүр үнийг ₮1–₮5-аар нэмнэ',
    'Санал бүр «Ялагч тодрох» хугацааг дахин эхлүүлнэ',
    'Хугацаа 0 болоход сүүлийн санал ялагч болно',
    'Үе дуусвал дараагийн үе рүү шилжинэ',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ЯАЖ АЖИЛЛАДАГ?',
            style: AppTheme.headingStyle.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          ..._bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 11,
                        color: AppTheme.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
