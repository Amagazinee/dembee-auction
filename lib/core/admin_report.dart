import '../models/auction_model.dart';
import '../models/bid_history_model.dart';
import '../models/purchase_model.dart';
import '../models/user_model.dart';
import 'utils/formatters.dart';

enum ReportPeriod {
  today('Өнөөдөр'),
  week('7 хоног'),
  month('30 хоног'),
  all('Бүгд');

  const ReportPeriod(this.label);
  final String label;

  DateTime? get start {
    final now = DateTime.now();
    return switch (this) {
      ReportPeriod.today => DateTime(now.year, now.month, now.day),
      ReportPeriod.week => now.subtract(const Duration(days: 7)),
      ReportPeriod.month => now.subtract(const Duration(days: 30)),
      ReportPeriod.all => null,
    };
  }
}

class AdminReportData {
  const AdminReportData({
    required this.period,
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
    required this.recentPurchases,
    required this.recentAuctions,
  });

  final ReportPeriod period;
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
  final List<PurchaseModel> recentPurchases;
  final List<AuctionModel> recentAuctions;
}

class AdminReportBuilder {
  AdminReportBuilder._();

  static bool _inPeriod(DateTime dt, ReportPeriod period) {
    final start = period.start;
    if (start == null) return true;
    return !dt.isBefore(start);
  }

  static AdminReportData build({
    required ReportPeriod period,
    required List<UserModel> users,
    required List<AuctionModel> auctions,
    required List<PurchaseModel> purchases,
    required List<BidHistoryModel> bids,
    required Map<String, UserModel> usersById,
    DateTime? generatedAt,
  }) {
    final now = generatedAt ?? DateTime.now();
    final newUsers = users.where((u) => _inPeriod(u.createdAt, period)).length;
    final bannedUsers = users.where((u) => u.isBanned).length;

    final activeAuctions = auctions.where((a) => a.isOngoing).length;
    final scheduledAuctions =
        auctions.where((a) => a.isScheduled(now)).length;
    final finishedAuctions = auctions.where((a) => a.isFinished).length;
    final totalBidsAllTime =
        auctions.fold<int>(0, (sum, a) => sum + a.totalBids);

    final bidsInPeriod =
        bids.where((b) => _inPeriod(b.createdAt, period)).length;

    final periodPurchases =
        purchases.where((p) => _inPeriod(p.createdAt, period)).toList();
    final completed =
        periodPurchases.where((p) => p.isCompleted).toList();
    final refunded =
        periodPurchases.where((p) => p.isRefunded).toList();

    final grossRevenue =
        completed.fold<int>(0, (sum, p) => sum + p.amount);
    final refundedAmount =
        refunded.fold<int>(0, (sum, p) => sum + p.amount);
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

    final recentPurchases = [...periodPurchases]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recentAuctions = [...auctions]
      ..sort((a, b) {
        final aTime = a.updatedAt ?? a.endsAt;
        final bTime = b.updatedAt ?? b.endsAt;
        return bTime.compareTo(aTime);
      });

    return AdminReportData(
      period: period,
      generatedAt: now,
      totalUsers: users.length,
      newUsers: newUsers,
      bannedUsers: bannedUsers,
      activeAuctions: activeAuctions,
      scheduledAuctions: scheduledAuctions,
      finishedAuctions: finishedAuctions,
      totalBidsAllTime: totalBidsAllTime,
      bidsInPeriod: bidsInPeriod,
      completedPurchases: completed.length,
      refundedPurchases: refunded.length,
      grossRevenue: grossRevenue,
      refundedAmount: refundedAmount,
      netRevenue: grossRevenue - refundedAmount,
      bidsSold: bidsSold,
      phaseCounts: phaseCounts,
      packageSales: packageSales,
      recentPurchases: recentPurchases.take(20).toList(),
      recentAuctions: recentAuctions.take(15).toList(),
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
      ..writeln('Хугацаа: ${report.period.label}')
      ..writeln('Үүсгэсэн: ${formatDateTime(report.generatedAt)}')
      ..writeln('')
      ..writeln('=== ХЭРЭГЛЭГЧ ===')
      ..writeln('Нийт хэрэглэгч: ${report.totalUsers}')
      ..writeln('Шинэ бүртгэл (${report.period.label}): ${report.newUsers}')
      ..writeln('Хориглогдсон: ${report.bannedUsers}')
      ..writeln('')
      ..writeln('=== ДУУДЛАГА ===')
      ..writeln('Идэвхтэй: ${report.activeAuctions}')
      ..writeln('Төлөвлөгдсөн: ${report.scheduledAuctions}')
      ..writeln('Дууссан: ${report.finishedAuctions}')
      ..writeln('Нийт санал (бүх цаг): ${formatNumber(report.totalBidsAllTime)}')
      ..writeln('Санал (${report.period.label}): ${formatNumber(report.bidsInPeriod)}')
      ..writeln('')
      ..writeln('=== ОРЛОГО ===')
      ..writeln('Амжилттай гүйлгээ: ${report.completedPurchases}')
      ..writeln('Буцаагдсан: ${report.refundedPurchases}')
      ..writeln('Борлуулсан санал: ${formatNumber(report.bidsSold)}')
      ..writeln('Нийт орлого: ${formatPrice(report.grossRevenue)}')
      ..writeln('Буцаалтын дүн: ${formatPrice(report.refundedAmount)}')
      ..writeln('Цэвэр орлого: ${formatPrice(report.netRevenue)}');

    if (report.packageSales.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('=== БАГЦ БОРЛУУЛАЛТ ===');
      final sorted = report.packageSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted) {
        buffer.writeln('${entry.key}: ${entry.value} удаа');
      }
    }

    buffer.writeln('');
    buffer.writeln('=== ҮЕ ХУВААРИЛАЛТ (идэвхтэй) ===');
    for (var i = 0; i < report.phaseCounts.length; i++) {
      buffer.writeln('${i + 1}-р үе: ${report.phaseCounts[i]}');
    }

    if (report.recentPurchases.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('=== СҮҮЛИЙН ГҮЙЛГЭЭ ===');
      for (final p in report.recentPurchases.take(10)) {
        final user = usersById[p.userUid];
        final name = user?.name.isNotEmpty == true ? user!.name : p.userUid;
        buffer.writeln(
          '${formatDateTime(p.createdAt)} | $name | ${p.bidCount} санал | '
          '${formatPrice(p.amount)} | ${p.statusLabel}',
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
      ['Хугацаа', report.period.label],
      ['Үүсгэсэн', formatDateTime(report.generatedAt)],
      [],
      ['Үзүүлэлт', 'Утга'],
      ['Нийт хэрэглэгч', '${report.totalUsers}'],
      ['Шинэ бүртгэл', '${report.newUsers}'],
      ['Хориглогдсон', '${report.bannedUsers}'],
      ['Идэвхтэй дуудлага', '${report.activeAuctions}'],
      ['Төлөвлөгдсөн дуудлага', '${report.scheduledAuctions}'],
      ['Дууссан дуудлага', '${report.finishedAuctions}'],
      ['Нийт санал', '${report.totalBidsAllTime}'],
      ['Санал (хугацаанд)', '${report.bidsInPeriod}'],
      ['Амжилттай гүйлгээ', '${report.completedPurchases}'],
      ['Буцаагдсан гүйлгээ', '${report.refundedPurchases}'],
      ['Борлуулсан санал', '${report.bidsSold}'],
      ['Нийт орлого (₮)', '${report.grossRevenue}'],
      ['Буцаалт (₮)', '${report.refundedAmount}'],
      ['Цэвэр орлого (₮)', '${report.netRevenue}'],
    ];

    if (report.packageSales.isNotEmpty) {
      rows.addAll([[], ['Багц', 'Тоо']]);
      final sorted = report.packageSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted) {
        rows.add([entry.key, '${entry.value}']);
      }
    }

    rows.addAll([[], ['Үе', 'Идэвхтэй дуудлага']]);
    for (var i = 0; i < report.phaseCounts.length; i++) {
      rows.add(['${i + 1}-р үе', '${report.phaseCounts[i]}']);
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

    if (report.recentAuctions.isNotEmpty) {
      rows.addAll([
        [],
        ['Дуудлага', 'Төлөв', 'Үе', 'Үнэ (₮)', 'Санал', 'Ялагч'],
      ]);
      for (final a in report.recentAuctions) {
        rows.add([
          _csvEscape(a.title),
          a.status,
          '${a.currentPhase}',
          '${a.price}',
          '${a.totalBids}',
          _csvEscape(a.winnerName ?? ''),
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
