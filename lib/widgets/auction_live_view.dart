import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/auction_phases.dart';
import '../core/utils/formatters.dart';
import '../models/auction_model.dart';
import '../models/bid_history_model.dart';
import '../theme/app_theme.dart';
import 'auction_live_widgets.dart';
import 'go_home_button.dart';
import 'phase_legend.dart';

/// Figma live дуудлага дэлгэцийн гол хэсэг
class AuctionLiveView extends StatefulWidget {
  const AuctionLiveView({
    super.key,
    required this.auction,
    required this.bids,
    required this.bidBalance,
    required this.now,
    required this.currentUserUid,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onPlaceBid,
    this.onClose,
  });

  final AuctionModel auction;
  final List<BidHistoryModel> bids;
  final int bidBalance;
  final DateTime now;
  final String? currentUserUid;
  final bool isSubmitting;
  final String? errorMessage;
  final Future<void> Function(int amount) onPlaceBid;
  final VoidCallback? onClose;

  @override
  State<AuctionLiveView> createState() => _AuctionLiveViewState();
}

class _AuctionLiveViewState extends State<AuctionLiveView> {
  late int _selectedAmount;
  bool _phaseInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedAmount = widget.auction.bidIncrement.clamp(1, 5);
  }

  @override
  void didUpdateWidget(AuctionLiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auction.id != widget.auction.id) {
      _selectedAmount = widget.auction.bidIncrement.clamp(1, 5);
    }
  }

  bool get _canBid =>
      widget.auction.isBiddable(widget.now) && widget.bidBalance > 0;

  bool get _isFinished =>
      widget.auction.isClosed || widget.auction.hasEnded;

  bool get _isPending => widget.auction.isPending;

  @override
  Widget build(BuildContext context) {
    if (_isPending) {
      return _PendingView(
        auction: widget.auction,
        now: widget.now,
        bidBalance: widget.bidBalance,
        onClose: widget.onClose,
      );
    }
    if (_isFinished) {
      return _FinishedView(
        auction: widget.auction,
        bidBalance: widget.bidBalance,
        onClose: widget.onClose,
      );
    }

    final auction = widget.auction;
    final winRemaining =
        auction.effectiveWinCountdownEndsAt.difference(widget.now);
    final phaseRemaining =
        auction.effectivePhaseEndsAt.difference(widget.now);
    final phaseConfig = auction.phaseConfig;
    final phaseStart = auction.phaseStartedAt ?? widget.now;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LiveHeader(
          bidBalance: widget.bidBalance,
          onClose: widget.onClose ?? () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RoundCard(
                  phase: auction.currentPhase,
                  phaseTimeRange: formatPhaseTimeRange(
                    phaseStart,
                    phaseConfig.duration,
                  ),
                  winRemaining: winRemaining,
                  phaseInfoExpanded: _phaseInfoExpanded,
                  onTogglePhaseInfo: () =>
                      setState(() => _phaseInfoExpanded = !_phaseInfoExpanded),
                ),
                const SizedBox(height: 20),
                Text(
                  'Хаагдахад:',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 13,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatPhaseCountdown(phaseRemaining),
                  textAlign: TextAlign.center,
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: isUrgentCountdown(phaseRemaining)
                        ? AppTheme.destructive
                        : AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['Өдөр', 'Цаг', 'Мин', 'Секунд']
                      .map(
                        (label) => Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 10,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Таны илгээх үнэ:',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 13,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+ ${_selectedAmount}₮',
                  textAlign: TextAlign.center,
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                if (!_canBid) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.bidBalance <= 0
                        ? 'Санал дууссан. Санал багц аваарай.'
                        : 'Санал өгөх боломжгүй',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color: AppTheme.destructive,
                    ),
                  ),
                ],
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.destructive,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                RecentBiddersPanel(
                  bids: widget.bids,
                  currentUserUid: widget.currentUserUid,
                ),
              ],
            ),
          ),
        ),
        AuctionBidBar(
          selectedAmount: _selectedAmount,
          enabled: _canBid,
          isSubmitting: widget.isSubmitting,
          onDecrease: () {
            if (_selectedAmount > 1) {
              setState(() => _selectedAmount -= 1);
            }
          },
          onIncrease: () {
            if (_selectedAmount < 5) {
              setState(() => _selectedAmount += 1);
            }
          },
          onSubmit: () => widget.onPlaceBid(_selectedAmount),
        ),
      ],
    );
  }
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader({
    required this.bidBalance,
    required this.onClose,
  });

  final int bidBalance;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          Material(
            color: AppTheme.secondary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: AppTheme.secondary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => context.go('/home'),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.home_outlined, size: 20),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel, size: 18, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  '$bidBalance',
                  style: AppTheme.monoStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({
    required this.phase,
    required this.phaseTimeRange,
    required this.winRemaining,
    required this.phaseInfoExpanded,
    required this.onTogglePhaseInfo,
  });

  final int phase;
  final String phaseTimeRange;
  final Duration winRemaining;
  final bool phaseInfoExpanded;
  final VoidCallback onTogglePhaseInfo;

  @override
  Widget build(BuildContext context) {
    final winExpired = winRemaining.isNegative;
    final winUrgent = isUrgentCountdown(winRemaining);
    final winCountdownLabel = formatWinCountdownMs(winRemaining);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Round: $phase',
                  style: AppTheme.monoStyle.copyWith(fontSize: 11),
                ),
              ),
              const Spacer(),
              Icon(Icons.schedule, size: 14, color: AppTheme.mutedForeground),
              const SizedBox(width: 4),
              Text(
                phaseTimeRange,
                style: AppTheme.monoStyle.copyWith(
                  fontSize: 10,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            winExpired ? 'Ялагч тодорхойлогдлоо' : 'Ялагч тодорхойлоход',
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 12,
              color: winUrgent && !winExpired
                  ? AppTheme.destructive
                  : AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            winExpired ? '00.000' : winCountdownLabel,
            textAlign: TextAlign.center,
            style: AppTheme.monoStyle.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: winExpired
                  ? AppTheme.primary
                  : winUrgent
                      ? AppTheme.destructive
                      : AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTogglePhaseInfo,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Үе шат (Round) мэдээлэл',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  Icon(
                    phaseInfoExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppTheme.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (phaseInfoExpanded) ...[
            const SizedBox(height: 8),
            const PhaseLegend(embedded: true),
          ],
        ],
      ),
    );
  }
}

class _PendingView extends StatelessWidget {
  const _PendingView({
    required this.auction,
    required this.now,
    required this.bidBalance,
    this.onClose,
  });

  final AuctionModel auction;
  final DateTime now;
  final int bidBalance;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final startsAt = auction.startsAt ?? now;
    final remaining = startsAt.difference(now);

    return Column(
      children: [
        _LiveHeader(
          bidBalance: bidBalance,
          onClose: onClose ?? () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 56,
                    color: Color(0xFF60A5FA),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ДУУДЛАГА ЭХЛЭХЭД',
                    style: AppTheme.headingStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatScheduledStart(startsAt),
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 14,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    remaining.isNegative
                        ? '00 : 00 : 00 : 00'
                        : formatPhaseCountdown(remaining),
                    style: AppTheme.monoStyle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auction.title,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({
    required this.auction,
    required this.bidBalance,
    this.onClose,
  });

  final AuctionModel auction;
  final int bidBalance;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LiveHeader(
          bidBalance: bidBalance,
          onClose: onClose ?? () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 56,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ЯЛАГЧ ТОДОРХОЙЛОГДЛОО',
                    style: AppTheme.headingStyle.copyWith(fontSize: 20),
                  ),
                  if (auction.winnerName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      auction.winnerName!,
                      style: AppTheme.headingStyle.copyWith(fontSize: 24),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    formatPrice(auction.finalPrice ?? auction.price),
                    style: AppTheme.monoStyle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auction.title,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
