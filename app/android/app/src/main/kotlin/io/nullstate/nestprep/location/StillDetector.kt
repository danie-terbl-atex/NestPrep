package io.nullstate.nestprep.location

import kotlin.math.max

class StillDetector(
    private val windowMillis: Long = WINDOW_MILLIS,
    private val radiusMetres: Double = RADIUS_METRES,
) {
    private var anchor: Fix? = null
    private var anchoredAt = 0L

    fun restart(fix: Fix?, nowMillis: Long) {
        anchor = fix
        anchoredAt = nowMillis
    }

    fun onFix(fix: Fix, nowMillis: Long): Boolean {
        val current = anchor
        // A fix wobbling inside its own accuracy circle is not travel.
        if (current != null && fix.metresTo(current) < max(radiusMetres, fix.accuracyMetres.toDouble())) return false
        restart(fix, nowMillis)
        return true
    }

    fun deadline(): Long? = anchor?.let { anchoredAt + windowMillis }

    fun isStill(nowMillis: Long): Boolean = anchor != null && nowMillis - anchoredAt >= windowMillis

    companion object {
        const val WINDOW_MILLIS = 5 * 60 * 1000L
        const val RADIUS_METRES = 50.0
    }
}
