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
import '../../widgets/dual_timer.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/phase_bar.dart';

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailHero(auction: auction),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auction.title,
                            style: AppTheme.headingStyle.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatPrice(auction.price),
                                style: AppTheme.monoStyle.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (auction.retailValue != null) ...[
                                const SizedBox(width: 12),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    formatPrice(auction.retailValue!),
                                    style: AppTheme.bodyStyle.copyWith(
                                      fontSize: 14,
                                      color: AppTheme.mutedForeground,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${formatNumber(auction.totalBids)} нийт санал · ${auction.currentPhase}-р үе',
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 12,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 20),
                          PhaseBar(currentPhase: auction.currentPhase),
                          const SizedBox(height: 16),
                          DualTimer(
                            winCountdownEndsAt: auction.effectiveWinCountdownEndsAt,
                            resetLabel: auction.winCountdownResetLabel,
                          ),
                          const SizedBox(height: 16),
                          _InfoTile(
                            icon: Icons.schedule,
                            label: 'Үе дуусах хугацаа',
                            child: CountdownTimerWidget(
                              endsAt: auction.endsAt,
                              style: AppTheme.monoStyle.copyWith(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InfoTile(
                            icon: Icons.person_outline,
                            label: 'Сүүлийн санал өгсөн',
                            value: auction.lastBidder ?? '—',
                          ),
                          if (auction.lastBidAmount > 0) ...[
                            const SizedBox(height: 8),
                            _InfoTile(
                              icon: Icons.trending_up,
                              label: 'Сүүлийн санал',
                              value: '+${auction.lastBidAmount}₮',
                              valueColor: AppTheme.primary,
                            ),
                          ],
                          if (auction.isClosed && auction.winnerName != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radius),
                                border: Border.all(color: AppTheme.primary),
                              ),
                              child: Text(
                                '🏆 Ялагч: ${auction.winnerName}\n${formatPrice(auction.finalPrice ?? auction.price)}',
                                style: AppTheme.headingStyle.copyWith(
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          if (_bidError != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _bidError!,
                              style: const TextStyle(color: AppTheme.destructive),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BidFooter(
              auction: auction,
              bidBalance: bidBalance,
              canBid: canBid,
              isBidding: _isBidding,
              onBid: (amount) => _placeBid(auction, amount),
            ),
          ],
        );
      },
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.auction});

  final AuctionModel auction;

  @override
  Widget build(BuildContext context) {
    final isFinished = auction.isClosed || auction.hasEnded;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (auction.image != null && auction.image!.isNotEmpty)
            Image.network(
              auction.image!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _HeroPlaceholder(),
            )
          else
            const _HeroPlaceholder(),
          if (isFinished)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Text(
                'ДУУССАН',
                style: AppTheme.monoStyle.copyWith(
                  fontSize: 20,
                  color: AppTheme.destructive,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.card.withValues(alpha: 0.9),
                foregroundColor: AppTheme.foreground,
              ),
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.secondary,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    this.child,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 13,
                color: AppTheme.mutedForeground,
              ),
            ),
          ),
          if (child != null)
            child!
          else
            Text(
              value ?? '',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.foreground,
              ),
            ),
        ],
      ),
    );
  }
}

class _BidFooter extends StatelessWidget {
  const _BidFooter({
    required this.auction,
    required this.bidBalance,
    required this.canBid,
    required this.isBidding,
    required this.onBid,
  });

  final AuctionModel auction;
  final int bidBalance;
  final bool canBid;
  final bool isBidding;
  final void Function(int amount) onBid;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Үлдсэн санал: ',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  Text(
                    formatNumber(bidBalance),
                    style: AppTheme.monoStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' (-1 бүр)',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (canBid)
                Row(
                  children: AppConstants.bidIncrements.map((amount) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ElevatedButton(
                          onPressed:
                              isBidding ? null : () => onBid(amount),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.primaryForeground,
                          ),
                          child: Text(
                            '+$amount₮',
                            style: AppTheme.monoStyle.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryForeground,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else if (auction.isActive &&
                  !auction.hasEnded &&
                  bidBalance == 0)
                Column(
                  children: [
                    const Text(
                      'Санал дууссан байна',
                      style: TextStyle(color: AppTheme.destructive),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/topup'),
                        child: const Text('Санал багц авах'),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  auction.isClosed || auction.hasEnded
                      ? 'Дуудлага дууссан — санал өгөх боломжгүй'
                      : 'Дуудлага эхлээгүй байна',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.destructive),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
