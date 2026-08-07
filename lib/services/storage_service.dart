import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/errors/app_exception.dart';
import '../firebase_options.dart';

/// Firebase Storage — дуудлагын зураг upload
class StorageService {
  StorageService({
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  })  : _storage = storage ?? _defaultStorage(),
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

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

    try {
      return await _uploadViaCloudFunction(
        auctionId: auctionId,
        bytes: bytes,
        extension: extension,
      );
    } on FirebaseFunctionsException {
      return _uploadDirect(
        auctionId: auctionId,
        bytes: bytes,
        extension: extension,
      );
    }
  }

  Future<String> _uploadViaCloudFunction({
    required String auctionId,
    required Uint8List bytes,
    required String extension,
  }) async {
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
  }

  Future<String> _uploadDirect({
    required String auctionId,
    required Uint8List bytes,
    required String extension,
  }) async {
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
        return 'Зураг upload хийх эрхгүй. Админ эрхээ шалгана уу.';
      case 'object-not-found':
        return 'Зураг upload хийхэд алдаа: Storage тохиргоо буруу. '
            'firebase deploy --only functions:uploadAuctionImageAdmin ажиллуулна уу.';
      case 'canceled':
        return 'Зураг upload цуцлагдлаа';
      default:
        return 'Зураг upload хийхэд алдаа: ${e.message ?? e.code}';
    }
  }
}
