package io.nullstate.nestprep.location

import kotlin.math.min

class WriteLane(
    private val clock: Clock,
    private val scheduler: Scheduler,
    private val settled: () -> Unit,
) {
    var ackedAt: Long? = null
        private set
    var inFlight = false
        private set
    private var timer: Cancellable? = null
    private var failures = 0

    val waiting: Boolean get() = timer != null
    val busy: Boolean get() = inFlight || waiting

    fun send(write: (WriteDone) -> Unit, onAck: () -> Unit, onDenied: (stale: Boolean) -> Unit, retry: () -> Unit) {
        inFlight = true
        val sentAt = clock.nowMillis()
        write { result ->
            inFlight = false
            when (result) {
                WriteResult.Acknowledged -> {
                    failures = 0
                    ackedAt = clock.nowMillis()
                    onAck()
                }
                WriteResult.Denied -> {
                    failures = 0
                    onDenied(clock.nowMillis() - sentAt > STALE_MILLIS)
                }
                WriteResult.Failed -> wait(backoffMillis(++failures), retry)
            }
            settled()
        }
    }

    fun wait(delayMillis: Long, then: () -> Unit) {
        timer?.cancel()
        timer = scheduler.after(delayMillis) {
            timer = null
            then()
        }
    }

    fun cancel() {
        timer?.cancel()
        timer = null
    }

    companion object {
        const val STALE_MILLIS = 5 * 60 * 1000L
        const val DENIAL_RETRY_MILLIS = 30_000L
        private const val MAX_BACKOFF_MILLIS = 15 * 60 * 1000L

        fun backoffMillis(failures: Int): Long =
            min(DENIAL_RETRY_MILLIS shl (failures - 1).coerceIn(0, 10), MAX_BACKOFF_MILLIS)
    }
}
