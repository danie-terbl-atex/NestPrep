package io.nullstate.nestprep.location

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent

class GeofenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) {
            if (event.errorCode == GeofenceStatusCodes.GEOFENCE_NOT_AVAILABLE) {
                LocationService.deliver(context, LocationService.refence(context))
            }
            return
        }
        val fix = event.triggeringLocation?.toFix()
        for (fence in event.triggeringGeofences.orEmpty()) {
            val id = fence.requestId
            val delivery = when {
                id == AndroidSensors.STILL_FENCE_ID && event.geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT ->
                    LocationService.wake(context, fix)
                id.startsWith(PlaceFences.PREFIX) -> placeTransition(event.geofenceTransition)?.let {
                    LocationService.place(context, id.removePrefix(PlaceFences.PREFIX), it)
                }
                else -> null
            }
            delivery?.let { LocationService.deliver(context, it) }
        }
    }

    private fun placeTransition(transition: Int): PlaceTransition? = when (transition) {
        Geofence.GEOFENCE_TRANSITION_DWELL -> PlaceTransition.Dwell
        Geofence.GEOFENCE_TRANSITION_EXIT -> PlaceTransition.Exit
        else -> null
    }
}
