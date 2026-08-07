import '../models/auction_model.dart';
import '../models/bid_history_model.dart';
import '../models/purchase_model.dart';
import '../models/user_model.dart';
import 'utils/formatters.dart';

enum ReportPeriod {
  today('Өнөөдөр'),
  week('7 хоног'),
  month('30 хоног'),
  all('Бүгд'),
  custom('Сонгосон хугацаа');

  const ReportPeriod(this.label);
  final String label;
}

class ReportFilter {
  const ReportFilter({
    required this.label,
    this.start,
    this.end,
  });

  final String label;
  final DateTime? start;
  final DateTime? end;

  factory ReportFilter.fromPeriod(ReportPeriod period, {DateTime? now}) {
    final anchor = now ?? DateTime.now();
    return switch (period) {
      ReportPeriod.today => ReportFilter(
          label: period.label,
          start: DateTime(anchor.year, anchor.month, anchor.day),
          end: DateTime(anchor.year, anchor.month, anchor.day, 23, 59, 59),
        ),
      ReportPeriod.week => ReportFilter(
          label: period.label,
          start: anchor.subtract(const Duration(days: 7)),
          end: anchor,
        ),
      ReportPeriod.month => ReportFilter(
          label: period.label,
          start: anchor.subtract(const Duration(days: 30)),
          end: anchor,
        ),
      ReportPeriod.all => ReportFilter(label: period.label),
      ReportPeriod.custom => ReportFilter(label: period.label),
    };
  }

  factory ReportFilter.customRange({
    required DateTime start,
    required DateTime end,
    String? label,
  }) {
    final normalizedStart =
        DateTime(start.year, start.month, start.day);
    final normalizedEnd =
        DateTime(end.year, end.month, end.day, 23, 59, 59);
    return ReportFilter(
      label: label ??
          '${formatDate(normalizedStart)} – ${formatDate(normalizedEnd)}',
      start: normalizedStart,
      end: normalizedEnd,
    );
  }

  bool contains(DateTime dateTime) {
    if (start != null && dateTime.isBefore(start!)) return false;
    if (end != null && dateTime.isAfter(end!)) return false;
    return true;
  }
}

class AdminReportData {
  const AdminReportData({
    required this.filter,
    required this.generatedAt,
    required this.totalUsers,
    required this.newUsers,
    required this.bannedUsers,
    required this.activeAuctions,
    required this.scheduledAuctions,
    required this.finishedAuctions,
    required this.totalBidsAllTime,
    required this.bidsInPeriod,
    required this.completedPurchases,
    required this.refundedPurchases,
    required this.grossRevenue,
    required this.refundedAmount,
    required this.netRevenue,
    required this.bidsSold,
    required this.phaseCounts,
    required this.packageSales,
    required this.newUsersList,
    required this.refundsList,
    required this.successfulAuctions,
    required this.failedAuctions,
    required this.recentPurchases,
  });

  final ReportFilter filter;
  final DateTime generatedAt;
  final int totalUsers;
  final int newUsers;
  final int bannedUsers;
  final int activeAuctions;
  final int scheduledAuctions;
  final int finishedAuctions;
  final int totalBidsAllTime;
  final int bidsInPeriod;
  final int completedPurchases;
  final int refundedPurchases;
  final int grossRevenue;
  final int refundedAmount;
  final int netRevenue;
  final int bidsSold;
  final List<int> phaseCounts;
  final Map<String, int> packageSales;
  final List<UserModel> newUsersList;
  final List<PurchaseModel> refundsList;
  final List<AuctionModel> successfulAuctions;
  final List<AuctionModel> failedAuctions;
  final List<PurchaseModel> recentPurchases;

  String get periodLabel => filter.label;
}

class AdminReportBuilder {
  AdminReportBuilder._();

  static DateTime _auctionEndTime(AuctionModel auction) =>
      auction.updatedAt ?? auction.endsAt;

  static bool _auctionFinishedInPeriod(AuctionModel auction, ReportFilter filter) {
    if (!auction.isFinished) return false;
    return filter.contains(_auctionEndTime(auction));
  }

  static bool _auctionSucceeded(AuctionModel auction) =>
      auction.isClosed &&
      auction.winnerUid != null &&
      auction.winnerUid!.isNotEmpty;

  static bool _auctionFailed(AuctionModel auction) =>
      auction.isFinished && !_auctionSucceeded(auction);

  static AdminReportData build({
    required ReportFilter filter,
    required List<UserModel> users,
    required List<AuctionModel> auctions,
    required List<PurchaseModel> purchases,
    required List<BidHistoryModel> bids,
    required Map<String, UserModel> usersById,
    DateTime? generatedAt,
  }) {
    final now = generatedAt ?? DateTime.now();
    final newUsersList =
        users.where((u) => filter.contains(u.createdAt)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final bannedUsers = users.where((u) => u.isBanned).length;

    final activeAuctions = auctions.where((a) => a.isOngoing).length;
    final scheduledAuctions =
        auctions.where((a) => a.isScheduled(now)).length;
    final finishedAuctions = auctions.where((a) => a.isFinished).length;
    final totalBidsAllTime =
        auctions.fold<int>(0, (sum, a) => sum + a.totalBids);

    final bidsInPeriod =
        bids.where((b) => filter.contains(b.createdAt)).length;

    final periodPurchases =
        purchases.where((p) => filter.contains(p.createdAt)).toList();
    final completed =
        periodPurchases.where((p) => p.isCompleted).toList();
    final refundsList = purchases
        .where((p) {
          if (!p.isRefunded) return false;
          final refundedAt = p.refundedAt ?? p.createdAt;
          return filter.contains(refundedAt);
        })
        .toList()
      ..sort((a, b) {
        final aTime = a.refundedAt ?? a.createdAt;
        final bTime = b.refundedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

    final grossRevenue =
        completed.fold<int>(0, (sum, p) => sum + p.amount);
    final refundedAmount =
        refundsList.fold<int>(0, (sum, p) => sum + p.amount);
    final bidsSold = completed.fold<int>(0, (sum, p) => sum + p.bidCount);

    final packageSales = <String, int>{};
    for (final p in completed) {
      packageSales[p.packageLabel] =
          (packageSales[p.packageLabel] ?? 0) + 1;
    }

    final phaseCounts = List.filled(8, 0);
    for (final auction in auctions.where((a) => a.isOngoing)) {
      final index = auction.currentPhase.clamp(1, 8) - 1;
      phaseCounts[index]++;
    }

    final finishedInPeriod =
        auctions.where((a) => _auctionFinishedInPeriod(a, filter)).toList();
    final successfulAuctions = finishedInPeriod
        .where(_auctionSucceeded)
        .toList()
      ..sort((a, b) => _auctionEndTime(b).compareTo(_auctionEndTime(a)));
    final failedAuctions = finishedInPeriod
        .where(_auctionFailed)
        .toList()
      ..sort((a, b) => _auctionEndTime(b).compareTo(_auctionEndTime(a)));

    final recentPurchases = [...periodPurchases]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return AdminReportData(
      filter: filter,
      generatedAt: now,
      totalUsers: users.length,
      newUsers: newUsersList.length,
      bannedUsers: bannedUsers,
      activeAuctions: activeAuctions,
      scheduledAuctions: scheduledAuctions,
      finishedAuctions: finishedAuctions,
      totalBidsAllTime: totalBidsAllTime,
      bidsInPeriod: bidsInPeriod,
      completedPurchases: completed.length,
      refundedPurchases: refundsList.length,
      grossRevenue: grossRevenue,
      refundedAmount: refundedAmount,
      netRevenue: grossRevenue - refundedAmount,
      bidsSold: bidsSold,
      phaseCounts: phaseCounts,
      packageSales: packageSales,
      newUsersList: newUsersList,
      refundsList: refundsList,
      successfulAuctions: successfulAuctions,
      failedAuctions: failedAuctions,
      recentPurchases: recentPurchases,
    );
  }
}

class AdminReportExporter {
  AdminReportExporter._();

  static String toReadableText(
    AdminReportData report, {
    required Map<String, UserModel> usersById,
  }) {
    final buffer = StringBuffer()
      ..writeln('ДЭМБЭЭ — АДМИН ТАЙЛАН')
      ..writeln('Хугацаа: ${report.periodLabel}')
      ..writeln('Үүсгэсэн: ${formatDateTime(report.generatedAt)}')
      ..writeln('')
      ..writeln('=== ОРЛОГО ===')
      ..writeln('Нийт орлого: ${formatPrice(report.grossRevenue)}')
      ..writeln('Буцаалт: ${formatPrice(report.refundedAmount)}')
      ..writeln('Цэвэр орлого: ${formatPrice(report.netRevenue)}')
      ..writeln('Борлуулсан санал: ${formatNumber(report.bidsSold)}')
      ..writeln('Амжилттай гүйлгээ: ${report.completedPurchases}')
      ..writeln('')
      ..writeln('=== ХЭРЭГЛЭГЧ ===')
      ..writeln('Шинэ бүртгэл: ${report.newUsers}')
      ..writeln('Нийт хэрэглэгч: ${report.totalUsers}');

    if (report.packageSales.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('=== БАГЦ БОРЛУУЛАЛТ ===');
      final sorted = report.packageSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted) {
        buffer.writeln('${entry.key}: ${entry.value} удаа');
      }
    }

    if (report.successfulAuctions.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('=== АМЖИЛТТАЙ ДУУССАН БАРАА ===');
      for (final a in report.successfulAuctions) {
        buffer.writeln(
          '${a.title} | ${formatPrice(a.finalPrice ?? a.price)} | '
          '${a.winnerName ?? ''} | ${a.image ?? ''}',
        );
      }
    }

    if (report.failedAuctions.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('=== АМЖИЛТГҮЙ ДУУССАН БАРАА ===');
      for (final a in report.failedAuctions) {
        buffer.writeln(
          '${a.title} | ${formatPrice(a.finalPrice ?? a.price)} | '
          'Санал: ${a.totalBids} | ${a.image ?? ''}',
        );
      }
    }

    if (report.refundsList.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('=== БУЦААЛТ ===');
      for (final p in report.refundsList) {
        final user = usersById[p.userUid];
        final name = user?.name.isNotEmpty == true ? user!.name : p.userUid;
        buffer.writeln(
          '${formatDateTime(p.refundedAt ?? p.createdAt)} | $name | '
          '${p.packageLabel} | ${formatPrice(p.amount)}',
        );
      }
    }

    return buffer.toString();
  }

  static String toCsv(
    AdminReportData report, {
    required Map<String, UserModel> usersById,
  }) {
    final rows = <List<String>>[
      ['ДЭМБЭЭ Админ тайлан'],
      ['Хугацаа', report.periodLabel],
      ['Үүсгэсэн', formatDateTime(report.generatedAt)],
      [],
      ['Үзүүлэлт', 'Утга'],
      ['Нийт орлого (₮)', '${report.grossRevenue}'],
      ['Буцаалт (₮)', '${report.refundedAmount}'],
      ['Цэвэр орлого (₮)', '${report.netRevenue}'],
      ['Борлуулсан санал', '${report.bidsSold}'],
      ['Шинэ хэрэглэгч', '${report.newUsers}'],
      ['Амжилттай гүйлгээ', '${report.completedPurchases}'],
      ['Буцаагдсан гүйлгээ', '${report.refundedPurchases}'],
    ];

    if (report.packageSales.isNotEmpty) {
      rows.addAll([[], ['Багц', 'Тоо']]);
      final sorted = report.packageSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted) {
        rows.add([entry.key, '${entry.value}']);
      }
    }

    if (report.newUsersList.isNotEmpty) {
      rows.addAll([[], ['Шинэ хэрэглэгч', 'Имэйл', 'Утас', 'Огноо']]);
      for (final u in report.newUsersList) {
        rows.add([
          _csvEscape(u.name),
          _csvEscape(u.email),
          _csvEscape(u.phone),
          formatDateTime(u.createdAt),
        ]);
      }
    }

    if (report.successfulAuctions.isNotEmpty) {
      rows.addAll([
        [],
        ['Амжилттай бараа', 'Үнэ (₮)', 'Ялагч', 'Санал', 'Зураг URL'],
      ]);
      for (final a in report.successfulAuctions) {
        rows.add([
          _csvEscape(a.title),
          '${a.finalPrice ?? a.price}',
          _csvEscape(a.winnerName ?? ''),
          '${a.totalBids}',
          _csvEscape(a.image ?? ''),
        ]);
      }
    }

    if (report.failedAuctions.isNotEmpty) {
      rows.addAll([
        [],
        ['Амжилтгүй бараа', 'Үнэ (₮)', 'Санал', 'Зураг URL'],
      ]);
      for (final a in report.failedAuctions) {
        rows.add([
          _csvEscape(a.title),
          '${a.finalPrice ?? a.price}',
          '${a.totalBids}',
          _csvEscape(a.image ?? ''),
        ]);
      }
    }

    if (report.refundsList.isNotEmpty) {
      rows.addAll([
        [],
        ['Буцаалтын огноо', 'Хэрэглэгч', 'Багц', 'Дүн (₮)'],
      ]);
      for (final p in report.refundsList) {
        final user = usersById[p.userUid];
        final name = user?.name.isNotEmpty == true ? user!.name : p.userUid;
        rows.add([
          formatDateTime(p.refundedAt ?? p.createdAt),
          _csvEscape(name),
          _csvEscape(p.packageLabel),
          '${p.amount}',
        ]);
      }
    }

    if (report.recentPurchases.isNotEmpty) {
      rows.addAll([
        [],
        ['Огноо', 'Хэрэглэгч', 'Санал', 'Дүн (₮)', 'Төлбөр', 'Төлөв'],
      ]);
      for (final p in report.recentPurchases) {
        final user = usersById[p.userUid];
        final name = user?.name.isNotEmpty == true ? user!.name : p.userUid;
        rows.add([
          formatDateTime(p.createdAt),
          _csvEscape(name),
          '${p.bidCount}',
          '${p.amount}',
          p.paymentLabel,
          p.statusLabel,
        ]);
      }
    }

    return rows.map(_rowToCsv).join('\n');
  }

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _rowToCsv(List<String> cells) => cells.join(',');
}
