import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/admin_report.dart';
import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../models/bid_history_model.dart';
import '../../models/purchase_model.dart';
import '../../models/user_model.dart';
import '../../services/auction_service.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';

/// Админ — тайлан үзэх, CSV болон текст хэлбэрээр гаргах
class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({
    super.key,
    required this.auctionService,
    required this.creditsService,
  });

  final AuctionService auctionService;
  final CreditsService creditsService;

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  ReportPeriod _period = ReportPeriod.month;
  bool _exporting = false;

  Future<void> _copyReport(AdminReportData report, Map<String, UserModel> users) async {
    final text = AdminReportExporter.toReadableText(report, usersById: users);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Тайлан хуулбарласан'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareCsv(AdminReportData report, Map<String, UserModel> users) async {
    setState(() => _exporting = true);
    try {
      final csv = AdminReportExporter.toCsv(report, usersById: users);
      final fileName =
          'dembee-report-${formatDate(report.generatedAt)}.csv';
      await Share.share(csv, subject: 'Дэмбээ тайлан', sharePositionOrigin: null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Тайлан хуваалцлаа ($fileName)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuctionModel>>(
      stream: widget.auctionService.watchAuctions(),
      builder: (context, auctionSnap) {
        if (!auctionSnap.hasData) {
          return const LoadingWidget(message: 'Тайлан бэлдэж байна...');
        }

        return StreamBuilder<List<UserModel>>(
          stream: widget.creditsService.watchAllUsersList(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const LoadingWidget(message: 'Тайлан бэлдэж байна...');
            }

            return StreamBuilder<List<PurchaseModel>>(
              stream: widget.creditsService.watchAllPurchases(),
              builder: (context, purchaseSnap) {
                if (!purchaseSnap.hasData) {
                  return const LoadingWidget(message: 'Тайлан бэлдэж байна...');
                }

                return StreamBuilder<List<BidHistoryModel>>(
                  stream: widget.auctionService.watchAllBidHistory(),
                  builder: (context, bidSnap) {
                    if (!bidSnap.hasData) {
                      return const LoadingWidget(message: 'Тайлан бэлдэж байна...');
                    }

                    final users = userSnap.data!;
                    final usersById = {for (final u in users) u.uid: u};
                    final report = AdminReportBuilder.build(
                      period: _period,
                      users: users,
                      auctions: auctionSnap.data!,
                      purchases: purchaseSnap.data!,
                      bids: bidSnap.data!,
                      usersById: usersById,
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Тайлан',
                                  style: AppTheme.headingStyle.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Text(
                                formatDateTime(report.generatedAt),
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 11,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ReportPeriod.values.map((period) {
                              final selected = _period == period;
                              return FilterChip(
                                label: Text(period.label),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _period = period),
                                selectedColor:
                                    AppTheme.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppTheme.primary,
                                labelStyle: AppTheme.bodyStyle.copyWith(
                                  fontSize: 12,
                                  color: selected
                                      ? AppTheme.primary
                                      : AppTheme.mutedForeground,
                                ),
                                side: const BorderSide(color: AppTheme.border),
                                backgroundColor: AppTheme.card,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cols = constraints.maxWidth > 700 ? 3 : 2;
                              return GridView.count(
                                crossAxisCount: cols,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.55,
                                children: [
                                  _ReportStatCard(
                                    label: 'Цэвэр орлого',
                                    value: formatPrice(report.netRevenue),
                                    sub:
                                        '${report.completedPurchases} гүйлгээ · ${report.period.label}',
                                    color: const Color(0xFF22C55E),
                                  ),
                                  _ReportStatCard(
                                    label: 'Шинэ хэрэглэгч',
                                    value: '${report.newUsers}',
                                    sub: 'Нийт ${report.totalUsers}',
                                    color: const Color(0xFF60A5FA),
                                  ),
                                  _ReportStatCard(
                                    label: 'Санал',
                                    value: formatNumber(report.bidsInPeriod),
                                    sub: 'Нийт ${formatNumber(report.totalBidsAllTime)}',
                                    color: AppTheme.primary,
                                  ),
                                  _ReportStatCard(
                                    label: 'Идэвхтэй дуудлага',
                                    value: '${report.activeAuctions}',
                                    sub:
                                        '${report.scheduledAuctions} төлөвлөгдсөн',
                                    color: const Color(0xFFA855F7),
                                  ),
                                  _ReportStatCard(
                                    label: 'Борлуулсан санал',
                                    value: formatNumber(report.bidsSold),
                                    sub: formatPrice(report.grossRevenue),
                                    color: const Color(0xFFF97316),
                                  ),
                                  _ReportStatCard(
                                    label: 'Буцаалт',
                                    value: '${report.refundedPurchases}',
                                    sub: formatPrice(report.refundedAmount),
                                    color: AppTheme.destructive,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          if (report.packageSales.isNotEmpty)
                            _ReportSection(
                              title: 'Багц борлуулалт',
                              child: Column(
                                children: [
                                  for (final entry
                                      in (report.packageSales.entries.toList()
                                        ..sort(
                                          (a, b) =>
                                              b.value.compareTo(a.value),
                                        )))
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style:
                                                  AppTheme.bodyStyle.copyWith(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${entry.value} удаа',
                                            style: AppTheme.monoStyle.copyWith(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          _ReportSection(
                            title: 'Үе хуваарилалт (идэвхтэй)',
                            child: Column(
                              children: List.generate(8, (i) {
                                final count = report.phaseCounts[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 52,
                                        child: Text(
                                          '${i + 1}-р үе',
                                          style: AppTheme.bodyStyle.copyWith(
                                            fontSize: 12,
                                            color: AppTheme.mutedForeground,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '$count дуудлага',
                                          style: AppTheme.monoStyle.copyWith(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _exporting
                                      ? null
                                      : () => _copyReport(report, usersById),
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Хуулбарлах'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _exporting
                                      ? null
                                      : () => _shareCsv(report, usersById),
                                  icon: _exporting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.background,
                                          ),
                                        )
                                      : const Icon(Icons.ios_share, size: 18),
                                  label: const Text('CSV хуваалцах'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'CSV-г Gmail, Drive, Excel руу хуваалцаж тайлан хадгална.',
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 11,
                              color: AppTheme.mutedForeground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ReportStatCard extends StatelessWidget {
  const _ReportStatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTheme.monoStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 12,
              color: AppTheme.mutedForeground,
            ),
          ),
          Text(
            sub,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 10,
              color: AppTheme.mutedForeground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.headingStyle.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
