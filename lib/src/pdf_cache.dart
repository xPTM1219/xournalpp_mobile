import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Key identifying one cached rasterized PDF page.
class PdfPageKey {
  const PdfPageKey(this.documentId, this.page, this.dpi);

  /// Stable identifier of the source PDF (hash of its bytes).
  final int documentId;

  /// Zero-based page index.
  final int page;

  /// Dots per inch the page was rasterized with.
  final double dpi;

  @override
  bool operator ==(Object other) =>
      other is PdfPageKey &&
      other.documentId == documentId &&
      other.page == page &&
      other.dpi == dpi;

  @override
  int get hashCode => Object.hash(documentId, page, dpi);
}

/// Raster function injected into [PdfRasterCache], mirroring the
/// `Printing.raster` contract: takes the document bytes, a zero-based
/// page index and the dpi, and yields the rasterized page as PNG bytes.
typedef RasterPage = Future<Uint8List> Function(
    Uint8List document, int page, double dpi);

/// LRU cache of rasterized PDF pages, keyed by document bytes identity,
/// page index and dpi. One raster call per cached page keeps memory
/// proportional to viewed pages instead of total pages.
class PdfRasterCache {
  /// Creates a cache holding at most [maxPages] rasterized PNG pages.
  ///
  /// [documentId] derives the per-document identity from the PDF bytes.
  /// [rasterPage] performs the actual rasterization of a single page.
  PdfRasterCache({
    this.maxPages = 8,
    int Function(Uint8List bytes)? documentId,
    RasterPage? rasterPage,
  })  : _documentId = documentId ?? fnv1aHash,
        _rasterPage = rasterPage ?? printingRasterPage;

  /// Maximum number of pages kept in memory. Raising this trades memory
  /// for fewer re-rasterizations when paging back and forth.
  final int maxPages;

  final int Function(Uint8List bytes) _documentId;
  final RasterPage _rasterPage;

  /// Cached pages in use order; first entry is least recently used.
  final LinkedHashMap<PdfPageKey, Uint8List> _pages = LinkedHashMap();

  /// Bytes already resolved to a document id in this cache.
  final Map<int, int> _documentIdByBytesIdentity = {};

  /// Bytes with their in-flight rasterizations, so concurrent requests
  /// for the same page share one raster call.
  final Map<PdfPageKey, Future<Uint8List>> _pending = {};

  /// FNV-1a 32-bit hash used as the per-document identity. The 32-bit
  /// variant fits JavaScript integers exactly, keeping the web build valid.
  static int fnv1aHash(Uint8List bytes) {
    int hash = 0x811c9dc5;
    for (final int byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Resolves the document id for the given bytes, hashing once per
  /// [Uint8List] identity and reusing the id on subsequent calls.
  int _idFor(Uint8List bytes) {
    final int identity = identityHashCode(bytes);
    return _documentIdByBytesIdentity.putIfAbsent(
        identity, () => _documentId(bytes));
  }

  /// Returns the rasterized PNG for [page] of [document], rasterizing at
  /// most one page per call and serving repeated requests from the cache.
  ///
  /// Concurrent requests for the same page share a single rasterization.
  Future<Uint8List> page(Uint8List document, int page, double dpi) async {
    final PdfPageKey key = PdfPageKey(_idFor(document), page, dpi);
    final Uint8List? cached = _pages.remove(key);
    if (cached != null) {
      _pages[key] = cached;
      return cached;
    }
    final Future<Uint8List>? pending = _pending[key];
    if (pending != null) {
      return pending;
    }
    final Future<Uint8List> rasterized = () async {
      try {
        final Uint8List png = await _rasterPage(document, page, dpi);
        _pages[key] = png;
        while (_pages.length > maxPages) {
          _pages.remove(_pages.keys.first);
        }
        return png;
      } finally {
        _pending.remove(key);
      }
    }();
    _pending[key] = rasterized;
    return rasterized;
  }

  /// Drops every cached page. Call when a document is closed.
  void clear() {
    _pages.clear();
    _documentIdByBytesIdentity.clear();
  }

  /// Number of pages currently held.
  int get length => _pages.length;
}

/// Default raster function bound to the printing plugin.
Future<Uint8List> printingRasterPage(Uint8List document, int page, double dpi) {
  return _printingInstance.rasterPage(document, page, dpi);
}

/// Keeps the printing plugin import in one small seam.
class _PrintingRaster {
  Future<Uint8List> rasterPage(Uint8List document, int page, double dpi) {
    return Printing.raster(document, pages: [page], dpi: dpi)
        .first
        .then((raster) => raster.toPng());
  }
}

_PrintingRaster get _printingInstance => _instance;
final _PrintingRaster _instance = _PrintingRaster();

/// Shared cache instance used by the app-facing PDF helpers.
final PdfRasterCache pdfRasterCache = PdfRasterCache();