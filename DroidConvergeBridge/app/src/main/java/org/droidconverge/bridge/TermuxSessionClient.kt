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

    private fun failureMessage(error: Exception): String = when {
        error.message?.contains("Blocked by AutoLaunch", ignoreCase = true) == true ->
            "RedMagic blocca l'avvio automatico di Termux. Apri Termux, torna qui e riprova; abilita l'avvio automatico di Termux nelle impostazioni RedMagic."
        error is SecurityException -> "Permesso Android RUN_COMMAND negato"
        else -> "Termux non disponibile: ${error.javaClass.simpleName}"
    }

    fun runInstaller(context: Context): Boolean {
        if (!isAvailable(context)) return false
        val script = """
            set -e
            pkg install -y git
            if [ ! -d "${'$'}HOME/droidconverge/.git" ]; then
              git clone --depth 1 --branch codex/external-display https://github.com/VulcasX/droidconverge.git "${'$'}HOME/droidconverge"
            else
              test "${'$'}(git -C "${'$'}HOME/droidconverge" remote get-url origin)" = 'https://github.com/VulcasX/droidconverge.git' || { echo 'Repository origin inatteso'; exit 1; }
              test "${'$'}(git -C "${'$'}HOME/droidconverge" branch --show-current)" = 'codex/external-display' || { echo 'Branch inattesa'; exit 1; }
              test -z "${'$'}(git -C "${'$'}HOME/droidconverge" status --porcelain)" || { echo 'Checkout modificato: update rifiutato'; exit 1; }
              git -C "${'$'}HOME/droidconverge" pull --ff-only
            fi
            cd "${'$'}HOME/droidconverge"
            bash scripts/install/install-system.sh --apply
            printf '\nPremi Invio per chiudere.\n'
            read -r _
        """.trimIndent()
        val intent = Intent("com.termux.RUN_COMMAND").setClassName(packageName, serviceName)
            .putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
            .putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-s"))
            .putExtra("com.termux.RUN_COMMAND_STDIN", script)
            .putExtra("com.termux.RUN_COMMAND_BACKGROUND", false)
            .putExtra("com.termux.RUN_COMMAND_COMMAND_LABEL", "DroidConverge installazione guidata")
        return try {
            context.startService(intent) != null
        } catch (error: SecurityException) {
            DebugLog.log("TERMUX|INSTALL|SECURITY|${error.message}")
            false
        } catch (_: IllegalStateException) {
            false
        }
    }

    fun run(context: Context, action: String): Boolean {
        if (action !in setOf("status", "start", "stop", "restart", "recover") || !isAvailable(context)) return false
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
        val state = context.getSharedPreferences(preferences, Context.MODE_PRIVATE)
        state.edit().putString("last_result", "Comando $action inviato; risposta in attesa").apply()
        return try {
            val sent = context.startService(intent) != null
            if (!sent) state.edit().putString("last_result", "Comando non inviato").apply()
            sent
        } catch (error: SecurityException) {
            DebugLog.log("TERMUX|$action|SECURITY|${error.message}")
            state.edit().putString("last_result", "Comando non inviato: ${failureMessage(error)}").apply()
            false
        } catch (error: IllegalStateException) {
            DebugLog.log("TERMUX|$action|STATE|${error.message}")
            state.edit().putString("last_result", "Comando non inviato: ${failureMessage(error)}").apply()
            false
        }
    }
}

class TermuxSessionResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val result = intent.getBundleExtra("result")
        val line = result?.getString("stdout", "")?.lineSequence()?.firstOrNull()?.trim().orEmpty()
        val accepted = setOf("RUNNING", "STOPPED", "STARTED", "ALREADY_RUNNING", "STOP_REQUESTED", "STOP_PENDING", "UNKNOWN", "ORPHANED", "RECOVERED", "RECOVERY_PENDING", "RESTART_REFUSED")
        val summary = if (result?.getInt("exitCode", -1) == 0 && line in accepted) {
            line
        } else {
            "Comando non verificato: controllare Termux e i permessi"
        }
        context.getSharedPreferences("session_panel", Context.MODE_PRIVATE).edit()
            .putString("last_result", summary).apply()
    }
}
