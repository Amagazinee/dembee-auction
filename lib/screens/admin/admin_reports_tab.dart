import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/admin_report.dart';
import '../../core/utils/formatters.dart';
import '../../models/auction_model.dart';
import '../../models/bid_history_model.dart';
import '../../models/purchase_model.dart';
import '../../models/user_model.dart';
import '../../services/admin_report_file_exporter.dart';
import '../../services/auction_service.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widget.dart';

/// Админ — тайлан үзэх, хүснэгт, PDF/Excel экспорт
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
  DateTimeRange? _customRange;
  bool _exporting = false;

  ReportFilter get _filter {
    if (_period == ReportPeriod.custom && _customRange != null) {
      return ReportFilter.customRange(
        start: _customRange!.start,
        end: _customRange!.end,
      );
    }
    return ReportFilter.fromPeriod(_period);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      helpText: 'Тайлангийн хугацаа сонгох',
      cancelText: 'Болих',
      confirmText: 'Сонгох',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customRange = picked;
      _period = ReportPeriod.custom;
    });
  }

  Future<void> _copyReport(
    AdminReportData report,
    Map<String, UserModel> users,
  ) async {
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

  Future<void> _shareCsv(
    AdminReportData report,
    Map<String, UserModel> users,
  ) async {
    final csv = AdminReportExporter.toCsv(report, usersById: users);
    await _exportFile(
      report: report,
      users: users,
      extension: 'csv',
      mimeType: 'text/csv',
      bytes: const [],
      isString: true,
      stringContent: csv,
    );
  }

  Future<void> _shareExcel(
    AdminReportData report,
    Map<String, UserModel> users,
  ) async {
    final bytes = AdminReportFileExporter.toExcelBytes(
      report,
      usersById: users,
    );
    await _exportFile(
      report: report,
      users: users,
      extension: 'xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      bytes: bytes,
    );
  }

  Future<void> _sharePdf(
    AdminReportData report,
    Map<String, UserModel> users,
  ) async {
    final bytes = await AdminReportFileExporter.toPdfBytes(
      report,
      usersById: users,
    );
    await _exportFile(
      report: report,
      users: users,
      extension: 'pdf',
      mimeType: 'application/pdf',
      bytes: bytes,
    );
  }

  Future<void> _exportFile({
    required AdminReportData report,
    required Map<String, UserModel> users,
    required String extension,
    required String mimeType,
    required List<int> bytes,
    bool isString = false,
    String? stringContent,
  }) async {
    setState(() => _exporting = true);
    try {
      final dir = await getTemporaryDirectory();
      final fileName =
          'dembee-report-${formatDate(report.generatedAt)}.$extension';
      final file = File('${dir.path}/$fileName');
      if (isString && stringContent != null) {
        await file.writeAsString(stringContent);
      } else {
        await file.writeAsBytes(bytes);
      }
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'Дэмбээ тайлан — ${report.periodLabel}',
      );
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
                      return const LoadingWidget(
                        message: 'Тайлан бэлдэж байна...',
                      );
                    }

                    final users = userSnap.data!;
                    final usersById = {for (final u in users) u.uid: u};
                    final report = AdminReportBuilder.build(
                      filter: _filter,
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
                            children: [
                              for (final period in ReportPeriod.values)
                                if (period != ReportPeriod.custom)
                                  FilterChip(
                                    label: Text(period.label),
                                    selected: _period == period,
                                    onSelected: (_) => setState(
                                      () => _period = period,
                                    ),
                                    selectedColor: AppTheme.primary
                                        .withValues(alpha: 0.2),
                                    checkmarkColor: AppTheme.primary,
                                    labelStyle: AppTheme.bodyStyle.copyWith(
                                      fontSize: 12,
                                      color: _period == period
                                          ? AppTheme.primary
                                          : AppTheme.mutedForeground,
                                    ),
                                    side: const BorderSide(
                                      color: AppTheme.border,
                                    ),
                                    backgroundColor: AppTheme.card,
                                  ),
                              FilterChip(
                                label: Text(
                                  _period == ReportPeriod.custom &&
                                          _customRange != null
                                      ? _filter.label
                                      : 'Хугацаа сонгох',
                                ),
                                selected: _period == ReportPeriod.custom,
                                onSelected: (_) => _pickCustomRange(),
                                selectedColor:
                                    AppTheme.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppTheme.primary,
                                labelStyle: AppTheme.bodyStyle.copyWith(
                                  fontSize: 12,
                                ),
                                side: const BorderSide(color: AppTheme.border),
                                backgroundColor: AppTheme.card,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryGrid(report),
                          const SizedBox(height: 16),
                          if (report.packageSales.isNotEmpty)
                            _ReportSection(
                              title: 'Багц борлуулалт',
                              child: _DataTableSection(
                                columns: const ['Багц', 'Тоо'],
                                rows: (report.packageSales.entries.toList()
                                      ..sort(
                                        (a, b) =>
                                            b.value.compareTo(a.value),
                                      ))
                                    .map((e) => [e.key, '${e.value} удаа'])
                                    .toList(),
                              ),
                            ),
                          if (report.newUsersList.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _ReportSection(
                              title:
                                  'Шинэ хэрэглэгч (${report.newUsersList.length})',
                              child: _DataTableSection(
                                columns: const [
                                  'Нэр',
                                  'Имэйл',
                                  'Утас',
                                  'Огноо',
                                ],
                                rows: report.newUsersList
                                    .map(
                                      (u) => [
                                        u.name,
                                        u.email,
                                        u.phone,
                                        formatDateTime(u.createdAt),
                                      ],
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _ReportSection(
                            title:
                                'Амжилттай дууссан бараа (${report.successfulAuctions.length})',
                            child: report.successfulAuctions.isEmpty
                                ? const _EmptyTableMessage(
                                    'Энэ хугацаанд амжилттай дууссан бараа байхгүй',
                                  )
                                : _AuctionTable(auctions: report.successfulAuctions),
                          ),
                          const SizedBox(height: 12),
                          _ReportSection(
                            title:
                                'Амжилтгүй дууссан бараа (${report.failedAuctions.length})',
                            child: report.failedAuctions.isEmpty
                                ? const _EmptyTableMessage(
                                    'Энэ хугацаанд амжилтгүй дууссан бараа байхгүй',
                                  )
                                : _AuctionTable(auctions: report.failedAuctions),
                          ),
                          if (report.refundsList.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _ReportSection(
                              title: 'Буцаалт (${report.refundsList.length})',
                              child: _DataTableSection(
                                columns: const [
                                  'Огноо',
                                  'Хэрэглэгч',
                                  'Багц',
                                  'Дүн',
                                ],
                                rows: report.refundsList.map((p) {
                                  final user = usersById[p.userUid];
                                  final name = user?.name.isNotEmpty == true
                                      ? user!.name
                                      : p.userUid;
                                  return [
                                    formatDateTime(
                                      p.refundedAt ?? p.createdAt,
                                    ),
                                    name,
                                    p.packageLabel,
                                    formatPrice(p.amount),
                                  ];
                                }).toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _exporting
                                    ? null
                                    : () =>
                                        _copyReport(report, usersById),
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Хуулбарлах'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _exporting
                                    ? null
                                    : () => _shareCsv(report, usersById),
                                icon: const Icon(Icons.table_chart, size: 18),
                                label: const Text('CSV'),
                              ),
                              FilledButton.icon(
                                onPressed: _exporting
                                    ? null
                                    : () => _shareExcel(report, usersById),
                                icon: const Icon(Icons.grid_on, size: 18),
                                label: const Text('Excel'),
                              ),
                              FilledButton.icon(
                                onPressed: _exporting
                                    ? null
                                    : () => _sharePdf(report, usersById),
                                icon: const Icon(Icons.picture_as_pdf, size: 18),
                                label: const Text('PDF'),
                              ),
                            ],
                          ),
                          if (_exporting)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
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

  Widget _buildSummaryGrid(AdminReportData report) {
    return LayoutBuilder(
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
              sub: '${report.completedPurchases} гүйлгээ · ${report.periodLabel}',
              color: const Color(0xFF22C55E),
            ),
            _ReportStatCard(
              label: 'Шинэ хэрэглэгч',
              value: '${report.newUsers}',
              sub: 'Нийт ${report.totalUsers}',
              color: const Color(0xFF60A5FA),
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
            _ReportStatCard(
              label: 'Амжилттай бараа',
              value: '${report.successfulAuctions.length}',
              sub: 'Дууссан дуудлага',
              color: AppTheme.primary,
            ),
            _ReportStatCard(
              label: 'Амжилтгүй бараа',
              value: '${report.failedAuctions.length}',
              sub: 'Ялагчгүй / саналгүй',
              color: AppTheme.mutedForeground,
            ),
          ],
        );
      },
    );
  }
}

class _AuctionTable extends StatelessWidget {
  const _AuctionTable({required this.auctions});

  final List<AuctionModel> auctions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 72,
        columns: const [
          DataColumn(label: Text('Зураг')),
          DataColumn(label: Text('Бараа')),
          DataColumn(label: Text('Үнэ')),
          DataColumn(label: Text('Санал')),
          DataColumn(label: Text('Ялагч')),
        ],
        rows: [
          for (final a in auctions)
            DataRow(
              cells: [
                DataCell(
                  _AuctionThumb(imageUrl: a.image, title: a.title),
                ),
                DataCell(
                  SizedBox(
                    width: 160,
                    child: Text(
                      a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(formatPrice(a.finalPrice ?? a.price))),
                DataCell(Text('${a.totalBids}')),
                DataCell(Text(a.winnerName ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}

class _AuctionThumb extends StatelessWidget {
  const _AuctionThumb({required this.imageUrl, required this.title});

  final String? imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        color: AppTheme.secondary,
        child: const Icon(Icons.image_not_supported, size: 18),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        imageUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 44,
          height: 44,
          color: AppTheme.secondary,
          child: const Icon(Icons.broken_image, size: 18),
        ),
      ),
    );
  }
}

class _DataTableSection extends StatelessWidget {
  const _DataTableSection({
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        columns: [for (final c in columns) DataColumn(label: Text(c))],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                for (final cell in row) DataCell(Text(cell)),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyTableMessage extends StatelessWidget {
  const _EmptyTableMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: AppTheme.bodyStyle.copyWith(
          fontSize: 12,
          color: AppTheme.mutedForeground,
        ),
      ),
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
