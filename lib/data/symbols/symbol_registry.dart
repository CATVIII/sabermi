import 'package:saber/data/symbols/custom_symbol_store.dart';
import 'package:saber/data/symbols/symbol_definition.dart';

/// Looks up bundled and user-imported symbols by id.
abstract final class SymbolRegistry {
  static List<SymbolDefinition> get all => [
    ...SymbolDefinitions.builtIn,
    ...CustomSymbolStore.symbols,
  ];

  static SymbolDefinition? byId(String id) {
    for (final symbol in all) {
      if (symbol.id == id) return symbol;
    }
    return null;
  }

  static bool isBuiltIn(String id) =>
      SymbolDefinitions.builtIn.any((symbol) => symbol.id == id);
}
