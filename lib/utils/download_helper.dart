import 'dart:typed_data';

/// Abstract interface for platform-specific download functionality
abstract class DownloadHelper {
  static DownloadHelper? _instance;

  static DownloadHelper get instance {
    _instance ??= _createInstance();
    return _instance!;
  }

  static DownloadHelper _createInstance() {
    throw UnsupportedError(
      'Cannot create a DownloadHelper without a platform implementation. '
      'Import download_helper_web.dart or download_helper_mobile.dart instead.',
    );
  }

  Future<void> downloadImage(Uint8List bytes, String filename);
}
