import 'package:flutter/material.dart';

import '../../models/auction_model.dart';
import '../../services/auction_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/profile_sub_page_scaffold.dart';
import '../../widgets/won_auction_card.dart';

/// Figma — Дуудлага худалдааны түүх (ялсан бараа)
class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AuctionService();

    return ProfileSubPageScaffold(
      title: 'Дуудлага худалдааны түүх',
      child: StreamBuilder<List<AuctionModel>>(
        stream: service.watchWonAuctions(),
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

          final won = snap.data ?? [];
          if (won.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 48, color: AppTheme.mutedForeground),
                    const SizedBox(height: 16),
                    Text(
                      'Ялсан бараа байхгүй',
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Дуудлага худалдаанд ялбал энд харагдана',
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
            itemCount: won.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => WonAuctionCard(auction: won[i]),
          );
        },
      ),
    );
  }
}
