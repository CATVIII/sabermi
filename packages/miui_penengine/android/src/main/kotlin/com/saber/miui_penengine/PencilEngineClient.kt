// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Cat8th
//
// Part of SaberMI, a fork of Saber (https://github.com/saber-notes/saber).

package com.saber.miui_penengine

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.os.Parcel
import android.util.Log

/**
 * Minimal client for `com.xiaomi.touchservice`'s `IPencilEngine` binder.
 *
 * Registering makes the system deliver tap / slide-up / slide-down key events
 * to this app. Without it, the system swallows those three gestures before they
 * ever reach the app (the pinch gesture is not gated).
 *
 * Protocol, reverse engineered from `TouchService.apk` and verified on a
 * Xiaomi Pad 8 running HyperOS 4.0:
 *
 * - transaction 1: `registerListener(callback)`
 * - transaction 2: `unregisterListener()`
 * - transaction 3: `triggerFunction(feature, enable) -> int`
 * - transaction 4: `registerListenerByPackageName(callback, packageName)`
 *
 * **Transaction 1 must not be used.** It stores a null package name, so when
 * the touch-film feature is enabled the service cannot tell the system which
 * package to whitelist and gives up silently - while still returning 0 from
 * [triggerFunction]. Only transaction 4 carries the package name through.
 */
internal class PencilEngineClient(private val context: Context) {

    private companion object {
        const val TAG = "MiuiPenengine"
        const val SERVICE_PACKAGE = "com.xiaomi.touchservice"
        const val SERVICE_CLASS = "$SERVICE_PACKAGE.pencilengine.PencilEngineManagerService"
        const val DESCRIPTOR = "$SERVICE_PACKAGE.pencilengine.IPencilEngine"
        const val CALLBACK_DESCRIPTOR = "$SERVICE_PACKAGE.pencilengine.IPencilEngineCallback"

        const val TX_REGISTER_BY_PACKAGE_NAME = 4
        const val TX_UNREGISTER = 2
        const val TX_TRIGGER_FUNCTION = 3

        /** 0 = colour pick, 1 = posture, 2 = touch film. */
        const val FEATURE_TOUCH_FILM = 2
    }

    /** Cheap callback stub: the touch-film path never calls back. */
    private val callback = object : android.os.Binder() {
        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
            try {
                data.enforceInterface(CALLBACK_DESCRIPTOR)
            } catch (_: Throwable) {
            }
            reply?.writeNoException()
            return true
        }
    }

    @Volatile
    private var binder: IBinder? = null

    @Volatile
    private var bound = false

    @Volatile
    private var registered = false

    private var pendingEnable: Boolean? = null

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            Log.i(TAG, "connected to $SERVICE_PACKAGE")
            binder = service
            bound = true
            val pending = pendingEnable ?: return
            pendingEnable = null
            if (pending) doRegister() else doUnregister()
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            Log.i(TAG, "disconnected from $SERVICE_PACKAGE")
            binder = null
            bound = false
            registered = false
        }
    }

    fun isSupported(): Boolean {
        return try {
            val intent = Intent().setComponent(ComponentName(SERVICE_PACKAGE, SERVICE_CLASS))
            context.packageManager.resolveService(intent, 0) != null
        } catch (t: Throwable) {
            Log.w(TAG, "isSupported failed", t)
            false
        }
    }

    fun isRegistered(): Boolean = registered

    fun setEnabled(enable: Boolean): Boolean {
        if (enable && registered) return true
        if (!enable && !registered) return true

        if (!bound) {
            pendingEnable = enable
            bind()
            // The real answer arrives asynchronously; report optimistically so
            // the caller does not treat "still binding" as a hard failure.
            return enable
        }

        return if (enable) doRegister() else doUnregister()
    }

    private fun bind() {
        try {
            val intent = Intent().setComponent(ComponentName(SERVICE_PACKAGE, SERVICE_CLASS))
            val ok = context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            Log.i(TAG, "bindService -> $ok")
            if (!ok) pendingEnable = null
        } catch (t: Throwable) {
            Log.w(TAG, "bindService threw", t)
            pendingEnable = null
        }
    }

    private fun doRegister(): Boolean {
        val service = binder ?: return false
        val packageName = context.packageName

        if (!transactRegister(service, packageName)) return false

        val result = transactTrigger(service, enable = true)
        registered = result == 0
        if (registered) {
            Log.i(
                TAG,
                "registered $packageName for touch-film gestures; " +
                    "verify with logcat: MiuiStylusTouchFilmManager",
            )
        } else {
            Log.w(TAG, "triggerFunction(touch film, on) returned $result")
        }
        return registered
    }

    private fun doUnregister(): Boolean {
        val service = binder ?: return false
        transactTrigger(service, enable = false)
        transactUnregister(service)
        registered = false
        return true
    }

    private fun transactRegister(service: IBinder, packageName: String): Boolean {
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        return try {
            data.writeInterfaceToken(DESCRIPTOR)
            data.writeStrongBinder(callback)
            data.writeString(packageName)
            service.transact(TX_REGISTER_BY_PACKAGE_NAME, data, reply, 0)
            reply.readException()
            true
        } catch (t: Throwable) {
            Log.w(TAG, "registerListenerByPackageName failed", t)
            false
        } finally {
            reply.recycle()
            data.recycle()
        }
    }

    private fun transactUnregister(service: IBinder) {
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        try {
            data.writeInterfaceToken(DESCRIPTOR)
            service.transact(TX_UNREGISTER, data, reply, 0)
            reply.readException()
        } catch (t: Throwable) {
            Log.w(TAG, "unregisterListener failed", t)
        } finally {
            reply.recycle()
            data.recycle()
        }
    }

    /** @return 0 on success, -1 when no listener is registered. */
    private fun transactTrigger(service: IBinder, enable: Boolean): Int {
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        return try {
            data.writeInterfaceToken(DESCRIPTOR)
            data.writeInt(FEATURE_TOUCH_FILM)
            data.writeInt(if (enable) 1 else 0)
            service.transact(TX_TRIGGER_FUNCTION, data, reply, 0)
            reply.readException()
            reply.readInt()
        } catch (t: Throwable) {
            Log.w(TAG, "triggerFunction failed", t)
            -998
        } finally {
            reply.recycle()
            data.recycle()
        }
    }
}
