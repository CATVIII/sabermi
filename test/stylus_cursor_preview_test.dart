import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/canvas/stylus_cursor_preview.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/pages/editor/editor.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  group('StylusCursorPreview.screenDiameter', () {
    test('scales with the page and the zoom', () {
      expect(
        StylusCursorPreview.screenDiameter(
          diameter: 10,
          pageScale: 0.5,
          zoom: 2,
        ),
        10,
      );
    });

    test('clamps tiny and huge rings', () {
      expect(
        StylusCursorPreview.screenDiameter(
          diameter: 1,
          pageScale: 0.1,
          zoom: 1,
        ),
        6,
      );
      expect(
        StylusCursorPreview.screenDiameter(
          diameter: 100,
          pageScale: 2,
          zoom: 5,
        ),
        200,
      );
    });
  });

  testWidgets('shows the cursor only while a position is set', (tester) async {
    final position = ValueNotifier<Offset?>(null);
    final controller = TransformationController();
    final sizeRevision = ValueNotifier(0);
    addTearDown(position.dispose);
    addTearDown(controller.dispose);
    addTearDown(sizeRevision.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              StylusCursorPreview(
                position: position,
                color: Colors.black,
                diameter: () => 10,
                pageScale: 1,
                transformationController: controller,
                sizeListenable: sizeRevision,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(StylusCursorPreview.cursorKey), findsNothing);

    position.value = const Offset(100, 100);
    await tester.pump();
    expect(find.byKey(StylusCursorPreview.cursorKey), findsOneWidget);

    position.value = null;
    await tester.pump();
    expect(find.byKey(StylusCursorPreview.cursorKey), findsNothing);
  });

  testWidgets('the ring follows live brush size changes', (tester) async {
    final position = ValueNotifier<Offset?>(const Offset(100, 100));
    final controller = TransformationController();
    final sizeRevision = ValueNotifier(0);
    var diameter = 10.0;
    addTearDown(position.dispose);
    addTearDown(controller.dispose);
    addTearDown(sizeRevision.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              StylusCursorPreview(
                position: position,
                color: Colors.black,
                diameter: () => diameter,
                pageScale: 1,
                transformationController: controller,
                sizeListenable: sizeRevision,
              ),
            ],
          ),
        ),
      ),
    );

    double ringWidth() => tester
        .widget<Positioned>(find.byKey(StylusCursorPreview.cursorKey))
        .width!;

    expect(ringWidth(), 10 + 6);

    // The size slider only rebuilds itself, not the editor, so it notifies
    // through `sizeListenable` instead. No hover event is needed.
    diameter = 20;
    sizeRevision.value++;
    await tester.pump();
    expect(ringWidth(), 20 + 6);

    // Zooming changes the on-screen size too.
    controller.value = Matrix4.identity()..scaleByDouble(2, 2, 2, 1);
    await tester.pump();
    expect(ringWidth(), 40 + 6);
  });

  testWidgets('a hovering stylus shows the cursor in the editor', (
    tester,
  ) async {
    FlavorConfig.setup();
    FileManager.documentsDirectory =
        '$tmpDir/stylus_cursor_test/'
        '${FileManager.appRootDirectoryPrefix}';

    await tester.pumpWidget(MaterialApp(home: Editor()));
    final state = tester.state<EditorState>(find.byType(Editor));
    addTearDown(state.cancelAutosaveAndMarkSaved);

    final pointer = TestPointer(1, PointerDeviceKind.stylus);
    final center = tester.getCenter(find.byType(Editor));

    await tester.sendEventToBinding(pointer.hover(center));
    await tester.pump();

    expect(state.stylusHoverPosition.value, isNotNull);
    expect(find.byKey(StylusCursorPreview.cursorKey), findsOneWidget);

    await tester.sendEventToBinding(pointer.down(center));
    await tester.pump();

    expect(state.stylusHoverPosition.value, isNull);
    expect(find.byKey(StylusCursorPreview.cursorKey), findsNothing);
  });
}
