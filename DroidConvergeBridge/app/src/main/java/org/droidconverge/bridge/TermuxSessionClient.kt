package org.droidconverge.bridge

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager

object TermuxSessionClient {
    const val permission = "com.termux.permission.RUN_COMMAND"
    private const val packageName = "com.termux"
    private const val serviceName = "com.termux.app.RunCommandService"
    private const val commandPath = "/data/data/com.termux/files/usr/bin/droidconverge-session"
    private const val preferences = "session_panel"

    fun isAvailable(context: Context): Boolean =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED &&
            context.packageManager.resolveService(Intent("com.termux.RUN_COMMAND").setClassName(packageName, serviceName), 0) != null

    fun lastResult(context: Context): String =
        context.getSharedPreferences(preferences, Context.MODE_PRIVATE)
            .getString("last_result", "Stato Anland/KDE non interrogato") ?: "Stato Anland/KDE non interrogato"

    fun run(context: Context, action: String): Boolean {
        if (action !in setOf("status", "start", "stop", "restart") || !isAvailable(context)) return false
        val resultIntent = Intent(context, TermuxSessionResultReceiver::class.java)
            .putExtra("requested_action", action)
        val pending = PendingIntent.getBroadcast(
            context,
            (System.currentTimeMillis() and 0x7fffffff).toInt(),
            resultIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_MUTABLE
        )
        val intent = Intent("com.termux.RUN_COMMAND").setClassName(packageName, serviceName)
            .putExtra("com.termux.RUN_COMMAND_PATH", commandPath)
            .putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf(action))
            .putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            .putExtra("com.termux.RUN_COMMAND_PENDING_INTENT", pending)
        return try {
            context.startService(intent) != null
        } catch (_: SecurityException) {
            false
        } catch (_: IllegalStateException) {
            false
        }
    }
}

class TermuxSessionResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val result = intent.getBundleExtra("result")
        val line = result?.getString("stdout", "")?.lineSequence()?.firstOrNull()?.trim().orEmpty()
        val accepted = setOf("RUNNING", "STOPPED", "STARTED", "ALREADY_RUNNING", "STOP_REQUESTED", "STOP_PENDING", "UNKNOWN", "RESTART_REFUSED")
        val summary = if (result?.getInt("exitCode", -1) == 0 && line in accepted) {
            line
        } else {
            "Comando non verificato: controllare Termux e i permessi"
        }
        context.getSharedPreferences("session_panel", Context.MODE_PRIVATE).edit()
            .putString("last_result", summary).apply()
    }
}
