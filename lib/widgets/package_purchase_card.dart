import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/purchase_model.dart';
import '../theme/app_theme.dart';

/// Figma — санал багц худалдан авалтын карт
class PackagePurchaseCard extends StatelessWidget {
  const PackagePurchaseCard({super.key, required this.purchase});

  final PurchaseModel purchase;

  static const Color _priceGreen = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(Icons.bolt, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Санал багц — ${purchase.bidCount} санал',
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDate(purchase.createdAt)} · ${purchase.paymentLabel}',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatPrice(purchase.amount),
            style: AppTheme.monoStyle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _priceGreen,
            ),
          ),
        ],
      ),
    );
  }
}
