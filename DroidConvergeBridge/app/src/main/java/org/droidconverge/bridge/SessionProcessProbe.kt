package org.droidconverge.bridge

import java.util.concurrent.TimeUnit

/** Read-only process evidence. An Android process is not itself proof of a healthy desktop. */
object SessionProcessProbe {
    fun summary(): String {
        val process = try {
            val command = """
                for name in com.termux anland; do
                    if pidof "${'$'}name" >/dev/null 2>&1; then echo "${'$'}name:yes"; else echo "${'$'}name:no"; fi
                done
                pid="${'$'}(pidof plasma_session)"
                if [ -n "${'$'}pid" ] && [ "${'$'}(readlink /proc/${'$'}pid/root)" = /data/local/chroot-distro/ubuntu26 ]; then
                    echo ubuntu:yes
                else
                    echo ubuntu:no
                fi
            """.trimIndent()
            ProcessBuilder("su", "-c", command)
                .redirectErrorStream(true).start()
        } catch (_: Exception) {
            return "Processi: verifica root non disponibile"
        }
        if (!process.waitFor(4, TimeUnit.SECONDS)) {
            process.destroyForcibly()
            return "Processi: verifica root scaduta"
        }
        if (process.exitValue() != 0) return "Processi: verifica root non riuscita"
        val facts = process.inputStream.bufferedReader().use { it.readText() }
        val termux = "com.termux:yes" in facts
        val anland = "anland:yes" in facts
        val plasma = "ubuntu:yes" in facts
        return "Termux: ${if (termux) "attivo" else "non rilevato"}  •  " +
            "Anland: ${if (anland) "attivo" else "non rilevato"}\n" +
            "Ubuntu/KDE: ${if (plasma) "sessione Linux rilevata" else "non confermato"}"
    }
}
