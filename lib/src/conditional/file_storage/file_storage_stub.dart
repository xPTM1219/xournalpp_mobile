import 'dart:typed_data';

import 'file_storage.dart';

/// IO fallback: browser storage only exists on the web, so every call is a
/// no-op that reports an empty store.
Future<void> saveToBrowserStorageImpl(String name, Uint8List bytes) async {}

Future<Uint8List> loadFromBrowserStorageImpl(String name) async {
  throw StateError('No document stored under "$name"');
}

Future<List<StoredFileInfo>> listBrowserStorageImpl() async => [];

Future<void> deleteFromBrowserStorageImpl(String name) async {}
