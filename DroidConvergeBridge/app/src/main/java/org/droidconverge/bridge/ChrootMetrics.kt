package org.droidconverge.bridge

import android.content.Context
import java.util.concurrent.TimeUnit

data class ChrootMetrics(
    val totalJiffies: Long,
    val chrootJiffies: Long,
    val rssKb: Long,
    val memTotalKb: Long,
    val processCount: Int
) {
    fun cpuPercent(previous: ChrootMetrics?): Int? {
        if (previous == null) return null
        val totalDelta = totalJiffies - previous.totalJiffies
        val usedDelta = chrootJiffies - previous.chrootJiffies
        if (totalDelta <= 0 || usedDelta < 0) return null
        return (usedDelta * 100 / totalDelta).toInt().coerceIn(0, 100)
    }

    val memoryPercent: Int
        get() = if (memTotalKb > 0) (rssKb * 100 / memTotalKb).toInt().coerceIn(0, 100) else 0
}

object ChrootMetricsProbe {
    fun read(context: Context): ChrootMetrics? {
        val script = context.assets.open("chroot-metrics.sh").bufferedReader().use { it.readText() }
        val path = context.getFileStreamPath("chroot-metrics.sh")
        path.writeText(script)
        val process = try {
            ProcessBuilder("su", "-c", "sh ${path.absolutePath}")
                .redirectErrorStream(true).start()
        } catch (_: Exception) { return null }
        if (!process.waitFor(8, TimeUnit.SECONDS)) {
            process.destroyForcibly()
            return null
        }
        if (process.exitValue() != 0) return null
        val values = process.inputStream.bufferedReader().use { stream ->
            stream.lineSequence().mapNotNull { line ->
                val parts = line.split('=', limit = 2)
                if (parts.size == 2) parts[0] to parts[1].toLongOrNull() else null
            }.filter { it.second != null }.associate { it.first to it.second!! }
        }
        return ChrootMetrics(
            totalJiffies = values["TOTAL"] ?: return null,
            chrootJiffies = values["CHROOT"] ?: return null,
            rssKb = values["RSS_KB"] ?: return null,
            memTotalKb = values["MEM_TOTAL_KB"] ?: return null,
            processCount = (values["PROCESSES"] ?: return null).toInt()
        )
    }
}
