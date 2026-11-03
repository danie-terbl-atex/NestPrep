package io.nullstate.nestprep.location

import android.annotation.SuppressLint
import android.app.AlarmManager
import android.content.Context
import android.location.Location
import android.os.Build
import android.os.Looper
import android.os.SystemClock
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

@SuppressLint("MissingPermission")
internal class AndroidSensors(
    private val context: Context,
    private val onFix: (Fix) -> Unit,
    private val onRevoked: () -> Unit,
) : Sensors {
    private val fused = LocationServices.getFusedLocationProviderClient(context)
    private val geofencing = LocationServices.getGeofencingClient(context)
    private val alarms = context.getSystemService(AlarmManager::class.java)
    private val callback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            result.lastLocation?.let { onFix(it.toFix()) }
        }
    }

    fun primeWithLastKnown() = guarded {
        fused.lastLocation.addOnSuccessListener { location ->
            if (location != null && SystemClock.elapsedRealtimeNanos() - location.elapsedRealtimeNanos < FRESH_NANOS) {
                onFix(location.toFix())
            }
        }
    }

    override fun track(intervalMillis: Long) = guarded {
        val request = LocationRequest.Builder(Priority.PRIORITY_BALANCED_POWER_ACCURACY, intervalMillis)
            .setMinUpdateDistanceMeters(MOVING_DISTANCE_METRES)
            .build()
        fused.requestLocationUpdates(request, callback, Looper.getMainLooper())
    }

    override fun stopTracking() {
        fused.removeLocationUpdates(callback)
    }

    override fun watchForMovement(anchor: Fix) = guarded {
        if (!LocationPermissions.hasFine(context)) return@guarded watchCheaply()
        val fence = Geofence.Builder()
            .setRequestId(STILL_FENCE_ID)
            .setCircularRegion(anchor.latitude, anchor.longitude, Engine.STILL_FENCE_METRES.toFloat())
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_EXIT)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .build()
        val request = GeofencingRequest.Builder().setInitialTrigger(0).addGeofence(fence).build()
        geofencing.addGeofences(request, LocationIntents.stillFence(context))
            .addOnFailureListener { guarded { watchCheaply() } }
    }

    override fun stopWatchingForMovement() {
        geofencing.removeGeofences(LocationIntents.stillFence(context))
    }

    override fun scheduleHeartbeat(delayMillis: Long) {
        val alarms = alarms ?: return
        val at = SystemClock.elapsedRealtime() + delayMillis
        val intent = LocationIntents.heartbeat(context)
        // Only an exact allow-while-idle alarm lets the receiver restart a dead foreground service on Android 12+.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, intent)
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, intent)
        }
    }

    override fun cancelHeartbeat() {
        alarms?.cancel(LocationIntents.heartbeat(context))
    }

    override fun freshFix(done: (Fix?) -> Unit) {
        val request = CurrentLocationRequest.Builder()
            .setPriority(Priority.PRIORITY_BALANCED_POWER_ACCURACY)
            .setDurationMillis(FRESH_FIX_TIMEOUT_MILLIS)
            .setMaxUpdateAgeMillis(FRESH_FIX_MAX_AGE_MILLIS)
            .build()
        try {
            fused.getCurrentLocation(request, null).addOnCompleteListener { task ->
                done(if (task.isSuccessful) task.result?.toFix() else null)
            }
        } catch (_: SecurityException) {
            done(null)
            onRevoked()
        }
    }

    // Without a usable geofence (coarse only, or the add failed) a sparse low-power request
    // stands in, and the engine treats a fix beyond the fence radius as leaving it.
    private fun watchCheaply() {
        val request = LocationRequest.Builder(Priority.PRIORITY_LOW_POWER, CHEAP_INTERVAL_MILLIS)
            .setMinUpdateDistanceMeters(Engine.STILL_FENCE_METRES.toFloat())
            .build()
        fused.requestLocationUpdates(request, callback, Looper.getMainLooper())
    }

    private fun guarded(block: () -> Unit) {
        try {
            block()
        } catch (_: SecurityException) {
            onRevoked()
        }
    }

    companion object {
        const val STILL_FENCE_ID = "still"
        private const val MOVING_DISTANCE_METRES = 25f
        private const val CHEAP_INTERVAL_MILLIS = 5 * 60 * 1000L
        private const val FRESH_NANOS = 2 * 60 * 1_000_000_000L
        private const val FRESH_FIX_TIMEOUT_MILLIS = 30_000L
        private const val FRESH_FIX_MAX_AGE_MILLIS = 60_000L
    }
}

// Aged on the monotonic clock: a phone whose wall clock disagrees with the fix's own time still judges staleness right.
internal fun Location.toFix() = Fix(
    latitude = latitude,
    longitude = longitude,
    accuracyMetres = if (hasAccuracy()) accuracy else Float.MAX_VALUE,
    atMillis = System.currentTimeMillis() - (SystemClock.elapsedRealtimeNanos() - elapsedRealtimeNanos) / 1_000_000,
)
