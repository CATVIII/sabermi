import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/toolbar/symbol_picker.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/symbols/symbol_definition.dart';
import 'package:saber/data/tools/symbol_tool.dart';
import 'package:saber/i18n/strings.g.dart';

void main() {
  FlavorConfig.setup();

  setUp(() {
    SymbolTool.current.setSymbol('builtin:quarter');
  });

  testWidgets('the picker shows compact, label-free note tiles', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSymbolPicker(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SvgPicture), findsNWidgets(5));
    expect(find.byIcon(Icons.add), findsOneWidget);

    // The note names under the previews were removed to keep the picker dense.
    for (final symbol in SymbolDefinitions.builtIn) {
      expect(find.text(symbol.label(t)), findsNothing);
    }
  });
}
