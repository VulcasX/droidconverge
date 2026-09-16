package org.droidconverge.bridge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.IBinder

class BridgeService : Service() {

    companion object {
        const val CHANNEL_ID = "droidconverge_bridge"
        const val NOTIFICATION_ID = 1001
    }

    private var server: BridgeServer? = null

    override fun onCreate() {
        super.onCreate()

        createNotificationChannel()

        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("DroidConverge Bridge")
            .setContentText("Bridge TCP attivo su 127.0.0.1:8765")
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
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

        DebugLog.log("SERVICE|STARTED")
    }

    override fun onDestroy() {
        server?.stop()
        server = null

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
