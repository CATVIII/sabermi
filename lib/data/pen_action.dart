import 'package:stow_codecs/stow_codecs.dart';

/// An action that a pen-body gesture can trigger.
///
/// The first two entries are the two eraser behaviours, deliberately named so
/// the difference is obvious in the settings UI:
///
/// - [temporaryEraser] swaps to the eraser while the gesture is held, and
///   restores the previous pen when it is released. Best for [PenGesture.pinch].
/// - [toggleEraser] swaps between the current pen and the eraser on every
///   press, and stays there. Best for [PenGesture.tap].
enum PenAction {
  /// Do nothing.
  none,

  /// Switch to the eraser while the gesture is held, restore on release.
  temporaryEraser,

  /// Switch between the current pen and the eraser on each press.
  toggleEraser,

  /// Open the pen / highlighter / pencil options panel.
  ///
  /// Kept for backward compatibility: the settings dropdown no longer offers
  /// this action, and saved gestures are migrated to
  /// [openPenOptionsAndColors]. It must keep its position because [codec]
  /// stores enum values by index.
  openPenOptions,

  /// Open the colour picker bar.
  ///
  /// Kept for backward compatibility, like [openPenOptions].
  openColorPicker,

  undo,
  redo,

  /// Scroll to the previous page.
  previousPage,

  /// Scroll to the next page.
  nextPage,

  /// Toggle whether fingers draw.
  toggleFingerDrawing,

  /// Toggle fullscreen mode.
  toggleFullscreen,

  /// Switch to the laser pointer tool.
  laserPointer,

  /// Switch to the selection tool.
  selectTool,

  /// Open the colour picker bar and the current tool's options panel together.
  openPenOptionsAndColors;

  static const codec = EnumCodec(values);

  /// The actions offered by the settings dropdown.
  ///
  /// [openPenOptions] and [openColorPicker] were merged into
  /// [openPenOptionsAndColors]. They stay in [values] so that previously saved
  /// preferences keep their indices, but they are no longer selectable.
  static const List<PenAction> selectable = [
    none,
    temporaryEraser,
    toggleEraser,
    openPenOptionsAndColors,
    undo,
    redo,
    previousPage,
    nextPage,
    toggleFingerDrawing,
    toggleFullscreen,
    laserPointer,
    selectTool,
  ];

  /// Whether this action needs both the down and the up half of the gesture.
  bool get isHoldAction => this == .temporaryEraser;

  /// Actions that only make sense for a held gesture.
  static List<PenAction> get holdOnly => const [.temporaryEraser];
}
