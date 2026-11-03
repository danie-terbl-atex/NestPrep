package io.nullstate.nestprep.location

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

internal object LocationIntents {
    fun placeFences(context: Context) = filledBySystem(context, GeofenceReceiver::class.java, PLACE_FENCES)

    fun stillFence(context: Context) = filledBySystem(context, GeofenceReceiver::class.java, STILL_FENCE)

    fun motion(context: Context) = filledBySystem(context, ActivityTransitionReceiver::class.java, MOTION)

    fun heartbeat(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        HEARTBEAT,
        Intent(context, HeartbeatReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun pause(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        PAUSE,
        Intent(context, PauseReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun openApp(context: Context): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        return PendingIntent.getActivity(
            context,
            OPEN_APP,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    // Play services writes the geofence or activity event into the intent, so it must stay mutable.
    private fun filledBySystem(
        context: Context,
        receiver: Class<out BroadcastReceiver>,
        requestCode: Int,
    ): PendingIntent {
        val mutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, receiver),
            PendingIntent.FLAG_UPDATE_CURRENT or mutable,
        )
    }

    private const val PLACE_FENCES = 1
    private const val STILL_FENCE = 2
    private const val MOTION = 3
    private const val HEARTBEAT = 4
    private const val OPEN_APP = 5
    private const val PAUSE = 6
}
