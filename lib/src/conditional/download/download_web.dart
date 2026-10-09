import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web implementation: builds an object URL from the bytes and starts a
/// download of [fileName] through a temporary anchor element.
Future<String?> downloadFileImpl(String fileName, Uint8List bytes) async {
  final web.Blob blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement anchor = web.document.createElement('a')
      as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  // The download starts immediately; report the target name like a save path.
  return fileName;
}