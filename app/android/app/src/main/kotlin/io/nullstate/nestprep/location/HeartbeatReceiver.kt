package io.nullstate.nestprep.location

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class HeartbeatReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        LocationService.deliver(context, LocationService.heartbeat(context))
    }
}
