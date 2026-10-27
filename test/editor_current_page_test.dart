import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/canvas/canvas_gesture_detector.dart';
import 'package:saber/data/editor/page.dart';
import 'package:saber/pages/editor/editor.dart';

void main() {
  group('getPageIndexFromScrollPosition', () {
    final pages = <EditorPage>[
      EditorPage(size: const Size(100, 100)),
      EditorPage(size: const Size(100, 200)),
      EditorPage(size: const Size(100, 300)),
    ];

    test('returns 0 when scroll position is 0', () {
      expect(
        EditorState.getPageIndexFromScrollPosition(
          scrollY: 0,
          screenWidth: 100,
          pages: pages,
        ),
        0,
      );
    });

    test('returns 0 when scroll position is negative', () {
      expect(
        EditorState.getPageIndexFromScrollPosition(
          scrollY: -100000,
          screenWidth: 100,
          pages: pages,
        ),
        0,
      );
    });

    test('returns 0 when scroll position is within first page', () {
      expect(
        EditorState.getPageIndexFromScrollPosition(
          scrollY: 50, // middle of first page
          screenWidth: 100,
          pages: pages,
        ),
        0,
      );
    });

    test('returns 1 when scroll position is within second page', () {
      expect(
        EditorState.getPageIndexFromScrollPosition(
          scrollY: 150, // middle of second page
          screenWidth: 100,
          pages: pages,
        ),
        1,
      );
    });

    test('returns 2 when scroll position is within third page', () {
      expect(
        EditorState.getPageIndexFromScrollPosition(
          scrollY: 400, // within third page (it starts at 2 gaps + 2 pages)
          screenWidth: 100,
          pages: pages,
        ),
        2,
      );
    });

    test(
      'returns last page index when scroll position is beyond last page',
      () {
        expect(
          EditorState.getPageIndexFromScrollPosition(
            scrollY: 100000,
            screenWidth: 100,
            pages: pages,
          ),
          2,
        );
      },
    );
  });

  group('current page after scrollToPage', () {
    final pages = <EditorPage>[
      EditorPage(size: const Size(100, 100)),
      EditorPage(size: const Size(100, 200)),
      EditorPage(size: const Size(100, 300)),
    ];

    /// Mirrors the maths in `EditorState.currentPageIndex` at scale 1.
    int pageIndexAfterScrollTo(int target) {
      final controller = TransformationController();
      CanvasGestureDetector.scrollToPage(
        pageIndex: target,
        pages: pages,
        screenWidth: 100,
        transformationController: controller,
      );

      final scrollY = controller.value.getTranslation().y;
      return EditorState.getPageIndexFromScrollPosition(
        scrollY: -scrollY,
        screenWidth: 100,
        pages: pages,
      );
    }

    for (var target = 0; target < pages.length; target++) {
      test('scrolling to page $target reports page $target', () {
        expect(pageIndexAfterScrollTo(target), target);
      });
    }

    test('scrolling to a page aligns its top with the viewport top', () {
      for (var target = 0; target < pages.length; target++) {
        final controller = TransformationController();
        CanvasGestureDetector.scrollToPage(
          pageIndex: target,
          pages: pages,
          screenWidth: 100,
          transformationController: controller,
        );

        final topOfPage = CanvasGestureDetector.getTopOfPage(
          pageIndex: target,
          pages: pages,
          screenWidth: 100,
        );
        // translation.y == -topOfPage means the page starts at the very top of
        // the viewport, with nothing of the previous page peeking above it.
        expect(controller.value.getTranslation().y, -topOfPage);
      }
    });

    test('the first page starts below the leading page gaps', () {
      // _PagesBuilder puts two gaps of padding above the first page; if
      // getTopOfPage forgets them, every scrollToPage lands one strip low.
      expect(
        CanvasGestureDetector.getTopOfPage(
          pageIndex: 0,
          pages: pages,
          screenWidth: 100,
        ),
        Editor.gapBetweenPages * 2,
      );
    });

    test('repeated relative navigation keeps advancing', () {
      // 0 -> 1 -> 2: this broke when currentPageIndex lagged one page behind.
      var current = pageIndexAfterScrollTo(0);
      for (var expected = 1; expected < pages.length; expected++) {
        current = pageIndexAfterScrollTo(current + 1);
        expect(current, expected);
      }
    });
  });
}
