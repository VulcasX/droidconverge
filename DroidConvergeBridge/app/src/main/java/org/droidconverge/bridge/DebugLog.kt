package org.droidconverge.bridge

import android.os.Handler
import android.os.Looper
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.CopyOnWriteArrayList

object DebugLog {

    private const val MAX_LINES = 500

    private val lock = Any()
    private val lines = ArrayList<String>()
    private val listeners = CopyOnWriteArrayList<(String) -> Unit>()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun log(message: String) {
        val line = "${SimpleDateFormat("HH:mm:ss.SSS", Locale.US).format(Date())}  $message"

        synchronized(lock) {
            lines.add(line)
            if (lines.size > MAX_LINES) {
                lines.subList(0, lines.size - MAX_LINES).clear()
            }
        }

        listeners.forEach { listener ->
            mainHandler.post { listener(line) }
        }
    }

    fun addListener(listener: (String) -> Unit): List<String> {
        listeners += listener
        return synchronized(lock) { lines.toList() }
    }

    fun removeListener(listener: (String) -> Unit) {
        listeners -= listener
    }

    fun snapshot(): List<String> = synchronized(lock) { lines.toList() }

    fun clear() {
        synchronized(lock) { lines.clear() }
        listeners.forEach { listener -> mainHandler.post { listener("") } }
    }
}
