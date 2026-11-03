package io.nullstate.nestprep.location

import android.app.ActivityManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Process
import android.os.ResultReceiver
import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.Source

class LocationService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var files: LocationFiles
    private var config: LocationConfig? = null
    private var engine: Engine? = null
    private var store: FirestoreStore? = null
    private var firebase: LocationFirebase? = null
    private var places: PlaceFences? = null
    private var motionWatch: MotionWatch? = null
    private var authListener: FirebaseAuth.AuthStateListener? = null
    private var watchingProviders = false
    private var retiring = false
    private var halting = false
    private val providers = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (LocationPermissions.locationEnabled(context)) refence()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        files = LocationFiles(this)
        running = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        WakeHold.hold(this)
        return try {
            command(intent)
        } finally {
            settleWake()
        }
    }

    override fun onDestroy() {
        running = null
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
        // Ending the :location process makes the next start read the persisted sign-in afresh.
        Process.killProcess(Process.myPid())
    }

    internal fun handle(intent: Intent) {
        WakeHold.hold(this)
        try {
            dispatch(intent)
        } finally {
            settleWake()
        }
    }

    private fun command(intent: Intent?): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stop(intent.resultReceiver())
                return START_NOT_STICKY
            }
            ACTION_SIGNED_OUT -> {
                halt(StopReason.SignedOut)
                return START_NOT_STICKY
            }
        }
        if (halting) return START_NOT_STICKY
        val stored = files.readConfig()
        if (!promote(stored)) return START_NOT_STICKY
        if (stored == null) {
            halt(null)
            return START_NOT_STICKY
        }
        val current = config
        when {
            retiring -> return START_STICKY
            engine == null -> if (!begin(stored)) return START_NOT_STICKY
            current != null && !current.sameSharer(stored) -> {
                switchTo(stored)
                return START_STICKY
            }
        }
        intent?.let(::dispatch)
        return START_STICKY
    }

    private fun dispatch(intent: Intent) {
        if (intent.action == ACTION_PAUSE) return pauseSharing()
        val engine = engine ?: return
        when (intent.action) {
            ACTION_START -> reload()?.let { engine.refresh() }
            ACTION_RELOAD -> reload()
            ACTION_MOTION -> engine.onActivity(Motion.ofWire(intent.getStringExtra(EXTRA_MOTION)))
            ACTION_PLACE -> {
                val placeId = intent.getStringExtra(EXTRA_PLACE) ?: return
                val transition = intent.getStringExtra(EXTRA_TRANSITION)
                    ?.let { name -> PlaceTransition.entries.firstOrNull { it.name == name } } ?: return
                engine.onPlace(placeId, transition)
            }
            ACTION_WAKE -> if (stillPermitted()) engine.onWake(intent.fix())
            ACTION_HEARTBEAT -> if (stillPermitted()) {
                refence()
                refreshPlaces()
                engine.onHeartbeat()
            }
            ACTION_REFENCE -> refence()
        }
    }

    private fun promote(stored: LocationConfig?): Boolean = try {
        if (stored == null) SharingNotification.promoteBare(this) else SharingNotification.promote(this, stored)
        true
    } catch (_: SecurityException) {
        halt(StopReason.PermissionRevoked)
        false
    } catch (e: IllegalStateException) {
        Log.w(LOG_TAG, "Could not go foreground", e)
        halt(null)
        false
    }

    private fun begin(stored: LocationConfig): Boolean {
        if (!LocationPermissions.hasLocation(this)) {
            halt(StopReason.PermissionRevoked)
            return false
        }
        val firebase = LocationFirebase.connect(this, stored)
        val uid = firebase.auth.currentUser?.uid
        if (uid == null || uid != files.readUid()) {
            halt(StopReason.SignedOut)
            return false
        }
        val store = FirestoreStore(firebase.firestore, stored.householdId, stored.memberId)
        val sensors = AndroidSensors(
            this,
            onFix = { fix ->
                WakeHold.hold(this)
                engine?.onFix(fix)
                settleWake()
            },
            onRevoked = { halt(StopReason.PermissionRevoked) },
        )
        val engine = Engine(
            config = stored,
            uid = uid,
            session = { firebase.auth.currentUser?.uid },
            clock = { System.currentTimeMillis() },
            scheduler = AlarmScheduler(this, handler, ::settleWake),
            store = store,
            sensors = sensors,
            battery = AndroidBattery(this),
            trail = TrailBuffer(files.trail),
            ledger = DayLedger(files.ledger),
            logger = { Log.w(LOG_TAG, it) },
            onIdle = { WakeHold.release() },
            onStop = ::halt,
        )
        this.config = stored
        this.firebase = firebase
        this.store = store
        this.engine = engine
        places = (places ?: PlaceFences(this)).also { it.register(stored.places) }
        motionWatch = (motionWatch ?: MotionWatch(this)).also { it.start() }
        watchAuth(firebase.auth, uid)
        watchProviders()
        files.writeStopReason(null)
        engine.start()
        sensors.primeWithLastKnown()
        refreshPlaces()
        announce(this, EVENT_STARTED, null)
        return true
    }

    private fun reload(): LocationConfig? {
        val stored = files.readConfig() ?: return null
        if (stored.places != config?.places) places?.register(stored.places)
        motionWatch?.start()
        config = stored
        engine?.reconfigure(stored)
        return stored
    }

    private fun refence() {
        config?.let { places?.register(it.places) }
        engine?.refence()
    }

    private fun refreshPlaces() {
        val asked = config ?: return
        val firestore = firebase?.firestore ?: return
        firestore.collection(Paths.places(asked.householdId)).get(Source.SERVER).addOnSuccessListener { snapshot ->
            val current = config ?: return@addOnSuccessListener
            if (!current.sameSharer(asked) || halting) return@addOnSuccessListener
            val fetched = snapshot.documents.mapNotNull { doc ->
                val centre = doc.getGeoPoint("centre") ?: return@mapNotNull null
                val radius = doc.getLong("radiusMetres") ?: return@mapNotNull null
                Place(doc.id, centre.latitude, centre.longitude, radius.toInt())
            }
            if (fetched.toSet() == current.places.toSet()) return@addOnSuccessListener
            val updated = current.copy(places = fetched)
            config = updated
            places?.register(fetched)
            engine?.reconfigure(updated)
        }
    }

    private fun watchAuth(auth: FirebaseAuth, uid: String) {
        authListener?.let(auth::removeAuthStateListener)
        val listener = FirebaseAuth.AuthStateListener { if (it.currentUser?.uid != uid) halt(StopReason.SignedOut) }
        auth.addAuthStateListener(listener)
        authListener = listener
    }

    private fun watchProviders() {
        if (watchingProviders) return
        val filter = IntentFilter(LocationManager.PROVIDERS_CHANGED_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(providers, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(providers, filter)
        }
        watchingProviders = true
    }

    private fun stillPermitted(): Boolean {
        if (LocationPermissions.hasLocation(this)) return true
        halt(StopReason.PermissionRevoked)
        return false
    }

    private fun settleWake() {
        if (engine?.writing != true && !retiring) WakeHold.release()
    }

    private fun stop(receiver: ResultReceiver?) {
        val reply = {
            receiver?.send(0, null)
            halt(null)
        }
        if (retiring || engine == null) return reply()
        retire(deleteLive = false, reply)
    }

    private fun pauseSharing() {
        if (retiring || halting) return
        retire(deleteLive = true) { halt(StopReason.Paused) }
    }

    private fun switchTo(next: LocationConfig) {
        retire(deleteLive = true) {
            teardown()
            files.clearTrail()
            if (files.readConfig()?.sameSharer(next) == true) begin(next) else halt(null)
        }
    }

    private fun retire(deleteLive: Boolean, then: () -> Unit) {
        retiring = true
        WakeHold.hold(this)
        val engine = engine
        val store = store
        var finished = false
        val complete = Runnable {
            if (!finished) {
                finished = true
                retiring = false
                then()
                settleWake()
            }
        }
        handler.postDelayed(complete, RETIRE_CAP_MILLIS)
        val afterFlush = {
            if (deleteLive && store != null) store.deleteLive { complete.run() } else complete.run()
        }
        if (engine == null) afterFlush() else engine.finish(FLUSH_BUDGET_MILLIS, afterFlush)
    }

    private fun teardown() {
        engine?.shutdown()
        engine = null
        authListener?.let { listener -> firebase?.auth?.removeAuthStateListener(listener) }
        authListener = null
    }

    private fun halt(reason: StopReason?) {
        if (halting) return
        halting = true
        teardown()
        places?.clear()
        motionWatch?.stop()
        if (watchingProviders) runCatching { unregisterReceiver(providers) }
        watchingProviders = false
        files.forget()
        if (reason != null) {
            files.writeStopReason(reason)
            announce(this, EVENT_STOPPED, reason)
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        WakeHold.release()
    }

    companion object {
        const val ACTION_STATUS = "io.nullstate.nestprep.location.STATUS"
        const val EXTRA_EVENT = "event"
        const val EXTRA_REASON = "reason"
        const val EVENT_STARTED = "started"
        const val EVENT_STOPPED = "stopped"

        private const val ACTION_START = "io.nullstate.nestprep.location.START"
        private const val ACTION_STOP = "io.nullstate.nestprep.location.STOP"
        private const val ACTION_SIGNED_OUT = "io.nullstate.nestprep.location.SIGNED_OUT"
        private const val ACTION_PAUSE = "io.nullstate.nestprep.location.PAUSE"
        private const val ACTION_RELOAD = "io.nullstate.nestprep.location.RELOAD"
        private const val ACTION_MOTION = "io.nullstate.nestprep.location.MOTION"
        private const val ACTION_PLACE = "io.nullstate.nestprep.location.PLACE"
        private const val ACTION_WAKE = "io.nullstate.nestprep.location.WAKE"
        private const val ACTION_HEARTBEAT = "io.nullstate.nestprep.location.HEARTBEAT"
        private const val ACTION_REFENCE = "io.nullstate.nestprep.location.REFENCE"
        private const val EXTRA_RESULT = "result"
        private const val EXTRA_MOTION = "motion"
        private const val EXTRA_PLACE = "place"
        private const val EXTRA_TRANSITION = "transition"
        private const val EXTRA_LATITUDE = "latitude"
        private const val EXTRA_LONGITUDE = "longitude"
        private const val EXTRA_ACCURACY = "accuracy"
        private const val EXTRA_AT = "at"
        private const val FLUSH_BUDGET_MILLIS = 10_000L
        private const val RETIRE_CAP_MILLIS = 13_000L
        const val STOP_REPLY_MILLIS = RETIRE_CAP_MILLIS + 1_000L

        private var running: LocationService? = null

        fun start(context: Context) = intent(context, ACTION_START)

        fun reload(context: Context) = intent(context, ACTION_RELOAD)

        fun signedOut(context: Context) = intent(context, ACTION_SIGNED_OUT)

        fun refence(context: Context) = intent(context, ACTION_REFENCE)

        fun stop(context: Context, receiver: ResultReceiver) =
            intent(context, ACTION_STOP).putExtra(EXTRA_RESULT, receiver)

        fun motion(context: Context, motion: Motion) =
            intent(context, ACTION_MOTION).putExtra(EXTRA_MOTION, motion.wire)

        fun place(context: Context, placeId: String, transition: PlaceTransition) = intent(context, ACTION_PLACE)
            .putExtra(EXTRA_PLACE, placeId)
            .putExtra(EXTRA_TRANSITION, transition.name)

        fun heartbeat(context: Context) = intent(context, ACTION_HEARTBEAT)

        fun wake(context: Context, fix: Fix?): Intent = intent(context, ACTION_WAKE).apply {
            if (fix == null) return@apply
            putExtra(EXTRA_LATITUDE, fix.latitude)
            putExtra(EXTRA_LONGITUDE, fix.longitude)
            putExtra(EXTRA_ACCURACY, fix.accuracyMetres)
            putExtra(EXTRA_AT, fix.atMillis)
        }

        fun pause(context: Context) {
            running?.let { return it.handle(intent(context, ACTION_PAUSE)) }
            val files = LocationFiles(context)
            files.forget()
            files.writeStopReason(StopReason.Paused)
            announce(context, EVENT_STOPPED, StopReason.Paused)
            WakeHold.release()
        }

        fun deliver(context: Context, intent: Intent) {
            WakeHold.hold(context)
            running?.let { return it.handle(intent) }
            if (LocationFiles(context).readConfig() != null && LocationPermissions.canRunInBackground(context)) {
                launch(context, intent)
            }
        }

        fun launch(context: Context, intent: Intent): Boolean = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            true
        } catch (e: IllegalStateException) {
            Log.w(LOG_TAG, "Location service not started; the next wake will try again", e)
            false
        } catch (e: SecurityException) {
            Log.w(LOG_TAG, "Location service not started", e)
            false
        }

        @Suppress("DEPRECATION")
        fun isRunning(context: Context): Boolean =
            context.getSystemService(ActivityManager::class.java)
                ?.getRunningServices(Int.MAX_VALUE)
                ?.any { it.service.className == LocationService::class.java.name } == true

        fun announce(context: Context, event: String, reason: StopReason?) {
            context.sendBroadcast(
                Intent(ACTION_STATUS)
                    .setPackage(context.packageName)
                    .putExtra(EXTRA_EVENT, event)
                    .putExtra(EXTRA_REASON, reason?.wire),
            )
        }

        private fun intent(context: Context, action: String) =
            Intent(context, LocationService::class.java).setAction(action)

        private fun Intent.fix(): Fix? {
            if (!hasExtra(EXTRA_LATITUDE)) return null
            return Fix(
                latitude = getDoubleExtra(EXTRA_LATITUDE, 0.0),
                longitude = getDoubleExtra(EXTRA_LONGITUDE, 0.0),
                accuracyMetres = getFloatExtra(EXTRA_ACCURACY, Float.MAX_VALUE),
                atMillis = getLongExtra(EXTRA_AT, System.currentTimeMillis()),
            )
        }

        private fun Intent.resultReceiver(): ResultReceiver? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                getParcelableExtra(EXTRA_RESULT, ResultReceiver::class.java)
            } else {
                @Suppress("DEPRECATION")
                getParcelableExtra(EXTRA_RESULT)
            }
    }
}
