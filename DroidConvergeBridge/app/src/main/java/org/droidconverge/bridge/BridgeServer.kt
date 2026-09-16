package org.droidconverge.bridge

import android.content.Context
import java.io.BufferedReader
import java.io.BufferedWriter
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.InetAddress
import java.net.ServerSocket
import java.net.SocketException
import java.util.concurrent.Executors

class BridgeServer(
    private val context: Context,
    private val tokenProvider: () -> String
) {

    companion object {
        const val HOST = "127.0.0.1"
        const val PORT = 8765
    }

    private val executor =
        Executors.newCachedThreadPool()

    private val actions =
        BridgeActions(context)

    @Volatile
    private var running = false

    @Volatile
    private var serverSocket: ServerSocket? = null

    fun start() {

        if (running) {
            return
        }

        running = true

        executor.execute {

            try {

                serverSocket =
                    ServerSocket(
                        PORT,
                        50,
                        InetAddress.getByName(HOST)
                    )

                DebugLog.log(
                    "SERVER|LISTEN|$HOST:$PORT"
                )

                while (running) {

                    try {

                        val client =
                            serverSocket?.accept()
                                ?: break

                        executor.execute {
                            handle(client)
                        }

                    } catch (e: SocketException) {

                        if (running) {

                            DebugLog.log(
                                "SERVER|ACCEPT_ERROR|${e.message}"
                            )
                        }
                    }
                }

            } catch (e: Exception) {

                DebugLog.log(
                    "SERVER|START_ERROR|" +
                        "${e.javaClass.simpleName}:${e.message}"
                )

                running = false
            }
        }
    }

    fun stop() {

        running = false

        runCatching {
            serverSocket?.close()
        }

        serverSocket = null

        DebugLog.log(
            "SERVER|STOP"
        )
    }

    private fun handle(
        socket: java.net.Socket
    ) {

        socket.use { client ->

            client.soTimeout = 10000

            DebugLog.log(
                "CLIENT|CONNECTED|${client.remoteSocketAddress}"
            )

            val reader =
                BufferedReader(
                    InputStreamReader(
                        client.getInputStream(),
                        Charsets.UTF_8
                    )
                )

            val writer =
                BufferedWriter(
                    OutputStreamWriter(
                        client.getOutputStream(),
                        Charsets.UTF_8
                    )
                )

            while (running) {

                val line =
                    reader.readLine()
                        ?: break

                val response =
                    process(line)

                writer.write(response)
                writer.newLine()
                writer.flush()
            }

            DebugLog.log(
                "CLIENT|DISCONNECTED|${client.remoteSocketAddress}"
            )
        }
    }

    private fun process(
        line: String
    ): String {

        val request =
            try {

                BridgeProtocol.parse(line)

            } catch (_: Exception) {

                DebugLog.log(
                    "RX|INVALID_JSON"
                )

                return BridgeProtocol.error(
                    "",
                    "invalid",
                    "invalid_json"
                )
            }

        DebugLog.log(
            "RX|${request.action}" +
                (
                    request.state?.let {
                        "|$it"
                    } ?: ""
                )
        )

        if (
            request.token.isNullOrBlank() ||
            request.token != tokenProvider()
        ) {

            DebugLog.log(
                "AUTH|DENIED|${request.action}"
            )

            return BridgeProtocol.error(
                request.id,
                request.action,
                "unauthorized"
            )
        }

        return try {

            val (ok, data) =
                actions.execute(request)

            if (ok) {

                BridgeProtocol.response(
                    id = request.id,
                    action = request.action,
                    ok = true,
                    data = data
                )

            } else {

                BridgeProtocol.response(
                    id = request.id,
                    action = request.action,
                    ok = false,
                    error = data?.optString(
                        "error",
                        "operation_failed"
                    ),
                    data = data
                )
            }

        } catch (e: SecurityException) {

            DebugLog.log(
                "ACTION|PERMISSION_DENIED|${request.action}"
            )

            BridgeProtocol.error(
                request.id,
                request.action,
                "permission_denied"
            )

        } catch (e: Exception) {

            DebugLog.log(
                "ACTION|ERROR|" +
                    "${e.javaClass.simpleName}:${e.message}"
            )

            BridgeProtocol.error(
                request.id,
                request.action,
                "internal_error"
            )
        }
    }
}

