package io.nullstate.nestprep.location

import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

data class Fix(
    val latitude: Double,
    val longitude: Double,
    val accuracyMetres: Float,
    val atMillis: Long,
)

fun Fix.metresTo(other: Fix): Double {
    val dLat = Math.toRadians(other.latitude - latitude)
    val dLon = Math.toRadians(other.longitude - longitude)
    val a = sin(dLat / 2).pow(2) +
        cos(Math.toRadians(latitude)) * cos(Math.toRadians(other.latitude)) * sin(dLon / 2).pow(2)
    return 2 * EARTH_RADIUS_METRES * asin(sqrt(a))
}

private const val EARTH_RADIUS_METRES = 6_371_008.8
