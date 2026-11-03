package io.nullstate.nestprep.location

class Engine(
    private var config: LocationConfig,
    private val uid: String,
    private val session: Session,
    private val clock: Clock,
    private val scheduler: Scheduler,
    private val store: LocationStore,
    private val sensors: Sensors,
    private val battery: BatteryGauge,
    private val trail: TrailBuffer,
    private val ledger: DayLedger,
    private val logger: Logger,
    private val onIdle: () -> Unit,
    private val onStop: (StopReason) -> Unit,
) {
    private data class PendingEvent(val placeId: String, val kind: PlaceKind, val atMillis: Long)

    private val live = WriteLane(clock, scheduler, ::settled)
    private val day = WriteLane(clock, scheduler, ::settled)
    private val event = WriteLane(clock, scheduler, ::settled)
    private val stillness = StillDetector()
    private val recorder = TrailRecorder()
    private val debounce = PlaceDebounce()
    private val events = ArrayDeque<PendingEvent>()
    private var days = TrailDays(config.timeZone, logger)

    private var moving = false
    private var motion = Motion.Unknown
    private var lastFix: Fix? = null
    private var sentFix: Fix? = null
    private var sentMotion: Motion? = null
    private var liveForced = false
    private var liveWanted = false
    private var liveDenials = 0
    private var firstDenialForgiven = false
    private var drainUntil: Long? = null
    private var stillCheck: Cancellable? = null
    private var flushTimer: Cancellable? = null
    private var finishing: (() -> Unit)? = null
    private var finishBy = 0L
    private var stopped = false

    private val active: Boolean get() = !stopped && finishing == null

    val isMoving: Boolean get() = moving
    val writing: Boolean get() = live.inFlight || day.inFlight || event.inFlight

    fun start() {
        goMoving()
        attemptLive()
        if (trail.size > 0) drain()
    }

    fun reconfigure(next: LocationConfig) {
        val cadenceChanged = next.foreground != config.foreground
        if (next.timeZone != config.timeZone) days = TrailDays(next.timeZone, logger)
        config = next
        val placeIds = next.places.mapTo(HashSet()) { it.id }
        events.removeAll { it.placeId !in placeIds }
        if (active && moving && cadenceChanged) sensors.track(cadence())
    }

    fun refresh() = attemptLive(forced = true)

    fun refence() {
        if (active && !moving) lastFix?.let(sensors::watchForMovement)
    }

    fun onFix(fix: Fix) {
        if (!active) return
        val wasStill = !moving
        if (wasStill) {
            val anchor = lastFix
            if (anchor != null && fix.metresTo(anchor) < STILL_FENCE_METRES) return
        }
        lastFix = fix
        if (wasStill) goMoving()
        val now = clock.nowMillis()
        if (stillness.onFix(fix, now)) scheduleStillCheck()
        if (recorder.shouldRecord(fix, now)) record(TrailPoint.of(fix))
        attemptLive()
    }

    fun onWake(fix: Fix?) {
        if (!active) return
        if (moving) {
            fix?.let(::onFix)
            return
        }
        fix?.let { lastFix = it }
        goMoving()
        attemptLive()
    }

    fun onActivity(detected: Motion) {
        if (!active) return
        motion = detected
        if (detected == Motion.Still) {
            if (moving) goStill()
            return
        }
        if (!moving) goMoving()
        attemptLive()
    }

    fun onHeartbeat() {
        if (!active || moving) return
        sensors.scheduleHeartbeat(HEARTBEAT_MILLIS)
        lastFix?.let(sensors::watchForMovement)
        sensors.freshFix(::onHeartbeatFix)
        if (trail.size > 0) drain()
    }

    fun onPlace(placeId: String, transition: PlaceTransition) {
        if (!active) return
        val now = clock.nowMillis()
        val kind = debounce.onTransition(placeId, transition, now) ?: return
        events.addLast(PendingEvent(placeId, kind, now))
        sendNextEvent()
    }

    fun finish(budgetMillis: Long, done: () -> Unit) {
        if (!active) return done()
        finishing = done
        finishBy = clock.nowMillis() + budgetMillis
        quiet()
        drainUntil = Long.MAX_VALUE
        if (!day.inFlight) day.cancel()
        flushNext()
    }

    fun shutdown() {
        stopped = true
        finishing = null
        quiet()
        day.cancel()
    }

    private fun cadence(): Long = if (config.foreground) FOREGROUND_INTERVAL_MILLIS else BACKGROUND_INTERVAL_MILLIS

    private fun goMoving() {
        moving = true
        if (motion == Motion.Still) motion = Motion.Unknown
        sensors.stopWatchingForMovement()
        sensors.cancelHeartbeat()
        sensors.track(cadence())
        stillness.restart(lastFix, clock.nowMillis())
        scheduleStillCheck()
        liveForced = true
    }

    private fun goStill() {
        val anchor = lastFix ?: return
        moving = false
        motion = Motion.Still
        stillCheck?.cancel()
        stillCheck = null
        sensors.stopTracking()
        sensors.watchForMovement(anchor)
        sensors.scheduleHeartbeat(HEARTBEAT_MILLIS)
        attemptLive(forced = true)
        drain()
    }

    private fun scheduleStillCheck() {
        stillCheck?.cancel()
        val deadline = stillness.deadline() ?: return
        stillCheck = scheduler.after((deadline - clock.nowMillis()).coerceAtLeast(0)) {
            stillCheck = null
            if (!active || !moving) return@after
            if (stillness.isStill(clock.nowMillis())) goStill() else scheduleStillCheck()
        }
    }

    private fun onHeartbeatFix(fix: Fix?) {
        if (!active || fix == null || isStale(fix)) return
        if (moving) return onFix(fix)
        val anchor = lastFix
        if (anchor != null && fix.metresTo(anchor) >= STILL_FENCE_METRES) return onWake(fix)
        lastFix = fix
        attemptLive(forced = true)
    }

    private fun isStale(fix: Fix) = clock.nowMillis() - fix.atMillis > MAX_FIX_AGE_MILLIS

    private fun signedIn(): Boolean {
        if (session.uid() == uid) return true
        stop(StopReason.SignedOut)
        return false
    }

    private fun attemptLive(forced: Boolean = false) {
        if (!active) return
        if (forced) liveForced = true
        if (!moving && !liveForced) return
        val fix = lastFix ?: return
        if (live.busy) {
            liveWanted = true
            return
        }
        if (isStale(fix)) return
        val now = clock.nowMillis()
        val sinceAck = live.ackedAt?.let { now - it }
        val moved = sentFix?.let(fix::metresTo) ?: Double.MAX_VALUE
        val sending = if (moving) motion else Motion.Still
        if (!LivePolicy.isDue(sinceAck, moved, sending != sentMotion, config.foreground, liveForced)) {
            if (liveForced && sinceAck != null) live.wait(LivePolicy.FLOOR_MILLIS - sinceAck) { attemptLive() }
            return
        }
        if (!signedIn()) return
        liveForced = false
        liveWanted = false
        sentFix = fix
        sentMotion = sending
        live.send(
            write = { done -> store.setLive(Payloads.live(fix, battery.read(), sending, clock.nowMillis()), done) },
            onAck = {
                liveDenials = 0
                if (liveWanted && active) live.wait(LivePolicy.recheckMillis(config.foreground)) { attemptLive() }
            },
            onDenied = ::liveDenied,
            retry = { attemptLive(forced = true) },
        )
    }

    private fun liveDenied(stale: Boolean) {
        if (!active) return
        when {
            stale -> live.wait(LivePolicy.FLOOR_MILLIS) { attemptLive(forced = true) }
            // A restart inside the server's 10 s pace window is denied once through no fault of the sharer.
            live.ackedAt == null && !firstDenialForgiven -> {
                firstDenialForgiven = true
                live.wait(LivePolicy.FLOOR_MILLIS) { attemptLive(forced = true) }
            }
            ++liveDenials < 2 -> live.wait(WriteLane.DENIAL_RETRY_MILLIS) { attemptLive(forced = true) }
            else -> stop(StopReason.Refused)
        }
    }

    private fun record(point: TrailPoint) {
        trail.add(point)
        if (trail.size >= FLUSH_AT_POINTS) flushNext() else armFlushTimer()
    }

    private fun armFlushTimer() {
        if (flushTimer != null || trail.size == 0 || !active) return
        flushTimer = scheduler.after(FLUSH_EVERY_MILLIS) {
            flushTimer = null
            if (active) drain()
        }
    }

    private fun drain() {
        drainUntil = clock.nowMillis() / 1000
        flushNext()
    }

    private fun flushNext() {
        if (stopped || day.busy) return
        val now = clock.nowMillis()
        val batches = pendingBatches()
        if (batches.isEmpty()) return settleFlush()
        val ready = batches.firstOrNull { ledger.waitBefore(it.day, now) == 0L }
            ?: return waitToFlush(batches.minOf { ledger.waitBefore(it.day, now) })
        if (!signedIn()) return
        day.send(
            write = { done -> store.mergeDay(ready.day, Payloads.day(ready.points, clock.nowMillis()), done) },
            onAck = {
                trail.remove(ready.points)
                ledger.acknowledged(ready.day, ready.points.size, clock.nowMillis())
                continueFlush()
            },
            onDenied = { stale ->
                if (stale) {
                    waitToFlush(DayLedger.SPACING_MILLIS)
                } else {
                    logger.log("Trail day ${ready.day} refused ${ready.points.size} points; dropped")
                    trail.remove(ready.points)
                    continueFlush()
                }
            },
            retry = ::flushNext,
        )
    }

    private fun pendingBatches(): List<TrailBatch> {
        val batches = days.batches(trail.points, ledger::room)
        val overflow = batches.flatMap { it.overflow }
        if (overflow.isNotEmpty()) {
            logger.log("Dropped ${overflow.size} trail points past the day's limit")
            trail.remove(overflow)
        }
        return batches.filter { it.points.isNotEmpty() }
    }

    private fun waitToFlush(delayMillis: Long) {
        if (finishing != null && clock.nowMillis() + delayMillis > finishBy) completeFinish()
        else day.wait(delayMillis, ::flushNext)
    }

    private fun continueFlush() = if (keepFlushing()) flushNext() else settleFlush()

    private fun keepFlushing(): Boolean {
        val oldest = trail.points.firstOrNull() ?: return false
        return trail.size >= FLUSH_AT_POINTS || drainUntil?.let { oldest.t <= it } == true
    }

    private fun settleFlush() {
        drainUntil = null
        if (finishing != null) completeFinish() else armFlushTimer()
    }

    private fun completeFinish() {
        val done = finishing ?: return
        finishing = null
        stopped = true
        day.cancel()
        done()
    }

    private fun sendNextEvent() {
        if (!active || event.busy) return
        val now = clock.nowMillis()
        while (events.firstOrNull()?.let { now - it.atMillis > CROSSING_MAX_AGE_MILLIS } == true) {
            val old = events.removeFirst()
            logger.log("Dropped a ${old.kind.wire} at ${old.placeId} from ${(now - old.atMillis) / 60_000} min ago")
        }
        val next = events.firstOrNull() ?: return
        if (!signedIn()) return
        event.send(
            write = { done -> store.addEvent(Payloads.placeEvent(next.placeId, next.kind, clock.nowMillis()), done) },
            onAck = {
                events.remove(next)
                sendNextEvent()
            },
            onDenied = { stale ->
                if (!stale) {
                    logger.log("Place event ${next.kind.wire} at ${next.placeId} refused; dropped")
                    events.remove(next)
                }
                sendNextEvent()
            },
            retry = ::sendNextEvent,
        )
    }

    private fun settled() {
        if (!writing) onIdle()
    }

    private fun stop(reason: StopReason) {
        if (stopped) return
        if (finishing != null) return completeFinish()
        shutdown()
        onStop(reason)
    }

    private fun quiet() {
        sensors.stopTracking()
        sensors.stopWatchingForMovement()
        sensors.cancelHeartbeat()
        stillCheck?.cancel()
        stillCheck = null
        flushTimer?.cancel()
        flushTimer = null
        live.cancel()
        event.cancel()
    }

    companion object {
        const val FOREGROUND_INTERVAL_MILLIS = 10_000L
        const val BACKGROUND_INTERVAL_MILLIS = 30_000L
        const val STILL_FENCE_METRES = 150.0
        const val HEARTBEAT_MILLIS = 60 * 60 * 1000L
        const val FLUSH_AT_POINTS = 30
        const val FLUSH_EVERY_MILLIS = 15 * 60 * 1000L
        const val MAX_FIX_AGE_MILLIS = 10 * 60 * 1000L
        const val CROSSING_MAX_AGE_MILLIS = 15 * 60 * 1000L
    }
}
