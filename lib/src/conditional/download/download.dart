/// Platform dispatch for triggering a browser download.
///
/// On the web, `file_picker`'s `saveFile` with bytes produces a download of
/// `<fileName>`. IO platforms never download, so the stub returns null.
library;

import 'dart:typed_data';

import 'download_stub.dart' if (dart.library.html) 'download_web.dart';

/// Triggers a browser download of [bytes] as [fileName].
///
/// Returns the file name on success, or null when the platform does not
/// support downloads.
Future<String?> downloadFile(String fileName, Uint8List bytes) =>
    downloadFileImpl(fileName, bytes);
