import 'dart:typed_data';

/// IO fallback: downloads are a web-only concept here.
Future<String?> downloadFileImpl(String fileName, Uint8List bytes) async =>
    null;
