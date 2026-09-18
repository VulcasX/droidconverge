package org.droidconverge.bridge

import android.content.Context
import android.hardware.usb.UsbManager
import android.media.AudioDeviceInfo
import android.media.AudioManager

object ExternalPeripheralStatus {
    fun summary(context: Context): String {
        val usb = context.getSystemService(UsbManager::class.java).deviceList.values
            .sortedWith(compareBy({ it.vendorId }, { it.productId }))
            .map { device ->
                val label = device.productName?.take(60) ?: "Dispositivo USB"
                "$label (${device.vendorId.toString(16)}:${device.productId.toString(16)})"
            }
        val outputs = context.getSystemService(AudioManager::class.java)
            .getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        val hdmi = outputs.any { it.type == AudioDeviceInfo.TYPE_HDMI || it.type == AudioDeviceInfo.TYPE_HDMI_ARC }
        val usbAudio = outputs.any { it.type == AudioDeviceInfo.TYPE_USB_DEVICE || it.type == AudioDeviceInfo.TYPE_USB_HEADSET }
        return "USB: ${if (usb.isEmpty()) "nessun dispositivo visibile all'app" else usb.joinToString() }\n" +
            "Audio Android: HDMI ${if (hdmi) "disponibile" else "non rilevato"}; USB ${if (usbAudio) "disponibile" else "non rilevato"}. " +
            "La disponibilità non conferma la riproduzione da KDE."
    }
}
