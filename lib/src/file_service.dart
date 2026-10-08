import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:xournalpp/src/XppFile.dart';
import 'package:xournalpp/src/conditional/download/download.dart';
import 'package:xournalpp/src/conditional/file_storage/file_storage.dart';

/// File name suffix used for every notebook written by this app.
const String kXoppFileExtension = 'xopp';

/// Thrown when a picker dialog is dismissed without selecting a file.
class FileSelectionCanceledException implements Exception {
  @override
  String toString() => 'File selection canceled';
}

/// Platform-agnostic save/open helpers for `.xopp` notebooks.
///
/// Android and desktop read and write real files with `dart:io`; the "save
/// as" flow goes through the SAF-capable `file_picker` save dialog. On the
/// web, documents persist in browser storage (IndexedDB) and "save as"
/// downloads the `.xopp` file to the user's device.
class FileService {
  /// Writes the [file] bytes and returns the saved path for the recent files
  /// list.
  ///
  /// [existingPath] is the path the document was opened from. When it still
  /// exists, the save overwrites it in place; otherwise the document lands in
  /// the application documents directory as `<title>.xopp`. On the web the
  /// bytes go into browser storage under the document title, so the notebook
  /// survives a reload and can be reopened from the recent list.
  static Future<String> saveXopp(XppFile file, {String? existingPath}) async {
    final Uint8List bytes = file.toUint8List()!;
    final String fileName = _xoppFileName(file);
    if (kIsWeb) {
      final String storageName = _storageNameFor(file, existingPath, fileName);
      await saveToBrowserStorage(storageName, bytes);
      return '/xournalpp/$storageName';
    }
    // Overwrite in place only when the document came from a real `.xopp`
    // file that is still present. Anything else falls back to the
    // application documents directory.
    String targetPath = existingPath ?? '';
    if (!targetPath.endsWith('.$kXoppFileExtension') ||
        !File(targetPath).existsSync()) {
      final Directory documents = await getApplicationDocumentsDirectory();
      targetPath = '${documents.path}/$fileName';
    }
    final File target = File(targetPath);
    await target.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);
    return targetPath;
  }

  /// Opens the "save as" dialog and writes the [file] bytes to the chosen
  /// location. Returns the selected path, or null when the dialog was
  /// canceled.
  ///
  /// On the web this triggers a browser download of `<title>.xopp` and
  /// returns the file name.
  static Future<String?> exportXoppAs(XppFile file) async {
    final Uint8List bytes = file.toUint8List()!;
    final String fileName = _xoppFileName(file);
    if (kIsWeb) {
      return downloadFile(fileName, bytes);
    }
    // `.xopp` maps to no known MIME type on Android/iOS, so the plugin
    // rejects `FileType.custom` with that extension. The generic type keeps
    // the SAF "create document" dialog working there; desktop dialogs filter
    // by extension natively.
    final bool filterByExtension = !(Platform.isAndroid || Platform.isIOS);
    final String? path = await FilePicker.platform.saveFile(
      fileName: fileName,
      type: filterByExtension ? FileType.custom : FileType.any,
      allowedExtensions:
          filterByExtension ? const [kXoppFileExtension] : null,
      bytes: bytes,
    );
    if (path != null) {
      // On Android the save dialog may return a content URI that the plain
      // File API cannot write, and file_picker's own bytes argument is not
      // persisted on every platform. Write defensively when a real path is
      // available.
      try {
        final File target = File(path);
        await target.create(recursive: true);
        await target.writeAsBytes(bytes, flush: true);
      } catch (_) {
        // Keep the returned path; the picker already handled the content.
      }
    }
    return path;
  }

  /// Shows the open dialog filtered to `.xopp` files and wraps the result in
  /// a [FilePickerCross] so the existing parse path keeps working.
  ///
  /// Returns null when the user cancels the dialog; callers treat that as a
  /// silent no-op instead of an error.
  static Future<FilePickerCross?> pickXopp() async {
    if (kIsWeb) {
      try {
        return await FilePickerCross.importFromStorage(
            type: FileTypeCross.custom, fileExtension: kXoppFileExtension);
      } on FileSelectionCanceledError {
        return null;
      }
    }
    final bool filterByExtension = !(Platform.isAndroid || Platform.isIOS);
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      // `.xopp` has no MIME type registered on Android/iOS, so the SAF
      // `FileType.custom` filter is rejected by the plugin and the dialog
      // never opens ("Unsupported filter"). Pick any file there and validate
      // the extension below; desktop pickers filter natively by extension.
      type: filterByExtension ? FileType.custom : FileType.any,
      allowedExtensions:
          filterByExtension ? const [kXoppFileExtension] : null,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final PlatformFile picked = result.files.single;
    final String fileName = (picked.name).toLowerCase();
    if (filterByExtension && !fileName.endsWith('.$kXoppFileExtension')) {
      throw FileSelectionCanceledException();
    }
    final Uint8List bytes = picked.bytes ??
        (picked.path != null ? await File(picked.path!).readAsBytes() : null)!;
    return FilePickerCross(bytes,
        path: picked.path,
        type: FileTypeCross.custom,
        fileExtension: kXoppFileExtension);
  }

  /// Reads a document back from browser storage (web) or the
  /// app-internal fake filesystem / documents directory (IO), which is
  /// where [saveXopp] stores documents. The returned [FilePickerCross]
  /// carries the original path so parsing extracts the document title.
  ///
  /// Throws [StateError] when no data is stored under [path].
  static Future<FilePickerCross> pickInternal(String path) async {
    if (kIsWeb) {
      final String storageName = path.split('/').last;
      final Uint8List bytes = await loadFromBrowserStorage(storageName);
      return FilePickerCross(bytes,
          path: path,
          type: FileTypeCross.custom,
          fileExtension: kXoppFileExtension);
    }
    final String fileName = path.split('/').last;
    final Directory documents = await getApplicationDocumentsDirectory();
    return FilePickerCross(await File('${documents.path}/$fileName')
            .readAsBytes(),
        path: path,
        type: FileTypeCross.custom,
        fileExtension: kXoppFileExtension);
  }

  /// Lists the documents persisted in browser storage (web only), most
  /// recent first. Returns an empty list on IO platforms.
  static Future<List<StoredFileInfo>> listBrowserStoredFiles() async {
    if (!kIsWeb) return [];
    return listBrowserStorage();
  }

  /// Deletes the document stored under [storagePath] from browser storage
  /// (web only). No-op on IO platforms.
  static Future<void> deleteBrowserStoredFile(String storagePath) async {
    if (!kIsWeb) return;
    await deleteFromBrowserStorage(storagePath.split('/').last);
  }

  /// Storage key for a web save: keeps the previously used name when the
  /// document was opened from browser storage so in-place saves replace the
  /// same record.
  static String _storageNameFor(XppFile file, String? existingPath,
      String fallbackName) {
    if (existingPath != null && existingPath.startsWith('/xournalpp/')) {
      return existingPath.substring('/xournalpp/'.length);
    }
    return fallbackName;
  }

  /// File name for a document, falling back to a generic name when untitled.
  static String _xoppFileName(XppFile file) {
    final String title = (file.title ?? 'notebook').trim();
    final String sanitized = title.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    return '$sanitized.$kXoppFileExtension';
  }
}
