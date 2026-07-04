import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../core/errors/app_exception.dart';

/// Firebase Storage — дуудлагын зураг upload
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadAuctionImage({
    required String auctionId,
    required File file,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final ref = _storage.ref().child('auctions/$auctionId/cover.$ext');

    try {
      await ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw FirestoreException('Зураг upload хийхэд алдаа: ${e.message}');
    }
  }
}
