import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saber/components/toolbar/symbol_picker.dart';
import 'package:saber/data/extensions/axis_extensions.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/symbols/symbol_definition.dart';
import 'package:saber/data/tools/symbol_tool.dart';
import 'package:saber/i18n/strings.g.dart';

/// The toolbar panel for the symbol tool: picker button, size slider and a
/// short hint about the stem direction.
class SymbolModal extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final axis = stows.editorToolbarAlignment.value.axis.opposite;
    final tool = SymbolTool.current;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: SymbolTool.changed,
      builder: (context, _) {
        final symbol = tool.symbol;
        final slider = SizedBox(
          width: 150,
          child: Slider(
            value: tool.size.clamp(symbol.sizeMin, symbol.sizeMax).toDouble(),
            min: symbol.sizeMin,
            max: symbol.sizeMax,
            divisions:
                ((symbol.sizeMax - symbol.sizeMin) / symbol.sizeStep).round(),
            onChanged: tool.setSize,
          ),
        );

        return Flex(
          direction: axis,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            TextButton(
              onPressed: () async {
                final id = await showSymbolPicker(context);
                if (id != null) tool.setSymbol(id);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SymbolThumbnail(symbol: symbol),
                  const SizedBox(width: 6),
                  Text(symbol.label(t)),
                ],
              ),
            ),
            Text(t.editor.symbols.size),
            RotatedBox(
              quarterTurns: axis == Axis.vertical ? 1 : 0,
              child: slider,
            ),
            Text(tool.size.round().toString()),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                symbol.supportsStem
                    ? t.editor.symbols.stemHint
                    : t.editor.symbols.tapToInsert,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SymbolThumbnail extends StatelessWidget {
  const new({required this.symbol});

  final SymbolDefinition symbol;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == .dark
        ? Colors.white
        : Colors.black;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        width: 28,
        height: 28,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(color, .srcIn),
          child: SvgPicture.string(
            symbol.buildGlyph(stemUp: true, color: color).svg,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
