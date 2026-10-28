import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/toolbar/toolbar.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/pen_action.dart';
import 'package:saber/data/tools/highlighter.dart';
import 'package:saber/data/tools/symbol_tool.dart';
import 'package:saber/pages/editor/editor.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  group('openPenOptionsAndColors', () {
    testWidgets('opens and closes both panels together', (tester) async {
      final state = await _pumpEditor(tester);

      expect(state.toolOptionsType.value, ToolOptions.hide);
      expect(state.showColorOptions.value, isFalse);

      state.togglePenOptionsAndColors();
      await tester.pump();
      expect(state.toolOptionsType.value, ToolOptions.pen);
      expect(state.showColorOptions.value, isTrue);

      state.togglePenOptionsAndColors();
      await tester.pump();
      expect(state.toolOptionsType.value, ToolOptions.hide);
      expect(state.showColorOptions.value, isFalse);
    });

    testWidgets('opens both panels when only the colour bar is open', (
      tester,
    ) async {
      final state = await _pumpEditor(tester);
      state.showColorOptions.value = true;
      await tester.pump();

      state.togglePenOptionsAndColors();
      await tester.pump();

      expect(state.toolOptionsType.value, ToolOptions.pen);
      expect(state.showColorOptions.value, isTrue);
    });

    testWidgets('uses the highlighter panel when the highlighter is selected', (
      tester,
    ) async {
      final state = await _pumpEditor(tester);
      state.selectTool(Highlighter.currentHighlighter);

      state.togglePenOptionsAndColors();
      await tester.pump();

      expect(state.toolOptionsType.value, ToolOptions.highlighter);
      expect(state.showColorOptions.value, isTrue);
    });

    testWidgets('uses the symbol panel when the symbol tool is selected', (
      tester,
    ) async {
      final state = await _pumpEditor(tester);
      state.selectTool(SymbolTool.current);

      state.togglePenOptionsAndColors();
      await tester.pump();

      expect(state.toolOptionsType.value, ToolOptions.symbol);
      expect(state.showColorOptions.value, isTrue);
    });
  });

  test('the settings dropdown hides the actions that were merged away', () {
    expect(PenAction.selectable, contains(PenAction.openPenOptionsAndColors));
    expect(PenAction.selectable, isNot(contains(PenAction.openPenOptions)));
    expect(PenAction.selectable, isNot(contains(PenAction.openColorPicker)));
  });
}

Future<EditorState> _pumpEditor(WidgetTester tester) async {
  FlavorConfig.setup();
  FileManager.documentsDirectory =
      '$tmpDir/pen_options_and_colors/'
      '${FileManager.appRootDirectoryPrefix}';

  await tester.pumpWidget(MaterialApp(home: Editor()));
  final state = tester.state<EditorState>(find.byType(Editor));
  addTearDown(state.cancelAutosaveAndMarkSaved);
  return state;
}
