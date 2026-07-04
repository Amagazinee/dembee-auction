import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/purchase_model.dart';
import '../../models/user_model.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';

/// Админ самбар — бүх хэрэглэгчийн амжилттай санал багц худалдан авалт
class AdminTransactionsTab extends StatelessWidget {
  const AdminTransactionsTab({super.key, required this.creditsService});

  final CreditsService creditsService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PurchaseModel>>(
      stream: creditsService.watchAllCompletedPurchases(),
      builder: (context, purchaseSnap) {
        if (purchaseSnap.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Гүйлгээ ачаалж байна...');
        }
        if (purchaseSnap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Алдаа: ${purchaseSnap.error}',
                style: const TextStyle(color: AppTheme.destructive),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final purchases = purchaseSnap.data ?? [];

        return StreamBuilder<Map<String, UserModel>>(
          stream: creditsService.watchAllUsers(),
          builder: (context, userSnap) {
            final users = userSnap.data ?? {};
            final totalRevenue =
                purchases.fold<int>(0, (sum, p) => sum + p.amount);
            final totalBids =
                purchases.fold<int>(0, (sum, p) => sum + p.bidCount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryChip(
                          label: 'Нийт гүйлгээ',
                          value: '${purchases.length}',
                          color: const Color(0xFF60A5FA),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryChip(
                          label: 'Нийт орлого',
                          value: formatPrice(totalRevenue),
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryChip(
                          label: 'Нэмсэн санал',
                          value: formatNumber(totalBids),
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Амжилттай санал багц худалдан авалтууд',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ),
                Expanded(
                  child: purchases.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 48, color: AppTheme.mutedForeground),
                              const SizedBox(height: 12),
                              Text(
                                'Гүйлгээ байхгүй',
                                style: AppTheme.bodyStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Хэрэглэгч санал багц авахад энд харагдана',
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 12,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: purchases.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final purchase = purchases[i];
                            final user = users[purchase.userUid];
                            return _AdminPurchaseCard(
                              purchase: purchase,
                              user: user,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.monoStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 10,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminPurchaseCard extends StatelessWidget {
  const _AdminPurchaseCard({
    required this.purchase,
    this.user,
  });

  final PurchaseModel purchase;
  final UserModel? user;

  static const Color _priceGreen = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    final userName = user?.name.isNotEmpty == true
        ? user!.name
        : 'Хэрэглэгч ${purchase.userUid.length > 6 ? '${purchase.userUid.substring(0, 6)}…' : purchase.userUid}';
    final userContact = user?.email.isNotEmpty == true
        ? user!.email
        : user?.phone ?? purchase.userUid;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userContact,
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 11,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _priceGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _priceGreen.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Амжилттай',
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: 9,
                    color: _priceGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Санал багц — ${purchase.bidCount} санал',
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDateTime(purchase.createdAt)} · ${purchase.paymentLabel}',
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 11,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+${formatPrice(purchase.amount)}',
                style: AppTheme.monoStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _priceGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
