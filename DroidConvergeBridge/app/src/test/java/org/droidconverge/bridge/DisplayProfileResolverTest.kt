package org.droidconverge.bridge

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class DisplayProfileResolverTest {
    private fun facts(
        total: Int = 1,
        presentation: Int = 0,
        external: Int = 0,
        override: DisplayOverride = DisplayOverride.Automatic,
        manufacturer: String = "nubia",
        model: String = "NP05J"
    ) = DisplayFacts(total, presentation, external, manufacturer, model, override)

    @Test fun internalOnlyWithoutVisibleExternalDisplay() {
        assertEquals(DisplayPath.InternalOnly, DisplayProfileResolver.resolve(facts()).path)
    }

    @Test fun mirrorRequiresManualObservation() {
        assertEquals(DisplayPath.MirrorCompanion,
            DisplayProfileResolver.resolve(facts(override = DisplayOverride.MirrorObserved)).path)
    }

    @Test fun presentationDisplayDoesNotClaimKdeExtension() {
        val result = DisplayProfileResolver.resolve(facts(total = 2, presentation = 1, external = 1))
        assertEquals(DisplayPath.SecondaryDisplayCompanion, result.path)
        assertEquals(true, result.canShowPresentation)
    }

    @Test fun unclassifiedDisplayIsUnknown() {
        assertEquals(DisplayPath.UnsupportedOrUnknown,
            DisplayProfileResolver.resolve(facts(total = 2, external = 1)).path)
    }

    @Test fun desktopPathOnlyWithExplicitObservation() {
        val automatic = DisplayProfileResolver.resolve(facts(manufacturer = "samsung", model = "Galaxy"))
        assertEquals(DisplayPath.InternalOnly, automatic.path)
        assertEquals("Samsung (DeX da verificare)", automatic.family)
        assertFalse(automatic.canShowPresentation)
        assertEquals(DisplayPath.DesktopEnvironmentDetected,
            DisplayProfileResolver.resolve(facts(override = DisplayOverride.ProprietaryDesktopObserved)).path)
    }
}
