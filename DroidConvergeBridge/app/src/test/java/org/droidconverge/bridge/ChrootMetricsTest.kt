package org.droidconverge.bridge

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ChrootMetricsTest {
    @Test fun computesShareOfHostCpuAndApproximateRam() {
        val before = ChrootMetrics(1000, 100, 200000, 1000000, 4)
        val after = ChrootMetrics(1200, 150, 250000, 1000000, 5)
        assertEquals(25, after.cpuPercent(before))
        assertEquals(25, after.memoryPercent)
        assertNull(before.cpuPercent(null))
    }
}
