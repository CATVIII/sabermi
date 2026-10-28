import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saber/components/theming/adaptive_alert_dialog.dart';
import 'package:saber/data/symbols/custom_symbol_store.dart';
import 'package:saber/data/symbols/symbol_definition.dart';
import 'package:saber/data/tools/symbol_tool.dart';
import 'package:saber/i18n/strings.g.dart';

/// Opens the symbol picker and returns the selected symbol id.
Future<String?> showSymbolPicker(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _SymbolPickerDialog(),
  );
}

class _SymbolPickerDialog extends StatefulWidget {
  const new();

  @override
  State<_SymbolPickerDialog> createState() => _SymbolPickerDialogState();
}

class _SymbolPickerDialogState extends State<_SymbolPickerDialog> {
  static const _tileSize = 60.0;
  static const _tileGap = 8.0;

  var _adding = false;
  Future<void> _addSvg() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['svg'],
    );
    if (file == null || !mounted) return;

    setState(() => _adding = true);
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > CustomSymbolStore.maxSvgBytes) {
        _showError(t.editor.symbols.svgTooLarge);
        return;
      }

      final svg = utf8.decode(bytes, allowMalformed: true);
      final name = file.name.replaceFirst(
        RegExp(r'\.svg$', caseSensitive: false),
        '',
      );
      final symbol = await CustomSymbolStore.addSvg(name: name, svg: svg);
      if (!mounted) return;
      SymbolTool.current.setSymbol(symbol.id);
      Navigator.of(context).pop(symbol.id);
    } catch (e) {
      if (mounted) _showError(t.editor.symbols.invalidSvg);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _delete(SymbolDefinition symbol) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AdaptiveAlertDialog(
        title: Text(t.editor.symbols.deleteSymbol),
        content: Text(symbol.label(t)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.editor.symbols.deleteSymbol),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await CustomSymbolStore.delete(symbol);
    if (!mounted) return;
    if (SymbolTool.current.symbolId == symbol.id) {
      SymbolTool.current.setSymbol(SymbolDefinitions.fallback.id);
    }
    setState(() {});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewColor = isDark ? Colors.white : Colors.black;

    return AnimatedBuilder(
      animation: CustomSymbolStore.changed,
      builder: (context, _) {
        final custom = CustomSymbolStore.symbols;
        final titleStyle = Theme.of(context).textTheme.titleSmall;
        final selectedId = SymbolTool.current.symbolId;
        final contentWidth = (MediaQuery.sizeOf(context).width - 128)
            .clamp(200.0, 360.0)
            .toDouble();

        return AdaptiveAlertDialog(
          title: Text(t.editor.symbols.pickSymbol),
          content: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.editor.symbols.builtIn, style: titleStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: _tileGap,
                    runSpacing: _tileGap,
                    children: [
                      for (final symbol in SymbolDefinitions.builtIn)
                        _SymbolTile(
                          symbol: symbol,
                          size: _tileSize,
                          color: previewColor,
                          selected: symbol.id == selectedId,
                          deletable: false,
                          onTap: () => Navigator.pop(context, symbol.id),
                          onDelete: null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(t.editor.symbols.custom, style: titleStyle),
                  const SizedBox(height: 8),
                  // Leave room on the top/right for the delete badges of the
                  // custom tiles, which sit just outside the tile.
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: Wrap(
                      spacing: _tileGap,
                      runSpacing: _tileGap,
                      children: [
                        for (final symbol in custom)
                          _SymbolTile(
                            symbol: symbol,
                            size: _tileSize,
                            color: previewColor,
                            selected: symbol.id == selectedId,
                            deletable: true,
                            onTap: () => Navigator.pop(context, symbol.id),
                            onDelete: () => _delete(symbol),
                          ),
                        _AddSymbolTile(
                          size: _tileSize,
                          adding: _adding,
                          onTap: _addSvg,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(t.common.cancel),
            ),
          ],
        );
      },
    );
  }
}

class _SymbolTile extends StatelessWidget {
  const new({
    required this.symbol,
    required this.size,
    required this.color,
    required this.selected,
    required this.deletable,
    required this.onTap,
    required this.onDelete,
  });

  final SymbolDefinition symbol;
  final double size;
  final Color color;
  final bool selected;
  final bool deletable;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: selected
                      ? Border.all(color: colorScheme.primary, width: 2)
                      : null,
                ),
                child: ColorFiltered(
                  // The picker shows a monochrome preview: black in light
                  // mode, white in dark mode. Custom SVGs keep their original
                  // colours once inserted.
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  child: SvgPicture.string(
                    symbol.buildGlyph(stemUp: true, color: color).svg,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          if (deletable)
            Positioned(
              top: -8,
              right: -8,
              child: Material(
                color: colorScheme.surfaceContainerHighest,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  iconSize: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  tooltip: t.editor.symbols.deleteSymbol,
                  onPressed: onDelete,
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddSymbolTile extends StatelessWidget {
  const new({
    required this.size,
    required this.adding,
    required this.onTap,
  });

  final double size;
  final bool adding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Tooltip(
        message: t.editor.symbols.addSvg,
        child: InkWell(
          onTap: adding ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: adding
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
                    Icons.add,
                    color: colorScheme.primary,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}
