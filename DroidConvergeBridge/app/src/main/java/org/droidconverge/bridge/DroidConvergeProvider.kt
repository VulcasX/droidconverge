package org.droidconverge.bridge

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.Binder
import android.os.Bundle
import android.os.VibrationEffect
import android.os.VibrationAttributes
import android.os.VibratorManager

/**
 * Minimal Android IPC surface for DroidConverge.
 *
 * Linux/root clients can invoke provider-defined methods with Android's
 * ContentResolver/content tooling. The API intentionally starts tiny and
 * grows only after each command is validated on real hardware.
 */
class DroidConvergeProvider : ContentProvider() {

    companion object {
        const val AUTHORITY = "org.droidconverge.bridge"
        private const val METHOD_HAPTIC = "haptic"
        private const val RESULT_OK = "ok"
        private const val RESULT_ERROR = "error"

        private const val UID_ROOT = 0
        private const val UID_SHELL = 2000
    }

    override fun onCreate(): Boolean = true

    override fun call(method: String, arg: String?, extras: Bundle?): Bundle {
        enforceCaller()

        return try {
            when (method) {
                METHOD_HAPTIC -> {
                    performHaptic()
                    Bundle().apply {
                        putString("status", RESULT_OK)
                        putString("method", METHOD_HAPTIC)
                    }
                }

                else -> Bundle().apply {
                    putString("status", RESULT_ERROR)
                    putString("message", "Unknown method: $method")
                }
            }
        } catch (t: Throwable) {
            Bundle().apply {
                putString("status", RESULT_ERROR)
                putString("message", t.message ?: t.javaClass.simpleName)
            }
        }
    }

    private fun enforceCaller() {
        val callingUid = Binder.getCallingUid()
        val ownUid = context?.applicationInfo?.uid ?: -1

        require(callingUid == UID_ROOT || callingUid == UID_SHELL || callingUid == ownUid) {
            "Caller UID $callingUid is not authorized"
        }
    }

    private fun performHaptic() {
        val ctx = requireNotNull(context)
        val vibratorManager = ctx.getSystemService(VibratorManager::class.java)
            ?: error("VibratorManager unavailable")

        val vibrator = vibratorManager.defaultVibrator
        if (!vibrator.hasVibrator()) {
            error("No vibrator available")
        }

        val effect = VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
        val attributes = VibrationAttributes.Builder()
            .setUsage(VibrationAttributes.USAGE_TOUCH)
            .build()

        vibrator.vibrate(effect, attributes)
    }

    // The first bridge version is command/IPC-only; data CRUD is intentionally unsupported.
    override fun query(uri: Uri, projection: Array<String>?, selection: String?, selectionArgs: Array<String>?, sortOrder: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<String>?): Int = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<String>?): Int = 0
}
