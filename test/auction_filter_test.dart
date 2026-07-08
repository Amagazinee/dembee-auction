import 'package:dembee_app/core/auction_filter.dart';
import 'package:dembee_app/models/auction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 8, 12, 0);

  AuctionModel auction({
    required String title,
    String status = 'active',
    String? category,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return AuctionModel(
      id: title,
      title: title,
      price: 100,
      endsAt: endsAt ?? now.add(const Duration(hours: 2)),
      status: status,
      category: category,
      startsAt: startsAt,
    );
  }

  test('filters by title query', () {
    final auctions = [
      auction(title: 'iPhone 15'),
      auction(title: 'Samsung TV'),
    ];

    final result = const AuctionFilter(query: 'iphone').apply(auctions, now);
    expect(result.length, 1);
    expect(result.first.title, 'iPhone 15');
  });

  test('filters by status', () {
    final auctions = [
      auction(title: 'Active', status: 'active'),
      auction(
        title: 'Scheduled',
        status: 'pending',
        startsAt: now.add(const Duration(hours: 1)),
      ),
      auction(
        title: 'Finished',
        status: 'closed',
        endsAt: now.subtract(const Duration(hours: 1)),
      ),
    ];

    final ongoing =
        const AuctionFilter(status: AuctionStatusFilter.ongoing).apply(auctions, now);
    expect(ongoing.map((a) => a.title), ['Active']);

    final scheduled = const AuctionFilter(status: AuctionStatusFilter.scheduled)
        .apply(auctions, now);
    expect(scheduled.map((a) => a.title), ['Scheduled']);

    final finished = const AuctionFilter(status: AuctionStatusFilter.finished)
        .apply(auctions, now);
    expect(finished.map((a) => a.title), ['Finished']);
  });

  test('filters by category', () {
    final auctions = [
      auction(title: 'Phone', category: 'Электроник'),
      auction(title: 'Shoes', category: 'Загвар'),
    ];

    final result = const AuctionFilter(category: 'Загвар').apply(auctions, now);
    expect(result.length, 1);
    expect(result.first.title, 'Shoes');
  });
}
