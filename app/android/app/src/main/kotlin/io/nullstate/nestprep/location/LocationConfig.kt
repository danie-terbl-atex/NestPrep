package io.nullstate.nestprep.location

import org.json.JSONArray
import org.json.JSONObject

data class Place(
    val id: String,
    val latitude: Double,
    val longitude: Double,
    val radiusMetres: Int,
) {
    companion object {
        fun listFrom(value: Any?): List<Place> = (value as? List<*>).orEmpty().map { entry ->
            val fields = entry as? Map<*, *> ?: throw IllegalArgumentException("place")
            Place(
                id = fields.string("id"),
                latitude = fields.number("latitude").toDouble(),
                longitude = fields.number("longitude").toDouble(),
                radiusMetres = fields.number("radiusMetres").toInt(),
            )
        }
    }
}

data class LocationConfig(
    val householdId: String,
    val memberId: String,
    val timeZone: String,
    val emulatorHost: String?,
    val firestorePort: Int,
    val authPort: Int,
    val foreground: Boolean,
    val places: List<Place>,
    val notificationTitle: String,
    val notificationBody: String,
    val notificationChannelName: String,
    val notificationPauseLabel: String?,
) {
    fun sameSharer(other: LocationConfig): Boolean =
        householdId == other.householdId && memberId == other.memberId && emulatorHost == other.emulatorHost

    fun toJson(): String = JSONObject()
        .put("householdId", householdId)
        .put("memberId", memberId)
        .put("timeZone", timeZone)
        .put("emulatorHost", emulatorHost ?: JSONObject.NULL)
        .put("firestorePort", firestorePort)
        .put("authPort", authPort)
        .put("foreground", foreground)
        .put(
            "places",
            JSONArray(
                places.map {
                    JSONObject()
                        .put("id", it.id)
                        .put("latitude", it.latitude)
                        .put("longitude", it.longitude)
                        .put("radiusMetres", it.radiusMetres)
                },
            ),
        )
        .put("notificationTitle", notificationTitle)
        .put("notificationBody", notificationBody)
        .put("notificationChannelName", notificationChannelName)
        .put("notificationPauseLabel", notificationPauseLabel ?: JSONObject.NULL)
        .toString()

    companion object {
        fun fromArguments(arguments: Map<*, *>): LocationConfig = LocationConfig(
            householdId = arguments.string("householdId"),
            memberId = arguments.string("memberId"),
            timeZone = arguments.string("timeZone"),
            emulatorHost = arguments["emulatorHost"] as? String,
            firestorePort = arguments.number("firestorePort").toInt(),
            authPort = arguments.number("authPort").toInt(),
            foreground = arguments["foreground"] == true,
            places = Place.listFrom(arguments["places"]),
            notificationTitle = arguments.string("notificationTitle"),
            notificationBody = arguments.string("notificationBody"),
            notificationChannelName = arguments.string("notificationChannelName"),
            notificationPauseLabel = (arguments["notificationPauseLabel"] as? String)?.takeIf { it.isNotBlank() },
        )

        fun fromJson(text: String): LocationConfig = fromArguments(JSONObject(text).toMap())
    }
}

private fun Map<*, *>.string(key: String): String =
    this[key] as? String ?: throw IllegalArgumentException(key)

private fun Map<*, *>.number(key: String): Number =
    this[key] as? Number ?: throw IllegalArgumentException(key)

private fun JSONObject.toMap(): Map<String, Any?> = keys().asSequence().associateWith { unwrap(get(it)) }

private fun unwrap(value: Any?): Any? = when (value) {
    JSONObject.NULL -> null
    is JSONObject -> value.toMap()
    is JSONArray -> (0 until value.length()).map { unwrap(value.get(it)) }
    else -> value
}
