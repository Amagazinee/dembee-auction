import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/bid_history_model.dart';
import '../../models/purchase_model.dart';
import '../../services/auction_service.dart';
import '../../services/credits_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/profile_sub_page_scaffold.dart';

enum _TxType { purchase, bid }

class _TransactionItem {
  const _TransactionItem({
    required this.type,
    required this.createdAt,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
  });

  final _TxType type;
  final DateTime createdAt;
  final String title;
  final String subtitle;
  final String amountLabel;
}

/// Figma TransactionsView — гүйлгээний түүх (багц + санал)
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      return const ProfileSubPageScaffold(
        title: 'Гүйлгээний түүх',
        child: Center(child: Text('Нэвтэрнэ үү')),
      );
    }

    final purchasesStream = CreditsService().watchUserPurchases();
    final bidsStream = AuctionService().watchUserBids(uid);

    return ProfileSubPageScaffold(
      title: 'Гүйлгээний түүх',
      child: StreamBuilder<List<PurchaseModel>>(
        stream: purchasesStream,
        builder: (context, purchaseSnap) {
          return StreamBuilder<List<BidHistoryModel>>(
            stream: bidsStream,
            builder: (context, bidSnap) {
              if (purchaseSnap.connectionState == ConnectionState.waiting ||
                  bidSnap.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Ачаалж байна...');
              }

              final purchases = purchaseSnap.data ?? [];
              final bids = bidSnap.data ?? [];

              final items = <_TransactionItem>[
                ...purchases.map(
                  (p) => _TransactionItem(
                    type: _TxType.purchase,
                    createdAt: p.createdAt,
                    title: 'Санал багц — ${p.packageLabel}',
                    subtitle: '${p.paymentLabel} · ${formatDateTime(p.createdAt)}',
                    amountLabel: '-${formatPrice(p.amount)}',
                    isCredit: false,
                  ),
                ),
                ...bids.map(
                  (b) => _TransactionItem(
                    type: _TxType.bid,
                    createdAt: b.createdAt,
                    title: 'Санал өгсөн',
                    subtitle: formatDateTime(b.createdAt),
                    amountLabel: '-1 санал',
                    isCredit: false,
                  ),
                ),
              ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz, size: 48, color: AppTheme.mutedForeground),
                        SizedBox(height: 16),
                        Text('Гүйлгээ байхгүй'),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _TxCard(item: items[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  const _TxCard({required this.item});

  final _TransactionItem item;

  @override
  Widget build(BuildContext context) {
    final icon = item.type == _TxType.purchase
        ? Icons.shopping_bag_outlined
        : Icons.gavel_outlined;

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.amountLabel,
            style: AppTheme.monoStyle.copyWith(
              fontSize: 12,
              color: AppTheme.destructive,
            ),
          ),
        ],
      ),
    );
  }
}
