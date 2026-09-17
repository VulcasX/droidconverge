package org.droidconverge.bridge

import org.json.JSONObject

data class BridgeRequest(
    val id: String,
    val action: String,
    val state: String? = null,
    val title: String? = null,
    val text: String? = null,
    val token: String? = null
)

object BridgeProtocol {

    private fun optionalString(json: JSONObject, key: String): String? =
        if (json.has(key) && !json.isNull(key)) json.optString(key) else null

    fun parse(line: String): BridgeRequest {
        val json = JSONObject(line)

        return BridgeRequest(
            id = json.optString("id", ""),
            action = json.getString("action"),
            state = optionalString(json, "state"),
            title = optionalString(json, "title"),
            text = optionalString(json, "text"),
            token = optionalString(json, "token")
        )
    }

    fun response(
        id: String,
        action: String,
        ok: Boolean,
        error: String? = null,
        data: JSONObject? = null
    ): String {
        val json = JSONObject()
            .put("id", id)
            .put("action", action)
            .put("ok", ok)

        if (error != null) {
            json.put("error", error)
        }

        if (data != null) {
            json.put("data", data)
        }

        return json.toString()
    }

    fun error(
        id: String,
        action: String,
        error: String
    ): String {
        return response(
            id = id,
            action = action,
            ok = false,
            error = error
        )
    }
}

