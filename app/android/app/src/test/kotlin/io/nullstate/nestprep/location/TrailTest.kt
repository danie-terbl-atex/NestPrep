package io.nullstate.nestprep.location

import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.util.TimeZone

class TrailTest {
    @get:Rule
    val folder = TemporaryFolder()

    private fun point(t: Long) = TrailPoint(t, -26.2, 28.0, 10)

    @Test
    fun `days are cut in the household's zone`() {
        val days = TrailDays("Africa/Johannesburg") {}
        assertEquals("2026-10-26", days.dayOf(point(1_793_051_999)))
        assertEquals("2026-10-27", days.dayOf(point(1_793_052_000)))
        assertEquals("2026-10-26", TrailDays("UTC") {}.dayOf(point(1_793_052_000)))
    }

    @Test
    fun `an unknown zone falls back to the device's and says so`() {
        val logged = mutableListOf<String>()
        val previous = TimeZone.getDefault()
        TimeZone.setDefault(TimeZone.getTimeZone("Africa/Johannesburg"))
        try {
            val days = TrailDays("Mars/Olympus_Mons") { logged += it }
            assertEquals("2026-10-27", days.dayOf(point(1_793_052_000)))
            assertEquals(1, logged.size)
        } finally {
            TimeZone.setDefault(previous)
        }
    }

    @Test
    fun `each day is its own batch of at most 120 points within the day's room`() {
        val days = TrailDays("UTC") {}
        val first = (0 until 150L).map { point(1_793_000_000 + it) }
        val next = point(1_793_100_000)
        val batches = days.batches(first + next) { 3_000 }
        assertEquals(listOf("2026-10-26", "2026-10-27"), batches.map { it.day })
        assertEquals(first.take(120), batches[0].points)
        assertEquals(emptyList<TrailPoint>(), batches[0].overflow)
        assertEquals(listOf(next), batches[1].points)

        val full = days.batches(first) { 100 }.single()
        assertEquals(first.take(100), full.points)
        assertEquals(first.drop(100), full.overflow)

        assertEquals(emptyList<TrailBatch>(), days.batches(emptyList()) { 3_000 })
    }

    @Test
    fun `the buffer survives a restart, drops its oldest past capacity and skips a torn line`() {
        val file = folder.root.resolve("trail.jsonl")
        val buffer = TrailBuffer(file, capacity = 3)
        (1L..4L).forEach { buffer.add(point(it)) }
        assertEquals((2L..4L).map(::point), buffer.points)
        buffer.add(point(5))
        file.appendText("{\"t\":6,\"la\":")
        val reopened = TrailBuffer(file, capacity = 3)
        assertEquals((3L..5L).map(::point), reopened.points)
        reopened.remove(listOf(point(2), point(3)))
        assertEquals(listOf(point(4), point(5)), TrailBuffer(file, capacity = 3).points)
    }

    @Test
    fun `the ledger spaces each day doc and counts its points`() {
        val file = folder.root.resolve("ledger.json")
        val ledger = DayLedger(file)
        assertEquals(0L, ledger.waitBefore("2026-11-02", 0))
        ledger.acknowledged("2026-11-02", 120, 1_000)
        assertEquals(20_000L, ledger.waitBefore("2026-11-02", 11_000))
        assertEquals(0L, ledger.waitBefore("2026-11-03", 11_000))
        val reopened = DayLedger(file)
        assertEquals(2_880, reopened.room("2026-11-02"))
        assertEquals(0L, reopened.waitBefore("2026-11-02", 31_000))
    }
}
