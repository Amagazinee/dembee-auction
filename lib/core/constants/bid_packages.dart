/// Санал багц — Figma TopUpView
class BidPackage {
  const BidPackage({
    required this.id,
    required this.amount,
    required this.price,
    this.bonus = 0,
    this.popular = false,
  });

  final String id;
  final int amount;
  final int price;
  final int bonus;
  final bool popular;

  int get pricePerBid => price ~/ amount;
}

class BidPackages {
  BidPackages._();

  static const List<BidPackage> all = [
    BidPackage(id: 'pkg_10', amount: 10, price: 10000),
    BidPackage(id: 'pkg_20', amount: 20, price: 18000),
    BidPackage(
      id: 'pkg_40',
      amount: 40,
      price: 30000,
      popular: true,
    ),
    BidPackage(id: 'pkg_60', amount: 60, price: 45000),
    BidPackage(id: 'pkg_100', amount: 100, price: 65000),
    BidPackage(id: 'pkg_200', amount: 200, price: 110000),
  ];
}
