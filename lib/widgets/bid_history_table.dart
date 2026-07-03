import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/bid_history_model.dart';
import '../theme/app_theme.dart';

/// Figma "СҮҮЛД САНАЛ ЯВУУЛСАН" хүснэгт
class BidHistoryTable extends StatelessWidget {
  const BidHistoryTable({
    super.key,
    required this.bids,
    this.currentUserUid,
    this.maxRows = 5,
    this.compact = false,
  });

  final List<BidHistoryModel> bids;
  final String? currentUserUid;
  final int maxRows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final shown = bids.take(maxRows).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(
              children: [
                Text(
                  'СҮҮЛД САНАЛ ЯВУУЛСАН',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: compact ? 8 : 9,
                    letterSpacing: 0.5,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const Spacer(),
                Text(
                  '${shown.length}/${bids.length}',
                  style: AppTheme.monoStyle.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          ...shown.asMap().entries.map((entry) {
            final i = entry.key;
            final bid = entry.value;
            final isMe = bid.userUid == currentUserUid;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: compact ? 3 : 5,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      '${i + 1}',
                      style: AppTheme.monoStyle.copyWith(
                        fontSize: compact ? 9 : 10,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      isMe ? 'Та' : maskName(bid.userName),
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: compact ? 9 : 10,
                        color: isMe
                            ? const Color(0xFF22C55E)
                            : AppTheme.foreground,
                        fontWeight:
                            isMe ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    formatPrice(bid.priceAfter),
                    style: AppTheme.monoStyle.copyWith(
                      fontSize: compact ? 9 : 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bid.timeAgo,
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: compact ? 8 : 9,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
