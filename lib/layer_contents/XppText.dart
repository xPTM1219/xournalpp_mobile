import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:xournalpp/src/HexColor.dart';
import 'package:xournalpp/src/XppLayer.dart';
import 'package:xournalpp/src/XppPageContentWidget.dart';
import 'package:xournalpp/widgets/ToolBoxBottomSheet.dart';

class XppText extends XppContent {
  @required
  final Color? color;
  @required
  final double? size;
  @required
  final String? text;
  @required
  final Offset? offset;
  @required
  final String? fontFamily;

  XppText({this.size, this.offset, this.fontFamily, this.color, this.text});

  @override
  Offset? getOffset() => offset;

  /// Estimated box end for hit tests. The XOPP format stores no text box, so
  /// the width assumes an average glyph advance of 0.6 em at [size] until a
  /// real layout measures the rendered text.
  Offset get estimatedBottomRight =>
      offset! + Offset(text!.length * size! * 0.6, size!);

  @override
  XppPageContentWidget render() {
    return XppPageContentWidget(
      child: RichTextField(),
      tool: EditingTool.TEXT,
    );
  }

  @override
  XmlElement toXmlElement() => XmlElement(XmlName('text'), [
        XmlAttribute(XmlName('font'), fontFamily!),
        XmlAttribute(XmlName('size'), size.toString()),
        XmlAttribute(XmlName('x'), offset!.dx.toString()),
        XmlAttribute(XmlName('y'), offset!.dy.toString()),
        XmlAttribute(XmlName('color'), color!.toHexTriplet()),
      ], [
        XmlText(encodeText(text!))
      ]);

  static String encodeText(String text) {
    text.replaceAll(r'&', r'&amp;');
    text.replaceAll(r'<', r'&lt;');
    text.replaceAll(r'>', r'&gt;');
    return text;
  }

  @override
  bool inRegion({Offset? topLeft, Offset? bottomRight}) {
    if (topLeft == null || bottomRight == null) return false;
    if (offset == null || text == null || size == null) return false;
    return XppContent.boxInRegion(
        offset!, estimatedBottomRight, topLeft, bottomRight);
  }

  @override
  bool shouldSelectAt({Offset? coordinates, EditingTool? tool}) {
    if (coordinates == null) return false;
    if (offset == null || text == null || size == null) return false;
    return XppContent.pointInBox(coordinates, offset!, estimatedBottomRight);
  }
}

class RichTextField extends StatefulWidget {
  final Function(String text)? onChange;

  final String? text;

  final double? size;

  final Color? color;

  const RichTextField(
      {Key? key, this.onChange, this.text, this.size, this.color})
      : super(key: key);

  @override
  _RichTextFieldState createState() => _RichTextFieldState();
}

class _RichTextFieldState extends State<RichTextField> {
  //ZefyrController _controller;
  TextEditingController? _controller;
  FocusNode? _focusNode;

  bool active = false;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.text);
    //_controller = ZefyrController(
    //   NotusDocument.fromDelta(NotusMarkdownCodec().decode(widget.text)));
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return XppPageContentWidget(
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
      ),
    );
    /*return ZefyrEditor(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      mode: active ? ZefyrMode.edit : ZefyrMode.select,
    );*/
  }

  /*@override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }*/
}
