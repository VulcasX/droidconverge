package org.droidconverge.bridge

import android.content.Context

class BridgeSettings(context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var hapticEnabled: Boolean
        get() = prefs.getBoolean("haptic_enabled", true)
        set(value) {
            prefs.edit().putBoolean("haptic_enabled", value).apply()
        }

    var hapticEffect: String
        get() = prefs.getString("haptic_effect", EFFECT_CLICK) ?: EFFECT_CLICK
        set(value) {
            prefs.edit().putString("haptic_effect", value).apply()
        }

    var hapticDurationMs: Int
        get() = prefs.getInt("haptic_duration_ms", 30)
        set(value) {
            prefs.edit().putInt("haptic_duration_ms", value.coerceIn(1, MAX_HAPTIC_DURATION)).apply()
        }

    var hapticAmplitude: Int
        get() = prefs.getInt("haptic_amplitude", 180)
        set(value) {
            prefs.edit().putInt("haptic_amplitude", value.coerceIn(1, 255)).apply()
        }

    var vibrationEnabled: Boolean
        get() = prefs.getBoolean("vibration_enabled", true)
        set(value) {
            prefs.edit().putBoolean("vibration_enabled", value).apply()
        }

    var vibrationDurationMs: Int
        get() = prefs.getInt("vibration_duration_ms", 100)
        set(value) {
            prefs.edit().putInt("vibration_duration_ms", value.coerceIn(1, MAX_VIBRATION_DURATION)).apply()
        }

    var vibrationAmplitude: Int
        get() = prefs.getInt("vibration_amplitude", 180)
        set(value) {
            prefs.edit().putInt("vibration_amplitude", value.coerceIn(1, 255)).apply()
        }

    fun reset() {
        prefs.edit().clear().apply()
    }

    companion object {
        private const val PREFS_NAME = "droidconverge_bridge_settings"

        const val EFFECT_TICK = "tick"
        const val EFFECT_CLICK = "click"
        const val EFFECT_HEAVY_CLICK = "heavy_click"
        const val EFFECT_DOUBLE_CLICK = "double_click"
        const val EFFECT_CUSTOM = "custom"

        const val MAX_HAPTIC_DURATION = 1000
        const val MAX_VIBRATION_DURATION = 3000
    }
}
