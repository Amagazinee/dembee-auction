import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/constants/auth_constants.dart';
import '../core/errors/app_exception.dart';

/// Firebase Storage — дуудлагын зураг upload
class StorageService {
  StorageService({
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  static const _bucketCandidates = [
    '${AuthConstants.firebaseProjectId}.firebasestorage.app',
    '${AuthConstants.firebaseProjectId}.appspot.com',
  ];

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
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        throw FirestoreException(_mapFunctionsError(e));
      }
      try {
        return await _uploadDirect(
          auctionId: auctionId,
          bytes: bytes,
          extension: extension,
        );
      } on FirestoreException {
        rethrow;
      } catch (_) {
        throw FirestoreException(_mapFunctionsError(e));
      }
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
    final path = 'auctions/$auctionId/cover.$safeExt';
    final metadata = SettableMetadata(contentType: contentType);

    Object? lastError;
    for (final bucket in _bucketCandidates) {
      try {
        final ref = _storageForBucket(bucket).ref(path);
        final snapshot = await ref.putData(bytes, metadata);
        if (snapshot.state != TaskState.success) {
          throw const FirestoreException('Зураг хадгалагдаагүй');
        }
        return await snapshot.ref.getDownloadURL();
      } catch (e) {
        lastError = e;
      }
    }

    try {
      final ref = _storage.ref(path);
      final snapshot = await ref.putData(bytes, metadata);
      if (snapshot.state != TaskState.success) {
        throw const FirestoreException('Зураг хадгалагдаагүй');
      }
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw FirestoreException(_mapStorageError(e, lastError));
    }
  }

  FirebaseStorage _storageForBucket(String bucket) {
    return FirebaseStorage.instanceFor(bucket: bucket);
  }

  String _mapFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
      case 'unavailable':
        return 'Зураг upload function deploy хийгдээгүй. '
            'firebase deploy --only functions:purge,storage';
      case 'permission-denied':
        return 'Зураг upload хийх эрхгүй. Админ эрхээ шалгана уу.';
      case 'unauthenticated':
        return 'Нэвтэрсний дараа зураг upload хийнэ үү.';
      default:
        return 'Зураг upload: ${e.message ?? e.code}';
    }
  }

  String _mapStorageError(FirebaseException e, [Object? previous]) {
    switch (e.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'Зураг upload хийх эрхгүй. Админ эрх, Storage rules шалгана уу.';
      case 'object-not-found':
        return 'Storage bucket олдсонгүй. Firebase Console → Storage идэвхжүүлнэ үү.';
      case 'canceled':
        return 'Зураг upload цуцлагдлаа';
      default:
        final detail = e.message ?? e.code;
        if (previous != null) {
          return 'Зураг upload алдаа: $detail';
        }
        return 'Зураг upload алдаа: $detail';
    }
  }
}
