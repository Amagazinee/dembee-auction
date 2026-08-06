import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/errors/app_exception.dart';
import '../firebase_options.dart';

/// Firebase Storage — дуудлагын зураг upload
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? _defaultStorage();

  final FirebaseStorage _storage;

  static FirebaseStorage _defaultStorage() {
    final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
    if (bucket == null || bucket.isEmpty) {
      return FirebaseStorage.instance;
    }
    return FirebaseStorage.instanceFor(
      app: Firebase.app(),
      bucket: bucket,
    );
  }

  Future<String> uploadAuctionImage({
    required String auctionId,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    if (bytes.isEmpty) {
      throw const FirestoreException('Зураг хоосон байна');
    }

    final ext = extension.toLowerCase().replaceAll('.', '');
    final safeExt = ext == 'png' ? 'png' : 'jpg';
    final contentType = safeExt == 'png' ? 'image/png' : 'image/jpeg';
    final ref = _storage.ref().child('auctions/$auctionId/cover.$safeExt');
    final metadata = SettableMetadata(contentType: contentType);

    try {
      final snapshot = await ref.putData(bytes, metadata);
      if (snapshot.state != TaskState.success) {
        throw const FirestoreException(
          'Зураг upload хийхэд алдаа: файл хадгалагдаагүй',
        );
      }
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw FirestoreException(_mapStorageError(e));
    }
  }

  String _mapStorageError(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'Зураг upload хийх эрхгүй. Админ эрх болон Storage дүрмийг шалгана уу.';
      case 'object-not-found':
        return 'Зураг upload хийхэд алдаа: Storage тохиргоо буруу эсвэл дүрэм deploy хийгдээгүй. '
            'firebase deploy --only storage ажиллуулна уу.';
      case 'canceled':
        return 'Зураг upload цуцлагдлаа';
      default:
        return 'Зураг upload хийхэд алдаа: ${e.message ?? e.code}';
    }
  }
}
