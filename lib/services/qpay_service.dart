import 'package:cloud_functions/cloud_functions.dart';

import '../core/errors/app_exception.dart';

class QPayBankLink {
  const QPayBankLink({
    required this.name,
    required this.description,
    required this.link,
  });

  final String name;
  final String description;
  final String link;

  factory QPayBankLink.fromMap(Map<String, dynamic> map) {
    return QPayBankLink(
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      link: map['link'] as String? ?? '',
    );
  }
}

class QPayPaymentSession {
  const QPayPaymentSession({
    required this.purchaseId,
    required this.invoiceId,
    required this.qrText,
    required this.qrImage,
    required this.shortUrl,
    required this.amount,
    required this.bidCount,
    required this.urls,
  });

  final String purchaseId;
  final String invoiceId;
  final String qrText;
  final String qrImage;
  final String shortUrl;
  final int amount;
  final int bidCount;
  final List<QPayBankLink> urls;

  factory QPayPaymentSession.fromMap(Map<String, dynamic> map) {
    final rawUrls = map['urls'];
    final urls = rawUrls is List
        ? rawUrls
            .whereType<Map>()
            .map((item) => QPayBankLink.fromMap(Map<String, dynamic>.from(item)))
            .where((item) => item.link.isNotEmpty)
            .toList()
        : <QPayBankLink>[];

    return QPayPaymentSession(
      purchaseId: map['purchaseId'] as String? ?? '',
      invoiceId: map['invoiceId'] as String? ?? '',
      qrText: map['qrText'] as String? ?? '',
      qrImage: map['qrImage'] as String? ?? '',
      shortUrl: map['shortUrl'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      bidCount: (map['bidCount'] as num?)?.toInt() ?? 0,
      urls: urls,
    );
  }
}

class QPayService {
  QPayService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  Future<QPayPaymentSession> createPayment(String packageId) async {
    try {
      final result = await _functions.httpsCallable('createQPayPayment').call({
        'packageId': packageId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return QPayPaymentSession.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      throw FirestoreException(e.message ?? 'QPay төлбөр үүсгэхэд алдаа');
    }
  }

  Future<String> checkPayment(String purchaseId) async {
    try {
      final result = await _functions.httpsCallable('checkQPayPayment').call({
        'purchaseId': purchaseId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return data['status'] as String? ?? 'pending';
    } on FirebaseFunctionsException catch (e) {
      throw FirestoreException(e.message ?? 'Төлбөр шалгахад алдаа');
    }
  }
}
