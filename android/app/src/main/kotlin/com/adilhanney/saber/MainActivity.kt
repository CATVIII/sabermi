package com.adilhanney.saber

import android.os.Bundle
import android.view.KeyEvent
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import com.saber.miui_penengine.MiuiPenengineBridge
import io.flutter.embedding.android.FlutterActivity
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
            this.finish()
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)

        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightNavigationBars = true
    }

    /**
     * Xiaomi Focus Pen Pro pen-body gestures (pinch / tap / slide) arrive as key
     * events. Anything recognised by [MiuiPenengineBridge] is consumed here and
     * forwarded to Dart; everything else goes through untouched.
     */
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (MiuiPenengineBridge.handle(event)) return true
        return super.dispatchKeyEvent(event)
    }
}
