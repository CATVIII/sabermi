import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/data/editor/page.dart';
import 'package:saber/data/extensions/change_notifier_extensions.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tools/_tool.dart';
import 'package:saber/data/tools/highlighter.dart';
import 'package:saber/data/tools/pencil.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:sbn/tool_id.dart';
import 'package:stow_plain/stow_plain.dart';

class Pen extends Tool {
  @protected
  @visibleForTesting
  new({
    required this.name,
    required this.sizeMin,
    required this.sizeMax,
    required this.sizeStep,
    required this.icon,
    required this.options,
    required this.pressureEnabled,
    required this.color,
    required this.toolId,
  });

  new fountainPen()
    : name = t.editor.pens.fountainPen,
      sizeMin = 1,
      sizeMax = 25,
      sizeStep = 1,
      icon = fountainPenIcon,
      options = stows.lastFountainPenOptions.value,
      pressureEnabled = true,
      color = Color(stows.lastFountainPenColor.value),
      toolId = .fountainPen;

  new ballpointPen()
    : name = t.editor.pens.ballpointPen,
      sizeMin = 1,
      sizeMax = 25,
      sizeStep = 1,
      icon = ballpointPenIcon,
      options = stows.lastBallpointPenOptions.value,
      pressureEnabled = false,
      color = Color(stows.lastBallpointPenColor.value),
      toolId = .ballpointPen;

  final String name;
  final double sizeMin, sizeMax, sizeStep;
  late final int sizeStepsBetweenMinAndMax = ((sizeMax - sizeMin) / sizeStep)
      .round();
  final Object icon;

  @override
  final ToolId toolId;

  static const fountainPenIcon = FontAwesomeIcons.penFancy;
  static const ballpointPenIcon = FontAwesomeIcons.pen;

  static Stroke? currentStroke;
  Color color;
  bool pressureEnabled;
  StrokeOptions options;

  static var _currentPen = Pen.fountainPen();
  static Pen get currentPen => _currentPen;
  static set currentPen(Pen currentPen) {
    assert(
      currentPen is! Highlighter,
      'Use Highlighter.currentHighlighter instead',
    );
    assert(currentPen is! Pencil, 'Use Pencil.currentPencil instead');
    _currentPen = currentPen;
  }

  /// Fires when a pen's [options] change, e.g. when the size slider moves.
  ///
  /// The size slider mutates [options] without rebuilding the editor, so UI
  /// that mirrors the brush appearance (like the stylus cursor) listens to
  /// this instead of recomputing on every pointer event.
  static final optionsChanged = ChangeNotifier();

  /// The stow that stores this pen's options.
  PlainStow<StrokeOptions> get _optionsStow => switch (toolId) {
    ToolId.fountainPen => stows.lastFountainPenOptions,
    ToolId.ballpointPen => stows.lastBallpointPenOptions,
    ToolId.highlighter => stows.lastHighlighterOptions,
    ToolId.pencil => stows.lastPencilOptions,
    ToolId.shapePen => stows.lastShapePenOptions,
    _ => throw ArgumentError.value(toolId, 'toolId', 'Not a pen'),
  };

  /// The stow that stores this pen's colour.
  PlainStow<int> get _colorStow => switch (toolId) {
    ToolId.fountainPen => stows.lastFountainPenColor,
    ToolId.ballpointPen => stows.lastBallpointPenColor,
    ToolId.highlighter => stows.lastHighlighterColor,
    ToolId.pencil => stows.lastPencilColor,
    ToolId.shapePen => stows.lastShapePenColor,
    _ => throw ArgumentError.value(toolId, 'toolId', 'Not a pen'),
  };

  /// Persists the current [options].
  void saveOptions() {
    final stow = _optionsStow;
    stow.value = options;
    // `StrokeOptions` compares by value and [options] is usually the very
    // object stored in the stow, so the setter above can be a no-op. Notifying
    // forces the stow to write the current value.
    stow.notifyListenersPlease();
  }

  /// Persists the current [color].
  void saveColor() => _colorStow.value = color.toARGB32();

  void onDragStart(
    Offset position,
    EditorPage page,
    int pageIndex,
    double? pressure,
  ) {
    currentStroke = Stroke(
      color: color,
      pressureEnabled: pressureEnabled,
      options: options.copyWith(isComplete: false),
      pageIndex: pageIndex,
      page: page,
      toolId: toolId,
    );
    onDragUpdate(position, pressure);
  }

  void onDragUpdate(Offset position, double? pressure) {
    currentStroke?.addPoint(position, pressure);
  }

  Stroke? onDragEnd() {
    final stroke = currentStroke;
    currentStroke = null;
    if (stroke == null) return null;

    return stroke
      ..options.isComplete = true
      ..markPolygonNeedsUpdating();
  }

  /// The default stroke options.
  ///
  /// Note that these are different to the default options in [StrokeOptions]
  /// e.g. [StrokeOptions.defaultSize] for historical reasons
  /// (i.e. [StrokeOptions.toJson] does not include default values.)
  static final defaultOptions = StrokeOptions(size: 5);

  static StrokeOptions get fountainPenOptions => defaultOptions.copyWith();
  static StrokeOptions get ballpointPenOptions => defaultOptions.copyWith();
  static StrokeOptions get shapePenOptions =>
      defaultOptions.copyWith(smoothing: 0, streamline: 0);
  static StrokeOptions get highlighterOptions =>
      defaultOptions.copyWith(size: 50);
  static StrokeOptions get pencilOptions => defaultOptions.copyWith(
    streamline: 0.1,
    start: StrokeEndOptions.start(taperEnabled: true, customTaper: 1),
    end: StrokeEndOptions.end(taperEnabled: true, customTaper: 1),
  );
}
