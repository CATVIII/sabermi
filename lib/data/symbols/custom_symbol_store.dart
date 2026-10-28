import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saber/data/extensions/change_notifier_extensions.dart';
import 'package:saber/data/symbols/symbol_definition.dart';

/// Metadata stored in `index.json` for a user-imported SVG.
class CustomSymbolMeta {
  const new({required this.id, required this.name, required this.size});

  final String id;
  final String name;
  final Size size;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'w': size.width,
    'h': size.height,
  };

  factory fromJson(Map<String, dynamic> json) => CustomSymbolMeta(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'SVG',
    size: Size(
      (json['w'] as num?)?.toDouble() ?? 100,
      (json['h'] as num?)?.toDouble() ?? 100,
    ),
  );
}

class _CustomSymbol {
  const new({required this.meta, required this.definition});

  final CustomSymbolMeta meta;
  final SymbolDefinition definition;
}

/// Stores user-imported SVG symbols in the app's private support directory.
///
/// These live outside the notes directory (so they don't appear in the note
/// list or get synced) and outside the bundled assets, and survive app updates.
abstract final class CustomSymbolStore {
  static final log = Logger('CustomSymbolStore');

  /// Fires when [symbols] changes (add, delete or reload).
  static final changed = ChangeNotifier();

  /// Maximum accepted SVG file size.
  static const maxSvgBytes = 1024 * 1024;

  static final List<_CustomSymbol> _items = [];

  @visibleForTesting
  static Directory? directoryOverride;

  static List<SymbolDefinition> get symbols =>
      List.unmodifiable(_items.map((item) => item.definition));

  static Future<Directory> directory() async {
    final override = directoryOverride;
    if (override != null) return override;
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/custom_symbols');
  }

  /// Loads the index and SVG contents from disk.
  static Future<void> init() async {
    _items.clear();
    try {
      final dir = await directory();
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
        return;
      }

      final indexFile = File('${dir.path}/index.json');
      if (!indexFile.existsSync()) return;

      final decoded = jsonDecode(await indexFile.readAsString());
      if (decoded is! List) {
        log.warning('custom symbols index is not a list');
        return;
      }

      for (final entry in decoded) {
        try {
          final meta = CustomSymbolMeta.fromJson(
            (entry as Map).cast<String, dynamic>(),
          );
          final svgFile = File('${dir.path}/${meta.id}.svg');
          if (!svgFile.existsSync()) {
            log.warning('missing SVG for ${meta.id}');
            continue;
          }
          final svg = await svgFile.readAsString();
          _items.add(
            _CustomSymbol(meta: meta, definition: _definition(meta, svg)),
          );
        } catch (e, s) {
          log.warning('skipping invalid custom symbol', e, s);
        }
      }

      _items.sort((a, b) => a.meta.name.compareTo(b.meta.name));
    } catch (e, s) {
      log.warning('failed to load custom symbols', e, s);
    } finally {
      changed.notifyListenersPlease();
    }
  }

  /// Imports [svg] under [name] and returns the new symbol.
  ///
  /// Throws [ArgumentError] if the file isn't a valid SVG.
  static Future<SymbolDefinition> addSvg({
    required String name,
    required String svg,
  }) async {
    if (svg.trim().isEmpty) {
      throw ArgumentError.value(svg, 'svg', 'Empty SVG');
    }
    if (utf8.encode(svg).length > maxSvgBytes) {
      throw ArgumentError.value(svg, 'svg', 'SVG is too large');
    }
    if (!svg.toLowerCase().contains('<svg')) {
      throw ArgumentError.value(svg, 'svg', 'Not an SVG file');
    }

    final size = parseViewBox(svg);
    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    final meta = CustomSymbolMeta(
      id: id,
      name: name.trim().isEmpty ? 'SVG' : name.trim(),
      size: size,
    );

    final dir = await directory();
    await dir.create(recursive: true);
    await File('${dir.path}/$id.svg').writeAsString(svg, flush: true);

    _items.add(_CustomSymbol(meta: meta, definition: _definition(meta, svg)));
    _items.sort((a, b) => a.meta.name.compareTo(b.meta.name));
    await _writeIndex(dir);
    changed.notifyListenersPlease();

    return _items.firstWhere((item) => item.meta.id == id).definition;
  }

  /// Removes a custom symbol's file and index entry.
  static Future<void> delete(SymbolDefinition symbol) async {
    if (!symbol.isCustom) return;
    _items.removeWhere((item) => item.meta.id == symbol.id);

    final dir = await directory();
    final file = File('${dir.path}/${symbol.id}.svg');
    if (file.existsSync()) await file.delete();
    await _writeIndex(dir);

    changed.notifyListenersPlease();
  }

  /// Parses the SVG's viewBox, falling back to its width/height attributes.
  @visibleForTesting
  static Size parseViewBox(String svg) {
    final viewBox = RegExp(
      r'''viewBox\s*=\s*["']([^"']+)["']''',
    ).firstMatch(svg);
    if (viewBox != null) {
      final parts = viewBox
          .group(1)!
          .trim()
          .split(RegExp(r'[\s,]+'))
          .map((part) => double.tryParse(part))
          .toList();
      if (parts.length == 4 &&
          parts[2] != null &&
          parts[3] != null &&
          parts[2]! > 0 &&
          parts[3]! > 0) {
        return Size(parts[2]!, parts[3]!);
      }
    }

    final width = _parseLength(svg, 'width');
    final height = _parseLength(svg, 'height');
    if (width != null && height != null && width > 0 && height > 0) {
      return Size(width, height);
    }

    return const Size(100, 100);
  }

  static double? _parseLength(String svg, String attribute) {
    final match = RegExp(
      '''\\b$attribute\\s*=\\s*["']\\s*([\\d.]+)''',
    ).firstMatch(svg);
    return double.tryParse(match?.group(1) ?? '');
  }

  static SymbolDefinition _definition(CustomSymbolMeta meta, String svg) {
    final longest = max(meta.size.width, meta.size.height);
    return SymbolDefinition(
      id: meta.id,
      label: (t) => meta.name,
      referenceSize: longest <= 0 ? 100 : longest,
      supportsStem: false,
      isCustom: true,
      sizeMin: 10,
      sizeMax: 200,
      buildGlyph: ({required stemUp, required color}) => SymbolGlyph(
        svg: svg,
        viewBox: meta.size,
        anchor: meta.size.center(Offset.zero),
      ),
    );
  }

  static Future<void> _writeIndex(Directory dir) async {
    final index = jsonEncode(
      [for (final item in _items) item.meta.toJson()],
    );
    await File('${dir.path}/index.json').writeAsString(index, flush: true);
  }
}
