import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/purchase_model.dart';
import '../../models/user_model.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';

/// Админ самбар — бүх хэрэглэгчийн санал багц худалдан авалт
class AdminTransactionsTab extends StatefulWidget {
  const AdminTransactionsTab({super.key, required this.creditsService});

  final CreditsService creditsService;

  @override
  State<AdminTransactionsTab> createState() => _AdminTransactionsTabState();
}

class _AdminTransactionsTabState extends State<AdminTransactionsTab> {
  String? _busyPurchaseId;

  Future<void> _refundPurchase(PurchaseModel purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Буцаалт хийх уу?'),
        content: Text(
          '${purchase.bidCount} санал (${formatPrice(purchase.amount)}) буцаагдана. '
          'Хэрэглэгчийн үлдсэн саналаас хасагдана.',
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.mutedForeground,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болих'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.destructive,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Буцаах'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busyPurchaseId = purchase.id);
    try {
      await widget.creditsService.adminRefundPurchase(purchase.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Буцаалт амжилттай'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyPurchaseId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PurchaseModel>>(
      stream: widget.creditsService.watchAllPurchases(),
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
        final completed = purchases.where((p) => p.isCompleted).toList();

        return StreamBuilder<Map<String, UserModel>>(
          stream: widget.creditsService.watchAllUsers(),
          builder: (context, userSnap) {
            final users = userSnap.data ?? {};
            final totalRevenue =
                completed.fold<int>(0, (sum, p) => sum + p.amount);
            final totalBids =
                completed.fold<int>(0, (sum, p) => sum + p.bidCount);
            final refundedCount = purchases.where((p) => p.isRefunded).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryChip(
                          label: 'Амжилттай',
                          value: '${completed.length}',
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
                          label: 'Буцаагдсан',
                          value: '$refundedCount',
                          color: AppTheme.destructive,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Нэмсэн санал: ${formatNumber(totalBids)}',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 11,
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
                              busy: _busyPurchaseId == purchase.id,
                              onRefund: purchase.isCompleted
                                  ? () => _refundPurchase(purchase)
                                  : null,
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
    required this.busy,
    this.onRefund,
  });

  final PurchaseModel purchase;
  final UserModel? user;
  final bool busy;
  final VoidCallback? onRefund;

  static const Color _priceGreen = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    final userName = user?.name.isNotEmpty == true
        ? user!.name
        : 'Хэрэглэгч ${purchase.userUid.length > 6 ? '${purchase.userUid.substring(0, 6)}…' : purchase.userUid}';
    final userContact = user?.email.isNotEmpty == true
        ? user!.email
        : user?.phone ?? purchase.userUid;
    final statusColor =
        purchase.isRefunded ? AppTheme.destructive : _priceGreen;

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
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  purchase.statusLabel,
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: 9,
                    color: statusColor,
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
                    if (purchase.refundedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Буцаасан: ${formatDateTime(purchase.refundedAt!)}',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 11,
                          color: AppTheme.destructive,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                purchase.isRefunded
                    ? formatPrice(purchase.amount)
                    : '+${formatPrice(purchase.amount)}',
                style: AppTheme.monoStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  decoration: purchase.isRefunded
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ],
          ),
          if (onRefund != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onRefund,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.destructive,
                  side: BorderSide(
                    color: AppTheme.destructive.withValues(alpha: 0.5),
                  ),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.undo, size: 16),
                label: const Text('Буцаалт'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
