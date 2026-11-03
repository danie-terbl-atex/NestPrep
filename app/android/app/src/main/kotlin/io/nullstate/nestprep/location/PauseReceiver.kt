package io.nullstate.nestprep.location

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PauseReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WakeHold.hold(context)
        LocationService.pause(context)
    }
}
