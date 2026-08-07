import '../models/auction_model.dart';

const int kFinishedAuctionsPageSize = 6;

/// Нүүр хуудсын дуудлага жагсаалтыг төлөвөөр ангилж, дууссаныг хуудаслана.
class AuctionDisplayList {
  const AuctionDisplayList({
    required this.scheduled,
    required this.ongoing,
    required this.finished,
    required this.visibleFinished,
    required this.totalFinished,
    required this.hasMoreFinished,
    required this.hiddenFinishedCount,
  });

  final List<AuctionModel> scheduled;
  final List<AuctionModel> ongoing;
  final List<AuctionModel> finished;
  final List<AuctionModel> visibleFinished;
  final int totalFinished;
  final bool hasMoreFinished;
  final int hiddenFinishedCount;

  List<AuctionModel> get visible => [
        ...scheduled,
        ...ongoing,
        ...visibleFinished,
      ];

  static AuctionDisplayList fromFiltered({
    required List<AuctionModel> filtered,
    required DateTime now,
    int finishedVisibleCount = kFinishedAuctionsPageSize,
  }) {
    final scheduled = <AuctionModel>[];
    final ongoing = <AuctionModel>[];
    final finished = <AuctionModel>[];

    for (final auction in filtered) {
      if (auction.isScheduled(now)) {
        scheduled.add(auction);
      } else if (auction.isFinished) {
        finished.add(auction);
      } else {
        ongoing.add(auction);
      }
    }

    final clampedCount = finishedVisibleCount.clamp(0, finished.length);
    final visibleFinished = finished.take(clampedCount).toList();
    final hidden = finished.length - visibleFinished.length;

    return AuctionDisplayList(
      scheduled: scheduled,
      ongoing: ongoing,
      finished: finished,
      visibleFinished: visibleFinished,
      totalFinished: finished.length,
      hasMoreFinished: hidden > 0,
      hiddenFinishedCount: hidden,
    );
  }
}
