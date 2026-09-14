package org.droidconverge.bridge

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class MainActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(48, 64, 48, 48)
        }

        val title = TextView(this).apply {
            text = "DroidConverge Bridge\nDeveloper Preview"
            textSize = 24f
            gravity = Gravity.CENTER
        }

        val description = TextView(this).apply {
            text = "Android IPC bridge for the DroidConverge project.\n\nVersion 0.1.0-dev"
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 32)
        }

        val hapticButton = Button(this).apply {
            text = "Test haptic"
            setOnClickListener {
                contentResolver.call(
                    DroidConvergeProvider.AUTHORITY,
                    "haptic",
                    null,
                    null
                )
            }
        }

        root.addView(title, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        root.addView(description, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        root.addView(hapticButton, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)

        setContentView(root)
    }
}
