package org.droidconverge.bridge

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.VibratorManager
import org.json.JSONObject
import org.json.JSONArray
import java.io.BufferedReader
import java.io.InputStreamReader
import java.util.concurrent.TimeUnit

class BridgeActions(private val context: Context) {

    companion object {
        const val NOTIFICATION_CHANNEL = "droidconverge_bridge"
    }

    private val settings = BridgeSettings(context)

    fun execute(request: BridgeRequest): Pair<Boolean, JSONObject?> {
        return when (request.action.lowercase()) {
            "ping" -> true to JSONObject()
                .put("protocol", 1)
                .put("service", "DroidConverge Bridge")
                .put("version", BuildConfig.VERSION_NAME)

            "haptic" -> haptic() to null
            "vibrate" -> vibration() to null
            "battery" -> true to batteryInfo()
            "wifi" -> wifi(request.state)
            "bluetooth" -> bluetooth(request.state)
            "wifi-settings" -> openSettings(Settings.ACTION_WIFI_SETTINGS)
            "bluetooth-settings" -> openSettings(Settings.ACTION_BLUETOOTH_SETTINGS)
            "android-apps" -> androidApps()
            "android-launch" -> launchAndroidApp(request.state)
            "notify" -> notify(request.title ?: "", request.text ?: "")
            else -> false to JSONObject().put("error", "unknown_action")
        }
    }

    private fun openSettings(action: String): Pair<Boolean, JSONObject?> = try {
        context.startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true to JSONObject()
    } catch (_: Exception) {
        false to JSONObject().put("error", "settings_unavailable")
    }

    private fun launcherApps(): List<Pair<String, String>> {
        val query = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return context.packageManager.queryIntentActivities(query, 0)
            .map { it.activityInfo.packageName to it.loadLabel(context.packageManager).toString() }
            .distinctBy { it.first }.sortedBy { it.second.lowercase() }
    }

    private fun androidApps(): Pair<Boolean, JSONObject?> {
        val apps = JSONArray()
        launcherApps().forEach { (packageName, label) ->
            apps.put(JSONObject().put("package", packageName).put("label", label.take(120)))
        }
        return true to JSONObject().put("apps", apps)
    }

    private fun launchAndroidApp(packageName: String?): Pair<Boolean, JSONObject?> {
        if (packageName.isNullOrBlank() || !packageName.matches(Regex("[A-Za-z0-9_.]{3,180}")))
            return false to JSONObject().put("error", "invalid_package")
        if (launcherApps().none { it.first == packageName })
            return false to JSONObject().put("error", "app_not_launchable")
        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            ?: return false to JSONObject().put("error", "app_not_launchable")
        return try {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true to JSONObject().put("package", packageName)
        } catch (_: Exception) {
            false to JSONObject().put("error", "launch_failed")
        }
    }

    private fun haptic(): Boolean {
        if (!settings.hapticEnabled) {
            DebugLog.log("HAPTIC -> DISABLED")
            return false
        }

        return vibrateProfile(
            name = "HAPTIC",
            effect = settings.hapticEffect,
            durationMs = settings.hapticDurationMs,
            amplitude = settings.hapticAmplitude,
            usage = VibrationAttributes.USAGE_TOUCH
        )
    }

    private fun vibration(): Boolean {
        if (!settings.vibrationEnabled) {
            DebugLog.log("VIBRATION -> DISABLED")
            return false
        }

        return vibrateProfile(
            name = "VIBRATION",
            effect = BridgeSettings.EFFECT_CUSTOM,
            durationMs = settings.vibrationDurationMs,
            amplitude = settings.vibrationAmplitude,
            usage = VibrationAttributes.USAGE_NOTIFICATION
        )
    }

    private fun vibrateProfile(
        name: String,
        effect: String,
        durationMs: Int,
        amplitude: Int,
        usage: Int
    ): Boolean {
        return try {
            val vibratorManager = context.getSystemService(VibratorManager::class.java)
            val vibrator = vibratorManager?.defaultVibrator

            if (vibrator == null) {
                DebugLog.log("$name -> ERROR|vibrator_service_unavailable")
                return false
            }

            if (!vibrator.hasVibrator()) {
                DebugLog.log("$name -> ERROR|no_vibrator")
                return false
            }

            val vibrationEffect = when (effect) {
                BridgeSettings.EFFECT_TICK -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK)
                BridgeSettings.EFFECT_CLICK -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
                BridgeSettings.EFFECT_HEAVY_CLICK -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK)
                BridgeSettings.EFFECT_DOUBLE_CLICK -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_DOUBLE_CLICK)
                else -> VibrationEffect.createOneShot(
                    durationMs.toLong().coerceAtLeast(1L),
                    amplitude.coerceIn(1, 255)
                )
            }

            val attributes = VibrationAttributes.Builder()
                .setUsage(usage)
                .build()

            vibrator.vibrate(vibrationEffect, attributes)

            DebugLog.log(
                "$name -> OK|effect=$effect|duration=$durationMs|amplitude=$amplitude|usage=$usage"
            )
            true
        } catch (e: Exception) {
            DebugLog.log("$name -> ERROR|${e.javaClass.simpleName}:${e.message}")
            false
        }
    }

    private fun batteryInfo(): JSONObject {
        val batteryManager = context.getSystemService(BatteryManager::class.java)
        val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val plugged = intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL

        DebugLog.log("BATTERY -> OK|level=$level|charging=$charging|plugged=$plugged")

        return JSONObject()
            .put("level", level)
            .put("charging", charging)
            .put("plugged", plugged)
            .put("status", status)
    }

    private fun wifi(state: String?): Pair<Boolean, JSONObject?> {
        val manager = context.applicationContext.getSystemService(WifiManager::class.java)
            ?: return false to JSONObject().put("error", "service_unavailable")

        return when (state?.lowercase()) {
            null, "", "status", "get" -> {
                val enabled = manager.isWifiEnabled
                DebugLog.log("WIFI -> STATUS|$enabled")
                true to JSONObject().put("enabled", enabled)
            }

            "on", "enable", "enabled" -> {
                val result = runRoot("/system/bin/svc wifi enable")
                val enabled = waitForWifiState(manager, true)
                DebugLog.log("WIFI|ON -> exit=${result.exitCode}|enabled=$enabled")
                if (enabled) {
                    true to JSONObject().put("enabled", true)
                } else {
                    false to JSONObject()
                        .put("error", "wifi_enable_failed")
                        .put("exitCode", result.exitCode)
                        .put("output", result.output)
                        .put("enabled", enabled)
                }
            }

            "off", "disable", "disabled" -> {
                val result = runRoot("/system/bin/svc wifi disable")
                val enabled = waitForWifiState(manager, false)
                DebugLog.log("WIFI|OFF -> exit=${result.exitCode}|enabled=$enabled")
                if (!enabled) {
                    true to JSONObject().put("enabled", false)
                } else {
                    false to JSONObject()
                        .put("error", "wifi_disable_failed")
                        .put("exitCode", result.exitCode)
                        .put("output", result.output)
                        .put("enabled", enabled)
                }
            }

            else -> false to JSONObject().put("error", "invalid_wifi_state")
        }
    }

    private fun waitForWifiState(manager: WifiManager, expected: Boolean): Boolean {
        repeat(30) {
            if (manager.isWifiEnabled == expected) return expected
            Thread.sleep(100)
        }
        return manager.isWifiEnabled
    }

    private fun bluetooth(state: String?): Pair<Boolean, JSONObject?> {
        val adapter = context.getSystemService(BluetoothManager::class.java)?.adapter

        fun status(): Pair<Boolean, JSONObject?> {
            return try {
                val enabled = adapter?.isEnabled ?: false
                DebugLog.log("BLUETOOTH -> STATUS|$enabled")
                true to JSONObject().put("enabled", enabled)
            } catch (_: SecurityException) {
                DebugLog.log("BLUETOOTH -> ERROR|permission_required")
                false to JSONObject().put("error", "bluetooth_permission_required")
            }
        }

        return when (state?.lowercase()) {
            null, "", "status", "get" -> status()

            "on", "enable", "enabled" -> {
                val result = runRoot("/system/bin/svc bluetooth enable")
                val enabled = waitForBluetoothState(adapter, true)
                DebugLog.log("BLUETOOTH|ON -> exit=${result.exitCode}|enabled=$enabled")
                if (enabled) {
                    true to JSONObject().put("enabled", true)
                } else {
                    false to JSONObject()
                        .put("error", "bluetooth_enable_failed")
                        .put("exitCode", result.exitCode)
                        .put("output", result.output)
                        .put("enabled", enabled)
                }
            }

            "off", "disable", "disabled" -> {
                val result = runRoot("/system/bin/svc bluetooth disable")
                val enabled = waitForBluetoothState(adapter, false)
                DebugLog.log("BLUETOOTH|OFF -> exit=${result.exitCode}|enabled=$enabled")
                if (!enabled) {
                    true to JSONObject().put("enabled", false)
                } else {
                    false to JSONObject()
                        .put("error", "bluetooth_disable_failed")
                        .put("exitCode", result.exitCode)
                        .put("output", result.output)
                        .put("enabled", enabled)
                }
            }

            else -> false to JSONObject().put("error", "invalid_bluetooth_state")
        }
    }

    private fun waitForBluetoothState(adapter: BluetoothAdapter?, expected: Boolean): Boolean {
        repeat(30) {
            val enabled = try {
                adapter?.isEnabled ?: false
            } catch (_: SecurityException) {
                false
            }
            if (enabled == expected) return expected
            Thread.sleep(100)
        }

        return try {
            adapter?.isEnabled ?: false
        } catch (_: SecurityException) {
            false
        }
    }

    private fun notify(title: String, text: String): Pair<Boolean, JSONObject?> {
        val notificationManager = context.getSystemService(NotificationManager::class.java)
            ?: return false to JSONObject().put("error", "notification_service_unavailable")

        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            DebugLog.log("NOTIFY -> ERROR|notification_permission_required")
            return false to JSONObject().put("error", "notification_permission_required")
        }

        if (Build.VERSION.SDK_INT >= 26) {
            notificationManager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    "DroidConverge Bridge",
                    NotificationManager.IMPORTANCE_DEFAULT
                )
            )
        }

        val notification = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, NOTIFICATION_CHANNEL)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title.ifBlank { "DroidConverge" })
                .setContentText(text)
                .setAutoCancel(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title.ifBlank { "DroidConverge" })
                .setContentText(text)
                .setAutoCancel(true)
                .build()
        }

        notificationManager.notify(
            (System.currentTimeMillis() and 0x7FFFFFFF).toInt(),
            notification
        )

        DebugLog.log("NOTIFY -> OK")
        return true to JSONObject().put("sent", true)
    }

    private data class ShellResult(val exitCode: Int, val output: String)

    private fun runRoot(command: String): ShellResult {
        return try {
            DebugLog.log("ROOT|EXEC|$command")

            val process = ProcessBuilder("su", "-c", command)
                .redirectErrorStream(true)
                .start()

            val output = BufferedReader(InputStreamReader(process.inputStream)).use {
                it.readText().trim()
            }

            if (!process.waitFor(5, TimeUnit.SECONDS)) {
                process.destroyForcibly()
                DebugLog.log("ROOT|TIMEOUT|$command")
                return ShellResult(-1, "timeout")
            }

            val exitCode = process.exitValue()
            DebugLog.log("ROOT|RESULT|exit=$exitCode|output=$output")
            ShellResult(exitCode, output)
        } catch (e: Exception) {
            DebugLog.log("ROOT|ERROR|${e.javaClass.simpleName}:${e.message}")
            ShellResult(-1, e.message ?: e.javaClass.simpleName)
        }
    }
}
