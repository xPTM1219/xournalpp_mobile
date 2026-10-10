import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:xournalpp/widgets/ToolBoxBottomSheet.dart';

import 'XppPageContentWidget.dart';

class XppLayer {
  XppLayer({this.content});

  List<XppContent?>? content;

  static XppLayer empty() => XppLayer(content: []);

  XmlElement toXmlElement() => XmlElement(
      XmlName('layer'), const [], content!.map((e) => e!.toXmlElement()));
}

abstract class XppContent {
  Offset? getOffset();

  XppPageContentWidget render();

  XmlElement toXmlElement();

  bool shouldSelectAt({Offset? coordinates, EditingTool? tool});

  bool inRegion({Offset? topLeft, Offset? bottomRight});

  /// return [true] in case it should be fully deleted
  XppContentEraseData eraseWhere({Offset? coordinates, double? radius}) =>
      XppContentEraseData();

  /// True when the content box [min, max] overlaps the region rect
  /// [topLeft, bottomRight]. Touching edges count as overlap.
  static bool boxInRegion(Offset min, Offset max, Offset topLeft,
          Offset bottomRight) =>
      min.dx <= bottomRight.dx &&
      max.dx >= topLeft.dx &&
      min.dy <= bottomRight.dy &&
      max.dy >= topLeft.dy;

  /// True when [point] lies inside the box [min, max] plus a [tolerance]
  /// on every side.
  static bool pointInBox(Offset point, Offset min, Offset max,
          {double tolerance = 0}) =>
      point.dx >= min.dx - tolerance &&
      point.dx <= max.dx + tolerance &&
      point.dy >= min.dy - tolerance &&
      point.dy <= max.dy + tolerance;
}

class XppContentEraseData {
  final bool affected;
  final bool delete;
  final List<XppContent> newContent;

  XppContentEraseData(
      {this.affected = false, this.delete = false, this.newContent = const []});
}
