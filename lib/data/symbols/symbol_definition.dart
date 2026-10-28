import 'dart:ui';

import 'package:saber/i18n/strings.g.dart';

/// The rendered SVG of a symbol and the coordinate system it uses.
///
/// Music notes have direction-dependent bounds (a stem-up note extends upwards
/// from the notehead, a stem-down note downwards), so the glyph carries its own
/// viewBox and anchor.
class SymbolGlyph {
  const new({required this.svg, required this.viewBox, required this.anchor});

  final String svg;
  final Size viewBox;

  /// The point inside [viewBox] that is placed at the pen's landing point.
  final Offset anchor;

  /// The rect (in page coordinates) that puts [anchor] at [anchorOnPage].
  Rect dstRectFor({required Offset anchorOnPage, required double scale}) {
    return Rect.fromLTWH(
      anchorOnPage.dx - anchor.dx * scale,
      anchorOnPage.dy - anchor.dy * scale,
      viewBox.width * scale,
      viewBox.height * scale,
    );
  }
}

/// A symbol that the symbol tool can insert: a music note or a user SVG.
class SymbolDefinition {
  const new({
    required this.id,
    required this.label,
    required this.referenceSize,
    required this.supportsStem,
    required this.buildGlyph,
    this.isCustom = false,
    this.sizeMin = 10,
    this.sizeMax = 200,
    this.sizeStep = 2,
  });

  /// A stable id, e.g. `builtin:quarter` or `custom_1712...`.
  final String id;

  /// Localised display name.
  final String Function(Translations t) label;

  /// The size controlled by the toolbar slider, in the glyph's own units.
  ///
  /// Music notes use the notehead width; plain SVGs use their longest side.
  final double referenceSize;

  /// Whether dragging up/down changes the symbol's stem direction.
  final bool supportsStem;

  /// Builds the glyph to insert. [stemUp] and [color] are ignored by custom
  /// SVG symbols so that multi-colour graphics keep their original colours.
  final SymbolGlyph Function({required bool stemUp, required Color color})
  buildGlyph;

  final bool isCustom;

  final double sizeMin, sizeMax, sizeStep;

  double scaleFor(double size) => size / referenceSize;
}

/// The symbols bundled with the app.
abstract final class SymbolDefinitions {
  static final List<SymbolDefinition> builtIn = [
    _wholeNote,
    _halfNote,
    _quarterNote,
    _eighthNote,
    _sixteenthNote,
  ];

  static SymbolDefinition get fallback => _quarterNote;
}

final _wholeNote = SymbolDefinition(
  id: 'builtin:whole',
  label: (t) => t.editor.symbols.notes.whole,
  referenceSize: _noteHeadWidth,
  supportsStem: false,
  sizeMin: 10,
  sizeMax: 80,
  buildGlyph: ({required stemUp, required color}) => _noteGlyph(
    whole: true,
    filled: false,
    flags: 0,
    stemUp: stemUp,
    color: color,
  ),
);

final _halfNote = SymbolDefinition(
  id: 'builtin:half',
  label: (t) => t.editor.symbols.notes.half,
  referenceSize: _noteHeadWidth,
  supportsStem: true,
  sizeMin: 10,
  sizeMax: 80,
  buildGlyph: ({required stemUp, required color}) =>
      _noteGlyph(filled: false, flags: 0, stemUp: stemUp, color: color),
);

final _quarterNote = SymbolDefinition(
  id: 'builtin:quarter',
  label: (t) => t.editor.symbols.notes.quarter,
  referenceSize: _noteHeadWidth,
  supportsStem: true,
  sizeMin: 10,
  sizeMax: 80,
  buildGlyph: ({required stemUp, required color}) =>
      _noteGlyph(filled: true, flags: 0, stemUp: stemUp, color: color),
);

final _eighthNote = SymbolDefinition(
  id: 'builtin:eighth',
  label: (t) => t.editor.symbols.notes.eighth,
  referenceSize: _noteHeadWidth,
  supportsStem: true,
  sizeMin: 10,
  sizeMax: 80,
  buildGlyph: ({required stemUp, required color}) =>
      _noteGlyph(filled: true, flags: 1, stemUp: stemUp, color: color),
);

final _sixteenthNote = SymbolDefinition(
  id: 'builtin:sixteenth',
  label: (t) => t.editor.symbols.notes.sixteenth,
  referenceSize: _noteHeadWidth,
  supportsStem: true,
  sizeMin: 10,
  sizeMax: 80,
  buildGlyph: ({required stemUp, required color}) =>
      _noteGlyph(filled: true, flags: 2, stemUp: stemUp, color: color),
);

const _noteHeadWidth = 44.0;

// Noteheads extracted from `1342057_4586.svg` (a music worksheet icon).
// Only the notehead paths are reused; the stem and flags are redrawn cleanly.
const _filledNoteHeadPath =
    'M132.014,40.439c1.229,2.308-0.587,5.68-4.058,7.53'
    'c-3.473,1.854-7.285,1.484-8.518-0.825'
    'c-1.23-2.309,0.586-5.681,4.061-7.531'
    'C126.97,37.761,130.782,38.131,132.014,40.439z';
const _hollowNoteHeadPath =
    'M132.014,90.261c-1.232-2.308-5.044-2.677-8.515-0.825'
    'c-3.475,1.853-5.291,5.225-4.061,7.532'
    'c1.232,2.309,5.045,2.679,8.518,0.826'
    'C131.427,95.943,133.243,92.571,132.014,90.261z '
    'M127.257,96.455c-2.693,1.437-6.153,2.215-7.106,0.428'
    'c-0.955-1.788,1.582-4.336,4.275-5.771'
    'c2.693-1.439,5.743-1.908,6.696-0.12'
    'C132.075,92.777,129.95,95.02,127.257,96.455z';

// The icon's whole note is a flat, horizontal hollow oval (unlike the tilted
// noteheads used for the other note values).
const _wholeNoteHeadPath =
    'M53.905,58.058c-3.936-0.007-7.129,2.109-7.134,4.726'
    'c-0.004,2.617,3.184,4.741,7.118,4.747'
    'c3.936,0.007,7.129-2.109,7.135-4.726'
    'C61.027,60.189,57.842,58.065,53.905,58.058z '
    'M58.768,64.127c-0.432,1.572-2.961,2.251-5.649,1.514'
    'c-2.69-0.735-4.52-2.606-4.088-4.182'
    'c0.431-1.572,2.959-2.249,5.648-1.514'
    'C57.366,60.684,59.198,62.555,58.768,64.127z';

// The notehead paths' actual bounding boxes inside the source icon, measured
// by sampling the curves. Using the real bounds (instead of the icon's nominal
// notehead width) keeps the notehead at the requested size and, more
// importantly, puts its right/left edge exactly under the stem.
const _iconNoteHeadCenterX = 125.726;
const _iconFilledCenterY = 43.792;
const _iconHollowCenterY = 93.735;
const _iconNoteHeadWidth = 13.345;

// Bounds of the flat whole-note oval in the same source icon.
const _iconWholeCenterX = 53.897;
const _iconWholeCenterY = 62.795;
const _iconWholeWidth = 14.253;

/// Builds a music note with the notehead extracted from the provided icon.
///
/// The notehead is placed at [center] and scaled so its width is
/// [_noteHeadWidth]; the stem and flags are drawn in the glyph's own units.
String _noteHeadGroup({
  required bool filled,
  required String color,
  required Offset center,
}) {
  final path = filled ? _filledNoteHeadPath : _hollowNoteHeadPath;
  final iconCenterY = filled ? _iconFilledCenterY : _iconHollowCenterY;
  const scale = _noteHeadWidth / _iconNoteHeadWidth;
  return '<g transform="translate(${center.dx},${center.dy}) '
      'scale($scale) translate(${-_iconNoteHeadCenterX},${-iconCenterY})">'
      '<path d="$path" fill="$color" fill-rule="evenodd"/></g>';
}

/// Places the flat whole-note head from the source icon at [center].
String _wholeNoteHeadGroup({required String color, required Offset center}) {
  const scale = _noteHeadWidth / _iconWholeWidth;
  return '<g transform="translate(${center.dx},${center.dy}) '
      'scale($scale) translate(${-_iconWholeCenterX},${-_iconWholeCenterY})">'
      '<path d="$_wholeNoteHeadPath" fill="$color" fill-rule="evenodd"/></g>';
}

SymbolGlyph _noteGlyph({
  bool whole = false,
  required bool filled,
  required int flags,
  required bool stemUp,
  required Color color,
}) {
  final c = _svgColor(color);

  if (whole) {
    const anchor = Offset(26, 20);
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 52 40">'
        '<desc>whole</desc>'
        '${_wholeNoteHeadGroup(color: c, center: anchor)}'
        '</svg>';
    return SymbolGlyph(svg: svg, viewBox: const Size(52, 40), anchor: anchor);
  }

  const headCenterX = 50.0;
  final headCenterY = stemUp ? 100.0 : 20.0;
  final sb = StringBuffer()
    ..write(
      _noteHeadGroup(
        filled: filled,
        color: c,
        center: Offset(headCenterX, headCenterY),
      ),
    );

  // Attach the stem at the notehead's widest point so its outer edge is flush
  // with the head and no part of the stem sticks out past the head.
  if (stemUp) {
    final stemBottom = filled ? 94.2 : 95.5;
    sb.write(
      '<rect x="68" y="10" width="4" height="${stemBottom - 10}" fill="$c"/>',
    );
    for (var i = 0; i < flags; i++) {
      final y = 10.0 + i * 20;
      sb.write(
        '<path d="M72 $y C 87 ${y + 4}, 94 ${y + 14}, 92 ${y + 28} '
        'C 89 ${y + 17}, 82 ${y + 11}, 72 ${y + 9} Z" fill="$c"/>',
      );
    }
  } else {
    final stemTop = filled ? 25.8 : 25.4;
    sb.write(
      '<rect x="28" y="$stemTop" width="4" height="${110 - stemTop}" fill="$c"/>',
    );
    for (var i = 0; i < flags; i++) {
      final y = 110.0 - i * 20;
      sb.write(
        '<path d="M32 $y C 47 ${y - 4}, 54 ${y - 14}, 52 ${y - 28} '
        'C 49 ${y - 17}, 42 ${y - 11}, 32 ${y - 9} Z" fill="$c"/>',
      );
    }
  }

  // Crop the glyph to its ink (plus 2 units of padding) so the picker
  // preview, selection handles and eraser hit area hug the note. Stem-up and
  // stem-down notes extend in opposite directions, so they need separate
  // crops. Down stems and flags only extend to the right now, so that glyph
  // is narrower.
  const dx = -26.0;
  final dy = stemUp ? -8.0 : 0.0;
  final viewBox = stemUp ? const Size(72, 112) : const Size(48, 112);
  final anchor = Offset(headCenterX + dx, headCenterY + dy);
  final svg =
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'viewBox="0 0 ${viewBox.width} ${viewBox.height}">'
      '<desc>${stemUp ? 'stemUp' : 'stemDown'}</desc>'
      '<g transform="translate($dx,$dy)">$sb</g>'
      '</svg>';
  return SymbolGlyph(svg: svg, viewBox: viewBox, anchor: anchor);
}

String _svgColor(Color color) {
  final argb = color.toARGB32();
  final rgb = argb & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}
