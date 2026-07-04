import 'package:flutter/material.dart';

import '../../models/purchase_model.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/package_purchase_card.dart';
import '../../widgets/profile_sub_page_scaffold.dart';

/// Figma — Санал багц худалдан авалтын түүх (гүйлгээний түүх)
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CreditsService();

    return ProfileSubPageScaffold(
      title: 'Санал багц худалдан авалтын түүх',
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_outlined,
                        size: 48, color: AppTheme.mutedForeground),
                    const SizedBox(height: 16),
                    Text(
                      'Гүйлгээ байхгүй',
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Санал багц авах хэсгээс эхлэнэ үү',
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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: purchases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                PackagePurchaseCard(purchase: purchases[i]),
          );
        },
      ),
    );
  }
}
