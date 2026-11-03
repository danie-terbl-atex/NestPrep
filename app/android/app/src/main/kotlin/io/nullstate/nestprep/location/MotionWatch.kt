package io.nullstate.nestprep.location

import android.annotation.SuppressLint
import android.content.Context
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.DetectedActivity

@SuppressLint("MissingPermission")
internal class MotionWatch(private val context: Context) {
    private val client = ActivityRecognition.getClient(context)

    fun start() {
        if (!LocationPermissions.hasMotion(context)) return
        val transitions = listOf(
            DetectedActivity.STILL to ActivityTransition.ACTIVITY_TRANSITION_EXIT,
            DetectedActivity.STILL to ActivityTransition.ACTIVITY_TRANSITION_ENTER,
            DetectedActivity.IN_VEHICLE to ActivityTransition.ACTIVITY_TRANSITION_ENTER,
            DetectedActivity.WALKING to ActivityTransition.ACTIVITY_TRANSITION_ENTER,
            DetectedActivity.RUNNING to ActivityTransition.ACTIVITY_TRANSITION_ENTER,
            DetectedActivity.ON_BICYCLE to ActivityTransition.ACTIVITY_TRANSITION_ENTER,
        ).map { (activity, transition) ->
            ActivityTransition.Builder().setActivityType(activity).setActivityTransition(transition).build()
        }
        try {
            client.requestActivityTransitionUpdates(ActivityTransitionRequest(transitions), LocationIntents.motion(context))
        } catch (_: SecurityException) {
        }
    }

    fun stop() {
        try {
            client.removeActivityTransitionUpdates(LocationIntents.motion(context))
        } catch (_: SecurityException) {
        }
    }
}
