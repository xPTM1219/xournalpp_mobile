import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xournalpp/layer_contents/XppImage.dart';
import 'package:xournalpp/layer_contents/XppStroke.dart';
import 'package:xournalpp/layer_contents/XppText.dart';
import 'package:xournalpp/layer_contents/XppTexImage.dart';

void main() {
  group('XppStroke region helpers', () {
    final XppStroke stroke = XppStroke.byTool(
        tool: XppStrokeTool.PEN,
        color: Colors.black,
        points: [
          XppStrokePoint(x: 0.0, y: 5.0, width: 2.0),
          XppStrokePoint(x: 20.0, y: 30.0, width: 2.0),
        ]);

    test('inRegion reports bounding box overlap', () {
      expect(
          stroke.inRegion(topLeft: const Offset(10, 10),
              bottomRight: const Offset(40, 40)),
          isTrue);
      expect(
          stroke.inRegion(topLeft: const Offset(100, 100),
              bottomRight: const Offset(200, 200)),
          isFalse);
      expect(
          stroke.inRegion(topLeft: const Offset(-10, -10),
              bottomRight: const Offset(-1, -1)),
          isFalse);
    });

    test('inRegion tolerates missing arguments and points', () {
      expect(stroke.inRegion(), isFalse);
      final XppStroke empty =
          XppStroke.byTool(tool: XppStrokeTool.PEN, points: const []);
      expect(
          empty.inRegion(topLeft: const Offset(0, 0),
              bottomRight: const Offset(10, 10)),
          isFalse);
    });

    test('shouldSelectAt allows half of the widest point around the box', () {
      // Bounding box (0, 5) .. (20, 30); max width 2 gives tolerance 1.
      expect(stroke.shouldSelectAt(coordinates: const Offset(20.9, 30.9)),
          isTrue);
      expect(stroke.shouldSelectAt(coordinates: const Offset(21.1, 30.9)),
          isFalse);
      expect(stroke.shouldSelectAt(coordinates: const Offset(100, 100)),
          isFalse);
      expect(stroke.shouldSelectAt(), isFalse);
    });
  });

  group('XppImage region helpers', () {
    final XppImage image = XppImage(
        base64Data: '',
        topLeft: const Offset(0, 0),
        bottomRight: const Offset(10, 10));

    test('inRegion reports box overlap', () {
      expect(
          image.inRegion(topLeft: const Offset(5, 5),
              bottomRight: const Offset(20, 20)),
          isTrue);
      expect(
          image.inRegion(topLeft: const Offset(20, 20),
              bottomRight: const Offset(30, 30)),
          isFalse);
    });

    test('shouldSelectAt checks the image bounds', () {
      expect(image.shouldSelectAt(coordinates: const Offset(10, 10)), isTrue);
      expect(image.shouldSelectAt(coordinates: const Offset(10.1, 5)),
          isFalse);
      expect(image.shouldSelectAt(), isFalse);
    });
  });

  group('XppText region helpers', () {
    final XppText text = XppText(
        color: Colors.black,
        text: 'hello',
        size: 10.0,
        fontFamily: 'Arial',
        offset: const Offset(0, 0));

    test('estimatedBottomRight approximates the text box', () {
      // 5 characters at 10 mm font size and 0.6 em average advance.
      expect(text.estimatedBottomRight, const Offset(30, 10));
    });

    test('inRegion reports the estimated box overlap', () {
      expect(
          text.inRegion(topLeft: const Offset(25, 0),
              bottomRight: const Offset(50, 10)),
          isTrue);
      expect(
          text.inRegion(topLeft: const Offset(100, 0),
              bottomRight: const Offset(120, 10)),
          isFalse);
    });

    test('shouldSelectAt checks the estimated box', () {
      expect(text.shouldSelectAt(coordinates: const Offset(30, 10)), isTrue);
      expect(text.shouldSelectAt(coordinates: const Offset(31, 10)), isFalse);
    });
  });

  group('XppTexImage', () {
    test('fontSize uses the saved box height', () {
      final XppTexImage sized = XppTexImage(
          text: 'x^2',
          topLeft: const Offset(2, 3),
          bottomRight: const Offset(12, 23),
          color: Colors.black);
      expect(sized.fontSize, 20);
    });

    test('fontSize falls back to the default while the box is unknown', () {
      final XppTexImage unsized =
          XppTexImage(text: 'x^2', topLeft: const Offset(2, 3));
      expect(unsized.fontSize, 18);
    });

    test('region helpers use the parsed box', () {
      final XppTexImage image = XppTexImage(
          text: 'x^2',
          topLeft: const Offset(2, 3),
          bottomRight: const Offset(12, 23),
          color: Colors.black);
      expect(
          image.inRegion(topLeft: const Offset(10, 20),
              bottomRight: const Offset(30, 40)),
          isTrue);
      expect(
          image.inRegion(topLeft: const Offset(100, 100),
              bottomRight: const Offset(120, 120)),
          isFalse);
      expect(image.shouldSelectAt(coordinates: const Offset(12, 23)), isTrue);
      expect(image.shouldSelectAt(coordinates: const Offset(13, 23)), isFalse);
    });
  });
}