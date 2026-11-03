package io.nullstate.nestprep.location

import com.google.android.gms.location.DetectedActivity

enum class Motion(val wire: String) {
    Still("still"),
    OnFoot("onFoot"),
    Cycling("cycling"),
    Driving("driving"),
    Unknown("unknown");

    companion object {
        fun ofWire(wire: String?): Motion = entries.firstOrNull { it.wire == wire } ?: Unknown

        fun ofActivity(type: Int): Motion = when (type) {
            DetectedActivity.IN_VEHICLE -> Driving
            DetectedActivity.ON_BICYCLE -> Cycling
            DetectedActivity.WALKING, DetectedActivity.RUNNING, DetectedActivity.ON_FOOT -> OnFoot
            DetectedActivity.STILL -> Still
            else -> Unknown
        }
    }
}
