import 'package:flutter/material.dart';
import 'package:saber/data/extensions/change_notifier_extensions.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/symbols/symbol_definition.dart';
import 'package:saber/data/symbols/symbol_registry.dart';
import 'package:saber/data/tools/_tool.dart';
import 'package:sbn/tool_id.dart';

/// Inserts SVG symbols (music notes or user-imported graphics) at the pen tip.
class SymbolTool extends Tool {
  static final current = SymbolTool(
    symbolId: stows.symbolToolSymbolId.value,
    size: stows.symbolToolSize.value,
    color: Color(stows.symbolToolColor.value),
    stemUp: stows.symbolToolStemUp.value,
  );

  new({
    required this.symbolId,
    required this.size,
    required this.color,
    required this.stemUp,
  });

  /// Fires when the selected symbol, size or colour changes.
  static final changed = ChangeNotifier();

  String symbolId;
  double size;
  Color color;
  bool stemUp;

  /// The selected symbol, falling back to a quarter note if a custom symbol
  /// was deleted.
  SymbolDefinition get symbol =>
      SymbolRegistry.byId(symbolId) ?? SymbolDefinitions.fallback;

  void setSymbol(String id) {
    if (id == symbolId) return;
    symbolId = id;
    size = size.clamp(symbol.sizeMin, symbol.sizeMax).toDouble();
    stows.symbolToolSymbolId.value = symbolId;
    stows.symbolToolSize.value = size;
    changed.notifyListenersPlease();
  }

  void setSize(double value) {
    final clamped = value.clamp(symbol.sizeMin, symbol.sizeMax).toDouble();
    if (clamped == size) return;
    size = clamped;
    stows.symbolToolSize.value = size;
    changed.notifyListenersPlease();
  }

  void setColor(Color value) {
    if (value == color) return;
    color = value;
    stows.symbolToolColor.value = color.toARGB32();
    changed.notifyListenersPlease();
  }

  void setStemUp(bool value) {
    if (value == stemUp) return;
    stemUp = value;
    stows.symbolToolStemUp.value = stemUp;
    changed.notifyListenersPlease();
  }

  @override
  ToolId get toolId => .symbol;
}
