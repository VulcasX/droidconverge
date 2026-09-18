package org.droidconverge.bridge

import android.content.Context
import android.hardware.input.InputManager
import android.view.InputDevice

object PeripheralInventory {
    fun summary(context: Context): String {
        val manager = context.getSystemService(InputManager::class.java)
        val devices = manager.inputDeviceIds.toList().mapNotNull(manager::getInputDevice)
            .filter { !it.isVirtual && it.isExternal }
        if (devices.isEmpty()) return "Nessuna periferica di input esterna rilevata"
        return devices.joinToString("\n") { device ->
            val kinds = buildList {
                if (device.sources and InputDevice.SOURCE_KEYBOARD == InputDevice.SOURCE_KEYBOARD) add("tastiera")
                if (device.sources and InputDevice.SOURCE_MOUSE == InputDevice.SOURCE_MOUSE) add("mouse")
                if (device.sources and InputDevice.SOURCE_TOUCHPAD == InputDevice.SOURCE_TOUCHPAD) add("touchpad")
                if (device.sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD) add("gamepad")
            }.distinct().ifEmpty { listOf("input") }
            "${device.name.take(80)}: ${kinds.joinToString()}; ${if (device.isEnabled) "attiva" else "disabilitata"}"
        }
    }
}
