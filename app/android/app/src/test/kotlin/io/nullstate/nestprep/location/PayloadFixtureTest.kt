package io.nullstate.nestprep.location

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.time.Duration

class PayloadFixtureTest {
    private val fixture = JSONObject(File("../../test/fixtures/location_payloads.json").readText())
    private val now = 1_793_000_000_000L

    @Test
    fun `the live payload matches the fixture`() {
        val fields = fixture.getJSONObject("liveContinuous").getJSONObject("fields")
        val point = fields.getJSONObject("point").getJSONObject("geoPoint")
        val payload = Payloads.live(
            Fix(point.getDouble("latitude"), point.getDouble("longitude"), 11.6f, now),
            Battery(fields.getInt("batteryPercent"), fields.getBoolean("charging")),
            Motion.ofWire(fields.getString("motion")),
            now,
        )
        assertMatches(fields, payload)
    }

    @Test
    fun `the day flush matches the fixture`() {
        val fields = fixture.getJSONObject("dayFlush").getJSONObject("fields")
        val item = fields.getJSONObject("points").getJSONArray("arrayUnion").getJSONObject(0)
        val payload = Payloads.day(
            listOf(TrailPoint(item.getLong("t"), item.getDouble("la"), item.getDouble("lo"), item.getInt("ac"))),
            now,
        )
        assertMatches(fields, payload)
        val sent = (payload.getValue("points") as Field.Union).items.single()
        assertTrue(sent["t"] is Long)
        assertTrue(sent["la"] is Double)
        assertTrue(sent["lo"] is Double)
        assertTrue(sent["ac"] is Int)
    }

    @Test
    fun `the place event matches the fixture`() {
        val fields = fixture.getJSONObject("placeEvent").getJSONObject("fields")
        val kind = PlaceKind.entries.single { it.wire == fields.getString("kind") }
        assertMatches(fields, Payloads.placeEvent(fields.getString("placeId"), kind, now))
    }

    @Test
    fun `motion values are the fixture's`() {
        val wires = fixture.getJSONArray("motionValues").let { list -> (0 until list.length()).map(list::getString) }
        assertEquals(wires, Motion.entries.map { it.wire })
    }

    @Test
    fun `paths are the fixture's`() {
        fun path(name: String) = fixture.getJSONObject(name).getString("path")
            .replace("{householdId}", "h").replace("{memberId}", "m")
        assertEquals(path("liveContinuous"), Paths.live("h", "m"))
        assertEquals(path("dayFlush").replace("{yyyy-MM-dd}", "2026-11-02"), Paths.day("h", "m", "2026-11-02"))
        assertEquals(path("placeEvent").removeSuffix("/{autoId}"), Paths.events("h", "m"))
    }

    @Test
    fun `the start arguments parse and survive a round trip`() {
        val arguments = fixture.getJSONObject("startArguments")
        val config = LocationConfig.fromJson(arguments.toString())
        assertEquals("h1", config.householdId)
        assertEquals("m-sam", config.memberId)
        assertEquals("Africa/Johannesburg", config.timeZone)
        assertEquals(null, config.emulatorHost)
        assertEquals(8080, config.firestorePort)
        assertEquals(9099, config.authPort)
        assertEquals(true, config.foreground)
        assertEquals(listOf(Place("school", -26.1, 28.05, 150)), config.places)
        assertEquals("Sharing your location", config.notificationTitle)
        assertEquals("Location sharing", config.notificationChannelName)
        assertEquals(arguments.getString("notificationPauseLabel"), config.notificationPauseLabel)
        assertEquals(config, LocationConfig.fromJson(config.toJson()))
        arguments.remove("notificationPauseLabel")
        assertEquals(null, LocationConfig.fromJson(arguments.toString()).notificationPauseLabel)
    }

    private fun assertMatches(expected: JSONObject, actual: Map<String, Field>) {
        assertEquals(expected.keyNames(), actual.keys)
        for (key in expected.keyNames()) {
            val want = expected.get(key)
            val got = actual.getValue(key)
            when {
                want == "serverTimestamp" -> assertEquals(key, Field.ServerTime, got)
                want is JSONObject && want.has("geoPoint") -> {
                    val point = want.getJSONObject("geoPoint")
                    assertEquals(key, Field.Point(point.getDouble("latitude"), point.getDouble("longitude")), got)
                }
                want is JSONObject && want.has("timestampFromNow") -> assertEquals(
                    key,
                    Field.TimeAt(now + Duration.parse(want.getString("timestampFromNow")).toMillis()),
                    got,
                )
                want is JSONObject && want.has("arrayUnion") -> assertUnion(key, want.getJSONArray("arrayUnion"), got)
                else -> {
                    val value = (got as Field.Value).value
                    assertEquals(key, want::class, value::class)
                    assertEquals(key, want, value)
                }
            }
        }
    }

    private fun JSONObject.keyNames(): Set<String> = keys().asSequence().toSet()

    private fun assertUnion(key: String, expected: JSONArray, actual: Field) {
        val items = (actual as Field.Union).items
        assertEquals(key, expected.length(), items.size)
        items.forEachIndexed { index, item ->
            val want = expected.getJSONObject(index)
            assertEquals(key, want.keyNames(), item.keys)
            for (field in want.keyNames()) {
                assertEquals("$key.$field", (want.get(field) as Number).toDouble(), (item.getValue(field) as Number).toDouble(), 0.0)
                val integral = want.get(field).let { it is Int || it is Long }
                assertEquals("$key.$field", integral, item.getValue(field).let { it is Int || it is Long })
            }
        }
    }
}
