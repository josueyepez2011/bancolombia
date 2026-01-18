import 'dart:typed_data';

/// Stub implementation - this file is used for conditional imports
class DownloadHelper {
  Future<void> downloadImage(Uint8List bytes, String filename) async {
    throw UnsupportedError('Platform not supported');
  }
}

DownloadHelper getDownloadHelper() => DownloadHelper();
