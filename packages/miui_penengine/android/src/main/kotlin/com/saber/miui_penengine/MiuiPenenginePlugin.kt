// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Cat8th
//
// Part of SaberMI, a fork of Saber (https://github.com/saber-notes/saber).

package com.saber.miui_penengine

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes the Xiaomi pen touch-film gestures to Dart.
 *
 * Two channels:
 * - `saber/miui_pen`        : isSupported / register / unregister / isRegistered
 * - `saber/miui_pen/events` : stream of gesture events
 *
 * The actual key interception happens in [MiuiPenengineBridge], which the host
 * app calls from `Activity.dispatchKeyEvent`, because a plugin cannot override
 * the activity's key handling itself.
 */
class MiuiPenenginePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methods: MethodChannel
    private lateinit var events: EventChannel
    private lateinit var client: PencilEngineClient

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        client = PencilEngineClient(binding.applicationContext)

        methods = MethodChannel(binding.binaryMessenger, "saber/miui_pen")
        methods.setMethodCallHandler(this)

        events = EventChannel(binding.binaryMessenger, "saber/miui_pen/events")
        events.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        MiuiPenengineBridge.listener = null
        MiuiPenengineBridge.reset()
    }

    // ---------------------------------------------------------- MethodChannel --

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(client.isSupported())
            "isRegistered" -> result.success(client.isRegistered())
            "register" -> {
                val ok = client.setEnabled(true)
                result.success(ok)
            }

            "unregister" -> {
                client.setEnabled(false)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // ----------------------------------------------------------- EventChannel --

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) {
        MiuiPenengineBridge.listener = { gesture, isDown, durationMs, deviceName ->
            eventSink.success(
                mapOf(
                    "gesture" to gesture,
                    "isDown" to isDown,
                    "durationMs" to durationMs,
                    "deviceName" to deviceName,
                ),
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        MiuiPenengineBridge.listener = null
        MiuiPenengineBridge.reset()
    }
}
