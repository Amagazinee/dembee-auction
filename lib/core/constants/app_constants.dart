/// Аппын тогтмол утгууд
class AppConstants {
  AppConstants._();

  static const String appName = 'Дэмбээ';
  static const String appNameEn = 'Dembee Auction';

  // Firestore collection нэрүүд
  static const String usersCollection = 'users';
  static const String auctionsCollection = 'auctions';
  static const String auctionHistoryCollection = 'auctionHistory';

  // Auction төлөв
  static const String statusActive = 'active';
  static const String statusClosed = 'closed';
  static const String statusPending = 'pending';

  // Bid алхмууд (₮)
  static const List<int> bidIncrements = [1, 2, 3, 4, 5];
}
