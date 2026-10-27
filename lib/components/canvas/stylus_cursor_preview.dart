import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saber/data/extensions/matrix4_extensions.dart';

/// A ring at the stylus tip showing where a stroke would land while hovering.
///
/// Its diameter matches the current tool: the pen's stroke width or the
/// eraser's diameter. It is drawn in screen space, so the ring stays crisp at
/// any zoom level while still growing with the brush size.
class StylusCursorPreview extends StatefulWidget {
  const new({
    super.key,
    required this.position,
    required this.color,
    required this.diameter,
    required this.pageScale,
    required this.transformationController,
    required this.sizeListenable,
    this.minDiameter = 6,
    this.maxDiameter = 200,
  });

  static const cursorKey = Key('stylus-cursor-preview');

  /// The hover position in the canvas' coordinate space, or `null` to hide.
  final ValueListenable<Offset?> position;

  /// The ring's colour, already inverted for dark mode if needed.
  final Color color;

  /// Diameter in page units: `Pen.options.size` or twice `Eraser.size`.
  final double Function() diameter;

  /// How many screen pixels one page unit is worth at zoom 1.
  final double pageScale;

  final TransformationController transformationController;

  /// Fires when the brush size changes, e.g. when the size slider moves.
  ///
  /// The size slider doesn't rebuild the editor, so the ring recomputes its
  /// size when this notifies instead of on every hover event.
  final Listenable sizeListenable;

  /// Clamps so the ring stays visible at any brush size or zoom level.
  final double minDiameter;
  final double maxDiameter;

  /// The on-screen diameter of the ring.
  static double screenDiameter({
    required double diameter,
    required double pageScale,
    required double zoom,
    double minDiameter = 6,
    double maxDiameter = 200,
  }) {
    return (diameter * pageScale * zoom)
        .clamp(minDiameter, maxDiameter)
        .toDouble();
  }

  @override
  State<StylusCursorPreview> createState() => _StylusCursorPreviewState();
}

class _StylusCursorPreviewState extends State<StylusCursorPreview> {
  /// Cached so hover events only move the ring instead of recomputing its size.
  late double _screenDiameter;
  late double _lastZoom;

  @override
  void initState() {
    super.initState();
    _lastZoom = widget.transformationController.value.approxScale;
    _screenDiameter = _computeDiameter();
    widget.sizeListenable.addListener(_onSizeChanged);
    widget.transformationController.addListener(_onTransformChanged);
  }

  @override
  void didUpdateWidget(StylusCursorPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sizeListenable != widget.sizeListenable) {
      oldWidget.sizeListenable.removeListener(_onSizeChanged);
      widget.sizeListenable.addListener(_onSizeChanged);
    }
    if (oldWidget.transformationController != widget.transformationController) {
      oldWidget.transformationController.removeListener(_onTransformChanged);
      widget.transformationController.addListener(_onTransformChanged);
      _lastZoom = widget.transformationController.value.approxScale;
    }

    // The diameter getter may now point at a different tool (e.g. the eraser).
    _screenDiameter = _computeDiameter();
  }

  @override
  void dispose() {
    widget.sizeListenable.removeListener(_onSizeChanged);
    widget.transformationController.removeListener(_onTransformChanged);
    super.dispose();
  }

  double _computeDiameter() => StylusCursorPreview.screenDiameter(
    diameter: widget.diameter(),
    pageScale: widget.pageScale,
    zoom: widget.transformationController.value.approxScale,
    minDiameter: widget.minDiameter,
    maxDiameter: widget.maxDiameter,
  );

  void _onSizeChanged() {
    final diameter = _computeDiameter();
    if (diameter == _screenDiameter) return;
    setState(() => _screenDiameter = diameter);
  }

  void _onTransformChanged() {
    final zoom = widget.transformationController.value.approxScale;
    if (zoom == _lastZoom) return; // panning doesn't change the ring size
    _lastZoom = zoom;
    _onSizeChanged();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return ValueListenableBuilder<Offset?>(
      valueListenable: widget.position,
      builder: (context, position, _) {
        if (position == null) return const SizedBox.shrink();

        const padding = 3.0;
        final extent = _screenDiameter + padding * 2;

        return Positioned(
          key: StylusCursorPreview.cursorKey,
          left: position.dx - extent / 2,
          top: position.dy - extent / 2,
          width: extent,
          height: extent,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _StylusCursorPainter(
                color: color,
                radius: _screenDiameter / 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StylusCursorPainter extends CustomPainter {
  const new({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // The highlighter's colour is semi-transparent; force the ring opaque so it
    // stays readable.
    final ringColor = color.withValues(alpha: 1);
    final outlineColor = ringColor.computeLuminance() > 0.5
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.85);

    // A contrasting ring just outside the main one keeps the cursor visible on
    // both light and dark pages.
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = outlineColor;
    canvas.drawCircle(center, radius + 1, outlinePaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ringColor;
    canvas.drawCircle(center, radius, ringPaint);

    // The centre dot marks the exact landing point.
    final dotPaint = Paint()..color = ringColor;
    canvas.drawCircle(
      center,
      (radius * 0.25).clamp(1.5, 2.5).toDouble(),
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(_StylusCursorPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
