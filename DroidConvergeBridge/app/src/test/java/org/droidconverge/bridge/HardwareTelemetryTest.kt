package org.droidconverge.bridge

import org.junit.Assert.*
import org.junit.Test

class HardwareTelemetryTest {
    @Test fun selectsHighestClusterSensorAndRejectsInvalidValues() {
        val result = HardwareTelemetry.parse("""
            TEMP cpu-0-0 50100
            TEMP cpu-0-1 51700
            TEMP gpuss-0 45300
            TEMP battery 37900
            TEMP skin-msm-therm 38981
            TEMP cpu-bad 999999
            FAN 1 4
        """.trimIndent())
        assertEquals(51700, result.cpuMilliC)
        assertEquals(45300, result.gpuMilliC)
        assertEquals(37900, result.batteryMilliC)
        assertEquals(true, result.fanEnabled)
        assertEquals(4, result.fanLevel)
    }
}
