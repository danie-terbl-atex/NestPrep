package io.nullstate.nestprep.location

import org.json.JSONObject
import java.io.File

class DayLedger(private val file: File) {
    private data class Entry(val sent: Int, val ackedAt: Long)

    private val days: MutableMap<String, Entry> = load()

    fun room(day: String): Int = MAX_POINTS_PER_DAY - (days[day]?.sent ?: 0)

    fun waitBefore(day: String, nowMillis: Long): Long =
        days[day]?.let { (it.ackedAt + SPACING_MILLIS - nowMillis).coerceAtLeast(0) } ?: 0

    fun acknowledged(day: String, count: Int, nowMillis: Long) {
        days[day] = Entry((days[day]?.sent ?: 0) + count, nowMillis)
        days.entries.removeAll { nowMillis - it.value.ackedAt > KEEP_MILLIS }
        file.writeAtomically(
            JSONObject(days.mapValues { (_, e) -> JSONObject().put("sent", e.sent).put("ackedAt", e.ackedAt) })
                .toString(),
        )
    }

    fun clear() {
        days.clear()
        file.delete()
    }

    private fun load(): MutableMap<String, Entry> {
        val json = file.readTextOrNull()?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return mutableMapOf()
        return json.keys().asSequence().associateWithTo(mutableMapOf()) { day ->
            val entry = json.getJSONObject(day)
            Entry(entry.getInt("sent"), entry.getLong("ackedAt"))
        }
    }

    companion object {
        const val MAX_POINTS_PER_DAY = 3_000
        const val SPACING_MILLIS = 30_000L
        private const val KEEP_MILLIS = 3 * 24 * 60 * 60 * 1000L
    }
}
