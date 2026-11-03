package io.nullstate.nestprep.location

enum class PlaceTransition { Dwell, Exit }

class PlaceDebounce(private val settleMillis: Long = SETTLE_MILLIS) {
    private val arrivedAt = mutableMapOf<String, Long>()

    fun onTransition(placeId: String, transition: PlaceTransition, nowMillis: Long): PlaceKind? = when (transition) {
        PlaceTransition.Dwell -> {
            arrivedAt[placeId] = nowMillis
            PlaceKind.Arrive
        }
        PlaceTransition.Exit -> {
            val arrival = arrivedAt.remove(placeId)
            if (arrival != null && nowMillis - arrival < settleMillis) null else PlaceKind.Leave
        }
    }

    companion object {
        const val SETTLE_MILLIS = 3 * 60 * 1000L
    }
}
