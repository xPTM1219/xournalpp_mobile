import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:xournalpp/layer_contents/XppStroke.dart';
import 'package:xournalpp/src/XppBackground.dart';
import 'package:xournalpp/src/XppFile.dart';
import 'package:xournalpp/src/XppLayer.dart';
import 'package:xournalpp/src/XppPage.dart';
import 'package:xournalpp/src/file_service.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String documentsPath;
  _FakePathProvider(this.documentsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_service_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  XppFile buildFixture({String? title}) {
    final XppPageSize size = XppPageSize(width: 595.0, height: 842.0);
    return XppFile(
      title: title,
      previewImage: Uint8List.fromList([1, 2, 3]),
      pages: [
        XppPage(
          pageSize: size,
          background:
              XppBackgroundSolidPlain(color: Colors.white, size: size),
          layers: [
            XppLayer(content: [
              XppStroke.byTool(
                tool: XppStrokeTool.PEN,
                color: Colors.red,
                points: [
                  XppStrokePoint(x: 10.0, y: 20.0, width: 2.0),
                  XppStrokePoint(x: 30.0, y: 40.0, width: 2.0),
                ],
              )
            ])
          ],
        ),
      ],
    );
  }

  test('saveXopp writes to the documents directory for a new file',
      () async {
    final XppFile file = buildFixture(title: 'my notebook');
    final String path = await FileService.saveXopp(file);

    expect(path, '${tempDir.path}/my notebook.xopp');
    final bytes = await File(path).readAsBytes();
    expect(bytes[0], 0x1f);
    expect(bytes[1], 0x8b);
    final xml = utf8.decode(GZipCodec().decode(bytes));
    expect(xml, contains('<xournal'));
    expect(xml, contains('tool="pen"'));
  });

  test('saveXopp overwrites an existing opened path in place', () async {
    final File existing = File('${tempDir.path}/opened.xopp');
    await existing.writeAsBytes(Uint8List.fromList([9, 9, 9]));

    final XppFile file = buildFixture(title: 'opened');
    final String path =
        await FileService.saveXopp(file, existingPath: existing.path);

    expect(path, existing.path);
    final bytes = await existing.readAsBytes();
    expect(bytes[0], 0x1f);
  });

  test('saveXopp falls back when the existing path is gone', () async {
    final XppFile file = buildFixture(title: 'vanished');
    final String path = await FileService.saveXopp(
        file,
        existingPath:
            '${tempDir.path}/no-longer-there.xopp');

    expect(path, '${tempDir.path}/vanished.xopp');
    expect(File(path).existsSync(), isTrue);
  });

  test('saveXopp sanitizes hostile titles', () async {
    final XppFile file = buildFixture(title: r'a/b\c:d*e?f"g<h>i|j');
    final String path = await FileService.saveXopp(file);

    expect(path, '${tempDir.path}/a_b_c_d_e_f_g_h_i_j.xopp');
    expect(File(path).existsSync(), isTrue);
  });

  test('saveXopp falls back to a default name when untitled', () async {
    final XppFile file = buildFixture(title: null);
    final String path = await FileService.saveXopp(file);

    expect(path, '${tempDir.path}/notebook.xopp');
  });
}