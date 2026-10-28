import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/symbols/symbol_definition.dart';

void main() {
  FlavorConfig.setup();

  test('the first batch contains the five music notes', () {
    expect(SymbolDefinitions.builtIn.map((symbol) => symbol.id), [
      'builtin:whole',
      'builtin:half',
      'builtin:quarter',
      'builtin:eighth',
      'builtin:sixteenth',
    ]);
  });

  test('dstRectFor places the anchor at the landing point', () {
    final symbol = SymbolDefinitions.fallback;
    final glyph = symbol.buildGlyph(stemUp: true, color: Colors.black);
    const landing = Offset(200, 300);
    const size = 40.0;

    final scale = symbol.scaleFor(size);
    final rect = glyph.dstRectFor(anchorOnPage: landing, scale: scale);

    expect(rect.left + glyph.anchor.dx * scale, closeTo(landing.dx, 1e-9));
    expect(rect.top + glyph.anchor.dy * scale, closeTo(landing.dy, 1e-9));
    expect(rect.width, closeTo(glyph.viewBox.width * scale, 1e-9));
    expect(rect.height, closeTo(glyph.viewBox.height * scale, 1e-9));
  });

  test('note glyphs encode the stem direction with tight bounds', () {
    final quarter = SymbolDefinitions.builtIn.firstWhere(
      (symbol) => symbol.id == 'builtin:quarter',
    );

    final up = quarter.buildGlyph(stemUp: true, color: Colors.black);
    final down = quarter.buildGlyph(stemUp: false, color: Colors.black);

    expect(up.svg, contains('stemUp'));
    expect(down.svg, contains('stemDown'));
    expect(up.viewBox, const Size(72, 112));
    expect(down.viewBox, const Size(48, 112));
    expect(up.anchor.dy, isNot(down.anchor.dy));

    final whole = SymbolDefinitions.builtIn.firstWhere(
      (symbol) => symbol.id == 'builtin:whole',
    );
    expect(whole.supportsStem, isFalse);
    expect(
      whole.buildGlyph(stemUp: true, color: Colors.black).svg,
      isNot(contains('stemUp')),
    );
    expect(
      whole.buildGlyph(stemUp: true, color: Colors.black).viewBox,
      const Size(52, 40),
    );
  });

  test('monochrome notes use the requested colour', () {
    final glyph = SymbolDefinitions.fallback.buildGlyph(
      stemUp: true,
      color: const Color(0xFFFF0000),
    );
    expect(glyph.svg, contains('#ff0000'));
  });
}
