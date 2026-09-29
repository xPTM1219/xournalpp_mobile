import 'dart:typed_data';

import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xournalpp/src/XppBackground.dart';
import 'package:xournalpp/src/XppFile.dart';
import 'package:xournalpp/src/XppPage.dart';

/// Builds a two-page PDF in memory with the pdf package.
Future<Uint8List> buildTwoPagePdf() async {
  final pw.Document document = pw.Document();
  for (int i = 0; i < 2; i++) {
    document.addPage(pw.Page(
        pageFormat: i == 0 ? PdfPageFormat.a4 : PdfPageFormat.a5,
        build: (pw.Context context) => pw.Center(
            child: pw.Text('page ${i + 1}'))));
  }
  return document.save();
}

void main() {
  test('importPdf builds one page per PDF page with correct sizes',
      () async {
    final Uint8List bytes = await buildTwoPagePdf();
    int countCalls = 0;
    int sizesCalls = 0;
    final List<String> persisted = [];

    final XppFile file = await XppFile.importPdf(
      pdf: FilePickerCross(bytes,
          path: '/two-page.pdf', type: FileTypeCross.any),
      pageCountOf: (FilePickerCross pdf) async {
        countCalls++;
        return 2;
      },
      sizesOf: (FilePickerCross pdf, int pageCount) async {
        sizesCalls++;
        return {
          0: XppPageSize(width: 595, height: 842),
          1: XppPageSize(width: 420, height: 595),
        };
      },
      persistPdf: persisted.add,
    );

    expect(countCalls, 1);
    expect(sizesCalls, 1);
    expect(persisted, ['/two-page.pdf']);
    expect(file.pages!.length, 2);
    // The title keeps the file name as the picker reports it.
    expect(file.title, 'two-page.pdf');
    expect(file.pages![0].pageSize!.width, 595);
    expect(file.pages![0].pageSize!.height, 842);
    expect(file.pages![1].pageSize!.width, 420);
    expect(file.pages![1].pageSize!.height, 595);
    for (int i = 0; i < 2; i++) {
      final XppBackgroundPdf background =
          file.pages![i].background as XppBackgroundPdf;
      expect(background.page, i);
      expect(background.filename, '/two-page.pdf');
    }
  });

  test('importPdf keeps page backgrounds in zero-based order', () async {
    final Uint8List bytes = await buildTwoPagePdf();

    final XppFile file = await XppFile.importPdf(
      pdf: FilePickerCross(bytes,
          path: '/doc.pdf', type: FileTypeCross.any),
      pageCountOf: (FilePickerCross pdf) async => 3,
      sizesOf: (FilePickerCross pdf, int pageCount) async => {
        for (int i = 0; i < pageCount; i++)
          i: XppPageSize(width: 100.0 + i, height: 200.0 + i),
      },
      persistPdf: (_) {},
    );

    expect(file.pages!.length, 3);
    final List<int?> pageIndices =
        file.pages!.map((p) => (p.background as XppBackgroundPdf).page).toList();
    expect(pageIndices, [0, 1, 2]);
  });
}