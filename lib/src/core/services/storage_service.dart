import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

/// Handles binary content (PDFs, whiteboard images) that must NOT be stored
/// in Firestore (1 MB document limit). Files go to Firebase Storage and
/// Firestore stores only the download URL + metadata.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads raw bytes to `folder/{fileName}` and returns the download URL.
  ///
  /// [bytes] is used on web/desktop where `File` may not be available.
  /// [mimeType] helps set the content type (e.g. `application/pdf`, `image/png`).
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    String mimeType = 'application/octet-stream',
  }) async {
    final ref = _storage.ref('$folder/$fileName');
    final metadata = SettableMetadata(contentType: mimeType);
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  /// Deletes a file at the given storage path (no-op if missing).
  Future<void> delete(String path) async {
    if (path.isEmpty) return;
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  /// Deletes a file by full download URL (parses the storage path out of it).
  Future<void> deleteByUrl(String downloadUrl) async {
    if (downloadUrl.isEmpty) return;
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (_) {
      // Best-effort delete; metadata removal still happens in Firestore.
    }
  }

  /// Extracts a storage path (e.g. `lessons/abc.png`) from a download URL.
  static String pathFromUrl(String downloadUrl) {
    try {
      final uri = Uri.parse(downloadUrl);
      final path = uri.path;
      final oIndex = path.indexOf('/o/');
      if (oIndex == -1) return '';
      return Uri.decodeComponent(path.substring(oIndex + 3));
    } catch (_) {
      return '';
    }
  }
}
