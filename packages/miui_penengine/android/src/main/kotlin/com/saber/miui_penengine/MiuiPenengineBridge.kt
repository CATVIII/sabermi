// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Cat8th
//
// Part of SaberMI, a fork of Saber (https://github.com/saber-notes/saber).

package com.saber.miui_penengine

import android.view.KeyEvent

/**
 * Entry point for [android.app.Activity.dispatchKeyEvent].
 *
 * The four touch-film gestures arrive as ordinary key events, but only after
 * the system has decided to let them through. Filtering here (rather than in
 * Dart) lets us ignore physical keyboards, whose numpad keys share the same
 * key codes, and gives us the exact press duration.
 *
 * Host app wiring, in `MainActivity`:
 *
 * ```kotlin
 * override fun dispatchKeyEvent(event: KeyEvent): Boolean {
 *     if (MiuiPenengineBridge.handle(event)) return true
 *     return super.dispatchKeyEvent(event)
 * }
 * ```
 */
object MiuiPenengineBridge {
    /** Xiaomi Focus Pen Pro (Bluetooth HID). */
    private const val VENDOR_ID = 0x0022
    private const val PRODUCT_ID = 0x5081

    private const val KEY_PINCH = 194 // KEYCODE_BUTTON_7  (KEY_F19,  scan 189)
    private const val KEY_TAP = 195 // KEYCODE_BUTTON_8  (KPENTER,  scan 96)
    private const val KEY_SLIDE_UP = 196 // KEYCODE_BUTTON_9  (KP9,      scan 73)
    private const val KEY_SLIDE_DOWN = 197 // KEYCODE_BUTTON_10 (KP3,      scan 81)

    /** Mirrors `PenGesture` on the Dart side. */
    private const val GESTURE_PINCH = 0
    private const val GESTURE_DOUBLE_TAP = 1
    private const val GESTURE_SLIDE_UP = 2
    private const val GESTURE_SLIDE_DOWN = 3

    /** Set by the plugin while a Flutter engine is attached. */
    @Volatile
    internal var listener: ((gesture: Int, isDown: Boolean, durationMs: Long, deviceName: String) -> Unit)? = null

    private val downAt = LongArray(256)

    /**
     * @return `true` when the event belongs to the pen and has been consumed.
     */
    @JvmStatic
    fun handle(event: KeyEvent): Boolean {
        val sink = listener ?: return false

        val gesture = when (event.keyCode) {
            KEY_PINCH -> GESTURE_PINCH
            KEY_TAP -> GESTURE_DOUBLE_TAP
            KEY_SLIDE_UP -> GESTURE_SLIDE_UP
            KEY_SLIDE_DOWN -> GESTURE_SLIDE_DOWN
            else -> return false
        }

        val device = event.device ?: return false
        if (device.vendorId != VENDOR_ID || device.productId != PRODUCT_ID) return false

        val slot = event.keyCode and 0xFF
        val duration: Long
        when (event.action) {
            KeyEvent.ACTION_DOWN -> {
                // Android auto-repeats a held key. Those repeats are not new
                // presses: forwarding them would spam the Dart side and reset
                // the press timestamp, breaking the measured hold duration.
                if (event.repeatCount > 0) return true
                downAt[slot] = event.eventTime
                duration = 0L
            }

            KeyEvent.ACTION_UP -> {
                val down = downAt[slot]
                duration = if (down == 0L) 0L else event.eventTime - down
                downAt[slot] = 0L
            }

            else -> return false
        }

        return try {
            sink(gesture, event.action == KeyEvent.ACTION_DOWN, duration, device.name.orEmpty())
            true
        } catch (t: Throwable) {
            // Never let a broken listener break the app's input handling.
            false
        }
    }

    /** Clears stale press timestamps, e.g. when the Flutter engine detaches. */
    @JvmStatic
    fun reset() {
        downAt.fill(0L)
    }
}
