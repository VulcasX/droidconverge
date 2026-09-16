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

    fun parse(line: String): BridgeRequest {
        val json = JSONObject(line)

        return BridgeRequest(
            id = json.optString("id", ""),
            action = json.getString("action"),
            state = json.optString("state", null),
            title = json.optString("title", null),
            text = json.optString("text", null),
            token = json.optString("token", null)
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

