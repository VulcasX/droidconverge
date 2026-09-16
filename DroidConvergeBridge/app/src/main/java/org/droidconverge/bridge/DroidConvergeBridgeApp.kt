package org.droidconverge.bridge

import android.app.Application
import android.content.Intent
import android.os.Build
import java.util.UUID

class DroidConvergeBridgeApp : Application() {

    private val preferences by lazy {
        getSharedPreferences(
            "droidconverge_bridge",
            MODE_PRIVATE
        )
    }

    private val token: String by lazy {
        preferences.getString(
            "token",
            null
        ) ?: generateToken().also {
            preferences.edit()
                .putString("token", it)
                .apply()
        }
    }

    override fun onCreate() {
        super.onCreate()

        startBridgeService()

        DebugLog.log("APP|READY")
        DebugLog.log("API|TCP|127.0.0.1:${BridgeServer.PORT}")
    }

    private fun startBridgeService() {
        val intent = Intent(this, BridgeService::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    fun getBridgeToken(): String {
        return token
    }

    fun regenerateToken(): String {
        val generated = generateToken()

        preferences.edit()
            .putString("token", generated)
            .apply()

        DebugLog.log("AUTH|TOKEN_REGENERATED")

        return generated
    }

    private fun generateToken(): String {
        return UUID.randomUUID()
            .toString()
            .replace("-", "")
    }
}
