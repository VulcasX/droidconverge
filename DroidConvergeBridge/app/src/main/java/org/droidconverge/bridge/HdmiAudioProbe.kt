package org.droidconverge.bridge

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import kotlin.math.sin

object HdmiAudioProbe {
    /** A short explicit Android-side tone; KDE/PipeWire needs its own test. */
    fun play(context: Context): String {
        val hdmi = context.getSystemService(AudioManager::class.java)
            .getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            .firstOrNull { it.type == AudioDeviceInfo.TYPE_HDMI || it.type == AudioDeviceInfo.TYPE_HDMI_ARC }
            ?: return "Nessuna uscita audio HDMI rilevata"
        val sampleRate = 48_000
        val frames = sampleRate / 2
        val pcm = ByteArray(frames * 2)
        for (i in 0 until frames) {
            val sample = (sin(2.0 * Math.PI * 440.0 * i / sampleRate) * 7000).toInt().toShort()
            pcm[2 * i] = sample.toByte()
            pcm[2 * i + 1] = (sample.toInt() shr 8).toByte()
        }
        val track = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
            .setAudioFormat(AudioFormat.Builder().setSampleRate(sampleRate)
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
            .setBufferSizeInBytes(pcm.size)
            .setTransferMode(AudioTrack.MODE_STATIC)
            .build()
        return try {
            if (!track.setPreferredDevice(hdmi)) return "Android ha rifiutato la preferenza HDMI"
            if (track.write(pcm, 0, pcm.size) != pcm.size) return "Scrittura audio incompleta"
            track.play()
            Thread.sleep(150)
            val routed = track.routedDevice?.type
            Thread.sleep(500)
            DebugLog.log("AUDIO|HDMI_TONE|ROUTED=${routed == hdmi.type}")
            "Tono Android inviato; route HDMI: ${routed == hdmi.type}. Conferma l'audio sul monitor."
        } finally {
            if (track.playState == AudioTrack.PLAYSTATE_PLAYING) track.stop()
            track.release()
        }
    }
}
