import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xournalpp/layer_contents/XppStroke.dart';
import 'package:xournalpp/src/XppFile.dart';
import 'package:xournalpp/src/XppLayer.dart';
import 'package:xournalpp/src/XppPageContentWidget.dart';

/// Fails like the production callback for a background file that is gone.
Future<FilePickerCross> missingFile(String? path) => throw ('missing');

/// Builds a gzipped xopp payload with one eraser stroke and one pen stroke.
Uint8List buildEraserXopp() {
  const String xml = '''<?xml version="1.0" standalone="no"?>
<xournal creator="test" fileversion="4">
  <title>Xournal document - see http://math.mit.edu/~auroux/software/xournal/</title>
  <page width="595.0" height="842.0">
    <background type="solid" style="plain" color="white"/>
    <layer>
      <stroke tool="pen" color="red" width="2.0">0 0 10 10</stroke>
      <stroke tool="eraser" color="black" width="2.5">10 10 50 50</stroke>
    </layer>
  </page>
</xournal>''';
  return Uint8List.fromList(GZipCodec().encode(utf8.encode(xml)).toList());
}

XppStroke buildStroke(XppStrokeTool tool, List<XppStrokePoint> points) {
  return XppStroke.byTool(tool: tool, color: Colors.black, points: points);
}

void main() {
  test('getOffset returns the smallest x and y of the stroke points', () {
    final XppStroke stroke = buildStroke(XppStrokeTool.PEN, [
      XppStrokePoint(x: 0.0, y: 10.0, width: 2.0),
      XppStrokePoint(x: 20.0, y: 5.0, width: 2.0),
      XppStrokePoint(x: 5.0, y: 30.0, width: 2.0),
    ]);
    expect(stroke.getOffset(), const Offset(0, 5));
  });

  test('bottomRight returns the largest x and y of the stroke points', () {
    final XppStroke stroke = buildStroke(XppStrokeTool.PEN, [
      XppStrokePoint(x: 0.0, y: 10.0, width: 2.0),
      XppStrokePoint(x: 20.0, y: 5.0, width: 2.0),
      XppStrokePoint(x: 5.0, y: 30.0, width: 2.0),
    ]);
    expect(stroke.bottomRight, const Offset(20, 30));
  });

  test('empty stroke bounds fall back to the origin', () {
    final XppStroke stroke = buildStroke(XppStrokeTool.PEN, []);
    expect(stroke.getOffset(), const Offset(0, 0));
    expect(stroke.bottomRight, const Offset(0, 0));
  });

  test('render paints eraser strokes white without touching the color',
      () {
    final XppStroke stroke = buildStroke(XppStrokeTool.ERASER, [
      XppStrokePoint(x: 0.0, y: 0.0, width: 2.0),
      XppStrokePoint(x: 10.0, y: 10.0, width: 2.0),
    ]);
    final XppPageContentWidget widget = stroke.render();
    final XppStrokePainter painter =
        (widget.child! as CustomPaint).foregroundPainter as XppStrokePainter;
    expect(painter.color, Colors.white);
    // The stored color survives for the next save.
    expect(stroke.color, Colors.black);
  });

  test('render paints highlighter translucent without touching the color',
      () {
    final XppStroke stroke = buildStroke(XppStrokeTool.HIGHLIGHTER, [
      XppStrokePoint(x: 0.0, y: 0.0, width: 4.0),
      XppStrokePoint(x: 10.0, y: 10.0, width: 4.0),
    ]);
    final XppPageContentWidget widget = stroke.render();
    final XppStrokePainter painter =
        (widget.child! as CustomPaint).foregroundPainter as XppStrokePainter;
    expect(painter.color, Colors.black.withValues(alpha: .5));
    expect(stroke.color, Colors.black);
  });

  test('parsing keeps eraser strokes as whiteout strokes', () async {
    final XppFile file = await XppFile.fromFilePickerCross(
        FilePickerCross(buildEraserXopp(),
            path: '/tmp/whiteout.xopp',
            type: FileTypeCross.custom,
            fileExtension: 'xopp'),
        null,
        missingFile);

    expect(file.title, 'whiteout');
    final List<XppContent?> content = file.pages![0].layers![0].content!;
    expect(content.length, 2);
    final XppStrokeWhiteout whiteout = content[1] as XppStrokeWhiteout;
    expect(whiteout.tool, XppStrokeTool.ERASER);
    expect(whiteout.points!.length, 2);
    expect(whiteout.points![0].offset, const Offset(10, 10));
    expect(whiteout.points![1].offset, const Offset(50, 50));
    expect(whiteout.points![1].width, 2.5);
  });

  test('whiteout strokes serialize back with the eraser tool', () {
    final XppStroke stroke = buildStroke(XppStrokeTool.ERASER, [
      XppStrokePoint(x: 10.0, y: 10.0, width: 2.5),
    ]);
    final String xml = stroke.toXmlElement().toXmlString();
    expect(xml, contains('tool="eraser"'));
    expect(xml, contains('10.0 10.0'));
  });
}