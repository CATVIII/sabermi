// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Cat8th
//
// Part of SaberMI, a fork of Saber (https://github.com/saber-notes/saber).

import 'package:miui_penengine/src/pen_gesture.dart';

/// A single pen-body gesture event streamed from the Android side.
class PenGestureEvent {
  const new({
    required this.gesture,
    required this.isDown,
    this.duration = Duration.zero,
    this.deviceName = '',
  });

  final PenGesture gesture;

  /// `true` for the key-down half of the gesture, `false` for key-up.
  ///
  /// Only [PenGesture.pinch] is genuinely held; the other gestures are short
  /// impulses, so callers can simply ignore the up event for those.
  final bool isDown;

  /// How long the key was held. Only meaningful when [isDown] is `false`.
  final Duration duration;

  /// Name of the reporting input device, for logging only.
  final String deviceName;

  static PenGestureEvent? fromMap(Map<Object?, Object?> map) {
    final rawGesture = map['gesture'];
    if (rawGesture is! int) return null;
    final gesture = PenGesture.fromValue(rawGesture);
    if (gesture == null) return null;

    return PenGestureEvent(
      gesture: gesture,
      isDown: map['isDown'] == true,
      duration: Duration(milliseconds: (map['durationMs'] as int?) ?? 0),
      deviceName: (map['deviceName'] as String?) ?? '',
    );
  }

  @override
  String toString() {
    final phase = isDown ? 'DOWN' : 'UP';
    final held = isDown ? '' : ' hold=${duration.inMilliseconds}ms';
    return 'PenGestureEvent(${gesture.name} $phase$held)';
  }
}
