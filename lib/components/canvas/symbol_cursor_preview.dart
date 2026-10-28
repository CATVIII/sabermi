import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saber/components/canvas/invert_widget.dart';
import 'package:saber/data/extensions/matrix4_extensions.dart';
import 'package:saber/data/symbols/symbol_definition.dart';
import 'package:saber/data/tools/symbol_tool.dart';

/// The symbol being placed while the pen is held down.
class SymbolPending {
  const new({
    required this.pageIndex,
    required this.pagePosition,
    required this.screenPosition,
    required this.stemUp,
  });

  final int pageIndex;
  final Offset pagePosition;
  final Offset screenPosition;
  final bool stemUp;

  SymbolPending copyWith({bool? stemUp}) => SymbolPending(
    pageIndex: pageIndex,
    pagePosition: pagePosition,
    screenPosition: screenPosition,
    stemUp: stemUp ?? this.stemUp,
  );
}

/// Shows a ghost of the current symbol at the stylus position.
///
/// While hovering, the symbol is drawn semi-transparently at the pen tip. While
/// the pen is held down, the ghost stays at the landing point and follows the
/// chosen stem direction.
class SymbolCursorPreview extends StatefulWidget {
  const new({
    super.key,
    required this.hoverPosition,
    required this.pending,
    required this.tool,
    required this.pageScale,
    required this.transformationController,
    required this.pageInvert,
  });

  static const previewKey = Key('symbol-cursor-preview');

  final ValueListenable<Offset?> hoverPosition;
  final ValueListenable<SymbolPending?> pending;
  final SymbolTool tool;
  final double pageScale;
  final TransformationController transformationController;
  final ValueListenable<bool> pageInvert;

  @override
  State<SymbolCursorPreview> createState() => _SymbolCursorPreviewState();
}

class _SymbolCursorPreviewState extends State<SymbolCursorPreview> {
  SymbolGlyph? _symbolGlyph;
  Widget? _glyphWidget;
  String? _glyphKey;
  Size _screenSize = Size.zero;
  late double _lastZoom;

  @override
  void initState() {
    super.initState();
    _lastZoom = widget.transformationController.value.approxScale;
    SymbolTool.changed.addListener(_onToolChanged);
    widget.pending.addListener(_onPendingChanged);
    widget.pageInvert.addListener(_onInvertChanged);
    widget.transformationController.addListener(_onTransformChanged);
    _updateGlyph(notify: false);
  }

  @override
  void didUpdateWidget(SymbolCursorPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pending != widget.pending) {
      oldWidget.pending.removeListener(_onPendingChanged);
      widget.pending.addListener(_onPendingChanged);
    }
    if (oldWidget.pageInvert != widget.pageInvert) {
      oldWidget.pageInvert.removeListener(_onInvertChanged);
      widget.pageInvert.addListener(_onInvertChanged);
    }
    if (oldWidget.transformationController != widget.transformationController) {
      oldWidget.transformationController.removeListener(_onTransformChanged);
      widget.transformationController.addListener(_onTransformChanged);
      _lastZoom = widget.transformationController.value.approxScale;
    }
    _updateGlyph(notify: false);
  }

  @override
  void dispose() {
    SymbolTool.changed.removeListener(_onToolChanged);
    widget.pending.removeListener(_onPendingChanged);
    widget.pageInvert.removeListener(_onInvertChanged);
    widget.transformationController.removeListener(_onTransformChanged);
    super.dispose();
  }

  void _onToolChanged() {
    _updateGlyph();
    _updateSize(notify: true);
  }

  void _onPendingChanged() => _updateGlyph();

  void _onInvertChanged() => _updateGlyph();

  void _onTransformChanged() {
    final zoom = widget.transformationController.value.approxScale;
    if (zoom == _lastZoom) return;
    _lastZoom = zoom;
    _updateSize(notify: true);
  }

  void _updateGlyph({bool notify = true}) {
    final tool = widget.tool;
    final symbol = tool.symbol;
    final pending = widget.pending.value;
    final stemUp = pending?.stemUp ?? tool.stemUp;
    final invert = widget.pageInvert.value;
    final key = '${symbol.id}|$stemUp|${tool.color.toARGB32()}|$invert';
    if (key == _glyphKey) return;
    _glyphKey = key;

    final glyph = symbol.buildGlyph(stemUp: stemUp, color: tool.color);
    final glyphWidget = InvertWidget(
      invert: invert,
      child: SvgPicture.string(glyph.svg, fit: BoxFit.fill),
    );
    final size = _sizeFor(glyph);

    _symbolGlyph = glyph;
    if (notify && mounted) {
      setState(() {
        _glyphWidget = glyphWidget;
        _screenSize = size;
      });
    } else {
      _glyphWidget = glyphWidget;
      _screenSize = size;
    }
  }

  void _updateSize({bool notify = false}) {
    final glyph = _symbolGlyph;
    if (glyph == null) return;
    final size = _sizeFor(glyph);
    if (size == _screenSize) return;

    if (notify && mounted) {
      setState(() => _screenSize = size);
    } else {
      _screenSize = size;
    }
  }

  Size _sizeFor(SymbolGlyph glyph) {
    final tool = widget.tool;
    final zoom = widget.transformationController.value.approxScale;
    final scale =
        tool.size / tool.symbol.referenceSize * widget.pageScale * zoom;
    return Size(glyph.viewBox.width * scale, glyph.viewBox.height * scale);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.hoverPosition, widget.pending]),
      builder: (context, _) {
        final pending = widget.pending.value;
        final position = pending?.screenPosition ?? widget.hoverPosition.value;
        final glyph = _symbolGlyph;
        final glyphWidget = _glyphWidget;
        if (position == null ||
            glyph == null ||
            glyphWidget == null ||
            _screenSize.isEmpty) {
          return const SizedBox.shrink();
        }

        final scale = _screenSize.width / glyph.viewBox.width;
        return Positioned(
          key: SymbolCursorPreview.previewKey,
          left: position.dx - glyph.anchor.dx * scale,
          top: position.dy - glyph.anchor.dy * scale,
          width: _screenSize.width,
          height: _screenSize.height,
          child: IgnorePointer(
            child: Opacity(
              opacity: pending == null ? 0.5 : 0.85,
              child: glyphWidget,
            ),
          ),
        );
      },
    );
  }
}
