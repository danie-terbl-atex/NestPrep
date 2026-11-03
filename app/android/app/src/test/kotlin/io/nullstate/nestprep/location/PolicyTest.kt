package io.nullstate.nestprep.location

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PolicyTest {
    private fun fix(northMetres: Double = 0.0, accuracy: Float = 10f) =
        Fix(-26.2 + northMetres / 111_195.0, 28.0, accuracy, 0)

    @Test
    fun `live writes respect the floor even when forced`() {
        assertTrue(LivePolicy.isDue(null, 0.0, false, foreground = false, forced = false))
        assertFalse(LivePolicy.isDue(11_999, 1_000.0, true, foreground = true, forced = true))
        assertTrue(LivePolicy.isDue(12_000, 0.0, false, foreground = false, forced = true))
    }

    @Test
    fun `foreground live writes need 20 seconds and movement or a new motion`() {
        assertFalse(LivePolicy.isDue(19_999, 100.0, true, foreground = true, forced = false))
        assertFalse(LivePolicy.isDue(60_000, 24.0, false, foreground = true, forced = false))
        assertTrue(LivePolicy.isDue(20_000, 25.0, false, foreground = true, forced = false))
        assertTrue(LivePolicy.isDue(20_000, 0.0, true, foreground = true, forced = false))
    }

    @Test
    fun `background live writes come every two minutes or after a big jump`() {
        assertFalse(LivePolicy.isDue(119_999, 249.0, true, foreground = false, forced = false))
        assertTrue(LivePolicy.isDue(120_000, 0.0, false, foreground = false, forced = false))
        assertTrue(LivePolicy.isDue(15_000, 250.0, false, foreground = false, forced = false))
        assertFalse(LivePolicy.isDue(14_999, 250.0, false, foreground = false, forced = false))
    }

    @Test
    fun `stillness needs five minutes within fifty metres`() {
        val detector = StillDetector()
        assertNull(detector.deadline())
        assertTrue(detector.onFix(fix(), 0))
        assertFalse(detector.onFix(fix(40.0), 60_000))
        assertFalse(detector.isStill(299_999))
        assertTrue(detector.isStill(300_000))
        assertTrue(detector.onFix(fix(120.0), 200_000))
        assertFalse(detector.isStill(300_000))
        assertEquals(500_000L, detector.deadline())
    }

    @Test
    fun `a fix wobbling within its own accuracy is not travel`() {
        val detector = StillDetector()
        detector.onFix(fix(), 0)
        assertFalse(detector.onFix(fix(80.0, accuracy = 90f), 10_000))
        assertTrue(detector.onFix(fix(95.0, accuracy = 90f), 20_000))
    }

    @Test
    fun `trail points need accuracy and then distance or time`() {
        val recorder = TrailRecorder()
        assertFalse(recorder.shouldRecord(fix(accuracy = 101f), 0))
        assertTrue(recorder.shouldRecord(fix(), 0))
        assertFalse(recorder.shouldRecord(fix(29.0), 10_000))
        assertTrue(recorder.shouldRecord(fix(31.0), 20_000))
        assertFalse(recorder.shouldRecord(fix(31.0), 319_999))
        assertTrue(recorder.shouldRecord(fix(31.0), 320_000))
    }

    @Test
    fun `trail points are at least 15 seconds apart however far apart they are`() {
        val recorder = TrailRecorder()
        assertTrue(recorder.shouldRecord(fix(), 0))
        assertFalse(recorder.shouldRecord(fix(30.0), 1_000))
        assertFalse(recorder.shouldRecord(fix(400.0), 14_999))
        assertTrue(recorder.shouldRecord(fix(420.0), 15_000))
    }

    @Test
    fun `an exit soon after an arrival is ignored`() {
        val debounce = PlaceDebounce()
        assertEquals(PlaceKind.Arrive, debounce.onTransition("school", PlaceTransition.Dwell, 0))
        assertNull(debounce.onTransition("school", PlaceTransition.Exit, 179_999))
        assertEquals(PlaceKind.Arrive, debounce.onTransition("school", PlaceTransition.Dwell, 200_000))
        assertEquals(PlaceKind.Leave, debounce.onTransition("school", PlaceTransition.Exit, 380_000))
        assertEquals(PlaceKind.Leave, debounce.onTransition("home", PlaceTransition.Exit, 0))
    }

    @Test
    fun `activities map to the motion values`() {
        assertEquals(Motion.Driving, Motion.ofActivity(0))
        assertEquals(Motion.Cycling, Motion.ofActivity(1))
        assertEquals(Motion.OnFoot, Motion.ofActivity(2))
        assertEquals(Motion.Still, Motion.ofActivity(3))
        assertEquals(Motion.Unknown, Motion.ofActivity(4))
        assertEquals(Motion.Unknown, Motion.ofActivity(5))
        assertEquals(Motion.OnFoot, Motion.ofActivity(7))
        assertEquals(Motion.OnFoot, Motion.ofActivity(8))
    }

    @Test
    fun `backoff doubles to a quarter of an hour`() {
        assertEquals(30_000L, WriteLane.backoffMillis(1))
        assertEquals(60_000L, WriteLane.backoffMillis(2))
        assertEquals(900_000L, WriteLane.backoffMillis(20))
    }

    @Test
    fun `addresses read as number, street and suburb`() {
        assertEquals("12 Oak Street, Parkhurst", AddressLine.format("12", "Oak Street", "Parkhurst", "Johannesburg", "x"))
        assertEquals("Oak Street, Johannesburg", AddressLine.format(null, "Oak Street", " ", "Johannesburg", "x"))
        assertEquals("Parkhurst", AddressLine.format("12", null, "Parkhurst", null, "x"))
        assertEquals("1 Main Rd, Town", AddressLine.format(null, null, null, null, "1 Main Rd, Town"))
        assertNull(AddressLine.format(null, null, null, null, null))
    }
}
