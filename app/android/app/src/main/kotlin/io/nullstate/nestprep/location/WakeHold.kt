package io.nullstate.nestprep.location

import android.content.Context
import android.os.PowerManager

internal const val LOG_TAG = "NestPrepLocation"

internal object WakeHold {
    private const val HOLD_MILLIS = 60_000L
    private var lock: PowerManager.WakeLock? = null

    fun hold(context: Context) {
        val held = lock ?: context.getSystemService(PowerManager::class.java)
            ?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "nestprep:location")
            ?.apply { setReferenceCounted(false) }
            ?.also { lock = it }
        held?.acquire(HOLD_MILLIS)
    }

    fun release() {
        lock?.takeIf { it.isHeld }?.release()
    }
}
