import 'package:dembee_app/core/admin_report.dart';
import 'package:dembee_app/models/auction_model.dart';
import 'package:dembee_app/models/bid_history_model.dart';
import 'package:dembee_app/models/purchase_model.dart';
import 'package:dembee_app/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 8, 12, 0);

  UserModel user({
    required String uid,
    DateTime? createdAt,
    bool banned = false,
  }) {
    return UserModel(
      uid: uid,
      name: 'User $uid',
      phone: '',
      email: '$uid@test.mn',
      createdAt: createdAt ?? now,
      banned: banned,
    );
  }

  PurchaseModel purchase({
    required String id,
    required int amount,
    required int bidCount,
    String status = 'completed',
    DateTime? createdAt,
  }) {
    return PurchaseModel(
      id: id,
      userUid: 'u1',
      packageId: 'pkg_10',
      bidCount: bidCount,
      amount: amount,
      paymentMethod: 'test',
      status: status,
      createdAt: createdAt ?? now,
    );
  }

  test('builds revenue summary for period', () {
    final report = AdminReportBuilder.build(
      period: ReportPeriod.all,
      users: [
        user(uid: 'u1'),
        user(uid: 'u2', banned: true),
      ],
      auctions: [
        AuctionModel(
          id: 'a1',
          title: 'Phone',
          price: 100,
          endsAt: now.add(const Duration(hours: 2)),
          status: 'active',
          totalBids: 12,
        ),
      ],
      purchases: [
        purchase(id: 'p1', amount: 10000, bidCount: 10),
        purchase(id: 'p2', amount: 30000, bidCount: 40, status: 'refunded'),
      ],
      bids: [
        BidHistoryModel(
          id: 'b1',
          auctionId: 'a1',
          userUid: 'u1',
          userName: 'User',
          amount: 1,
          priceAfter: 101,
          createdAt: now,
        ),
      ],
      usersById: {},
      generatedAt: now,
    );

    expect(report.totalUsers, 2);
    expect(report.bannedUsers, 1);
    expect(report.grossRevenue, 10000);
    expect(report.refundedAmount, 30000);
    expect(report.netRevenue, -20000);
    expect(report.bidsInPeriod, 1);
  });

  test('exports csv with header rows', () {
    final report = AdminReportBuilder.build(
      period: ReportPeriod.today,
      users: [user(uid: 'u1')],
      auctions: const [],
      purchases: [purchase(id: 'p1', amount: 5000, bidCount: 10)],
      bids: const [],
      usersById: {'u1': user(uid: 'u1')},
      generatedAt: now,
    );

    final csv = AdminReportExporter.toCsv(
      report,
      usersById: {'u1': user(uid: 'u1')},
    );

    expect(csv, contains('ДЭМБЭЭ Админ тайлан'));
    expect(csv, contains('Цэвэр орлого (₮),5000'));
  });
}
