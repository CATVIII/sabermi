import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/canvas/canvas_image.dart';
import 'package:saber/components/canvas/image/editor_image.dart';
import 'package:saber/components/canvas/symbol_cursor_preview.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/tools/eraser.dart';
import 'package:saber/data/tools/symbol_tool.dart';
import 'package:saber/pages/editor/editor.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  FlavorConfig.setup();

  setUp(() {
    // Don't leave image load-out timers pending at the end of a test.
    EditorImage.shouldLoadOutImmediately = true;
    SymbolTool.current.setSymbol('builtin:quarter');
    SymbolTool.current.setSize(40);
    SymbolTool.current.setColor(Colors.black);
    SymbolTool.current.setStemUp(true);
  });

  tearDown(() {
    EditorImage.shouldLoadOutImmediately = false;
  });

  testWidgets('a stylus drag inserts a stem-up note at the landing point', (
    tester,
  ) async {
    final state = await _pumpEditor(tester);
    final page = state.coreInfo.pages.first;
    final center = tester.getCenter(find.byType(Editor));
    final downPage = page.renderBox!.globalToLocal(center);

    await _dragWithStylus(tester, center, const Offset(0, -120));

    expect(page.images, hasLength(1));
    final image = page.images.first as SvgEditorImage;
    expect(_svgOf(image), contains('stemUp'));
    _expectAnchorAt(image, downPage, stemUp: true);
  });

  testWidgets('dragging down inserts a stem-down note', (tester) async {
    final state = await _pumpEditor(tester);
    final page = state.coreInfo.pages.first;
    final center = tester.getCenter(find.byType(Editor));
    final downPage = page.renderBox!.globalToLocal(center);

    await _dragWithStylus(tester, center, const Offset(0, 120));

    expect(page.images, hasLength(1));
    final image = page.images.first as SvgEditorImage;
    expect(_svgOf(image), contains('stemDown'));
    _expectAnchorAt(image, downPage, stemUp: false);
  });

  testWidgets('the toolbar size and colour are used for new symbols', (
    tester,
  ) async {
    final state = await _pumpEditor(tester);
    SymbolTool.current.setSize(20);
    SymbolTool.current.setColor(const Color(0xFFFF0000));

    final page = state.coreInfo.pages.first;
    final center = tester.getCenter(find.byType(Editor));
    await _dragWithStylus(tester, center, const Offset(0, -120));

    final image = page.images.first as SvgEditorImage;
    final symbol = SymbolTool.current.symbol;
    final glyph = symbol.buildGlyph(
      stemUp: true,
      color: SymbolTool.current.color,
    );
    expect(
      image.dstRect.width,
      closeTo(glyph.viewBox.width * 20 / symbol.referenceSize, 1e-9),
    );
    expect(_svgOf(image), contains('#ff0000'));
  });

  testWidgets('hovering the stylus shows the symbol preview', (tester) async {
    await _pumpEditor(tester);

    final pointer = TestPointer(1, PointerDeviceKind.stylus);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.byType(Editor))),
    );
    await tester.pump();

    expect(find.byKey(SymbolCursorPreview.previewKey), findsOneWidget);
  });

  testWidgets('hover and press use the same canvas position', (tester) async {
    await _pumpEditor(tester);
    SymbolTool.current.setSize(20);

    final center = tester.getCenter(find.byType(Editor));
    final pointer = TestPointer(1, PointerDeviceKind.stylus);
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.pump();

    final preview = tester.widget<SymbolCursorPreview>(
      find.byType(SymbolCursorPreview),
    );
    final hover = preview.hoverPosition.value;
    expect(hover, isNotNull);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.stylus);
    await gesture.moveTo(center);
    await gesture.down(center);
    await tester.pump();

    final pending = tester
        .widget<SymbolCursorPreview>(find.byType(SymbolCursorPreview))
        .pending
        .value;
    expect(pending, isNotNull);
    expect(pending!.screenPosition.dx, closeTo(hover!.dx, 0.01));
    expect(pending.screenPosition.dy, closeTo(hover.dy, 0.01));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('a small note image stays centred on its dstRect', (
    tester,
  ) async {
    final state = await _pumpEditor(tester);
    SymbolTool.current.setSize(15);

    final page = state.coreInfo.pages.first;
    final center = tester.getCenter(find.byType(Editor));
    await _dragWithStylus(tester, center, const Offset(0, -120));
    await tester.pump();

    final image = page.images.single;
    final canvasImage = find.byWidgetPredicate(
      (widget) => widget is CanvasImage && widget.image == image,
    );
    expect(canvasImage, findsOneWidget);

    final box = tester.renderObject<RenderBox>(canvasImage);
    final boxCenter = box.localToGlobal(box.size.center(Offset.zero));
    final imageCenter = page.renderBox!.localToGlobal(image.dstRect.center);

    expect(boxCenter.dx, closeTo(imageCenter.dx, 0.1));
    expect(boxCenter.dy, closeTo(imageCenter.dy, 0.1));
  });

  testWidgets('the eraser removes a whole symbol and undo restores it', (
    tester,
  ) async {
    final state = await _pumpEditor(tester);
    final page = state.coreInfo.pages.first;
    final center = tester.getCenter(find.byType(Editor));

    await _dragWithStylus(tester, center, const Offset(0, -120));
    expect(page.images, hasLength(1));
    expect(page.images.first.isSymbol, isTrue);

    final imageCenter = page.images.first.dstRect.center;
    final global = page.renderBox!.localToGlobal(imageCenter);

    state.selectTool(Eraser());
    await tester.pump();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.stylus);
    await gesture.moveTo(global);
    await gesture.down(global);
    await gesture.moveBy(
      const Offset(2, 2),
      timeStamp: const Duration(milliseconds: 20),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 40));
    await tester.pump();

    expect(page.images, isEmpty);

    state.undo();
    await tester.pump();
    expect(page.images, hasLength(1));
  });
}

Future<EditorState> _pumpEditor(WidgetTester tester) async {
  FileManager.documentsDirectory =
      '$tmpDir/symbol_tool_test/'
      '${FileManager.appRootDirectoryPrefix}';

  await tester.pumpWidget(MaterialApp(home: Editor()));
  await tester.pump();
  final state = tester.state<EditorState>(find.byType(Editor));
  addTearDown(state.cancelAutosaveAndMarkSaved);

  // Wait for the note to load and the first page to be laid out.
  for (
    var i = 0;
    i < 20 &&
        (state.coreInfo.pages.isEmpty ||
            state.coreInfo.pages.first.renderBox == null);
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 50));
  }

  state.selectTool(SymbolTool.current);
  await tester.pump();
  return state;
}

Future<void> _dragWithStylus(
  WidgetTester tester,
  Offset start,
  Offset delta,
) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.stylus);
  await gesture.moveTo(start);
  await gesture.down(start);
  for (var i = 1; i <= 5; i++) {
    await gesture.moveBy(delta / 5, timeStamp: Duration(milliseconds: i * 20));
  }
  await gesture.up(timeStamp: const Duration(milliseconds: 200));
  await tester.pump();
}

String _svgOf(SvgEditorImage image) =>
    (image.svgLoader as SvgStringLoader).provideSvg(null);

void _expectAnchorAt(
  EditorImage image,
  Offset expected, {
  required bool stemUp,
}) {
  final tool = SymbolTool.current;
  final symbol = tool.symbol;
  final glyph = symbol.buildGlyph(stemUp: stemUp, color: tool.color);
  final scale = symbol.scaleFor(tool.size);
  expect(image.dstRect.left + glyph.anchor.dx * scale, closeTo(expected.dx, 1));
  expect(image.dstRect.top + glyph.anchor.dy * scale, closeTo(expected.dy, 1));
}
