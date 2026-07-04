import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/purchase_model.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/profile_sub_page_scaffold.dart';

/// Figma PurchasesView — санал багц худалдан авалтын түүх
class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CreditsService();

    return ProfileSubPageScaffold(
      title: 'Худалдан авалтын түүх',
      child: StreamBuilder<List<PurchaseModel>>(
        stream: service.watchUserPurchases(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Ачаалж байна...');
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Алдаа: ${snap.error}',
                  style: const TextStyle(color: AppTheme.destructive),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final purchases = snap.data ?? [];
          if (purchases.isEmpty) {
            return _EmptyState(
              icon: Icons.shopping_bag_outlined,
              message: 'Худалдан авалт байхгүй',
              hint: 'Санал багц авах хэсгээс эхлэнэ үү',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: purchases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _PurchaseCard(purchase: purchases[i]),
          );
        },
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.purchase});

  final PurchaseModel purchase;

  @override
  Widget build(BuildContext context) {
    final completed = purchase.status == 'completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.bolt, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.packageLabel,
                  style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDateTime(purchase.createdAt),
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                Text(
                  purchase.paymentLabel,
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: 10,
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
                formatPrice(purchase.amount),
                style: AppTheme.monoStyle.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: completed
                      ? AppTheme.secondary
                      : AppTheme.muted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  completed ? 'Амжилттай' : purchase.status,
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: 9,
                    color: completed ? AppTheme.secondaryForeground : AppTheme.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.hint,
  });

  final IconData icon;
  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.mutedForeground),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.mutedForeground,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
