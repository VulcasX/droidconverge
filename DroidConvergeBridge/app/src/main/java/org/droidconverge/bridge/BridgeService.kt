package org.droidconverge.bridge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.view.Display

class BridgeService : Service() {

    companion object {
        const val CHANNEL_ID = "droidconverge_bridge"
        const val NOTIFICATION_ID = 1001
        @Volatile var isRunning: Boolean = false
            private set
    }

    private var server: BridgeServer? = null
    private lateinit var displays: DisplayManager
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {
            if (displayId != Display.DEFAULT_DISPLAY) applyProfileAsync(true)
        }
        override fun onDisplayChanged(displayId: Int) {
            if (displayId != Display.DEFAULT_DISPLAY) applyProfileAsync(true)
        }
        override fun onDisplayRemoved(displayId: Int) {
            if (displayId != Display.DEFAULT_DISPLAY) {
                restoreInputAsync()
                applyProfileAsync(false)
            }
        }
    }

    private fun restoreInputAsync() {
        Thread { InputRouteController.clearAll(applicationContext) }.start()
    }

    private fun applyProfileAsync(external: Boolean) {
        if (!DisplayProfileController.auto(this)) return
        Thread {
            val result = DisplayProfileController.apply(applicationContext, external)
            DebugLog.log("DISPLAY_PROFILE|${if (external) "HDMI" else "TABLET"}|$result")
        }.start()
    }

    override fun onCreate() {
        super.onCreate()
        displays = getSystemService(DisplayManager::class.java)
        displays.registerDisplayListener(displayListener, Handler(Looper.getMainLooper()))
        if (displays.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
                .none { it.displayId != Display.DEFAULT_DISPLAY }) restoreInputAsync()
        applyProfileAsync(displays.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
            .any { it.displayId != Display.DEFAULT_DISPLAY })

        createNotificationChannel()

        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("DroidConverge Bridge")
            .setContentText("Bridge TCP attivo su 127.0.0.1:8765")
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setContentIntent(PendingIntent.getActivity(
                this, 0, Intent(this, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            ))
            .setOngoing(true)
            .build()

        startForeground(
            NOTIFICATION_ID,
            notification,
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
        )

        val app = application as DroidConvergeBridgeApp

        server = BridgeServer(this) {
            app.getBridgeToken()
        }

        server?.start()
        isRunning = true

        DebugLog.log("SERVICE|STARTED")
    }

    override fun onDestroy() {
        displays.unregisterDisplayListener(displayListener)
        restoreInputAsync()
        server?.stop()
        server = null
        isRunning = false

        DebugLog.log("SERVICE|STOPPED")

        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        val manager = getSystemService(NotificationManager::class.java)

        val channel = NotificationChannel(
            CHANNEL_ID,
            "DroidConverge Bridge",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Stato del bridge Android DroidConverge"
            setShowBadge(false)
        }

        manager.createNotificationChannel(channel)
    }
}
