import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../models/bid_history_model.dart';
import '../theme/app_theme.dart';

/// Сүүлийн 10 санал өгсөн хэрэглэгч — Figma leaderboard
class RecentBiddersPanel extends StatelessWidget {
  const RecentBiddersPanel({
    super.key,
    required this.bids,
    this.currentUserUid,
    this.maxRows = 10,
  });

  final List<BidHistoryModel> bids;
  final String? currentUserUid;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final shown = bids.take(maxRows).toList();
    if (shown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'Одоогоор санал байхгүй',
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.mutedForeground,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shown.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bid = shown[index];
        final isLeader = index == 0;
        final isMe = bid.userUid == currentUserUid;
        final name = isMe ? 'Та' : maskName(bid.userName);

        return _BidderRow(
          name: name,
          price: bid.priceAfter,
          timeLabel: formatBidClock(bid.createdAt),
          isLeader: isLeader,
          isMe: isMe,
        );
      },
    );
  }
}

class _BidderRow extends StatelessWidget {
  const _BidderRow({
    required this.name,
    required this.price,
    required this.timeLabel,
    required this.isLeader,
    required this.isMe,
  });

  final String name;
  final int price;
  final String timeLabel;
  final bool isLeader;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final borderColor = isLeader
        ? AppTheme.primary
        : AppTheme.border.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isLeader
            ? AppTheme.primary.withValues(alpha: 0.08)
            : AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isLeader ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          if (isLeader)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.emoji_events,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.secondary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isMe ? const Color(0xFF22C55E) : AppTheme.foreground,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLeader)
                  Text(
                    'Одоогийн ялагч',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 10,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  name,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isMe
                        ? const Color(0xFF22C55E)
                        : AppTheme.foreground,
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
                style: AppTheme.monoStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeLabel,
                style: AppTheme.monoStyle.copyWith(
                  fontSize: 10,
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

/// Доод хэсгийн санал илгээх товч — +/- 1–5₮
class AuctionBidBar extends StatelessWidget {
  const AuctionBidBar({
    super.key,
    required this.selectedAmount,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSubmit,
    required this.enabled,
    required this.isSubmitting,
  });

  final int selectedAmount;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onSubmit;
  final bool enabled;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final canDecrease =
        enabled && selectedAmount > AppConstants.bidIncrements.first;
    final canIncrease =
        enabled && selectedAmount < AppConstants.bidIncrements.last;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.remove,
            onPressed: canDecrease ? onDecrease : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: enabled && !isSubmitting ? onSubmit : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryForeground,
                      ),
                    )
                  : Text(
                      'Үнийн санал илгээх',
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.primaryForeground,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          _RoundIconButton(
            icon: Icons.add,
            onPressed: canIncrease ? onIncrease : null,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.secondary,
      shape: const CircleBorder(
        side: BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: onPressed != null
                ? AppTheme.foreground
                : AppTheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}
