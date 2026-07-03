import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../models/bid_history_model.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/countdown_timer_widget.dart';
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
  bool _isBidding = false;
  bool _isClosing = false;
  String? _bidError;

  Future<void> _closeIfExpired(String auctionId) async {
    if (_isClosing) return;
    _isClosing = true;

    try {
      await _auctionService.closeAuctionIfExpired(auctionId);
    } on AppException catch (e) {
      debugPrint('Дуудлага хаах алдаа: ${e.message}');
    } finally {
      _isClosing = false;
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Дуудлага'),
      ),
      body: StreamBuilder<AuctionModel?>(
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

          // Цаг дууссан идэвхтэй auction-ийг хаах
          if (auction.isActive && auction.hasEnded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _closeIfExpired(auction.id);
            });
          }

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
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                          onFinished: auction.isActive
                              ? () => _closeIfExpired(auction.id)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Төлөв',
                        value: _statusLabel(auction),
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
                      if (_showWinner(auction)) ...[
                        const SizedBox(height: 24),
                        _WinnerBanner(auction: auction),
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
                      const SizedBox(height: 32),
                      Text(
                        'Саналын түүх',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _BidHistoryList(
                        auctionId: auction.id,
                        auctionService: _auctionService,
                      ),
                    ],
                  ),
                ),
              ),
              if (auction.canBid)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: AppConstants.bidIncrements.map((amount) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: _isBidding
                                  ? null
                                  : () => _placeBid(auction, amount),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text('+$amount₮'),
                            ),
                          ),
                        );
                      }).toList(),
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
                      _closedMessage(auction),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(AuctionModel auction) {
    if (auction.isClosed) return 'Дууссан';
    if (auction.hasEnded) return 'Хаагдаж байна...';
    if (auction.isActive) return 'Идэвхтэй';
    return 'Хүлээгдэж буй';
  }

  bool _showWinner(AuctionModel auction) {
    return auction.isClosed && auction.winnerName != null;
  }

  String _closedMessage(AuctionModel auction) {
    if (auction.isClosed || auction.hasEnded) {
      return 'Дуудлага дууссан — санал өгөх боломжгүй';
    }
    return 'Дуудлага эхлээгүй байна';
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.auction});

  final AuctionModel auction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold),
      ),
      child: Text(
        '🏆 Ялагч: ${auction.winnerName} — '
        '${formatPrice(auction.finalPrice ?? auction.price)}',
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BidHistoryList extends StatelessWidget {
  const _BidHistoryList({
    required this.auctionId,
    required this.auctionService,
  });

  final String auctionId;
  final AuctionService auctionService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BidHistoryModel>>(
      stream: auctionService.watchBidHistory(auctionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Түүх уншихад алдаа гарлаа',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          );
        }

        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return const Text(
            'Санал өгөөгүй байна',
            style: TextStyle(color: Colors.white38),
          );
        }

        return Column(
          children: history.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.gold.withValues(alpha: 0.2),
                  child: Text(
                    item.userName.isNotEmpty
                        ? item.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: AppTheme.gold),
                  ),
                ),
                title: Text(item.userName),
                subtitle: Text(formatDateTime(item.createdAt)),
                trailing: Text(
                  '+${item.amount}₮ → ${formatPrice(item.newPrice ?? 0)}',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
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
