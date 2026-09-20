package org.droidconverge.bridge

import android.hardware.display.DisplayManager
import android.os.Build
import android.view.Display

enum class DisplayPath {
    InternalOnly,
    MirrorCompanion,
    SecondaryDisplayCompanion,
    DesktopEnvironmentDetected,
    UnsupportedOrUnknown
}

enum class DisplayOverride {
    Automatic,
    MirrorObserved,
    ProprietaryDesktopObserved
}

data class DisplayFacts(
    val totalDisplays: Int,
    val presentationDisplays: Int,
    val externalDisplays: Int,
    val manufacturer: String,
    val model: String,
    val override: DisplayOverride
)

data class DeviceCapabilityProfile(
    val family: String,
    val path: DisplayPath,
    val canShowPresentation: Boolean,
    val observation: String,
    val experimental: Boolean
)

object DisplayProfileResolver {
    fun resolve(facts: DisplayFacts): DeviceCapabilityProfile {
        val family = when {
            facts.manufacturer.contains("nubia", true) || facts.model.contains("NP05J", true) -> "RedMagic Astra"
            facts.manufacturer.contains("samsung", true) -> "Samsung (DeX da verificare)"
            facts.manufacturer.contains("motorola", true) -> "Motorola (Smart Connect da verificare)"
            facts.manufacturer.contains("google", true) -> "Pixel (modalità da verificare)"
            else -> "Dispositivo non profilato"
        }
        val path = when {
            facts.override == DisplayOverride.ProprietaryDesktopObserved -> DisplayPath.DesktopEnvironmentDetected
            facts.override == DisplayOverride.MirrorObserved -> DisplayPath.MirrorCompanion
            facts.presentationDisplays > 0 -> DisplayPath.SecondaryDisplayCompanion
            facts.externalDisplays > 0 || facts.totalDisplays > 1 -> DisplayPath.UnsupportedOrUnknown
            else -> DisplayPath.InternalOnly
        }
        val observation = when (path) {
            DisplayPath.InternalOnly -> "Solo display interno rilevato dalle API Android. Il mirroring hardware potrebbe non essere esposto."
            DisplayPath.MirrorCompanion -> "Mirroring dichiarato manualmente: verificare visivamente il monitor."
            DisplayPath.SecondaryDisplayCompanion -> "Android espone un display di presentazione separato; l'estensione del desktop KDE non è verificata."
            DisplayPath.DesktopEnvironmentDetected -> "Ambiente desktop dichiarato manualmente; nessuna integrazione proprietaria automatica."
            DisplayPath.UnsupportedOrUnknown -> "Display aggiuntivo rilevato senza capacità di presentazione; nessuna modifica automatica."
        }
        return DeviceCapabilityProfile(
            family = family,
            path = path,
            canShowPresentation = facts.presentationDisplays > 0,
            observation = observation,
            experimental = path != DisplayPath.InternalOnly
        )
    }
}

class ExternalDisplayDetector(private val manager: DisplayManager) {
    fun read(override: DisplayOverride): Pair<DisplayFacts, DeviceCapabilityProfile> {
        val displays = manager.displays.toList()
        val presentationIds = manager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
            .map(Display::getDisplayId).toSet()
        val facts = DisplayFacts(
            totalDisplays = displays.size,
            presentationDisplays = displays.count { it.displayId in presentationIds && it.displayId != Display.DEFAULT_DISPLAY },
            externalDisplays = displays.count { it.displayId != Display.DEFAULT_DISPLAY },
            manufacturer = Build.MANUFACTURER.orEmpty(),
            model = Build.MODEL.orEmpty(),
            override = override
        )
        return facts to DisplayProfileResolver.resolve(facts)
    }
}
