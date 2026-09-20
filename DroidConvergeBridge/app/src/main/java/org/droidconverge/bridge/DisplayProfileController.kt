package org.droidconverge.bridge

import android.content.Context
import android.os.Build
import java.util.concurrent.TimeUnit

/** RedMagic Anland output profile. All writes go through a checked KScreen script. */
object DisplayProfileController {
    private const val prefsName = "display_profiles"
    enum class Profile(val key: String, val label: String, val mode: String) {
        TOUCH("tablet", "Tablet Touch", "touch"),
        TABLET_DESKTOP("tabletDesktop", "Tablet Desktop", "desktop"),
        EXTERNAL_DESKTOP("external", "Monitor Desktop", "desktop")
    }
    fun supported(): Boolean = Build.MODEL.equals("NP05J", ignoreCase = true)
    fun auto(context: Context): Boolean = context.getSharedPreferences(prefsName, 0)
        .getBoolean("auto", supported())
    fun setAuto(context: Context, enabled: Boolean) {
        context.getSharedPreferences(prefsName, 0).edit().putBoolean("auto", enabled).apply()
    }
    fun tabletScale(context: Context): Int = context.getSharedPreferences(prefsName, 0)
        .getInt("tablet", 170)
    fun externalScale(context: Context): Int = context.getSharedPreferences(prefsName, 0)
        .getInt("external", 100)
    fun tabletDesktopScale(context: Context): Int = context.getSharedPreferences(prefsName, 0)
        .getInt("tabletDesktop", 100)
    fun internalProfile(context: Context): Profile = if (context.getSharedPreferences(prefsName, 0)
            .getBoolean("internalDesktop", false)) Profile.TABLET_DESKTOP else Profile.TOUCH
    fun setInternalProfile(context: Context, desktop: Boolean) {
        context.getSharedPreferences(prefsName, 0).edit().putBoolean("internalDesktop", desktop)
            .remove("lastApplied").apply()
    }
    fun setScales(context: Context, tablet: Int, tabletDesktop: Int, external: Int): Boolean {
        if (tablet !in 80..250 || tabletDesktop !in 80..250 || external !in 80..250) return false
        context.getSharedPreferences(prefsName, 0).edit()
            .putInt("tablet", tablet).putInt("tabletDesktop", tabletDesktop).putInt("external", external)
            .remove("lastApplied").apply()
        return true
    }

    @Synchronized fun apply(context: Context, external: Boolean, force: Boolean = false): String {
        return apply(context, if (external) Profile.EXTERNAL_DESKTOP else internalProfile(context), force)
    }

    @Synchronized fun apply(context: Context, profile: Profile, force: Boolean = false): String {
        if (!supported()) return "Profilo automatico disponibile solo sul RedMagic Astra verificato"
        if (!force && !auto(context)) return "Profilo automatico disattivato"
        val state = context.getSharedPreferences(prefsName, 0)
        val scale = when (profile) {
            Profile.TOUCH -> tabletScale(context)
            Profile.TABLET_DESKTOP -> tabletDesktopScale(context)
            Profile.EXTERNAL_DESKTOP -> externalScale(context)
        }
        val session = sessionPid()
        if (!force && session != null && state.getString("lastApplied", null) == "${profile.key}:$session")
            return "${profile.label}: ${scale}% (già applicato)"
        val output = run(context, "apply $scale ${profile.mode}")
        if (output.startsWith("APPLIED=")) {
            state.edit().putString("lastApplied", "${profile.key}:${sessionPid() ?: session}").apply()
            return "${profile.label}: ${scale}%"
        }
        return "Profilo non applicato: ${output.take(80)}"
    }

    @Synchronized fun status(context: Context): String {
        val raw = run(context, "status")
        val scale = raw.removePrefix("SCALE=").toDoubleOrNull()
        return if (scale != null) "${(scale * 100).toInt()}% su Anland" else raw
    }

    @Synchronized fun rollback(context: Context): String {
        setAuto(context, false)
        context.getSharedPreferences(prefsName, 0).edit().remove("lastApplied").apply()
        val raw = run(context, "rollback")
        val scale = raw.removePrefix("ROLLED_BACK=").toDoubleOrNull()
        return if (scale != null) "Scala ripristinata a ${(scale * 100).toInt()}%" else raw
    }

    private fun run(context: Context, args: String): String {
        val path = context.getFileStreamPath("display-profile.sh")
        try {
            path.writeText(context.assets.open("display-profile.sh").bufferedReader().use { it.readText() })
            val process = ProcessBuilder("su", "-c", "sh ${path.absolutePath} $args")
                .redirectErrorStream(true).start()
            if (!process.waitFor(25, TimeUnit.SECONDS)) {
                process.destroyForcibly()
                return "TIMEOUT"
            }
            val output = process.inputStream.bufferedReader().use { it.readText().trim() }
            return output.lineSequence().lastOrNull { line ->
                line.startsWith("APPLIED=") || line.startsWith("ROLLED_BACK=") ||
                    line.startsWith("SCALE=") || line.matches(Regex("[A-Z_]+"))
            } ?: if (process.exitValue() == 0) "OK" else "ERROR"
        } catch (_: Exception) {
            return "ROOT_UNAVAILABLE"
        }
    }

    private fun sessionPid(): String? = try {
        val process = ProcessBuilder("su", "-c", "pidof kwin_wayland")
            .redirectErrorStream(true).start()
        if (!process.waitFor(3, TimeUnit.SECONDS) || process.exitValue() != 0) null
        else process.inputStream.bufferedReader().use { it.readText().trim().split(' ').firstOrNull() }
    } catch (_: Exception) { null }
}
