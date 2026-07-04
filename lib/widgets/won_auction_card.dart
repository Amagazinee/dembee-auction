import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/formatters.dart';
import '../models/auction_model.dart';
import '../theme/app_theme.dart';

/// Figma — ялсан дуудлага худалдааны карт
class WonAuctionCard extends StatelessWidget {
  const WonAuctionCard({super.key, required this.auction});

  final AuctionModel auction;

  static const Color _priceGold = Color(0xFFC9A84C);
  static const Color _savingsGreen = Color(0xFF4ADE80);
  static const Color _wonBadgeGreen = Color(0xFF22C55E);

  int get _winPrice => auction.finalPrice ?? auction.price;

  int get _savings {
    final retail = auction.retailValue;
    if (retail == null || retail <= _winPrice) return 0;
    return retail - _winPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => context.go('/auction/${auction.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _thumbnail(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(auction.endsAt),
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          formatPrice(_winPrice),
                          style: AppTheme.monoStyle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _priceGold,
                          ),
                        ),
                        if (_savings > 0) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              formatSavings(_savings),
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 11,
                                color: _savingsGreen,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _wonBadgeGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ЯЛСАН',
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    if (auction.image != null && auction.image!.isNotEmpty) {
      return Image.network(
        auction.image!,
        fit: BoxFit.cover,
        cacheWidth: 144,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.secondary,
      child: const Icon(Icons.image_outlined, color: AppTheme.mutedForeground),
    );
  }
}
