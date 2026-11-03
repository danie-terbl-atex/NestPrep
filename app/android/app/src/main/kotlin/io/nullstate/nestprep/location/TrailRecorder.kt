package io.nullstate.nestprep.location

class TrailRecorder {
    private var last: Fix? = null
    private var lastAt = 0L

    fun shouldRecord(fix: Fix, nowMillis: Long): Boolean {
        if (fix.accuracyMetres > MAX_ACCURACY_METRES) return false
        val previous = last
        if (previous != null) {
            val sinceLast = nowMillis - lastAt
            if (sinceLast < MIN_GAP_MILLIS) return false
            if (fix.metresTo(previous) < MIN_METRES && sinceLast < MAX_GAP_MILLIS) return false
        }
        last = fix
        lastAt = nowMillis
        return true
    }

    companion object {
        const val MAX_ACCURACY_METRES = 100f
        const val MIN_METRES = 30.0
        const val MIN_GAP_MILLIS = 15_000L
        const val MAX_GAP_MILLIS = 5 * 60 * 1000L
    }
}
