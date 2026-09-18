package org.droidconverge.bridge

import android.Manifest
import android.app.Activity
import android.app.ActivityOptions
import android.app.AlertDialog
import android.app.Presentation
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.display.DisplayManager
import android.hardware.input.InputManager
import android.os.Build
import android.os.Bundle
import android.text.InputType
import android.text.method.ScrollingMovementMethod
import android.view.Gravity
import android.view.Display
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
    private lateinit var displayManager: DisplayManager
    private lateinit var displayDetector: ExternalDisplayDetector
    private lateinit var displaySummaryView: TextView
    private lateinit var sessionSummaryView: TextView
    private lateinit var processSummaryView: TextView
    private lateinit var peripheralSummaryView: TextView
    private lateinit var externalPeripheralStatusView: TextView
    private lateinit var inputRouteControls: LinearLayout
    private var externalPresentation: Presentation? = null
    private var selectedDisplayOverride = DisplayOverride.Automatic
    private var displayOverrideSpinner: Spinner? = null
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = refreshDisplayPanel()
        override fun onDisplayRemoved(displayId: Int) {
            externalPresentation?.dismiss()
            externalPresentation = null
            displayOverrideSpinner?.setSelection(0)
            refreshDisplayPanel()
            Thread { InputRouteController.clearAll(applicationContext) }.start()
        }
        override fun onDisplayChanged(displayId: Int) = refreshDisplayPanel()
    }
    private val inputListener = object : InputManager.InputDeviceListener {
        override fun onInputDeviceAdded(deviceId: Int) = refreshDisplayPanel()
        override fun onInputDeviceRemoved(deviceId: Int) = refreshDisplayPanel()
        override fun onInputDeviceChanged(deviceId: Int) = refreshDisplayPanel()
    }

    private val permissionRequestCode = 1001
    private val termuxPermissionRequestCode = 1002
    private val mainHandler by lazy { android.os.Handler(android.os.Looper.getMainLooper()) }
    private val sessionRefresh = Runnable { refreshDisplayPanel(); refreshProcessStatus() }

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
        displayManager = getSystemService(DisplayManager::class.java)
        displayDetector = ExternalDisplayDetector(displayManager)

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
            text = "Protocol v1 • ${BuildConfig.VERSION_NAME} (sperimentale)"
            textSize = 14f
            setPadding(0, 0, 0, 12)
        })

        addExternalDisplayPanel(top)

        val advanced = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
        }
        lateinit var logHeader: LinearLayout
        lateinit var logScroll: ScrollView
        addTestRow(top, listOf("Strumenti avanzati" to {
            val show = advanced.visibility != View.VISIBLE
            advanced.visibility = if (show) View.VISIBLE else View.GONE
            logHeader.visibility = if (show) View.VISIBLE else View.GONE
            logScroll.visibility = if (show) View.VISIBLE else View.GONE
        }))
        top.addView(advanced)

        advanced.addView(TextView(this).apply {
            text = "Authentication token"
            textSize = 15f
        })

        tokenView = TextView(this).apply {
            text = app.getBridgeToken()
            textSize = 13f
            setTextIsSelectable(true)
            setPadding(0, 8, 0, 8)
        }
        advanced.addView(tokenView)

        val tokenRow = row()
        tokenRow.addView(button("Copia token") {
            copyText("DroidConverge token", tokenView.text.toString())
        })
        tokenRow.addView(button("Rigenera token") {
            tokenView.text = app.regenerateToken()
            DebugLog.log("TOKEN|REGENERATED")
        })
        tokenRow.addView(button("Permessi") { requestPermissionsIfNeeded() })
        advanced.addView(tokenRow)

        advanced.addView(sectionTitle("Test API"))
        addTestRow(advanced, listOf(
            "Ping" to { testDirect("ping") },
            "Haptic" to { testDirect("haptic") },
            "Vibrazione" to { testDirect("vibrate") }
        ))
        addTestRow(advanced, listOf(
            "Battery" to { testDirect("battery") },
            "Wi-Fi status" to { testDirect("wifi", "status") },
            "Bluetooth status" to { testDirect("bluetooth", "status") }
        ))
        addTestRow(advanced, listOf(
            "Wi-Fi ON" to { testDirect("wifi", "on") },
            "Wi-Fi OFF" to { testDirect("wifi", "off") },
            "Notifica" to { testDirect("notify") }
        ))
        addTestRow(advanced, listOf(
            "Bluetooth ON" to { testDirect("bluetooth", "on") },
            "Bluetooth OFF" to { testDirect("bluetooth", "off") }
        ))

        advanced.addView(sectionTitle("Impostazioni vibrazione / feedback aptico"))

        advanced.addView(CheckBox(this).apply {
            text = "Feedback aptico TCP abilitato"
            isChecked = settings.hapticEnabled
            setOnCheckedChangeListener { _, checked ->
                settings.hapticEnabled = checked
                DebugLog.log("SETTING|hapticEnabled=$checked")
            }
        })

        advanced.addView(label("Effetto haptic"))

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
        advanced.addView(effectSpinner)

        advanced.addView(numericField(
            "Durata haptic (ms)",
            settings.hapticDurationMs.toString()
        ) { settings.hapticDurationMs = it })

        advanced.addView(numericField(
            "Intensità haptic (1-255)",
            settings.hapticAmplitude.toString()
        ) { settings.hapticAmplitude = it })

        advanced.addView(CheckBox(this).apply {
            text = "Vibrazione generale abilitata"
            isChecked = settings.vibrationEnabled
            setOnCheckedChangeListener { _, checked ->
                settings.vibrationEnabled = checked
                DebugLog.log("SETTING|vibrationEnabled=$checked")
            }
        })

        advanced.addView(numericField(
            "Durata vibrazione (ms)",
            settings.vibrationDurationMs.toString()
        ) { settings.vibrationDurationMs = it })

        advanced.addView(numericField(
            "Intensità vibrazione (1-255)",
            settings.vibrationAmplitude.toString()
        ) { settings.vibrationAmplitude = it })

        addTestRow(advanced, listOf(
            "Testa haptic" to { testDirect("haptic") },
            "Testa vibrazione" to { testDirect("vibrate") },
            "Reset impostazioni" to {
                settings.reset()
                recreate()
            }
        ))

        advanced.addView(TextView(this).apply {
            text = "Gli effetti predefiniti Android dipendono anche dal firmware. 'custom' usa durata + ampiezza."
            textSize = 12f
            setPadding(0, 8, 0, 12)
        })

        topScroll.addView(top, ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ))

        logHeader = row()
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

        logScroll = ScrollView(this).apply {
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
        logHeader.visibility = View.GONE
        logScroll.visibility = View.GONE

        setContentView(root)

        DebugLog.addListener(logListener).forEach(::appendLog)
        requestPermissionsIfNeeded()
    }

    override fun onStart() {
        super.onStart()
        displayManager.registerDisplayListener(displayListener, mainHandler)
        getSystemService(InputManager::class.java).registerInputDeviceListener(inputListener, mainHandler)
        refreshDisplayPanel()
        refreshProcessStatus()
        if (TermuxSessionClient.isAvailable(this)) {
            TermuxSessionClient.run(this, "status")
            scheduleSessionRefresh()
        }
    }

    override fun onStop() {
        displayManager.unregisterDisplayListener(displayListener)
        getSystemService(InputManager::class.java).unregisterInputDeviceListener(inputListener)
        externalPresentation?.dismiss()
        externalPresentation = null
        super.onStop()
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(sessionRefresh)
        DebugLog.removeListener(logListener)
        super.onDestroy()
    }

    private fun scheduleSessionRefresh() {
        refreshDisplayPanel()
        refreshProcessStatus()
        for (delay in listOf(1500L, 6000L, 30000L)) {
            mainHandler.postDelayed(sessionRefresh, delay)
        }
    }

    private fun refreshProcessStatus() {
        if (!::processSummaryView.isInitialized) return
        processSummaryView.text = "Verifica processi in corso…"
        Thread {
            val summary = SessionProcessProbe.summary()
            runOnUiThread { if (!isFinishing) processSummaryView.text = summary }
        }.start()
    }

    private fun currentOverride(): DisplayOverride = selectedDisplayOverride

    private fun addExternalDisplayPanel(parent: LinearLayout) {
        parent.addView(sectionTitle("Schermo esterno e sessione Anland"))
        displaySummaryView = TextView(this).apply { textSize = 14f; setTextIsSelectable(true) }
        sessionSummaryView = TextView(this).apply { textSize = 18f; setTextIsSelectable(true) }
        processSummaryView = TextView(this).apply { textSize = 16f; setTextIsSelectable(true) }
        parent.addView(sessionSummaryView)
        parent.addView(processSummaryView)
        val details = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; visibility = View.GONE }

        details.addView(label("Modalità osservata manualmente (sperimentale)"))
        val overrideSpinner = Spinner(this)
        displayOverrideSpinner = overrideSpinner
        val overrides = DisplayOverride.entries
        overrideSpinner.adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item,
            listOf("Automatica", "Mirroring visto sul monitor", "Desktop proprietario visto"))
        overrideSpinner.setSelection(overrides.indexOf(currentOverride()).coerceAtLeast(0))
        overrideSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onNothingSelected(parent: AdapterView<*>?) = Unit
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                selectedDisplayOverride = overrides[position]
                refreshDisplayPanel()
            }
        }
        details.addView(overrideSpinner)

        addTestRow(parent, listOf(
            "Aggiorna stato" to { refreshDisplayPanel(); refreshProcessStatus(); requestSessionStatus() }
        ))
        addTestRow(parent, listOf(
            "Abilita Termux" to {
                AlertDialog.Builder(this)
                    .setTitle("Permesso Termux")
                    .setMessage("Questo permesso consente all'app di eseguire comandi nel tuo Termux. È necessario anche allow-external-apps=true, da impostare manualmente in Termux. Continuare?")
                    .setNegativeButton("Annulla", null)
                    .setPositiveButton("Richiedi permesso") { _, _ ->
                        requestPermissions(arrayOf(TermuxSessionClient.permission), termuxPermissionRequestCode)
                    }
                    .show()
            },
            "Apri Termux" to {
                val launch = packageManager.getLaunchIntentForPackage("com.termux")
                if (launch != null) startActivity(launch)
                else Toast.makeText(this, "Termux non installato", Toast.LENGTH_LONG).show()
            }
        ))
        addTestRow(parent, listOf(
            "Avvia" to { confirmSessionAction("start", "Avviare la sessione Anland/KDE?") },
            "Ferma" to { confirmSessionAction("stop", "Richiedere l'arresto della sessione gestita? Il risultato va verificato in Termux.") },
            "Ripara" to { confirmSessionAction("recover", "Solo se KDE è rimasto attivo nella chroot senza Anland: terminare quel processo KDE e rimuovere il socket inattivo? I processi non verificati non vengono toccati.") }
        ))
        addTestRow(parent, listOf(
            "Anland su HDMI" to { openAnlandOnExternal() },
            "Anland su tablet" to { openAnlandOnInternal() },
            "Impostazioni schermo" to { startActivity(Intent(android.provider.Settings.ACTION_DISPLAY_SETTINGS)) }
        ))
        addTestRow(parent, listOf("Display e periferiche" to {
            details.visibility = if (details.visibility == View.VISIBLE) View.GONE else View.VISIBLE
        }))
        details.addView(displaySummaryView)
        addTestRow(details, listOf(
            "Copia diagnosi" to { copyText("Diagnosi DroidConverge", displaySummaryView.text.toString() + "\n" + sessionSummaryView.text.toString() + "\n" + processSummaryView.text.toString()) },
            "Riavvia KDE" to { confirmSessionAction("restart", "Riavviare la sessione gestita solo se l'arresto riesce?") }
        ))
        addTestRow(details, listOf(
            "Stato app sul monitor" to { showExternalStatus() },
            "Solo interno (app)" to {
                externalPresentation?.dismiss()
                externalPresentation = null
                overrideSpinner.setSelection(0)
                refreshDisplayPanel()
            }
        ))
        details.addView(TextView(this).apply {
            text = "I controlli non cambiano risoluzione, densità o modalità di sistema. Lo stato su monitor richiede un display di presentazione Android; il mirroring non è un desktop esteso."
            textSize = 12f
        })
        details.addView(sectionTitle("Periferiche collegate"))
        peripheralSummaryView = TextView(this).apply { textSize = 14f; setTextIsSelectable(true) }
        details.addView(peripheralSummaryView)
        externalPeripheralStatusView = TextView(this).apply { textSize = 14f; setTextIsSelectable(true) }
        details.addView(externalPeripheralStatusView)
        inputRouteControls = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        details.addView(inputRouteControls)
        addTestRow(details, listOf(
            "Aggiorna periferiche" to { refreshDisplayPanel() },
            "Metodi input" to { startActivity(Intent(android.provider.Settings.ACTION_INPUT_METHOD_SETTINGS)) },
            "Bluetooth" to { startActivity(Intent(android.provider.Settings.ACTION_BLUETOOTH_SETTINGS)) }
        ))
        addTestRow(details, listOf(
            "Rilascia tutti gli input" to { runInputRoute { InputRouteController.clearAll(applicationContext).joinToString() } },
            "Impostazioni audio" to { startActivity(Intent(android.provider.Settings.ACTION_SOUND_SETTINGS)) },
            "Tono HDMI" to { runInputRoute { HdmiAudioProbe.play(applicationContext) } }
        ))
        details.addView(label("Input: associazioni Android temporanee via root. Il touchscreen del tablet resta disponibile per il recupero. Il tono prova Android, non l'audio KDE. Le memorie USB richiedono un montaggio separato nella chroot."))
        parent.addView(details)
        parent.addView(sectionTitle("Installazione su un altro dispositivo"))
        parent.addView(label("Richiede Termux GitHub, root, Anland compatibile e permesso RUN_COMMAND. La procedura interattiva verifica i prerequisiti prima di modificare il chroot."))
        parent.addView(button("Avvia installazione guidata") { confirmInstall() })
        refreshDisplayPanel()
    }

    private fun refreshDisplayPanel() {
        if (!::displaySummaryView.isInitialized) return
        val (facts, profile) = displayDetector.read(currentOverride())
        displaySummaryView.text = "Profilo: ${profile.family}\nPercorso: ${profile.path}${if (profile.experimental) " (sperimentale)" else ""}\nDisplay Android: ${facts.totalDisplays}, presentazione: ${facts.presentationDisplays}, aggiuntivi: ${facts.externalDisplays}\n${profile.observation}"
        val result = TermuxSessionClient.lastResult(this)
        val state = when (result) {
            "RUNNING", "ALREADY_RUNNING", "STARTED" -> "SESSIONE AVVIATA"
            "STOPPED", "RECOVERED" -> "SESSIONE FERMA"
            "ORPHANED" -> "KDE RESIDUO SENZA ANLAND"
            "UNKNOWN" -> "SESSIONE NON GESTITA O INCERTA"
            else -> "STATO DA VERIFICARE"
        }
        sessionSummaryView.text = "$state\nTermux: ${if (TermuxSessionClient.isAvailable(this)) "permesso pronto" else "permesso o servizio mancante"}\nUltima risposta: $result"
        if (::peripheralSummaryView.isInitialized) peripheralSummaryView.text = PeripheralInventory.summary(this)
        if (::externalPeripheralStatusView.isInitialized) externalPeripheralStatusView.text = ExternalPeripheralStatus.summary(this)
        if (::inputRouteControls.isInitialized) refreshInputRouteControls()
    }

    private fun refreshInputRouteControls() {
        inputRouteControls.removeAllViews()
        val display = displayManager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
            .firstOrNull { it.displayId != Display.DEFAULT_DISPLAY }
        val owned = InputRouteController.owned(this)
        val devices = InputRouteController.devices(this)
        inputRouteControls.addView(label("Instradabili: ${devices.size}; HDMI: ${if (display == null) "assente" else display.displayId}"))
        devices.forEach { device ->
            val isRouted = device.descriptor in owned
            val label = "${device.name.take(42)}: ${if (isRouted) "Sul tablet" else "Su HDMI"}"
            val control = button(label) {
                if (isRouted) runInputRoute { InputRouteController.clear(applicationContext, device.descriptor) }
                else if (display != null) runInputRoute { InputRouteController.route(applicationContext, device, display.displayId) }
                else Toast.makeText(this, "Display HDMI non disponibile", Toast.LENGTH_LONG).show()
            }
            inputRouteControls.addView(row().apply { addView(control) })
        }
    }

    private fun runInputRoute(action: () -> String) {
        Thread {
            val result = try { action() } catch (error: Exception) { "Errore input: ${error.message}" }
            runOnUiThread {
                Toast.makeText(this, result.take(160), Toast.LENGTH_LONG).show()
                refreshDisplayPanel()
            }
        }.start()
    }

    private fun requestSessionStatus() {
        if (!TermuxSessionClient.run(this, "status")) {
            Toast.makeText(this, "Serve il permesso RUN_COMMAND e la configurazione Termux", Toast.LENGTH_LONG).show()
            return
        }
        scheduleSessionRefresh()
    }

    private fun confirmInstall() {
        AlertDialog.Builder(this)
            .setTitle("Installazione guidata")
            .setMessage("Apre Termux, scarica il checkout DroidConverge e avvia i controlli interattivi. Prima di ogni modifica al chroot richiede root, Anland, Ubuntu 26.04 e conferma nel terminale. Continuare?")
            .setNegativeButton("Annulla", null)
            .setPositiveButton("Apri Termux") { _, _ ->
                if (!TermuxSessionClient.runInstaller(this)) {
                    Toast.makeText(this, "Termux o permesso RUN_COMMAND non disponibile", Toast.LENGTH_LONG).show()
                }
            }
            .show()
    }

    private fun confirmSessionAction(action: String, message: String) {
        AlertDialog.Builder(this)
            .setTitle("Sessione Anland/KDE")
            .setMessage(message)
            .setNegativeButton("Annulla", null)
            .setPositiveButton("Continua") { _, _ ->
                if (!TermuxSessionClient.run(this, action)) {
                    val result = TermuxSessionClient.lastResult(this)
                    if (result.contains("RedMagic blocca")) {
                        AlertDialog.Builder(this)
                            .setTitle("Avvio Termux bloccato")
                            .setMessage("RedMagic impedisce all'app di avviare Termux a freddo. Apri Termux, torna a DroidConverge e ripeti il comando. Puoi abilitare l'avvio automatico di Termux nelle impostazioni del dispositivo.")
                            .setNegativeButton("Chiudi", null)
                            .setPositiveButton("Apri Termux") { _, _ ->
                                packageManager.getLaunchIntentForPackage("com.termux")?.let(::startActivity)
                            }
                            .show()
                    } else {
                        Toast.makeText(this, result.take(160), Toast.LENGTH_LONG).show()
                    }
                    refreshDisplayPanel()
                } else {
                    scheduleSessionRefresh()
                }
            }
            .show()
    }

    private fun showExternalStatus() {
        val display = displayManager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
            .firstOrNull { it.displayId != Display.DEFAULT_DISPLAY }
        if (display == null) {
            Toast.makeText(this, "Nessun display di presentazione Android rilevato", Toast.LENGTH_SHORT).show()
            return
        }
        externalPresentation?.dismiss()
        externalPresentation = object : Presentation(this, display) {
            override fun onCreate(savedInstanceState: Bundle?) {
                super.onCreate(savedInstanceState)
                setContentView(TextView(context).apply {
                    text = "DroidConverge Companion\nControlli sul display interno del tablet\nQuesta finestra mostra solo lo stato dell'app. Per KDE, apri Anland e scegli Schermo esteso in RedMagic."
                    textSize = 24f
                    gravity = Gravity.CENTER
                })
            }
        }
        try {
            externalPresentation?.show()
        } catch (_: android.view.WindowManager.InvalidDisplayException) {
            externalPresentation = null
            refreshDisplayPanel()
        }
    }

    private fun openAnlandOnExternal() {
        val display = displayManager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
            .firstOrNull { it.displayId != Display.DEFAULT_DISPLAY }
        if (display == null) {
            Toast.makeText(this, "Serve un display esterno e l'app Anland", Toast.LENGTH_LONG).show()
            return
        }
        openAnlandOnDisplay(display.displayId)
    }

    private fun openAnlandOnInternal() = openAnlandOnDisplay(Display.DEFAULT_DISPLAY)

    private fun openAnlandOnDisplay(displayId: Int) {
        val launch = packageManager.getLaunchIntentForPackage("com.anland.termux")
        if (launch == null) {
            Toast.makeText(this, "App Anland non installata o non avviabile", Toast.LENGTH_LONG).show()
            return
        }
        try {
            val options = ActivityOptions.makeBasic().setLaunchDisplayId(displayId)
            startActivity(launch, options.toBundle())
        } catch (_: RuntimeException) {
            Toast.makeText(this, "RedMagic non ha spostato Anland; usa le impostazioni schermo", Toast.LENGTH_LONG).show()
        }
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

        if (requestCode == permissionRequestCode || requestCode == termuxPermissionRequestCode) {
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
