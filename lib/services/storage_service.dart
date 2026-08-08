import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import '../core/errors/app_exception.dart';

/// Firebase Storage — дуудлагын зураг upload (Cloud Function)
class StorageService {
  StorageService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  Future<String> uploadAuctionImage({
    required String auctionId,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    if (bytes.isEmpty) {
      throw const FirestoreException('Зураг хоосон байна');
    }

    try {
      final result =
          await _functions.httpsCallable('uploadAuctionImageAdmin').call({
        'auctionId': auctionId,
        'imageBase64': base64Encode(bytes),
        'extension': extension,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final url = data['downloadUrl'] as String?;
      if (url == null || url.isEmpty) {
        throw const FirestoreException('Зураг upload хийхэд алдаа гарлаа');
      }
      return url;
    } on FirebaseFunctionsException catch (e) {
      throw FirestoreException(_mapFunctionsError(e));
    }
  }

  String _mapFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
      case 'unavailable':
        return 'Зураг upload function deploy хийгдээгүй. '
            'PowerShell: firebase deploy --only functions:purge';
      case 'permission-denied':
        return 'Зураг upload хийх эрхгүй. Админ эрхээ шалгана уу.';
      case 'unauthenticated':
        return 'Нэвтэрсний дараа зураг upload хийнэ үү.';
      default:
        return e.message ?? 'Зураг upload хийхэд алдаа гарлаа';
    }
  }
}
