/// Аппын тогтмол утгууд
class AppConstants {
  AppConstants._();

  static const String appName = 'Дэмбээ';
  static const String appNameEn = 'Dembee Auction';

  /// Бүртгэл үүсэхэд автоматаар admin role өгөх имэйлүүд
  static const List<String> adminSeedEmails = [
    'admin@dembee.mn',
  ];

  static bool isAdminSeedEmail(String email) {
    return adminSeedEmails.contains(email.trim().toLowerCase());
  }

  // Firestore collection нэрүүд
  static const String usersCollection = 'users';
  static const String auctionsCollection = 'auctions';
  static const String auctionHistoryCollection = 'auctionHistory';
  static const String purchasesCollection = 'purchases';

  // Auction төлөв
  static const String statusActive = 'active';
  static const String statusClosed = 'closed';
  static const String statusPending = 'pending';

  // Bid алхмууд (₮)
  static const List<int> bidIncrements = [1, 2, 3, 4, 5];
}
