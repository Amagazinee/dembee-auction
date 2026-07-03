/// Firestore талбарын нэрүүд — нэг газар төвлөрүүлсэн
class FirestoreFields {
  FirestoreFields._();

  // users
  static const String name = 'name';
  static const String phone = 'phone';
  static const String email = 'email';
  static const String createdAt = 'createdAt';
  static const String role = 'role';
  static const String bidBalance = 'bidBalance';

  // auctions
  static const String title = 'title';
  static const String price = 'price';
  static const String endsAt = 'endsAt';
  static const String status = 'status';
  static const String lastBidder = 'lastBidder';
  static const String lastBidUid = 'lastBidUid';
  static const String lastBidAmount = 'lastBidAmount';
  static const String updatedAt = 'updatedAt';
  static const String winnerUid = 'winnerUid';
  static const String winnerName = 'winnerName';
  static const String finalPrice = 'finalPrice';

  // auctionHistory
  static const String auctionId = 'auctionId';
  static const String userUid = 'userUid';
  static const String userName = 'userName';
  static const String amount = 'amount';

  // purchases
  static const String packageId = 'packageId';
  static const String bidCount = 'bidCount';
  static const String paymentMethod = 'paymentMethod';
  static const String purchaseStatus = 'status';
}
