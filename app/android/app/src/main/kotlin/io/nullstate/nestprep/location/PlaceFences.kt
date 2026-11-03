package io.nullstate.nestprep.location

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

@SuppressLint("MissingPermission")
internal class PlaceFences(private val context: Context) {
    private val client = LocationServices.getGeofencingClient(context)

    fun register(places: List<Place>) {
        clear()
        if (places.isEmpty() || !LocationPermissions.canRunInBackground(context)) return
        val fences = places.take(MAX_PLACES).map { place ->
            Geofence.Builder()
                .setRequestId(PREFIX + place.id)
                .setCircularRegion(place.latitude, place.longitude, place.radiusMetres.toFloat())
                .setTransitionTypes(
                    Geofence.GEOFENCE_TRANSITION_ENTER or
                        Geofence.GEOFENCE_TRANSITION_DWELL or
                        Geofence.GEOFENCE_TRANSITION_EXIT,
                )
                .setLoiteringDelay(DWELL_MILLIS)
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .build()
        }
        val request = GeofencingRequest.Builder().setInitialTrigger(0).addGeofences(fences).build()
        try {
            client.addGeofences(request, LocationIntents.placeFences(context))
                .addOnFailureListener { Log.w(LOG_TAG, "Place geofences not registered: ${it.message}") }
        } catch (e: SecurityException) {
            Log.w(LOG_TAG, "Place geofences not registered: ${e.message}")
        }
    }

    fun clear() {
        client.removeGeofences(LocationIntents.placeFences(context))
    }

    companion object {
        const val PREFIX = "place:"
        private const val DWELL_MILLIS = 60_000

        // Android allows 100 geofences per app and the stationary fence takes one of them.
        private const val MAX_PLACES = 99
    }
}
