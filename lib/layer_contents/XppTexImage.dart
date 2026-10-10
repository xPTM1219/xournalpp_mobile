import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:xml/xml.dart';
import 'package:xournalpp/layer_contents/XppText.dart';
import 'package:xournalpp/src/HexColor.dart';
import 'package:xournalpp/src/XppLayer.dart';
import 'package:xournalpp/src/XppPageContentWidget.dart';
import 'package:xournalpp/widgets/ToolBoxBottomSheet.dart';

class XppTexImage extends XppContent {
  Offset? topLeft = Offset(0, 0);

  /// Bottom/right corner of the element box. The XOPP format derives the
  /// box from the rendered formula, so freshly created elements keep
  /// (0, 0) until a render pass measures it; parsed desktop files carry
  /// the saved box.
  Offset? bottomRight = Offset(0, 0);

  @required
  final String? text;

  Color? color;

  XppTexImage({this.text, this.topLeft, this.bottomRight, this.color});

  static Future<XppTexImage> edit(
      {required BuildContext context,
      String text = 'x^2',
      Offset? topLeft,
      Color? color}) async {
    var laTeXController = TextEditingController(text: text);
    bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter LaTeX code'),
        content: TextField(
            controller: laTeXController = laTeXController,
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'LaTeX code',
                helperText: 'No delimiter required')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Okay'))
        ],
      ),
    );
    if (result == false) throw (UnsupportedError('Aborted.'));
    return (XppTexImage(
        text: laTeXController.text, topLeft: topLeft, color: color));
  }

  /// Render font size: the saved box height, or a readable default while
  /// the box is still unknown.
  double get fontSize {
    final Offset? min = topLeft;
    final Offset? max = bottomRight;
    if (min == null || max == null) return 18;
    final double height = (max.dy - min.dy).abs();
    return height > 0 ? height : 18;
  }

  @override
  XppPageContentWidget render() {
    return XppPageContentWidget(
      child: DefaultTextStyle(
        style: TextStyle(color: color, fontSize: fontSize),
        child: Math.tex('\\displaystyle{$text}'),
      ),
      onSelected: () => print('Edit LaTeX!'),
      tool: EditingTool.LATEX,
    );
  }

  @override
  Offset? getOffset() => topLeft;

  @override
  XmlElement toXmlElement() => XmlElement(XmlName('teximage'), [
        XmlAttribute(XmlName('text'), text!),
        XmlAttribute(XmlName('color'), color!.toHexTriplet()),
        XmlAttribute(XmlName('left'), topLeft!.dx.toString()),
        XmlAttribute(XmlName('right'), bottomRight?.dx.toString() ?? '0'),
        XmlAttribute(XmlName('top'), topLeft!.dy.toString()),
        XmlAttribute(XmlName('bottom'), bottomRight?.dy.toString() ?? '0'),
      ], [
        XmlText(XppText.encodeText(text!))
      ]);

  @override
  bool inRegion({Offset? topLeft, Offset? bottomRight}) {
    if (topLeft == null || bottomRight == null) return false;
    if (this.topLeft == null || this.bottomRight == null) return false;
    return XppContent.boxInRegion(
        this.topLeft!, this.bottomRight!, topLeft, bottomRight);
  }

  @override
  bool shouldSelectAt({Offset? coordinates, EditingTool? tool}) {
    if (coordinates == null) return false;
    if (topLeft == null || bottomRight == null) return false;
    return XppContent.pointInBox(coordinates, topLeft!, bottomRight!);
  }
}
