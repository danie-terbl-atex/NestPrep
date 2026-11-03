package io.nullstate.nestprep.location

import kotlin.math.roundToInt

sealed interface Field {
    data class Point(val latitude: Double, val longitude: Double) : Field
    data object ServerTime : Field
    data class TimeAt(val epochMillis: Long) : Field
    data class Union(val items: List<Map<String, Any>>) : Field
    data class Value(val value: Any) : Field
}

enum class PlaceKind(val wire: String) { Arrive("arrive"), Leave("leave") }

object Payloads {
    const val LEASE_MILLIS = 24 * 60 * 60 * 1000L
    const val RETENTION_MILLIS = 30 * 24 * 60 * 60 * 1000L
    const val MAX_POINTS_PER_WRITE = 120

    fun live(fix: Fix, battery: Battery, motion: Motion, nowMillis: Long): Map<String, Field> = mapOf(
        "point" to Field.Point(fix.latitude, fix.longitude),
        "accuracyMetres" to Field.Value(fix.accuracyMetres.roundToInt()),
        "reportedAt" to Field.ServerTime,
        "sharingUntil" to Field.TimeAt(nowMillis + LEASE_MILLIS),
        "mode" to Field.Value("continuous"),
        "batteryPercent" to Field.Value(battery.percent.coerceIn(0, 100)),
        "charging" to Field.Value(battery.charging),
        "motion" to Field.Value(motion.wire),
    )

    fun day(points: List<TrailPoint>, nowMillis: Long): Map<String, Field> = mapOf(
        "points" to Field.Union(points.take(MAX_POINTS_PER_WRITE).map(TrailPoint::toMap)),
        "updatedAt" to Field.ServerTime,
        "expiresAt" to Field.TimeAt(nowMillis + RETENTION_MILLIS),
    )

    fun placeEvent(placeId: String, kind: PlaceKind, nowMillis: Long): Map<String, Field> = mapOf(
        "placeId" to Field.Value(placeId),
        "kind" to Field.Value(kind.wire),
        "at" to Field.ServerTime,
        "expiresAt" to Field.TimeAt(nowMillis + RETENTION_MILLIS),
    )
}

object Paths {
    fun places(householdId: String) = "households/$householdId/places"

    fun live(householdId: String, memberId: String) = "households/$householdId/memberLocations/$memberId"

    fun day(householdId: String, memberId: String, day: String) =
        "households/$householdId/locationTrails/$memberId/trailDays/$day"

    fun events(householdId: String, memberId: String) =
        "households/$householdId/locationTrails/$memberId/placeEvents"
}
