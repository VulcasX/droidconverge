package org.droidconverge.bridge

import android.content.Context
import android.view.InputDevice
import java.util.concurrent.TimeUnit

/** Temporary USB runtime-power control for devices explicitly routed to HDMI. */
object UsbPowerController {
    private const val prefsName = "usb_power_original"
    private fun key(device: InputDevice) = "%04x:%04x".format(device.vendorId, device.productId)

    @Synchronized fun keepAwake(context: Context, device: InputDevice): String {
        if (device.vendorId == 0 || device.productId == 0) return "USB power non applicabile"
        val key = key(device)
        val original = get(context, device, "get") ?: return "USB power non disponibile"
        if (original !in setOf("auto", "on")) return "USB power sconosciuto"
        val prefs = context.getSharedPreferences(prefsName, 0)
        if (!prefs.contains(key) && !prefs.edit().putString(key, original).commit())
            return "Backup USB power fallito"
        return if (get(context, device, "set", "on") == "on") "USB mantenuto attivo"
        else "USB power non modificato"
    }

    @Synchronized fun restore(context: Context, device: InputDevice): String {
        val key = key(device)
        val prefs = context.getSharedPreferences(prefsName, 0)
        val previous = prefs.getString(key, null) ?: return "USB power non gestito"
        if (previous !in setOf("auto", "on")) return "Backup USB power invalido"
        val current = get(context, device, "set", previous)
        if (current == previous) prefs.edit().remove(key).apply()
        return if (current == previous) "USB power ripristinato" else "USB power da verificare"
    }

    fun isManaged(context: Context, device: InputDevice): Boolean =
        context.getSharedPreferences(prefsName, 0).contains(key(device))

    private fun get(context: Context, device: InputDevice, action: String, value: String = ""): String? {
        val path = context.getFileStreamPath("usb-power-control.sh")
        return try {
            path.writeText(context.assets.open("usb-power-control.sh").bufferedReader().use { it.readText() })
            val vendor = "%04x".format(device.vendorId)
            val product = "%04x".format(device.productId)
            val process = ProcessBuilder("su", "-c", "sh ${path.absolutePath} $action $vendor $product $value")
                .redirectErrorStream(true).start()
            if (!process.waitFor(5, TimeUnit.SECONDS)) {
                process.destroyForcibly()
                return null
            }
            if (process.exitValue() != 0) return null
            process.inputStream.bufferedReader().use { it.readText().trim() }.removePrefix("CONTROL=")
        } catch (_: Exception) { null }
    }
}
