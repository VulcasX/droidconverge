package org.droidconverge.bridge

import android.content.Context
import android.hardware.usb.UsbManager
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.storage.StorageManager
import android.os.Environment
import android.bluetooth.BluetoothManager
import android.net.wifi.WifiManager

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
        val volumes = context.getSystemService(StorageManager::class.java).storageVolumes
            .filter { it.isRemovable }
        val storage = if (volumes.isEmpty()) "nessun volume rimovibile" else volumes.joinToString { volume ->
            when (volume.state) {
                Environment.MEDIA_MOUNTED -> "memoria USB montata da Android"
                Environment.MEDIA_MOUNTED_READ_ONLY -> "memoria USB in sola lettura"
                Environment.MEDIA_UNMOUNTABLE -> "memoria USB non montabile; controllare il filesystem senza formattare"
                else -> "memoria USB: ${volume.state}"
            }
        }
        val wifi = context.getSystemService(WifiManager::class.java)?.isWifiEnabled == true
        val bluetooth = try {
            context.getSystemService(BluetoothManager::class.java)?.adapter?.isEnabled == true
        } catch (_: SecurityException) {
            null
        }
        return "USB: ${if (usb.isEmpty()) "nessun dispositivo visibile all'app" else usb.joinToString() }\n" +
            "Archiviazione: $storage. Il montaggio nella chroot richiede un volume Android montato.\n" +
            "Radio Android: Wi-Fi ${if (wifi) "attivo" else "spento"}; Bluetooth ${when (bluetooth) { true -> "attivo"; false -> "spento"; null -> "permesso richiesto" }}. La connessione del cooler non è confermata da questo stato.\n" +
            "Audio Android: HDMI ${if (hdmi) "disponibile" else "non rilevato"}; USB ${if (usbAudio) "disponibile" else "non rilevato"}. " +
            "La disponibilità non conferma la riproduzione da KDE."
    }
}
