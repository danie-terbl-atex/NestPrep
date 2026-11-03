package io.nullstate.nestprep.location

import android.app.AlarmManager
import android.content.Context
import android.os.Handler
import android.os.SystemClock

internal class AlarmScheduler(
    private val context: Context,
    private val handler: Handler,
    private val settle: () -> Unit,
) : Scheduler {
    private val alarms = context.getSystemService(AlarmManager::class.java)

    override fun after(delayMillis: Long, task: () -> Unit): Cancellable {
        val listener = AlarmManager.OnAlarmListener {
            WakeHold.hold(context)
            task()
            settle()
        }
        alarms.set(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + delayMillis,
            "nestprep:location",
            listener,
            handler,
        )
        return Cancellable { alarms.cancel(listener) }
    }
}
