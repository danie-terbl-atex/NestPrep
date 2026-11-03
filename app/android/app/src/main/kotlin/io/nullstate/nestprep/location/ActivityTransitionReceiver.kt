package io.nullstate.nestprep.location

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity

class ActivityTransitionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!ActivityTransitionResult.hasResult(intent)) return
        val latest = ActivityTransitionResult.extractResult(intent)?.transitionEvents?.lastOrNull() ?: return
        val motion = when {
            latest.transitionType == ActivityTransition.ACTIVITY_TRANSITION_ENTER -> Motion.ofActivity(latest.activityType)
            latest.activityType == DetectedActivity.STILL -> Motion.Unknown
            else -> return
        }
        LocationService.deliver(context, LocationService.motion(context, motion))
    }
}
