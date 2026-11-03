package io.nullstate.nestprep.location

import org.json.JSONObject
import kotlin.math.roundToInt

data class TrailPoint(val t: Long, val la: Double, val lo: Double, val ac: Int) {
    fun toMap(): Map<String, Any> = mapOf("t" to t, "la" to la, "lo" to lo, "ac" to ac)

    fun toLine(): String = JSONObject().put("t", t).put("la", la).put("lo", lo).put("ac", ac).toString()

    companion object {
        fun of(fix: Fix) = TrailPoint(fix.atMillis / 1000, fix.latitude, fix.longitude, fix.accuracyMetres.roundToInt())

        fun ofLine(line: String): TrailPoint? = runCatching {
            val json = JSONObject(line)
            TrailPoint(json.getLong("t"), json.getDouble("la"), json.getDouble("lo"), json.getInt("ac"))
        }.getOrNull()
    }
}
