import 'package:flutter_test/flutter_test.dart';

import 'package:dembee_app/core/auction_display_list.dart';
import 'package:dembee_app/core/constants/app_constants.dart';
import 'package:dembee_app/models/auction_model.dart';

AuctionModel _auction({
  required String id,
  required String status,
  required DateTime endsAt,
  DateTime? startsAt,
}) {
  return AuctionModel(
    id: id,
    title: 'Test $id',
    description: 'desc',
    image: '',
    price: 1000,
    bidIncrement: 1,
    status: status,
    phase: 1,
    startsAt: startsAt ?? DateTime(2020),
    endsAt: endsAt,
  );
}

void main() {
  final now = DateTime.now();

  test('shows scheduled, ongoing, then limited finished auctions', () {
    final auctions = [
      _auction(
        id: 'scheduled',
        status: AppConstants.statusPending,
        endsAt: now.add(const Duration(days: 2)),
        startsAt: now.add(const Duration(days: 1)),
      ),
      _auction(
        id: 'ongoing',
        status: AppConstants.statusActive,
        endsAt: now.add(const Duration(hours: 2)),
        startsAt: now.subtract(const Duration(hours: 1)),
      ),
      for (var i = 0; i < 8; i++)
        _auction(
          id: 'finished-$i',
          status: AppConstants.statusClosed,
          endsAt: now.subtract(Duration(days: i + 1)),
        ),
    ];

    final display = AuctionDisplayList.fromFiltered(
      filtered: auctions,
      now: now,
      finishedVisibleCount: kFinishedAuctionsPageSize,
    );

    expect(display.scheduled.map((a) => a.id), ['scheduled']);
    expect(display.ongoing.map((a) => a.id), ['ongoing']);
    expect(display.visibleFinished.length, kFinishedAuctionsPageSize);
    expect(display.hasMoreFinished, isTrue);
    expect(display.hiddenFinishedCount, 2);
    expect(display.visible.length, 2 + kFinishedAuctionsPageSize);
  });

  test('load more reveals additional finished auctions', () {
    final auctions = [
      for (var i = 0; i < 10; i++)
        _auction(
          id: 'finished-$i',
          status: AppConstants.statusClosed,
          endsAt: now.subtract(Duration(days: i + 1)),
        ),
    ];

    final firstPage = AuctionDisplayList.fromFiltered(
      filtered: auctions,
      now: now,
      finishedVisibleCount: kFinishedAuctionsPageSize,
    );
    final secondPage = AuctionDisplayList.fromFiltered(
      filtered: auctions,
      now: now,
      finishedVisibleCount: kFinishedAuctionsPageSize * 2,
    );

    expect(firstPage.hasMoreFinished, isTrue);
    expect(secondPage.hasMoreFinished, isFalse);
    expect(secondPage.visibleFinished.length, 10);
  });
}
