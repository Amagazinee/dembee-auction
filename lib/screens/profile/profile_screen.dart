import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../models/bid_history_model.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final auctionService = AuctionService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Профайл'),
      ),
      body: FutureBuilder(
        future: authService.getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return ErrorDisplayWidget(message: 'Алдаа: ${snapshot.error}');
          }

          final profile = snapshot.data;
          if (profile == null || user == null) {
            return const ErrorDisplayWidget(message: 'Профайл олдсонгүй');
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(
                  profile.name.isNotEmpty
                      ? profile.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 24),
              _ProfileTile(label: 'Нэр', value: profile.name),
              _ProfileTile(label: 'Имэйл', value: profile.email),
              _ProfileTile(label: 'Утас', value: profile.phone),
              const SizedBox(height: 32),
              _SectionTitle(title: 'Миний ялсан'),
              const SizedBox(height: 8),
              StreamBuilder<List<AuctionModel>>(
                stream: auctionService.watchWonAuctions(user.uid),
                builder: (context, wonSnapshot) {
                  if (wonSnapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  final won = wonSnapshot.data ?? [];
                  if (won.isEmpty) {
                    return const _EmptyCard(message: 'Ялсан дуудлага байхгүй');
                  }

                  return Column(
                    children: won.map((auction) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(auction.title),
                          subtitle: Text(
                            formatPrice(auction.finalPrice ?? auction.price),
                          ),
                          trailing: const Icon(
                            Icons.emoji_events,
                            color: AppTheme.gold,
                          ),
                          onTap: () => context.go('/auction/${auction.id}'),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Миний санал'),
              const SizedBox(height: 8),
              StreamBuilder<List<BidHistoryModel>>(
                stream: auctionService.watchUserBids(user.uid),
                builder: (context, bidSnapshot) {
                  if (bidSnapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  final bids = bidSnapshot.data ?? [];
                  if (bids.isEmpty) {
                    return const _EmptyCard(message: 'Санал өгөөгүй байна');
                  }

                  return Column(
                    children: bids.take(20).map((bid) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('+${bid.amount}₮'),
                          subtitle: Text(formatDateTime(bid.createdAt)),
                          trailing: Text(
                            formatPrice(bid.newPrice ?? 0),
                            style: const TextStyle(color: AppTheme.gold),
                          ),
                          onTap: () => context.go('/auction/${bid.auctionId}'),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white54,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white38),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
