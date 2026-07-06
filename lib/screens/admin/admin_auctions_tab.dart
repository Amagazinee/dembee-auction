import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../services/auction_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';

/// Админ — дуудлагын жагсаалт + шинэ бараа нэмэх товч
class AdminAuctionsTab extends StatelessWidget {
  const AdminAuctionsTab({super.key, required this.auctionService});

  final AuctionService auctionService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuctionModel>>(
      stream: auctionService.watchAuctions(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Дуудлага ачаалж байна...');
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

        final auctions = snap.data ?? [];
        final scheduled = auctions.where((a) => a.isPending).toList();
        final ongoing = auctions.where((a) => a.isOngoing).toList();
        final finished = auctions.where((a) => a.isFinished).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AddAuctionButton(
              onTap: () => context.push('/admin/add-auction'),
            ),
            if (scheduled.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Төлөвлөсөн дуудлага',
                count: scheduled.length,
                color: const Color(0xFF60A5FA),
              ),
              const SizedBox(height: 8),
              ...scheduled.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AdminAuctionCard(
                      auction: a,
                      auctionService: auctionService,
                      onTap: () => context.push('/auction/${a.id}'),
                    ),
                  )),
            ],
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Идэвхтэй дуудлага',
              count: ongoing.length,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 8),
            if (ongoing.isEmpty)
              const _EmptyHint('Одоогоор идэвхтэй дуудлага байхгүй')
            else
              ...ongoing.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AdminAuctionCard(
                      auction: a,
                      auctionService: auctionService,
                      onTap: () => context.push('/auction/${a.id}'),
                    ),
                  )),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Дууссан дуудлага',
              count: finished.length,
              color: AppTheme.mutedForeground,
            ),
            const SizedBox(height: 8),
            if (finished.isEmpty)
              const _EmptyHint('Дууссан дуудлага байхгүй')
            else
              ...finished.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AdminAuctionCard(
                      auction: a,
                      auctionService: auctionService,
                      onTap: () => context.push('/auction/${a.id}'),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class _AddAuctionButton extends StatelessWidget {
  const _AddAuctionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(Icons.add, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Шинэ бараа нэмэх',
                      style: AppTheme.headingStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Дуудлага худалдаанд шинэ бараа оруулах',
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTheme.headingStyle.copyWith(fontSize: 15),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: AppTheme.monoStyle.copyWith(fontSize: 11, color: color),
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.bodyStyle.copyWith(
          fontSize: 13,
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }
}

class _AdminAuctionCard extends StatefulWidget {
  const _AdminAuctionCard({
    required this.auction,
    required this.auctionService,
    required this.onTap,
  });

  final AuctionModel auction;
  final AuctionService auctionService;
  final VoidCallback onTap;

  @override
  State<_AdminAuctionCard> createState() => _AdminAuctionCardState();
}

class _AdminAuctionCardState extends State<_AdminAuctionCard> {
  bool _declaring = false;

  Future<void> _declareWinner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Ялагч тодорхойлох'),
        content: Text(
          '«${widget.auction.title}» дуудлагын сүүлийн санал өгсөн '
          '${widget.auction.lastBidder ?? 'хэрэглэгчийг'} ялагч болгох уу?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Болих'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Тодорхойлох'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _declaring = true);
    try {
      await widget.auctionService.declareWinnerAdmin(widget.auction.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ялагч амжилттай тодорхойлогдлоо'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _declaring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auction = widget.auction;
    final scheduled = auction.isPending;
    final ongoing = auction.isOngoing;
    final statusLabel =
        scheduled ? 'Төлөвлөсөн' : (ongoing ? 'Идэвхтэй' : 'Дууссан');
    final statusColor = scheduled
        ? const Color(0xFF60A5FA)
        : (ongoing ? const Color(0xFF22C55E) : AppTheme.mutedForeground);

    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AuctionThumb(imageUrl: auction.image),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            auction.title,
                            style: AppTheme.bodyStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            statusLabel,
                            style: AppTheme.monoStyle.copyWith(
                              fontSize: 9,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (scheduled && auction.startsAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Эхлэх: ${formatScheduledStart(auction.startsAt!)}',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF60A5FA),
                        ),
                      ),
                    ],
                    if (auction.category != null &&
                        auction.category!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        auction.category!,
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 11,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          formatPrice(auction.price),
                          style: AppTheme.monoStyle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${auction.currentPhase}-р үе',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 11,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${formatNumber(auction.totalBids)} санал',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 11,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (ongoing && auction.lastBidder != null) ...[
                      Text(
                        'Сүүлийн: ${auction.lastBidder}',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 11,
                          color: AppTheme.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Үлдсэн: ${formatDuration(auction.remaining)}',
                        style: AppTheme.monoStyle.copyWith(
                          fontSize: 10,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ] else if (auction.winnerName != null) ...[
                      Text(
                        'Ялагч: ${auction.winnerName}',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 11,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ] else if (!ongoing) ...[
                      Text(
                        'Дууссан: ${formatDateTime(auction.endsAt)}',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 11,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                    if (auction.bidIncrement > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Санал +₮${auction.bidIncrement}',
                        style: AppTheme.monoStyle.copyWith(
                          fontSize: 10,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (ongoing && auction.lastBidUid != null) ...[
                const Divider(height: 1, color: AppTheme.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _declaring ? null : _declareWinner,
                      icon: _declaring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.emoji_events_outlined, size: 18),
                      label: Text(
                        _declaring ? 'Тодорхойлож байна...' : 'Ялагч тодорхойлох',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuctionThumb extends StatelessWidget {
  const _AuctionThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 64,
        height: 64,
        color: AppTheme.muted,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_outlined,
                  color: AppTheme.mutedForeground,
                ),
              )
            : const Icon(Icons.gavel, color: AppTheme.mutedForeground, size: 28),
      ),
    );
  }
}
