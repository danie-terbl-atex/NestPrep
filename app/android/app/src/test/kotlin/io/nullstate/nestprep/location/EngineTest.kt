package io.nullstate.nestprep.location

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class EngineTest {
    @get:Rule
    val folder = TemporaryFolder()

    private class Time : Clock, Scheduler {
        private data class Job(val at: Long, val task: () -> Unit, var cancelled: Boolean = false)

        var now = 1_793_000_000_000L
        private val jobs = mutableListOf<Job>()

        override fun nowMillis() = now

        override fun after(delayMillis: Long, task: () -> Unit): Cancellable {
            val job = Job(now + delayMillis, task)
            jobs += job
            return Cancellable { job.cancelled = true }
        }

        fun advance(millis: Long) {
            val until = now + millis
            while (true) {
                val next = jobs.filter { !it.cancelled && it.at <= until }.minByOrNull { it.at } ?: break
                jobs.remove(next)
                now = next.at
                next.task()
            }
            now = until
        }
    }

    private class Writes : LocationStore {
        val live = mutableListOf<Pair<Map<String, Field>, WriteDone>>()
        val days = mutableListOf<Triple<String, Map<String, Field>, WriteDone>>()
        val events = mutableListOf<Pair<Map<String, Field>, WriteDone>>()
        var liveDeletes = 0

        override fun setLive(fields: Map<String, Field>, done: WriteDone) {
            live += fields to done
        }

        override fun deleteLive(done: () -> Unit) {
            liveDeletes += 1
            done()
        }

        override fun mergeDay(day: String, fields: Map<String, Field>, done: WriteDone) {
            days += Triple(day, fields, done)
        }

        override fun addEvent(fields: Map<String, Field>, done: WriteDone) {
            events += fields to done
        }
    }

    private class Probe : Sensors {
        var interval: Long? = null
        var watching: Fix? = null
        var heartbeat: Long? = null
        var fresh: ((Fix?) -> Unit)? = null

        override fun track(intervalMillis: Long) {
            interval = intervalMillis
        }

        override fun stopTracking() {
            interval = null
        }

        override fun watchForMovement(anchor: Fix) {
            watching = anchor
        }

        override fun stopWatchingForMovement() {
            watching = null
        }

        override fun scheduleHeartbeat(delayMillis: Long) {
            heartbeat = delayMillis
        }

        override fun cancelHeartbeat() {
            heartbeat = null
        }

        override fun freshFix(done: (Fix?) -> Unit) {
            fresh = done
        }
    }

    private val time = Time()
    private val writes = Writes()
    private val sensors = Probe()
    private val stops = mutableListOf<StopReason>()
    private val logged = mutableListOf<String>()
    private var signedInAs: String? = "uid-sam"

    private fun config(foreground: Boolean = true, places: List<Place> = emptyList()) = LocationConfig(
        "h", "m", "UTC", null, 8080, 9099, foreground, places, "t", "b", "c", "Pause",
    )

    private fun engine(foreground: Boolean = true, places: List<Place> = emptyList()) = Engine(
        config = config(foreground, places),
        uid = "uid-sam",
        session = { signedInAs },
        clock = time,
        scheduler = time,
        store = writes,
        sensors = sensors,
        battery = { Battery(64, false) },
        trail = TrailBuffer(folder.root.resolve("trail.jsonl")),
        ledger = DayLedger(folder.root.resolve("ledger.json")),
        logger = { logged += it },
        onIdle = {},
        onStop = { stops += it },
    )

    private fun fix(northMetres: Double, at: Long = time.now) = Fix(-26.2 + northMetres / 111_195.0, 28.0, 10f, at)

    private fun motionOf(fields: Map<String, Field>) = (fields.getValue("motion") as Field.Value).value

    private fun place(id: String) = Place(id, -26.1, 28.0, 150)

    private fun started(foreground: Boolean = true, places: List<Place> = emptyList()): Engine {
        val engine = engine(foreground, places)
        engine.start()
        engine.onFix(fix(0.0))
        return engine
    }

    @Test
    fun `one live write is in flight at a time and the latest point follows the ack`() {
        val engine = started()
        assertEquals(Engine.FOREGROUND_INTERVAL_MILLIS, sensors.interval)
        assertEquals(1, writes.live.size)

        time.advance(30_000)
        engine.onFix(fix(100.0))
        time.advance(30_000)
        engine.onFix(fix(200.0))
        assertEquals(1, writes.live.size)

        writes.live[0].second(WriteResult.Acknowledged)
        time.advance(19_999)
        assertEquals(1, writes.live.size)
        time.advance(1)
        assertEquals(2, writes.live.size)
        assertEquals(Field.Point(fix(200.0).latitude, 28.0), writes.live[1].first["point"])
    }

    @Test
    fun `a first write denied by the pace rule is retried after 12 seconds without counting`() {
        started()
        writes.live[0].second(WriteResult.Denied)
        time.advance(LivePolicy.FLOOR_MILLIS)
        assertEquals(2, writes.live.size)
        writes.live[1].second(WriteResult.Denied)
        assertEquals(emptyList<StopReason>(), stops)
        time.advance(WriteLane.DENIAL_RETRY_MILLIS)
        assertEquals(3, writes.live.size)
        writes.live[2].second(WriteResult.Denied)
        assertEquals(listOf(StopReason.Refused), stops)
        assertEquals(null, sensors.interval)
    }

    @Test
    fun `an acknowledged live write between denials resets the count`() {
        val engine = started()
        writes.live[0].second(WriteResult.Acknowledged)
        time.advance(30_000)
        engine.onFix(fix(100.0))
        writes.live[1].second(WriteResult.Denied)
        time.advance(WriteLane.DENIAL_RETRY_MILLIS)
        writes.live[2].second(WriteResult.Acknowledged)
        time.advance(30_000)
        engine.onFix(fix(200.0))
        writes.live[3].second(WriteResult.Denied)
        assertEquals(emptyList<StopReason>(), stops)
    }

    @Test
    fun `day and event denials are dropped and never count toward refusing`() {
        val engine = started(places = listOf(place("school"), place("gran")))
        writes.live[0].second(WriteResult.Acknowledged)
        repeat(30) {
            time.advance(TrailRecorder.MIN_GAP_MILLIS)
            engine.onFix(fix((it + 1) * 40.0))
        }
        assertEquals(1, writes.days.size)
        writes.days[0].third(WriteResult.Denied)

        engine.onPlace("gran", PlaceTransition.Dwell)
        writes.events[0].second(WriteResult.Denied)

        time.advance(30_000)
        engine.onFix(fix(5_000.0))
        writes.live.last().second(WriteResult.Denied)
        assertEquals(emptyList<StopReason>(), stops)
        assertEquals(1, writes.days.size)
        assertEquals(1, writes.events.size)
        assertEquals(2, logged.count { "dropped" in it })
    }

    @Test
    fun `a denial of a write queued for more than five minutes is retried with a fresh lease and never counted`() {
        val engine = started()
        repeat(3) { round ->
            time.advance(WriteLane.STALE_MILLIS + 1)
            engine.onFix(fix((round + 1) * 400.0))
            writes.live.last().second(WriteResult.Denied)
            time.advance(LivePolicy.FLOOR_MILLIS)
            assertEquals(round + 2, writes.live.size)
        }
        assertEquals(emptyList<StopReason>(), stops)
        assertEquals(Field.TimeAt(time.now + Payloads.LEASE_MILLIS), writes.live.last().first["sharingUntil"])
    }

    @Test
    fun `a stale day write is rebuilt with a fresh expiry rather than dropped`() {
        val engine = started()
        repeat(30) {
            time.advance(TrailRecorder.MIN_GAP_MILLIS)
            engine.onFix(fix((it + 1) * 40.0))
        }
        time.advance(WriteLane.STALE_MILLIS + 1)
        writes.days[0].third(WriteResult.Denied)
        time.advance(DayLedger.SPACING_MILLIS)
        assertEquals(2, writes.days.size)
        assertEquals(Field.TimeAt(time.now + Payloads.RETENTION_MILLIS), writes.days[1].second["expiresAt"])
        val queued = (writes.days[0].second.getValue("points") as Field.Union).items
        val resent = (writes.days[1].second.getValue("points") as Field.Union).items
        assertTrue(resent.containsAll(queued))
    }

    @Test
    fun `a write after the sharer signs out stops with signedOut and sends nothing`() {
        val engine = started()
        writes.live[0].second(WriteResult.Acknowledged)
        signedInAs = "uid-someone-else"
        time.advance(30_000)
        engine.onFix(fix(100.0))
        assertEquals(1, writes.live.size)
        assertEquals(listOf(StopReason.SignedOut), stops)
    }

    @Test
    fun `five quiet minutes go still, write once and arm the wakers`() {
        val engine = started(foreground = false)
        writes.live[0].second(WriteResult.Acknowledged)
        time.advance(StillDetector.WINDOW_MILLIS)
        assertFalse(engine.isMoving)
        assertEquals(null, sensors.interval)
        assertEquals(fix(0.0).latitude, sensors.watching!!.latitude, 0.0)
        assertEquals(Engine.HEARTBEAT_MILLIS, sensors.heartbeat)
        assertEquals(2, writes.live.size)
        assertEquals("still", motionOf(writes.live[1].first))
        writes.live[1].second(WriteResult.Acknowledged)

        engine.onFix(fix(100.0))
        assertFalse(engine.isMoving)

        time.advance(60_000)
        engine.onActivity(Motion.Driving)
        assertTrue(engine.isMoving)
        assertEquals(Engine.BACKGROUND_INTERVAL_MILLIS, sensors.interval)
        assertEquals(null, sensors.watching)
        assertEquals(null, sensors.heartbeat)
        assertEquals(3, writes.live.size)
        assertEquals("driving", motionOf(writes.live[2].first))
    }

    @Test
    fun `an activity still enter goes still at once`() {
        val engine = started()
        writes.live[0].second(WriteResult.Acknowledged)
        time.advance(20_000)
        engine.onActivity(Motion.Still)
        assertFalse(engine.isMoving)
        assertEquals(Engine.HEARTBEAT_MILLIS, sensors.heartbeat)
        assertEquals("still", motionOf(writes.live[1].first))
    }

    @Test
    fun `the heartbeat writes only a fresh fix and re-adds the still fence`() {
        val engine = started(foreground = false)
        writes.live[0].second(WriteResult.Acknowledged)
        time.advance(StillDetector.WINDOW_MILLIS)
        writes.live[1].second(WriteResult.Acknowledged)
        sensors.watching = null

        time.advance(Engine.HEARTBEAT_MILLIS)
        engine.onHeartbeat()
        assertEquals(fix(0.0).latitude, sensors.watching!!.latitude, 0.0)
        sensors.fresh!!(null)
        assertEquals(2, writes.live.size)

        engine.onHeartbeat()
        sensors.fresh!!(fix(20.0, at = time.now - Engine.MAX_FIX_AGE_MILLIS - 1))
        assertEquals(2, writes.live.size)

        engine.onHeartbeat()
        sensors.fresh!!(fix(20.0))
        assertEquals(3, writes.live.size)
        assertEquals(Field.Point(fix(20.0).latitude, 28.0), writes.live[2].first["point"])
        assertFalse(engine.isMoving)
    }

    @Test
    fun `thirty points flush one day write and leave the buffer until the ack`() {
        val engine = engine()
        engine.start()
        repeat(31) {
            engine.onFix(fix(it * 40.0))
            time.advance(TrailRecorder.MIN_GAP_MILLIS)
        }
        assertEquals(1, writes.days.size)
        val (day, fields, done) = writes.days[0]
        assertEquals("2026-10-26", day)
        assertEquals(30, (fields.getValue("points") as Field.Union).items.size)

        done(WriteResult.Acknowledged)
        assertEquals(1, writes.days.size)
    }

    @Test
    fun `finishing sends every day it can within the budget and reports once`() {
        val trail = TrailBuffer(folder.root.resolve("trail.jsonl"))
        val today = 1_793_000_000L
        (0 until 150L).forEach { trail.add(TrailPoint(today - 86_400 + it, -26.2, 28.0, 10)) }
        (0 until 5L).forEach { trail.add(TrailPoint(today + it, -26.2, 28.0, 10)) }
        val engine = engine()
        var finished = 0
        engine.finish(10_000) { finished += 1 }
        assertEquals(null, sensors.interval)
        assertEquals(1, writes.days.size)
        assertEquals("2026-10-25", writes.days[0].first)
        writes.days[0].third(WriteResult.Acknowledged)
        assertEquals(2, writes.days.size)
        assertEquals("2026-10-26", writes.days[1].first)
        assertEquals(0, finished)
        writes.days[1].third(WriteResult.Acknowledged)
        assertEquals(1, finished)
        assertEquals(30, TrailBuffer(folder.root.resolve("trail.jsonl")).size)
        engine.onFix(fix(1_000.0))
        assertEquals(2, writes.days.size)
    }

    @Test
    fun `place events go one at a time and a quick exit is dropped`() {
        val engine = started(places = listOf(place("school"), place("home")))
        engine.onPlace("school", PlaceTransition.Dwell)
        time.advance(60_000)
        engine.onPlace("school", PlaceTransition.Exit)
        engine.onPlace("home", PlaceTransition.Dwell)
        assertEquals(1, writes.events.size)
        assertEquals(Field.Value("arrive"), writes.events[0].first["kind"])
        writes.events[0].second(WriteResult.Acknowledged)
        assertEquals(2, writes.events.size)
        assertEquals(Field.Value("home"), writes.events[1].first["placeId"])
    }

    @Test
    fun `a crossing older than fifteen minutes is dropped instead of written`() {
        val engine = started(places = listOf(place("school"), place("home")))
        engine.onPlace("school", PlaceTransition.Dwell)
        engine.onPlace("home", PlaceTransition.Exit)
        time.advance(Engine.CROSSING_MAX_AGE_MILLIS + 1)
        writes.events[0].second(WriteResult.Acknowledged)
        assertEquals(1, writes.events.size)
        assertTrue(logged.any { "home" in it })
    }

    @Test
    fun `a removed place's queued crossing is pruned`() {
        val engine = started(places = listOf(place("school"), place("gran")))
        engine.onPlace("school", PlaceTransition.Dwell)
        engine.onPlace("gran", PlaceTransition.Dwell)
        engine.reconfigure(config(places = listOf(place("school"))))
        writes.events[0].second(WriteResult.Acknowledged)
        assertEquals(1, writes.events.size)
    }
}
