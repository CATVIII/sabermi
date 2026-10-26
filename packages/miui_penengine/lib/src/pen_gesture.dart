// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Cat8th
//
// Part of SaberMI, a fork of Saber (https://github.com/saber-notes/saber).

/// Gestures reported by the pen body touch film of a Xiaomi Focus Pen Pro.
///
/// The integer values must stay in sync with `MiuiPenengineBridge.Gesture`
/// on the Android side.
enum PenGesture {
  /// Squeeze the pen body. Reported as `KEYCODE_BUTTON_7` (194).
  ///
  /// This is a held gesture: a DOWN event when the squeeze starts and an UP
  /// event when it is released. Measured durations range from ~180 ms to
  /// several seconds, so it maps naturally onto "eraser while held".
  pinch(0),

  /// Double-tap the pen body. Reported as `KEYCODE_BUTTON_8` (195).
  ///
  /// Always a short impulse (~2-13 ms). The pen reports one event per
  /// double-tap gesture, so tapping rapidly two or four times still yields a
  /// single event - use [pinch] repetition if you need counting.
  doubleTap(1),

  /// Slide up on the pen body. `KEYCODE_BUTTON_9` (196).
  slideUp(2),

  /// Slide down on the pen body. `KEYCODE_BUTTON_10` (197).
  slideDown(3);

  new(this.value);

  final int value;

  static PenGesture? fromValue(int value) {
    for (final gesture in values) {
      if (gesture.value == value) return gesture;
    }
    return null;
  }
}
