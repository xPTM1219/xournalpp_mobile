import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart' show PrintingPlatform;
import 'package:printing/src/raster.dart' show PdfRaster;
import 'package:xournalpp/src/PdfImage.dart';
import 'package:xournalpp/src/XppPage.dart';
import 'package:xournalpp/src/pdf_cache.dart';

/// Counts raster calls and yields one fake page per requested index.
class FakeRasterPage {
  FakeRasterPage(this.pageWidth, this.pageHeight);

  final int pageWidth;
  final int pageHeight;

  int calls = 0;
  final List<int> requestedPages = [];

  RasterPage get rasterPage => (Uint8List document, int page, double dpi) {
        calls++;
        requestedPages.add(page);
        return Future.value(fakePng(pageWidth, pageHeight));
      };
}

/// Builds a minimal valid PNG with the given dimensions in its IHDR.
Uint8List fakePng(int width, int height) {
  final ByteData header = ByteData(24);
  header.setUint64(0, 0x89504e470d0a1a0a, Endian.host);
  header.setUint32(8, 13, Endian.big);
  header.setUint32(12, 0x49484452, Endian.big); // IHDR
  header.setUint32(16, width, Endian.big);
  header.setUint32(20, height, Endian.big);
  return header.buffer.asUint8List();
}

void main() {
  group('PdfRasterCache', () {
    test('requests the same page twice with one raster call', () async {
      final FakeRasterPage fake = FakeRasterPage(794, 1123);
      final PdfRasterCache cache = PdfRasterCache(rasterPage: fake.rasterPage);
      final Uint8List document = Uint8List.fromList([1, 2, 3]);

      final Uint8List first = await cache.page(document, 1, DPI);
      final Uint8List second = await cache.page(document, 1, DPI);

      expect(fake.calls, 1);
      expect(fake.requestedPages, [1]);
      expect(second, same(first));
    });

    test('evicts least recently used pages beyond capacity', () async {
      final FakeRasterPage fake = FakeRasterPage(794, 1123);
      final PdfRasterCache cache =
          PdfRasterCache(maxPages: 2, rasterPage: fake.rasterPage);
      final Uint8List document = Uint8List.fromList([1, 2, 3]);

      await cache.page(document, 0, DPI);
      await cache.page(document, 1, DPI);
      expect(cache.length, 2);

      // Touch page 0 so page 1 becomes the least recently used entry;
      // the touch itself is a cache hit with no raster call.
      await cache.page(document, 0, DPI);
      expect(fake.calls, 2);

      await cache.page(document, 2, DPI);

      expect(cache.length, 2);
      expect(fake.calls, 3);
      expect(fake.requestedPages, [0, 1, 2]);

      // Page 1 was evicted and must rasterize again.
      await cache.page(document, 1, DPI);
      expect(fake.calls, 4);
      expect(fake.requestedPages, [0, 1, 2, 1]);
    });

    test('concurrent requests for the same page share one raster call',
        () async {
      final Completer<void> gate = Completer<void>();
      final List<int> requestedPages = [];
      final PdfRasterCache cache = PdfRasterCache(
          rasterPage: (Uint8List document, int page, double dpi) {
        requestedPages.add(page);
        return gate.future.then((_) => fakePng(10, 10));
      });
      final Uint8List document = Uint8List.fromList([1, 2, 3]);

      final Future<Uint8List> first = cache.page(document, 0, DPI);
      final Future<Uint8List> second = cache.page(document, 0, DPI);
      gate.complete();
      final List<Uint8List> results = await Future.wait([first, second]);

      expect(requestedPages, [0]);
      expect(results[0], same(results[1]));
    });

    test('different dpi values get separate cache entries', () async {
      final FakeRasterPage fake = FakeRasterPage(794, 1123);
      final PdfRasterCache cache = PdfRasterCache(rasterPage: fake.rasterPage);
      final Uint8List document = Uint8List.fromList([1, 2, 3]);

      await cache.page(document, 0, 96);
      await cache.page(document, 0, 72);

      expect(fake.calls, 2);
    });

    test('clear drops cached pages and the document ids', () async {
      final FakeRasterPage fake = FakeRasterPage(794, 1123);
      final PdfRasterCache cache = PdfRasterCache(rasterPage: fake.rasterPage);
      final Uint8List document = Uint8List.fromList([1, 2, 3]);

      await cache.page(document, 0, DPI);
      cache.clear();

      expect(cache.length, 0);
      await cache.page(document, 0, DPI);
      expect(fake.calls, 2);
    });
  });

  group('PdfPageSizeCache', () {
    test('sizes come from one pass and repeat lookups are free', () async {
      final FakeRasterPage fake = FakeRasterPage(794, 1123);
      final PdfRasterCache rasters =
          PdfRasterCache(rasterPage: fake.rasterPage);
      final PdfPageSizeCache sizes = PdfPageSizeCache();
      final Uint8List document = Uint8List.fromList([1, 2, 3]);

      final Map<int, XppPageSize> first = await sizes.sizes(document, 3, DPI,
          rasterCache: rasters);
      expect(first.length, 3);
      expect(first[0]!.width, 794);
      expect(first[0]!.height, 1123);
      expect(fake.calls, 3);

      final Map<int, XppPageSize> second = await sizes.sizes(document, 3, DPI,
          rasterCache: rasters);
      expect(second[2]!.width, 794);
      expect(fake.calls, 3);
    });

    test('size cache evicts whole documents beyond capacity', () async {
      final FakeRasterPage fake = FakeRasterPage(100, 100);
      // One page per document forces an eviction on every reuse, so each
      // re-request of an evicted document rasterizes again.
      final PdfRasterCache rasters =
          PdfRasterCache(maxPages: 1, rasterPage: fake.rasterPage);
      final PdfPageSizeCache sizes = PdfPageSizeCache(maxDocuments: 1);
      final Uint8List documentA = Uint8List.fromList([1]);
      final Uint8List documentB = Uint8List.fromList([2]);

      await sizes.sizes(documentA, 2, DPI, rasterCache: rasters);
      await sizes.sizes(documentB, 2, DPI, rasterCache: rasters);
      final int callsAfterBoth = fake.calls;

      // Document A was evicted; asking again rasterizes its pages again.
      await sizes.sizes(documentA, 2, DPI, rasterCache: rasters);
      expect(fake.calls, callsAfterBoth + 2);
    });
  });

  group('pngSize', () {
    test('reads width and height from the IHDR header', () {
      final XppPageSize size = pngSize(fakePng(595, 842));
      expect(size.width, 595);
      expect(size.height, 842);
    });

    test('rejects data too short for an IHDR header', () {
      expect(() => pngSize(Uint8List.fromList([1, 2, 3])),
          throwsArgumentError);
    });
  });

  group('pdfImage through the printing platform interface', () {
    test('rasterizes exactly the requested page', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final List<List<int>?> requestedPages = [];
      final PdfRaster fakeRaster = PdfRaster(
          794, 1123, Uint8List.fromList(List.filled(794 * 1123 * 4, 128)));
      final PrintingPlatform original = PrintingPlatform.instance;
      PrintingPlatform.instance = _FakePrintingPlatform(
          (Uint8List document, List<int>? pages, double dpi) {
        requestedPages.add(pages);
        return Stream.fromIterable([fakeRaster]);
      });
      addTearDown(() => PrintingPlatform.instance = original);

      final FilePickerCross pdf = FilePickerCross(
          Uint8List.fromList([1, 2, 3]),
          path: '/doc.pdf',
          type: FileTypeCross.any);
      final Uint8List png = await pdfImage(pdf, 2);

      expect(requestedPages, [
        [2]
      ]);
      expect(png, isNotEmpty);
    });
  });
}

class _FakePrintingPlatform extends PrintingPlatform {
  _FakePrintingPlatform(this.rasterImpl);

  final Stream<PdfRaster> Function(
      Uint8List document, List<int>? pages, double dpi) rasterImpl;

  @override
  Stream<PdfRaster> raster(Uint8List document, List<int>? pages, double dpi) =>
      rasterImpl(document, pages, dpi);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final dynamic member = invocation.memberName;
    throw UnimplementedError('$member not faked');
  }
}