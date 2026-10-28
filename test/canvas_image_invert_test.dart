import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/canvas/canvas_image.dart';
import 'package:saber/components/canvas/image/editor_image.dart';
import 'package:saber/components/canvas/invert_widget.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/flavor_config.dart';

void main() {
  FlavorConfig.setup();

  setUp(() => EditorImage.shouldLoadOutImmediately = true);
  tearDown(() => EditorImage.shouldLoadOutImmediately = false);

  testWidgets('pageInvert controls whether an inline image is inverted', (
    tester,
  ) async {
    final coreInfo = EditorCoreInfo(filePath: 'test');
    final image = SvgEditorImage(
      id: 0,
      svgString: '<svg height="10" width="10"></svg>',
      svgFile: null,
      pageIndex: 0,
      pageSize: const Size(100, 100),
      invertible: true,
      onMoveImage: null,
      onDeleteImage: null,
      onMiscChange: null,
      assetCache: coreInfo.assetCache,
    );

    Future<void> pumpWith({required bool pageInvert}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: DeferredPointerHandler(
                  child: Stack(
                    children: [
                      CanvasImage(
                        filePath: '',
                        image: image,
                        pageSize: const Size(100, 100),
                        setAsBackground: null,
                        pageInvert: pageInvert,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return;
    }

    await pumpWith(pageInvert: false);
    expect(tester.widget<InvertWidget>(find.byType(InvertWidget)).invert, isFalse);

    await pumpWith(pageInvert: true);
    expect(tester.widget<InvertWidget>(find.byType(InvertWidget)).invert, isTrue);
  });
}
