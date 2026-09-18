package org.droidconverge.bridge

import android.content.Context
import android.hardware.input.InputManager
import android.view.InputDevice
import java.util.concurrent.TimeUnit

/** Owns only associations explicitly requested by DroidConverge. */
object InputRouteController {
    private const val prefsName = "external_input_routes"
    private const val key = "descriptors"

    fun owned(context: Context): Set<String> =
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .getStringSet(key, emptySet()).orEmpty().toSet()

    fun devices(context: Context): List<InputDevice> =
        context.getSystemService(InputManager::class.java).let { manager ->
            manager.inputDeviceIds.toList().mapNotNull(manager::getInputDevice)
        }
        .filter { device ->
            device.isExternal && !device.isVirtual && (
                device.sources and InputDevice.SOURCE_MOUSE == InputDevice.SOURCE_MOUSE ||
                    device.sources and InputDevice.SOURCE_KEYBOARD == InputDevice.SOURCE_KEYBOARD)
        }.sortedBy { it.name }

    @Synchronized fun route(context: Context, device: InputDevice, displayId: Int): String {
        val live = InputDevice.getDevice(device.id)
        require(live != null && live.descriptor == device.descriptor && live.isExternal && !live.isVirtual)
        val result = try { run(context, "route", device.id.toString(), displayId.toString()) }
        catch (error: Exception) {
            runCatching { run(context, "restore", device.descriptor) }
            throw error
        }
        try { save(context, owned(context) + device.descriptor) }
        catch (error: Exception) {
            run(context, "restore", device.descriptor)
            throw error
        }
        return result
    }

    @Synchronized fun clear(context: Context, descriptor: String): String {
        require(descriptor in owned(context))
        val result = run(context, "restore", descriptor)
        save(context, owned(context) - descriptor)
        return result
    }

    @Synchronized fun clearAll(context: Context): List<String> = owned(context).map { descriptor ->
        try { clear(context, descriptor) } catch (error: Exception) { "ERROR $descriptor: ${error.message}" }
    }

    private fun save(context: Context, values: Set<String>) {
        check(context.getSharedPreferences(prefsName, Context.MODE_PRIVATE).edit()
            .putStringSet(key, values).commit()) { "Input route state could not be saved" }
    }

    private fun run(context: Context, vararg args: String): String {
        val apk = context.applicationInfo.sourceDir
        require(apk.matches(Regex("[A-Za-z0-9/_~+.,=-]+")))
        require(args.all { it.matches(Regex("[A-Za-z0-9]+")) })
        val command = "CLASSPATH='$apk' app_process /system/bin org.droidconverge.bridge.InputRouterShell ${args.joinToString(" ")}"
        val process = ProcessBuilder("su", "-c", command).redirectErrorStream(true).start()
        if (!process.waitFor(15, TimeUnit.SECONDS)) {
            process.destroyForcibly()
            throw IllegalStateException("Root/router timeout")
        }
        val output = process.inputStream.bufferedReader().use { it.readText().take(500) }.trim()
        val code = process.exitValue()
        if (code != 0 || !output.startsWith("OK ")) throw IllegalStateException(output.ifEmpty { "Root/router failed ($code)" })
        return output
    }
}
