package org.droidconverge.bridge

import android.Manifest
import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.text.InputType
import android.text.method.ScrollingMovementMethod
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.CheckBox
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast

class MainActivity : Activity() {

    private lateinit var logView: TextView
    private lateinit var tokenView: TextView
    private lateinit var settings: BridgeSettings

    private val permissionRequestCode = 1001
    private val mainHandler by lazy { android.os.Handler(android.os.Looper.getMainLooper()) }

    private val logListener: (String) -> Unit = { line ->
        mainHandler.post {
            if (line.isEmpty()) {
                logView.text = ""
            } else {
                appendLog(line)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val app = application as DroidConvergeBridgeApp
        settings = BridgeSettings(this)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(20, 20, 20, 20)
        }

        val topScroll = ScrollView(this)
        val top = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        top.addView(TextView(this).apply {
            text = "DroidConverge Bridge"
            textSize = 26f
            setPadding(0, 0, 0, 8)
        })

        top.addView(TextView(this).apply {
            text = "TCP API: 127.0.0.1:${BridgeServer.PORT}"
            textSize = 16f
        })

        top.addView(TextView(this).apply {
            text = "Protocol v1 • 0.3.0-dev"
            textSize = 14f
            setPadding(0, 0, 0, 12)
        })

        top.addView(TextView(this).apply {
            text = "Authentication token"
            textSize = 15f
        })

        tokenView = TextView(this).apply {
            text = app.getBridgeToken()
            textSize = 13f
            setTextIsSelectable(true)
            setPadding(0, 8, 0, 8)
        }
        top.addView(tokenView)

        val tokenRow = row()
        tokenRow.addView(button("Copia token") {
            copyText("DroidConverge token", tokenView.text.toString())
        })
        tokenRow.addView(button("Rigenera token") {
            tokenView.text = app.regenerateToken()
            DebugLog.log("TOKEN|REGENERATED")
        })
        tokenRow.addView(button("Permessi") { requestPermissionsIfNeeded() })
        top.addView(tokenRow)

        top.addView(sectionTitle("Test API"))
        addTestRow(top, listOf(
            "Ping" to { testDirect("ping") },
            "Haptic" to { testDirect("haptic") },
            "Vibrazione" to { testDirect("vibrate") }
        ))
        addTestRow(top, listOf(
            "Battery" to { testDirect("battery") },
            "Wi-Fi status" to { testDirect("wifi", "status") },
            "Bluetooth status" to { testDirect("bluetooth", "status") }
        ))
        addTestRow(top, listOf(
            "Wi-Fi ON" to { testDirect("wifi", "on") },
            "Wi-Fi OFF" to { testDirect("wifi", "off") },
            "Notifica" to { testDirect("notify") }
        ))
        addTestRow(top, listOf(
            "Bluetooth ON" to { testDirect("bluetooth", "on") },
            "Bluetooth OFF" to { testDirect("bluetooth", "off") }
        ))

        top.addView(sectionTitle("Impostazioni vibrazione / feedback aptico"))

        top.addView(CheckBox(this).apply {
            text = "Feedback aptico TCP abilitato"
            isChecked = settings.hapticEnabled
            setOnCheckedChangeListener { _, checked ->
                settings.hapticEnabled = checked
                DebugLog.log("SETTING|hapticEnabled=$checked")
            }
        })

        top.addView(label("Effetto haptic"))

        val effects = listOf(
            BridgeSettings.EFFECT_CLICK,
            BridgeSettings.EFFECT_TICK,
            BridgeSettings.EFFECT_HEAVY_CLICK,
            BridgeSettings.EFFECT_DOUBLE_CLICK,
            BridgeSettings.EFFECT_CUSTOM
        )

        val effectSpinner = Spinner(this)
        effectSpinner.adapter = ArrayAdapter(
            this,
            android.R.layout.simple_spinner_dropdown_item,
            effects
        )
        effectSpinner.setSelection(effects.indexOf(settings.hapticEffect).coerceAtLeast(0))
        effectSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onNothingSelected(parent: AdapterView<*>?) = Unit

            override fun onItemSelected(
                parent: AdapterView<*>?,
                view: View?,
                position: Int,
                id: Long
            ) {
                settings.hapticEffect = effects[position]
                DebugLog.log("SETTING|hapticEffect=${effects[position]}")
            }
        }
        top.addView(effectSpinner)

        top.addView(numericField(
            "Durata haptic (ms)",
            settings.hapticDurationMs.toString()
        ) { settings.hapticDurationMs = it })

        top.addView(numericField(
            "Intensità haptic (1-255)",
            settings.hapticAmplitude.toString()
        ) { settings.hapticAmplitude = it })

        top.addView(CheckBox(this).apply {
            text = "Vibrazione generale abilitata"
            isChecked = settings.vibrationEnabled
            setOnCheckedChangeListener { _, checked ->
                settings.vibrationEnabled = checked
                DebugLog.log("SETTING|vibrationEnabled=$checked")
            }
        })

        top.addView(numericField(
            "Durata vibrazione (ms)",
            settings.vibrationDurationMs.toString()
        ) { settings.vibrationDurationMs = it })

        top.addView(numericField(
            "Intensità vibrazione (1-255)",
            settings.vibrationAmplitude.toString()
        ) { settings.vibrationAmplitude = it })

        addTestRow(top, listOf(
            "Testa haptic" to { testDirect("haptic") },
            "Testa vibrazione" to { testDirect("vibrate") },
            "Reset impostazioni" to {
                settings.reset()
                recreate()
            }
        ))

        top.addView(TextView(this).apply {
            text = "Gli effetti predefiniti Android dipendono anche dal firmware. 'custom' usa durata + ampiezza."
            textSize = 12f
            setPadding(0, 8, 0, 12)
        })

        topScroll.addView(top, ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ))

        val logHeader = row()
        logHeader.addView(TextView(this).apply {
            text = "Debug / API requests"
            textSize = 18f
            gravity = Gravity.CENTER_VERTICAL
        }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        logHeader.addView(button("Copia log") {
            copyText("DroidConverge debug log", DebugLog.snapshot().joinToString("\n"))
        })
        logHeader.addView(button("Pulisci log") { DebugLog.clear() })

        logView = TextView(this).apply {
            textSize = 12f
            setTextIsSelectable(true)
            movementMethod = ScrollingMovementMethod()
            setPadding(12, 12, 12, 12)
            setBackgroundColor(android.graphics.Color.rgb(20, 20, 20))
            setTextColor(android.graphics.Color.rgb(220, 220, 220))
        }

        val logScroll = ScrollView(this).apply {
            addView(logView, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            ))
        }

        root.addView(topScroll, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            0,
            1.35f
        ))
        root.addView(logHeader)
        root.addView(logScroll, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            0,
            1f
        ))

        setContentView(root)

        DebugLog.addListener(logListener).forEach(::appendLog)
        requestPermissionsIfNeeded()
    }

    override fun onDestroy() {
        DebugLog.removeListener(logListener)
        super.onDestroy()
    }

    private fun addTestRow(parent: LinearLayout, buttons: List<Pair<String, () -> Unit>>) {
        val r = row()
        buttons.forEach { (text, action) -> r.addView(button(text, action)) }
        parent.addView(r)
    }

    private fun sectionTitle(text: String) = TextView(this).apply {
        this.text = text
        textSize = 19f
        setPadding(0, 18, 0, 8)
    }

    private fun label(text: String) = TextView(this).apply {
        this.text = text
        textSize = 14f
        setPadding(0, 8, 0, 4)
    }

    private fun row() = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
    }

    private fun button(text: String, action: () -> Unit) = Button(this).apply {
        this.text = text
        setOnClickListener { action() }
        layoutParams = LinearLayout.LayoutParams(
            0,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            1f
        ).apply { setMargins(4, 4, 4, 4) }
    }

    private fun numericField(labelText: String, initial: String, save: (Int) -> Unit) = EditText(this).apply {
        hint = labelText
        inputType = InputType.TYPE_CLASS_NUMBER
        setText(initial)
        setOnFocusChangeListener { _, hasFocus ->
            if (!hasFocus) {
                text.toString().toIntOrNull()?.let(save)
                setText(initialValueFor(labelText))
            }
        }
    }

    private fun initialValueFor(labelText: String): String = when (labelText) {
        "Durata haptic (ms)" -> settings.hapticDurationMs.toString()
        "Intensità haptic (1-255)" -> settings.hapticAmplitude.toString()
        "Durata vibrazione (ms)" -> settings.vibrationDurationMs.toString()
        else -> settings.vibrationAmplitude.toString()
    }

    private fun testDirect(action: String, state: String? = null) {
        Thread {
            val request = BridgeRequest(
                id = "ui-${System.currentTimeMillis()}",
                action = action,
                state = state,
                title = if (action == "notify") "DroidConverge Test" else null,
                text = if (action == "notify") "Test dalla schermata Bridge" else null,
                token = (application as DroidConvergeBridgeApp).getBridgeToken()
            )
            val result = BridgeActions(this).execute(request)
            val ok = result.first
            val details = result.second?.toString() ?: ""
            DebugLog.log("UI_TEST|action=$action|state=${state ?: ""}|ok=$ok|data=$details")
            runOnUiThread {
                Toast.makeText(this, "$action: ${if (ok) "OK" else "FAIL"}", Toast.LENGTH_SHORT).show()
            }
        }.start()
    }

    private fun copyText(label: String, text: String) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText(label, text))
        Toast.makeText(this, "$label copiato", Toast.LENGTH_SHORT).show()
    }

    private fun appendLog(line: String) {
        if (!::logView.isInitialized) return
        logView.append("$line\n")
        val layout = logView.layout ?: return
        val scrollAmount = layout.getLineTop(logView.lineCount) - logView.height
        logView.scrollTo(0, maxOf(scrollAmount, 0))
    }

    private fun requestPermissionsIfNeeded() {
        val permissions = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= 31 &&
            checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED
        ) {
            permissions += Manifest.permission.BLUETOOTH_CONNECT
        }

        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            permissions += Manifest.permission.POST_NOTIFICATIONS
        }

        if (permissions.isNotEmpty()) {
            requestPermissions(permissions.toTypedArray(), permissionRequestCode)
        } else {
            DebugLog.log("PERMISSIONS|ALREADY_GRANTED")
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == permissionRequestCode) {
            DebugLog.log("PERMISSIONS|RESULT")
            permissions.forEachIndexed { index, permission ->
                val result = if (
                    grantResults.getOrNull(index) == PackageManager.PERMISSION_GRANTED
                ) "GRANTED" else "DENIED"
                DebugLog.log("PERMISSIONS|$permission|$result")
            }
        }
    }
}
