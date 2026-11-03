package io.nullstate.nestprep.location

import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import kotlin.math.min

data class TrailBatch(val day: String, val points: List<TrailPoint>, val overflow: List<TrailPoint>)

class TrailDays(timeZone: String, logger: Logger) {
    // java.time needs API 26 and this app supports 24, so the household's zone goes through Calendar,
    // whose lookup answers GMT for an id it does not know rather than failing.
    private val zone: TimeZone = TimeZone.getTimeZone(timeZone).takeIf { it.id == timeZone }
        ?: TimeZone.getDefault().also { logger.log("Unknown time zone $timeZone; using ${it.id}") }
    private val calendar = Calendar.getInstance(zone, Locale.US)

    fun dayOf(point: TrailPoint): String {
        calendar.timeInMillis = point.t * 1000
        return String.format(
            Locale.US,
            "%04d-%02d-%02d",
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )
    }

    fun batches(points: List<TrailPoint>, room: (String) -> Int): List<TrailBatch> =
        points.groupBy(::dayOf).map { (day, sameDay) ->
            val space = room(day).coerceAtLeast(0)
            TrailBatch(
                day = day,
                points = sameDay.take(min(Payloads.MAX_POINTS_PER_WRITE, space)),
                overflow = sameDay.drop(space),
            )
        }
}
