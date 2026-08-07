import 'package:cloud_functions/cloud_functions.dart';

import '../core/errors/app_exception.dart';

class AdminPurgeResult {
  const AdminPurgeResult({
    required this.auctions,
    required this.auctionHistory,
    required this.purchases,
    required this.notifications,
    required this.storageFiles,
  });

  final int auctions;
  final int auctionHistory;
  final int purchases;
  final int notifications;
  final int storageFiles;

  factory AdminPurgeResult.fromMap(Map<String, dynamic> data) {
    int readInt(String key) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    return AdminPurgeResult(
      auctions: readInt('auctions'),
      auctionHistory: readInt('auctionHistory'),
      purchases: readInt('purchases'),
      notifications: readInt('notifications'),
      storageFiles: readInt('storageFiles'),
    );
  }
}

class AdminPurgeService {
  AdminPurgeService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  Future<AdminPurgeResult> purgeHistoricalData() async {
    try {
      final result = await _functions.httpsCallable('purgeHistoricalData').call({
        'confirm': true,
      });
      final data = result.data;
      if (data is! Map) {
        throw const FirestoreException('Серверийн хариу буруу байна');
      }
      return AdminPurgeResult.fromMap(Map<String, dynamic>.from(data));
    } on FirebaseFunctionsException catch (e) {
      throw FirestoreException(e.message ?? 'Түүх цэвэрлэхэд алдаа гарлаа');
    }
  }
}
