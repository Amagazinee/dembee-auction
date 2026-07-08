import '../models/auction_model.dart';

enum AuctionStatusFilter {
  all('Бүгд'),
  ongoing('Идэвхтэй'),
  scheduled('Төлөвлөгдсөн'),
  finished('Дууссан');

  const AuctionStatusFilter(this.label);
  final String label;
}

class AuctionFilter {
  const AuctionFilter({
    this.query = '',
    this.status = AuctionStatusFilter.all,
    this.category,
  });

  final String query;
  final AuctionStatusFilter status;
  final String? category;

  List<AuctionModel> apply(List<AuctionModel> auctions, DateTime now) {
    final q = query.trim().toLowerCase();
    return auctions.where((auction) {
      if (status != AuctionStatusFilter.all) {
        final matchesStatus = switch (status) {
          AuctionStatusFilter.all => true,
          AuctionStatusFilter.ongoing => auction.isOngoing,
          AuctionStatusFilter.scheduled => auction.isScheduled(now),
          AuctionStatusFilter.finished => auction.isFinished,
        };
        if (!matchesStatus) return false;
      }

      if (category != null && category!.isNotEmpty) {
        if ((auction.category ?? '').toLowerCase() != category!.toLowerCase()) {
          return false;
        }
      }

      if (q.isEmpty) return true;

      if (auction.title.toLowerCase().contains(q)) return true;
      if ((auction.description ?? '').toLowerCase().contains(q)) return true;
      if ((auction.category ?? '').toLowerCase().contains(q)) return true;
      if ((auction.lastBidder ?? '').toLowerCase().contains(q)) return true;
      if ((auction.winnerName ?? '').toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }
}
