import 'dart:collection';
import 'dart:typed_data';

import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:printing/printing.dart';
import 'package:xournalpp/src/XppPage.dart';

import 'pdf_cache.dart';

const double DPI = 96;

/// Raster of one page at 96 dpi, served from the per-document LRU cache.
Future<Uint8List> pdfImage(FilePickerCross pdf, int? page) =>
    pdfRasterCache.page(pdf.toUint8List(), page!, DPI);

/// Page count through a single whole-document raster without dpi scaling.
/// The plugin yields all pages; only the stream length is consumed.
Future<int> pdfPageCount(FilePickerCross pdf) =>
    Printing.raster(pdf.toUint8List()).length;

/// Sizes of every page, keyed by zero-based page index.
///
/// Computed from the cached per-page 96 dpi rasters, so no extra
/// rasterization happens when sizes are looked up.
Future<Map<int, XppPageSize>> pdfPageSizes(
        FilePickerCross pdf, int pageCount) =>
    pdfPageSizeCache.sizes(pdf.toUint8List(), pageCount, DPI);

/// LRU cache of page sizes per document, derived from cached rasters.
class PdfPageSizeCache {
  /// Sizes keyed by document id, holding at most [maxDocuments] entries.
  PdfPageSizeCache({this.maxDocuments = 4});

  final int maxDocuments;

  /// Document ids in use order; first entry is least recently used.
  final LinkedHashMap<int, Map<int, XppPageSize>> _sizes = LinkedHashMap();

  /// Bytes already resolved to a document id in this cache.
  final Map<int, int> _documentIdByBytesIdentity = {};

  int _idFor(Uint8List bytes) {
    final int identity = identityHashCode(bytes);
    return _documentIdByBytesIdentity.putIfAbsent(
        identity, () => PdfRasterCache.fnv1aHash(bytes));
  }

  /// Computes or returns the cached sizes for every page of [document].
  ///
  /// Sizes are read from the PNG header of each cached page raster, so
  /// the raster cost stays proportional to the page count and repeat
  /// lookups are free.
  ///
  /// [rasterCache] defaults to the shared [pdfRasterCache]; tests inject
  /// their own instance.
  Future<Map<int, XppPageSize>> sizes(Uint8List document, int pageCount,
      double dpi,
      {PdfRasterCache? rasterCache}) async {
    final PdfRasterCache rasters = rasterCache ?? pdfRasterCache;
    final int id = _idFor(document);
    final Map<int, XppPageSize>? cached = _sizes.remove(id);
    if (cached != null) {
      _sizes[id] = cached;
      return cached;
    }
    final Map<int, XppPageSize> computed = {};
    for (int page = 0; page < pageCount; page++) {
      final Uint8List png = await rasters.page(document, page, dpi);
      computed[page] = pngSize(png);
    }
    _sizes[id] = computed;
    while (_sizes.length > maxDocuments) {
      _sizes.remove(_sizes.keys.first);
    }
    return computed;
  }

  void clear() {
    _sizes.clear();
    _documentIdByBytesIdentity.clear();
  }
}

/// Shared page size cache used by the app-facing PDF helpers.
final PdfPageSizeCache pdfPageSizeCache = PdfPageSizeCache();

/// Page dimensions read from the PNG IHDR header of [png].
///
/// PNG layout: 8-byte signature, then the IHDR chunk with a 4-byte
/// length, 4-byte type and the 13-byte header holding width and height
/// as big-endian 32-bit values at offsets 16 and 20.
XppPageSize pngSize(Uint8List png) {
  if (png.length < 24) {
    throw ArgumentError('PNG data too short to hold an IHDR header');
  }
  final ByteData view = ByteData.sublistView(png);
  final int width = view.getUint32(16);
  final int height = view.getUint32(20);
  return XppPageSize(width: width.toDouble(), height: height.toDouble());
}