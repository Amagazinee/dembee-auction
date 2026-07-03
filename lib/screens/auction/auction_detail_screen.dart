import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../services/credits_service.dart';
import '../../widgets/countdown_timer_widget.dart';
import '../../widgets/dembee_app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class AuctionDetailScreen extends StatefulWidget {
  const AuctionDetailScreen({super.key, required this.auctionId});

  final String auctionId;

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final _auctionService = AuctionService();
  final _authService = AuthService();
  final _creditsService = CreditsService();
  bool _isBidding = false;
  String? _bidError;

  Future<void> _placeBid(AuctionModel auction, int amount) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      _isBidding = true;
      _bidError = null;
    });

    try {
      final profile = await _authService.getCurrentUserProfile();
      await _auctionService.placeBid(
        auctionId: auction.id,
        bidAmount: amount,
        bidderName: profile?.name ?? user.email ?? 'Хэрэглэгч',
        bidderUid: user.uid,
      );
    } on AppException catch (e) {
      setState(() => _bidError = e.message);
    } finally {
      if (mounted) setState(() => _isBidding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _creditsService.watchCurrentUser(),
      builder: (context, userSnap) {
        final bidBalance = userSnap.data?.bidBalance ?? 0;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: DembeeAppBar(bidBalance: bidBalance),
          body: _buildBody(bidBalance),
        );
      },
    );
  }

  Widget _buildBody(int bidBalance) {
    return StreamBuilder<AuctionModel?>(
        stream: _auctionService.watchAuction(widget.auctionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return ErrorDisplayWidget(
              message: 'Алдаа: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }

          final auction = snapshot.data;
          if (auction == null) {
            return const ErrorDisplayWidget(message: 'Дуудлага олдсонгүй');
          }

          final canBid =
              auction.isActive && !auction.hasEnded && bidBalance > 0;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auction.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),
                      _InfoRow(
                        label: 'Одоогийн үнэ',
                        value: formatPrice(auction.price),
                        valueColor: AppTheme.gold,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Үлдсэн хугацаа',
                        valueWidget: CountdownTimerWidget(
                          endsAt: auction.endsAt,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Сүүлийн санал өгсөн',
                        value: auction.lastBidder ?? '—',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Сүүлийн санал',
                        value: auction.lastBidAmount > 0
                            ? '+${auction.lastBidAmount}₮'
                            : '—',
                      ),
                      if (auction.isClosed && auction.winnerName != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.gold),
                          ),
                          child: Text(
                            '🏆 Ялагч: ${auction.winnerName} — ${formatPrice(auction.finalPrice ?? auction.price)}',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      if (_bidError != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _bidError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (canBid)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Үлдсэн санал: $bidBalance (-1 бүр)',
                          style: AppTheme.monoStyle.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: AppConstants.bidIncrements.map((amount) {
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ElevatedButton(
                                  onPressed: _isBidding
                                      ? null
                                      : () => _placeBid(auction, amount),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: Text('+$amount₮'),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                )
              else if (auction.isActive &&
                  !auction.hasEnded &&
                  bidBalance == 0)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Санал дууссан байна',
                          style: TextStyle(color: AppTheme.destructive),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.go('/topup'),
                          child: const Text('Санал багц авах'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SafeArea(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    child: Text(
                      auction.isClosed || auction.hasEnded
                          ? 'Дуудлага дууссан — санал өгөх боломжгүй'
                          : 'Дуудлага эхлээгүй байна',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
            ],
          );
        },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.valueColor,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        if (valueWidget != null)
          valueWidget!
        else
          Text(
            value ?? '',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
      ],
    );
  }
}
