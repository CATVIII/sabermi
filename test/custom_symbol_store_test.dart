import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/symbols/custom_symbol_store.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sabermi_symbols_test');
    CustomSymbolStore.directoryOverride = dir;
    await CustomSymbolStore.init();
  });

  tearDown(() async {
    CustomSymbolStore.directoryOverride = null;
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('adds, reloads and deletes a custom SVG', () async {
    final symbol = await CustomSymbolStore.addSvg(
      name: 'Star',
      svg: '<svg xmlns="http://www.w3.org/2000/svg" '
          'viewBox="0 0 24 48"><path d="M0 0"/></svg>',
    );

    expect(symbol.isCustom, isTrue);
    expect(symbol.supportsStem, isFalse);
    expect(symbol.referenceSize, 48);
    final glyph = symbol.buildGlyph(stemUp: true, color: Colors.black);
    expect(glyph.viewBox, const Size(24, 48));
    expect(glyph.anchor, const Offset(12, 24));
    expect(CustomSymbolStore.symbols, hasLength(1));
    expect(File('${dir.path}/${symbol.id}.svg').existsSync(), isTrue);

    // Reload from disk, as if the app was restarted.
    await CustomSymbolStore.init();
    expect(CustomSymbolStore.symbols, hasLength(1));
    expect(CustomSymbolStore.symbols.first.id, symbol.id);
    expect(
      CustomSymbolStore.symbols.first.buildGlyph(
        stemUp: true,
        color: Colors.black,
      ).viewBox,
      const Size(24, 48),
    );

    await CustomSymbolStore.delete(symbol);
    expect(CustomSymbolStore.symbols, isEmpty);
    expect(File('${dir.path}/${symbol.id}.svg').existsSync(), isFalse);
  });

  test('rejects files that are not SVGs', () async {
    await expectLater(
      CustomSymbolStore.addSvg(name: 'bad', svg: 'not an svg'),
      throwsArgumentError,
    );
  });

  test('parses viewBox, width/height and falls back', () {
    expect(
      CustomSymbolStore.parseViewBox('<svg viewBox="0 0 32 16"/>'),
      const Size(32, 16),
    );
    expect(
      CustomSymbolStore.parseViewBox('<svg width="20" height="30"/>'),
      const Size(20, 30),
    );
    expect(CustomSymbolStore.parseViewBox('<svg/>'), const Size(100, 100));
  });
}
