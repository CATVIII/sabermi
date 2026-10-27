import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/canvas/_canvas_painter.dart';
import 'package:saber/components/canvas/image/editor_image.dart';
import 'package:saber/components/canvas/inner_canvas.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/editor/page.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/prefs.dart';

void main() {
  FlavorConfig.setup();

  setUp(() {
    stows.editorAutoInvert.value = true;
    // Don't leave image load-out timers pending at the end of the test.
    EditorImage.shouldLoadOutImmediately = true;
  });

  tearDown(() {
    EditorImage.shouldLoadOutImmediately = false;
  });

  testWidgets('a non-invertible background image keeps the page light', (
    tester,
  ) async {
    final coreInfo = _coreInfoWithBackground(invertible: false);

    await _pumpInnerCanvas(tester, coreInfo);

    // The PDF page stays white, so strokes must use light-mode colours and the
    // highlighter must use BlendMode.darken.
    expect(_canvasPainter(tester).invert, isFalse);
  });

  testWidgets('an invertible background image follows the dark theme', (
    tester,
  ) async {
    final coreInfo = _coreInfoWithBackground(invertible: true);

    await _pumpInnerCanvas(tester, coreInfo);

    expect(_canvasPainter(tester).invert, isTrue);
  });

  testWidgets('a page without a background image follows the dark theme', (
    tester,
  ) async {
    final coreInfo = EditorCoreInfo(filePath: 'test');
    coreInfo.pages = [EditorPage(size: const Size(100, 100))];

    await _pumpInnerCanvas(tester, coreInfo);

    expect(_canvasPainter(tester).invert, isTrue);
  });
}

EditorCoreInfo _coreInfoWithBackground({required bool invertible}) {
  final coreInfo = EditorCoreInfo(filePath: 'test');
  coreInfo.pages = [
    EditorPage(
      size: const Size(100, 100),
      backgroundImage: SvgEditorImage(
        id: 0,
        svgString: '<svg height="100" width="100"></svg>',
        svgFile: null,
        pageIndex: 0,
        pageSize: const Size(100, 100),
        invertible: invertible,
        onMoveImage: null,
        onDeleteImage: null,
        onMiscChange: null,
        assetCache: coreInfo.assetCache,
      ),
    ),
  ];
  return coreInfo;
}

Future<void> _pumpInnerCanvas(
  WidgetTester tester,
  EditorCoreInfo coreInfo,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: InnerCanvas(
              pageIndex: 0,
              width: 100,
              height: 100,
              coreInfo: coreInfo,
              currentStroke: null,
              currentStrokeDetectedShape: null,
              currentSelection: null,
              currentToolIsSelect: false,
              currentScale: 1,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

CanvasPainter _canvasPainter(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((widget) => widget.foregroundPainter)
      .whereType<CanvasPainter>()
      .first;
}
