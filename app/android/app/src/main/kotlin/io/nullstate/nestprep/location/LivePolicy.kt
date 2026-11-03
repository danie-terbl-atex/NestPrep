package io.nullstate.nestprep.location

object LivePolicy {
    const val FLOOR_MILLIS = 12_000L
    private const val FOREGROUND_MILLIS = 20_000L
    private const val FOREGROUND_METRES = 25.0
    private const val BACKGROUND_MILLIS = 120_000L
    private const val BACKGROUND_JUMP_METRES = 250.0
    private const val BACKGROUND_JUMP_MILLIS = 15_000L

    fun isDue(
        sinceAckMillis: Long?,
        movedMetres: Double,
        motionChanged: Boolean,
        foreground: Boolean,
        forced: Boolean,
    ): Boolean {
        if (sinceAckMillis == null) return true
        if (sinceAckMillis < FLOOR_MILLIS) return false
        if (forced) return true
        return if (foreground) {
            sinceAckMillis >= FOREGROUND_MILLIS && (movedMetres >= FOREGROUND_METRES || motionChanged)
        } else {
            sinceAckMillis >= BACKGROUND_MILLIS ||
                (movedMetres >= BACKGROUND_JUMP_METRES && sinceAckMillis >= BACKGROUND_JUMP_MILLIS)
        }
    }

    fun recheckMillis(foreground: Boolean): Long = if (foreground) FOREGROUND_MILLIS else BACKGROUND_JUMP_MILLIS
}
