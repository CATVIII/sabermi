import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/canvas/canvas_image_dialog.dart';
import 'package:saber/components/canvas/image/editor_image.dart';
import 'package:saber/components/theming/adaptive_switch.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/editor/page.dart';
import 'package:saber/data/flavor_config.dart';

void main() {
  group('Inverting a document', () {
    late EditorCoreInfo coreInfo;
    late EditorImage firstBackground;
    late EditorImage inlineImage;
    late EditorImage lastBackground;

    setUp(() {
      FlavorConfig.setup();
      coreInfo = EditorCoreInfo(filePath: 'test.sbn');
      firstBackground = _testImage(coreInfo, pageIndex: 0);
      inlineImage = _testImage(coreInfo, pageIndex: 1);
      lastBackground = _testImage(coreInfo, pageIndex: 2);
      coreInfo.pages = [
        EditorPage(
          size: const Size(100, 100),
          backgroundImage: firstBackground,
        ),
        EditorPage(size: const Size(100, 100), images: [inlineImage]),
        EditorPage(
          size: const Size(100, 100),
          backgroundImage: lastBackground,
        ),
      ];
    });

    test('setBackgroundImagesInvertible updates every page background', () {
      coreInfo.setBackgroundImagesInvertible(false);

      expect(firstBackground.invertible, isFalse);
      expect(lastBackground.invertible, isFalse);
      expect(
        coreInfo.backgroundImages.map((image) => image.invertible),
        everyElement(isFalse),
      );
    });

    test('setBackgroundImagesInvertible leaves inline images alone', () {
      coreInfo.setBackgroundImagesInvertible(false);

      expect(inlineImage.invertible, isTrue);
    });

    test('pages without a background image are skipped', () {
      expect(
        () => coreInfo.setBackgroundImagesInvertible(false),
        returnsNormally,
      );
      expect(coreInfo.pages[1].backgroundImage, isNull);
    });

    test('the document can be inverted again', () {
      coreInfo.setBackgroundImagesInvertible(false);
      coreInfo.setBackgroundImagesInvertible(true);

      expect(
        coreInfo.backgroundImages.map((image) => image.invertible),
        everyElement(isTrue),
      );
    });

    group('backgroundImageInvertibleNear', () {
      test('uses the closest background image', () {
        lastBackground.invertible = false;

        expect(coreInfo.backgroundImageInvertibleNear(2), isFalse);
        // page 1 has no background image of its own, so it looks backwards
        expect(coreInfo.backgroundImageInvertibleNear(1), isTrue);
      });

      test('inherits from a later page when there is nothing before', () {
        firstBackground.invertible = false;
        coreInfo.pages.insert(0, EditorPage(size: const Size(100, 100)));

        expect(coreInfo.backgroundImageInvertibleNear(0), isFalse);
      });

      test('returns true when the note has no background images', () {
        coreInfo.pages = [EditorPage(size: const Size(100, 100))];

        expect(coreInfo.backgroundImageInvertibleNear(0), isTrue);
      });

      test('returns true for an empty note', () {
        coreInfo.pages = [];

        expect(coreInfo.backgroundImageInvertibleNear(0), isTrue);
      });
    });
  });

  testWidgets(
    'CanvasImageDialog reports invertible changes to its callback',
    (tester) async {
      FlavorConfig.setup();
      final coreInfo = EditorCoreInfo(filePath: 'test.sbn');
      final image = _testImage(coreInfo, pageIndex: 0);
      bool? reported;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasImageDialog(
              filePath: coreInfo.filePath,
              image: image,
              redrawImage: () {},
              isBackground: true,
              toggleAsBackground: () {},
              onInvertibleChanged: (invertible) => reported = invertible,
            ),
          ),
        ),
      );

      expect(image.invertible, isTrue);

      await tester.tap(find.byType(AdaptiveSwitch));
      await tester.pump();

      expect(reported, isFalse);
      expect(image.invertible, isFalse);
    },
  );
}

EditorImage _testImage(EditorCoreInfo coreInfo, {required int pageIndex}) {
  return SvgEditorImage(
    id: coreInfo.nextImageId++,
    svgString: '<svg height="100" width="100"></svg>',
    svgFile: null,
    pageIndex: pageIndex,
    pageSize: const Size(100, 100),
    onMoveImage: null,
    onDeleteImage: null,
    onMiscChange: null,
    assetCache: coreInfo.assetCache,
  );
}
