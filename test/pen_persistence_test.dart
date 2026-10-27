import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tools/highlighter.dart';
import 'package:saber/data/tools/pen.dart';
import 'package:saber/data/tools/pencil.dart';
import 'package:saber/data/tools/shape_pen.dart';

void main() {
  FlavorConfig.setup();

  group('pen properties are persisted', () {
    test('fountain pen size and colour', () {
      final pen = Pen.fountainPen();
      pen.options = StrokeOptions(size: 17);
      pen.color = const Color(0xFF123456);
      pen.saveOptions();
      pen.saveColor();

      expect(stows.lastFountainPenOptions.value.size, 17);
      expect(stows.lastFountainPenColor.value, 0xFF123456);

      final restored = Pen.fountainPen();
      expect(restored.options.size, 17);
      expect(restored.color.toARGB32(), 0xFF123456);
    });

    test('ballpoint pen size and colour', () {
      final pen = Pen.ballpointPen();
      pen.options = StrokeOptions(size: 8);
      pen.color = const Color(0xFF654321);
      pen.saveOptions();
      pen.saveColor();

      final restored = Pen.ballpointPen();
      expect(restored.options.size, 8);
      expect(restored.color.toARGB32(), 0xFF654321);
    });

    test('pencil size and colour', () {
      final pen = Pencil.currentPencil;
      pen.options = StrokeOptions(size: 9);
      pen.color = const Color(0xFF00FF00);
      pen.saveOptions();
      pen.saveColor();

      final restored = Pencil();
      expect(restored.options.size, 9);
      expect(restored.color.toARGB32(), 0xFF00FF00);
    });

    test('highlighter colour is read from its stow', () {
      final pen = Highlighter.currentHighlighter;
      pen.color = const Color(0xFF00FFFF).withAlpha(Highlighter.alpha);
      pen.saveColor();

      expect(stows.lastHighlighterColor.value, pen.color.toARGB32());
      expect(Highlighter().color.toARGB32(), pen.color.toARGB32());
    });

    test('shape pen colour', () async {
      // ShapePen's static initializer asserts that this pref has been read.
      await stows.shapeRecognitionDelay.waitUntilRead();

      final pen = ShapePen();
      pen.color = const Color(0xFFABCDEF);
      pen.saveColor();

      expect(stows.lastShapePenColor.value, 0xFFABCDEF);
      expect(ShapePen().color.toARGB32(), 0xFFABCDEF);
    });

    test('saveOptions forces a write when the options object is reused', () {
      final pen = Pen.fountainPen();
      // Pen.options is usually the very object stored in the stow, so mutating
      // it in place doesn't change its identity and `stow.value = ...` alone
      // would be a no-op.
      pen.options.size = 12;

      var notifications = 0;
      void listener() => notifications++;
      stows.lastFountainPenOptions.addListener(listener);
      addTearDown(
        () => stows.lastFountainPenOptions.removeListener(listener),
      );

      pen.saveOptions();

      expect(notifications, greaterThan(0));
      expect(stows.lastFountainPenOptions.value.size, 12);
    });
  });
}
