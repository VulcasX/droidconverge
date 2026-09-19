package org.droidconverge.bridge

import android.content.Context
import java.util.concurrent.TimeUnit

data class HardwareTelemetry(
    val cpuMilliC: Int?, val gpuMilliC: Int?, val skinMilliC: Int?,
    val batteryMilliC: Int?, val fanEnabled: Boolean?, val fanLevel: Int?,
    val gpuBusy: Long? = null, val gpuTotal: Long? = null
) {
    fun gpuPercent(previous: HardwareTelemetry?): Int? {
        val busyDelta = gpuBusy?.minus(previous?.gpuBusy ?: return null) ?: return null
        val totalDelta = gpuTotal?.minus(previous.gpuTotal ?: return null) ?: return null
        if (busyDelta < 0 || totalDelta <= 0) return null
        return (busyDelta * 100 / totalDelta).toInt().coerceIn(0, 100)
    }
    fun summary(): String {
        fun temp(value: Int?) = value?.let { "%.1f°C".format(it / 1000.0) } ?: "n.d."
        val fan = when (fanEnabled) {
            true -> "ventola interna attiva, livello ${fanLevel ?: "?"}"
            false -> "ventola interna ferma"
            null -> "ventola interna non rilevata"
        }
        return "Temperature hardware: CPU ${temp(cpuMilliC)} • GPU ${temp(gpuMilliC)} • scocca ${temp(skinMilliC)} • batteria ${temp(batteryMilliC)}\n$fan"
    }

    companion object {
        fun parse(lines: String): HardwareTelemetry {
            val temperatures = mutableMapOf<String, Int>()
            var fanEnabled: Boolean? = null
            var fanLevel: Int? = null
            var gpuBusy: Long? = null
            var gpuTotal: Long? = null
            for (line in lines.lineSequence()) {
                val parts = line.trim().split(' ')
                if (parts.size == 3 && parts[0] == "TEMP") {
                    val value = parts[2].toIntOrNull()
                    if (value != null && value in 0..150_000) temperatures[parts[1]] = value
                } else if (parts.size == 3 && parts[0] == "FAN") {
                    fanEnabled = when (parts[1]) { "1" -> true; "0" -> false; else -> null }
                    fanLevel = parts[2].toIntOrNull()?.takeIf { it in 0..5 }
                } else if (parts.size == 3 && parts[0] == "GPU_BUSY") {
                    gpuBusy = parts[1].toLongOrNull()
                    gpuTotal = parts[2].toLongOrNull()
                }
            }
            fun max(prefix: String) = temperatures.filterKeys { it.startsWith(prefix) }.values.maxOrNull()
            return HardwareTelemetry(max("cpu-"), max("gpuss-"),
                temperatures["skin-msm-therm"], temperatures["battery"], fanEnabled, fanLevel,
                gpuBusy, gpuTotal)
        }
    }
}

object HardwareTelemetryProbe {
    fun read(context: Context): HardwareTelemetry? = try {
        val path = context.getFileStreamPath("hardware-telemetry.sh")
        path.writeText(context.assets.open("hardware-telemetry.sh").bufferedReader().use { it.readText() })
        val process = ProcessBuilder("su", "-c", "sh ${path.absolutePath}")
            .redirectErrorStream(true).start()
        if (!process.waitFor(8, TimeUnit.SECONDS)) {
            process.destroyForcibly()
            null
        } else if (process.exitValue() != 0) null
        else HardwareTelemetry.parse(process.inputStream.bufferedReader().use { it.readText() })
    } catch (_: Exception) { null }
}
