export interface BidPackageConfig {
  id: string;
  amount: number;
  price: number;
}

export const BID_PACKAGES: BidPackageConfig[] = [
  { id: "pkg_10", amount: 10, price: 10000 },
  { id: "pkg_20", amount: 20, price: 18000 },
  { id: "pkg_40", amount: 40, price: 30000 },
  { id: "pkg_60", amount: 60, price: 45000 },
  { id: "pkg_100", amount: 100, price: 65000 },
  { id: "pkg_200", amount: 200, price: 110000 },
];

export function getPackageById(packageId: string): BidPackageConfig | undefined {
  return BID_PACKAGES.find((pkg) => pkg.id === packageId);
}
