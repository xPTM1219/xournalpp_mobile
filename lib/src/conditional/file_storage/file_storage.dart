/// Platform dispatch for the browser-storage service.
///
/// On the web, documents persist in IndexedDB so a notebook survives a
/// browser reload. IO platforms keep using real files via `dart:io`, so the
/// stub returns empty results there.
library;

import 'dart:typed_data';

import 'file_storage_stub.dart'
    if (dart.library.html) 'file_storage_web.dart';

/// Metadata for one document kept in browser storage.
class StoredFileInfo {
  StoredFileInfo({required this.name, required this.savedAt});

  /// File name including the `.xopp` extension.
  final String name;

  /// When the document was last written.
  final DateTime savedAt;
}

/// Writes [bytes] under [name], replacing any record with the same name.
Future<void> saveToBrowserStorage(String name, Uint8List bytes) =>
    saveToBrowserStorageImpl(name, bytes);

/// Reads the document stored under [name].
///
/// Throws [StateError] when no record exists for [name].
Future<Uint8List> loadFromBrowserStorage(String name) =>
    loadFromBrowserStorageImpl(name);

/// Lists every document kept in browser storage, most recent first.
Future<List<StoredFileInfo>> listBrowserStorage() =>
    listBrowserStorageImpl();

/// Removes the document stored under [name].
Future<void> deleteFromBrowserStorage(String name) =>
    deleteFromBrowserStorageImpl(name);
