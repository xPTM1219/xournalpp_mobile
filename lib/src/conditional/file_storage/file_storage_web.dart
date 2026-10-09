import 'dart:typed_data';

import 'package:sembast_web/sembast_web.dart';

import 'file_storage.dart';

/// IndexedDB-backed implementation of the browser-storage service.
///
/// Documents live in the `files` object store keyed by file name; each
/// record holds `{name, bytes, savedAt}`. Same-name writes replace the
/// record, which mirrors the in-place overwrite on IO platforms.

const String _kDbName = 'xournalpp_mobile';
const String _kStoreName = 'files';

Database? _database;

/// Opens (and memoizes) the IndexedDB database used for notebook storage.
Future<Database> _openDatabase() async {
  _database ??= await databaseFactoryWeb.openDatabase(_kDbName);
  return _database!;
}

Future<void> saveToBrowserStorageImpl(String name, Uint8List bytes) async {
  final Database db = await _openDatabase();
  final StoreRef store = stringMapStoreFactory.store(_kStoreName);
  await store.record(name).put(db, {
    'name': name,
    'bytes': bytes,
    'savedAt': DateTime.now().toIso8601String(),
  });
}

Future<Uint8List> loadFromBrowserStorageImpl(String name) async {
  final Database db = await _openDatabase();
  final StoreRef store = stringMapStoreFactory.store(_kStoreName);
  final RecordSnapshot? snapshot = await store.record(name).getSnapshot(db);
  if (snapshot == null || snapshot.value is! Map) {
    throw StateError('No document stored under "$name"');
  }
  // Sembast serializes byte arrays to plain lists in JSON, so a cast to
  // Uint8List fails after a reload. Convert the dynamic elements back into
  // a typed view.
  final Object? raw = (snapshot.value as Map)['bytes'];
  if (raw is! List) {
    throw StateError('Stored document "$name" has no readable bytes');
  }
  return Uint8List.fromList(raw.map((Object? e) => (e as num).toInt()).toList());
}

Future<List<StoredFileInfo>> listBrowserStorageImpl() async {
  final Database db = await _openDatabase();
  final StoreRef store = stringMapStoreFactory.store(_kStoreName);
  final List<RecordSnapshot> snapshots = await store.find(db);
  final List<StoredFileInfo> files = snapshots.map((RecordSnapshot snapshot) {
    final Map<dynamic, dynamic> value =
        snapshot.value as Map<dynamic, dynamic>;
    return StoredFileInfo(
      name: value['name'] as String,
      savedAt: DateTime.parse(value['savedAt'] as String),
    );
  }).toList();
  // Most recently saved document first.
  files.sort((a, b) => b.savedAt.compareTo(a.savedAt));
  return files;
}

Future<void> deleteFromBrowserStorageImpl(String name) async {
  final Database db = await _openDatabase();
  final StoreRef store = stringMapStoreFactory.store(_kStoreName);
  await store.record(name).delete(db);
}
