package io.nullstate.nestprep.location

fun interface Clock {
    fun nowMillis(): Long
}

fun interface Cancellable {
    fun cancel()
}

fun interface Scheduler {
    fun after(delayMillis: Long, task: () -> Unit): Cancellable
}

fun interface Session {
    fun uid(): String?
}

fun interface Logger {
    fun log(message: String)
}

enum class WriteResult { Acknowledged, Denied, Failed }

typealias WriteDone = (WriteResult) -> Unit

interface LocationStore {
    fun setLive(fields: Map<String, Field>, done: WriteDone)
    fun deleteLive(done: () -> Unit)
    fun mergeDay(day: String, fields: Map<String, Field>, done: WriteDone)
    fun addEvent(fields: Map<String, Field>, done: WriteDone)
}

interface Sensors {
    fun track(intervalMillis: Long)
    fun stopTracking()
    fun watchForMovement(anchor: Fix)
    fun stopWatchingForMovement()
    fun scheduleHeartbeat(delayMillis: Long)
    fun cancelHeartbeat()
    fun freshFix(done: (Fix?) -> Unit)
}

data class Battery(val percent: Int, val charging: Boolean)

fun interface BatteryGauge {
    fun read(): Battery
}
