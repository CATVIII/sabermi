// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Cat8th
//
// Part of SaberMI, a fork of Saber (https://github.com/saber-notes/saber).

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:miui_penengine/src/pen_gesture_event.dart';

export 'src/pen_gesture.dart';
export 'src/pen_gesture_event.dart';

/// Access to the Xiaomi Focus Pen Pro touch-film gestures.
///
/// On a supported device the pen body reports four gestures as raw key events.
/// The system swallows three of them unless the app has registered itself with
/// `com.xiaomi.touchservice`, which is what [register] does.
///
/// ![gesture map](https://github.com/saber-notes/saber)
///
/// Everything degrades gracefully: on unsupported devices or when registration
/// fails, [isSupported] returns `false` and [events] never emits.
abstract final class MiuiPenengine {
  static final _log = Logger('MiuiPenengine');

  static const _methods = MethodChannel('saber/miui_pen');
  static const _eventChannel = EventChannel('saber/miui_pen/events');

  static Stream<PenGestureEvent>? _events;
  static bool? _supported;

  /// Whether this device exposes the Xiaomi stylus touch-film service.
  ///
  /// Returns `false` on every non-Android platform.
  static Future<bool> isSupported() async {
    if (_supported != null) return _supported!;
    try {
      _supported = await _methods.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      _supported = false;
    } on PlatformException catch (e) {
      _log.warning('isSupported failed', e);
      _supported = false;
    }
    return _supported!;
  }

  /// Registers this app so that tap / slide gestures are delivered to it.
  ///
  /// Safe to call repeatedly; returns `true` when the app is registered.
  /// A `true` return value does not guarantee that the system actually
  /// whitelisted the app - check logcat for
  /// `Add <pkg> to support touch film packages` when debugging.
  static Future<bool> register() async {
    if (!await isSupported()) return false;
    try {
      return await _methods.invokeMethod<bool>('register') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      _log.warning('register failed', e);
      return false;
    }
  }

  /// Removes this app from the touch-film allow list.
  static Future<void> unregister() async {
    try {
      await _methods.invokeMethod<void>('unregister');
    } on MissingPluginException {
      // Nothing to do.
    } on PlatformException catch (e) {
      _log.warning('unregister failed', e);
    }
  }

  /// Whether [register] has succeeded and the app is currently registered.
  static Future<bool> isRegistered() async {
    try {
      return await _methods.invokeMethod<bool>('isRegistered') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// The gesture stream. Only emits while the app is registered.
  static Stream<PenGestureEvent> get events {
    return _events ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          if (event is! Map) return null;
          return PenGestureEvent.fromMap(event);
        })
        .where((event) => event != null)
        .cast<PenGestureEvent>()
        .asBroadcastStream();
  }
}
