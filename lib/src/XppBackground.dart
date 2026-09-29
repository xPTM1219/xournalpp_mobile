import 'dart:typed_data';

import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:xml/xml.dart';
import 'package:xournalpp/src/HexColor.dart';
import 'package:xournalpp/src/PdfImage.dart';

import 'XppPage.dart';

abstract class XppBackground {
  XppBackgroundType? type;
  XppPageSize? size;

  static XppBackground get none => _NoXppBackground();

  Widget render();

  XmlElement toXmlElement();
}

/// page background for a [XppPage] made from an image URI. I am sure it will be hard to implement for web.
/// TODO: implement background for web
class XppBackgroundImage extends XppBackground {
  final String? filename;
  final XppBackgroundImageDomain domain;
  final XppBackgroundType? type;

  XppBackgroundImage(
      {this.type,
      this.filename,
      this.domain = XppBackgroundImageDomain.ABSOLUTE});

  @override
  Widget render() {
    return (Container());
  }

  @override
  XmlElement toXmlElement() {
    late String domainString;
    switch (domain) {
      case XppBackgroundImageDomain.ABSOLUTE:
        domainString = 'absolute';
        break;
      case XppBackgroundImageDomain.ATTACH:
        domainString = 'attach';
        break;
      case XppBackgroundImageDomain.CLONE:
        domainString = 'clone';
        break;
    }
    XmlElement node = XmlElement(XmlName('background'), [
      XmlAttribute(XmlName('type'), 'pixmap'),
      XmlAttribute(XmlName('domain'), domainString),
      XmlAttribute(XmlName('filename'), filename!),
    ]);
    return (node);
  }
}

typedef Future<FilePickerCross> FileNotAvailableCallback(String? path);

/// page background for a [XppPage] made from a PDF document
class XppBackgroundPdf extends XppBackground {
  final String? filename;
  final XppBackgroundImageDomain domain;
  final int? page;
  final FileNotAvailableCallback onUnavailable;

  XppBackgroundPdf(
      {required this.onUnavailable,
      this.page,
      this.filename,
      this.domain = XppBackgroundImageDomain.ABSOLUTE});

  @override
  Widget render() {
    return (PDfBackgroundWidget(provider: this));
  }

  @override
  XmlElement toXmlElement() {
    XmlElement node = XmlElement(XmlName('background'), [
      XmlAttribute(XmlName('type'), 'pdf'),
      XmlAttribute(XmlName('pageno'), page.toString()),
      XmlAttribute(XmlName('filename'), filename!),
    ]);
    return (node);
  }
}

class PDfBackgroundWidget extends StatefulWidget {
  final XppBackgroundPdf? provider;

  const PDfBackgroundWidget({Key? key, this.provider}) : super(key: key);
  @override
  _PDfBackgroundWidgetState createState() => _PDfBackgroundWidgetState();
}

class _PDfBackgroundWidgetState extends State<PDfBackgroundWidget>
    with AutomaticKeepAliveClientMixin {
  /// Decode-size cap in device pixels so huge PDF pages never enter the
  /// image cache at full raster resolution (96 dpi A4 is already ~794x1123).
  static const int _maxDecodeDimension = 2048;

  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(covariant PDfBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider?.filename != widget.provider?.filename ||
        oldWidget.provider?.page != widget.provider?.page) {
      _imageFuture = _loadImage();
    }
  }

  Future<Uint8List> _loadImage() {
    return FilePickerCross.fromInternalPath(path: widget.provider!.filename!)
        .then((value) {
      return pdfImage(value, widget.provider!.page);
    }).catchError((e) => widget.provider!
                .onUnavailable(widget.provider!.filename)
                .then((value) => pdfImage(value, widget.provider!.page)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return FutureBuilder(
        future: _imageFuture,
        builder: (context, AsyncSnapshot<Uint8List> snapshot) =>
            (snapshot.hasData)
                ? Image(
                    image: ResizeImage(
                      MemoryImage(snapshot.data!),
                      width: _decodeWidth(mediaQuery),
                      height: _decodeHeight(mediaQuery),
                      policy: ResizeImagePolicy.fit,
                    ),
                    fit: BoxFit.fill,
                  )
                : Center(child: CircularProgressIndicator()));
  }

  /// Decode width scaled to the device pixel ratio, clamped so the
  /// longest side never exceeds [_maxDecodeDimension] device pixels.
  int? _decodeWidth(MediaQueryData mediaQuery) {
    final int width = (mediaQuery.size.width * mediaQuery.devicePixelRatio)
        .round()
        .clamp(1, _maxDecodeDimension);
    return width;
  }

  /// Decode height scaled to the device pixel ratio, clamped so the
  /// longest side never exceeds [_maxDecodeDimension] device pixels.
  int? _decodeHeight(MediaQueryData mediaQuery) {
    final int height = (mediaQuery.size.height * mediaQuery.devicePixelRatio)
        .round()
        .clamp(1, _maxDecodeDimension);
    return height;
  }

  @override
  bool get wantKeepAlive => true;
}

/// page background for a [XppPage] made from a color and a style
abstract class XppBackgroundSolid extends XppBackground {
  Color? color;
  XppPageSize? size;
  XppBackgroundType? type = XppBackgroundType.SOLID;

  XmlElement generateXmlElement(String style) {
    XmlElement node = XmlElement(XmlName('background'), [
      XmlAttribute(XmlName('type'), 'solid'),
      XmlAttribute(XmlName('color'), color!.toHexTriplet()),
      XmlAttribute(XmlName('style'), style),
    ]);
    return (node);
  }
}

class XppBackgroundSolidLined extends XppBackgroundSolid {
  Color? color;
  XppPageSize? size;

  XppBackgroundSolidLined({this.color = Colors.white, this.size});
  @override
  Widget render() {
    return Container(
      color: color,
      child: CustomPaint(
        painter: _LinePainter(color: color),
        size: size!.toSize(),
      ),
    );
  }

  @override
  XmlElement toXmlElement() => generateXmlElement('lined');
}

class XppBackgroundSolidRuled extends XppBackgroundSolid {
  Color? color;
  XppPageSize? size;

  XppBackgroundSolidRuled({this.color = Colors.white, this.size});
  @override
  Widget render() {
    return Container(
      color: color,
      child: CustomPaint(
        painter: _RuledPainter(color: color),
        size: size!.toSize(),
      ),
    );
  }

  @override
  XmlElement toXmlElement() => generateXmlElement('ruled');
}

class XppBackgroundSolidGraph extends XppBackgroundSolid {
  Color? color;
  XppPageSize? size;

  XppBackgroundSolidGraph({this.color = Colors.white, this.size});
  @override
  Widget render() {
    return Container(
      color: color,
      child: CustomPaint(
        painter: _GraphPainter(color: color),
        size: size!.toSize(),
      ),
    );
  }

  @override
  XmlElement toXmlElement() => generateXmlElement('graph');
}

class XppBackgroundSolidDot extends XppBackgroundSolid {
  Color? color;
  XppPageSize? size;

  XppBackgroundSolidDot({this.color = Colors.white, this.size});
  @override
  Widget render() {
    return Container(
      color: color,
      child: CustomPaint(
        painter: _DotPainter(color: color),
        size: size!.toSize(),
      ),
    );
  }

  @override
  XmlElement toXmlElement() => generateXmlElement('dotted');
}

class XppBackgroundSolidPlain extends XppBackgroundSolid {
  Color? color;
  XppPageSize? size;

  XppBackgroundSolidPlain({this.color, this.size});
  @override
  Widget render() {
    return (Container(
      width: size!.width,
      height: size!.height,
      color: color,
    ));
  }

  @override
  XmlElement toXmlElement() => generateXmlElement('plain');
}

class _NoXppBackground extends XppBackground {
  XppPageSize? size = XppPageSize(width: 0, height: 0);
  XppBackgroundType? type = XppBackgroundType.NONE;

  @override
  Widget render() => Container();

  @override
  XmlElement toXmlElement() {
    XmlElement node = XmlElement(XmlName('background'), [
      XmlAttribute(XmlName('type'), 'solid'),
      XmlAttribute(XmlName('color'), 'white'),
      XmlAttribute(XmlName('style'), 'plain'),
    ]);
    return (node);
  }
}

class _LinePainter extends CustomPainter {
  final Color? color;

  _LinePainter({this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[500]!.withOpacity(.3)
      ..strokeWidth = 1;
    // 1 because no line at the top
    for (int i = 1; i < size.height / 24; i++) {
      canvas.drawLine(Offset(0, i * 24.toDouble()),
          Offset(size.width, i * 24.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _RuledPainter extends CustomPainter {
  final Color? color;

  _RuledPainter({this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[500]!.withOpacity(.3)
      ..strokeWidth = 1;
    // 1 because no line at the top
    for (int i = 1; i < size.height / 24; i++) {
      canvas.drawLine(Offset(0, i * 24.toDouble()),
          Offset(size.width, i * 24.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _GraphPainter extends CustomPainter {
  final Color? color;

  _GraphPainter({this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[500]!.withOpacity(.3)
      ..strokeWidth = 1;
    // 1 because no line at the top
    for (int i = 1; i < size.height / XppPageSize.pt2mm(5); i++) {
      canvas.drawLine(Offset(0, i * XppPageSize.pt2mm(5).toDouble()),
          Offset(size.width, i * XppPageSize.pt2mm(5).toDouble()), paint);
    }
    // 1 because no line at the beginning
    for (int i = 1; i < size.width / XppPageSize.pt2mm(5); i++) {
      canvas.drawLine(Offset(i * XppPageSize.pt2mm(5).toDouble(), 0),
          Offset(i * XppPageSize.pt2mm(5).toDouble(), size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _DotPainter extends CustomPainter {
  final Color? color;

  _DotPainter({this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[500]!.withOpacity(.3)
      ..strokeWidth = 1;
    // 1 because no line at the top
    for (int i = 1; i < size.height / XppPageSize.pt2mm(5); i++) {
      // 1 because no line at the beginning
      for (int j = 1; j < size.width / XppPageSize.pt2mm(5); j++) {
        canvas.drawCircle(
            Offset(j * XppPageSize.pt2mm(5).toDouble(),
                i * XppPageSize.pt2mm(5).toDouble()),
            XppPageSize.pt2mm(.5).toDouble(),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

enum XppBackgroundImageDomain { ABSOLUTE, ATTACH, CLONE }

enum XppBackgroundType { NONE, SOLID, PIXMAP }
