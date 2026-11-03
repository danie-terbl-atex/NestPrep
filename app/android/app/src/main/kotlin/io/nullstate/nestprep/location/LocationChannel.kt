package io.nullstate.nestprep.location

import android.Manifest
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LocationChannel(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private val files = LocationFiles(activity)
    private val geocoder = ReverseGeocoder(activity)
    private val main = Handler(Looper.getMainLooper())
    private var awaitingPermission: MethodChannel.Result? = null
    private val remainingSteps = ArrayDeque<List<String>>()
    private var sink: EventChannel.EventSink? = null
    private val signOut = SignOutWatch(activity, ::signedOut)
    private val status = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val event = intent.getStringExtra(LocationService.EXTRA_EVENT) ?: return
            val reason = intent.getStringExtra(LocationService.EXTRA_REASON)
            sink?.success(if (reason == null) mapOf("event" to event) else mapOf("event" to event, "reason" to reason))
        }
    }

    init {
        MethodChannel(messenger, METHODS).setMethodCallHandler(this)
        EventChannel(messenger, EVENTS).setStreamHandler(this)
        signOut.attach()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> start(call, result)
            "stop" -> stop(result)
            "status" -> result.success(status())
            "setForeground" -> update(result) { it.copy(foreground = call.argument<Boolean>("foreground") == true) }
            "setPlaces" -> update(result) { it.copy(places = Place.listFrom(call.argument<List<*>>("places"))) }
            "permissions" -> result.success(permissions(afterRequest = false))
            "requestAlways" -> requestAlways(result)
            "requestMotion" -> requestMotion(result)
            "openBatterySettings" -> {
                openAppSettings()
                result.success(null)
            }
            "reverseGeocode" -> {
                val latitude = call.argument<Number>("latitude")?.toDouble()
                val longitude = call.argument<Number>("longitude")?.toDouble()
                if (latitude == null || longitude == null) return result.success(null)
                geocoder.lookup(latitude, longitude) { result.success(it) }
            }
            "ready" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        val filter = IntentFilter(LocationService.ACTION_STATUS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.applicationContext.registerReceiver(status, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            activity.applicationContext.registerReceiver(status, filter)
        }
    }

    override fun onCancel(arguments: Any?) {
        sink = null
        runCatching { activity.applicationContext.unregisterReceiver(status) }
    }

    fun onPermissionsResult(requestCode: Int): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false
        val next = remainingSteps.removeFirstOrNull()
        if (next != null) {
            activity.requestPermissions(next.toTypedArray(), PERMISSION_REQUEST)
            return true
        }
        awaitingPermission?.success(permissions(afterRequest = true))
        awaitingPermission = null
        return true
    }

    fun dispose() {
        signOut.detach()
        onCancel(null)
    }

    private fun signedOut() {
        files.forget()
        files.writeStopReason(StopReason.SignedOut)
        if (LocationService.isRunning(activity)) {
            runCatching { activity.startService(LocationService.signedOut(activity)) }
        } else {
            sink?.success(mapOf("event" to LocationService.EVENT_STOPPED, "reason" to StopReason.SignedOut.wire))
        }
    }

    private fun start(call: MethodCall, result: MethodChannel.Result) {
        val config = try {
            LocationConfig.fromArguments(call.arguments as? Map<*, *> ?: emptyMap<String, Any>())
        } catch (e: IllegalArgumentException) {
            return result.error("badArguments", e.message, null)
        }
        if (!LocationPermissions.hasLocation(activity)) return result.error("noPermission", null, null)
        if (!LocationPermissions.hasBackground(activity)) return result.error("noBackground", null, null)
        val uid = signOut.currentUid() ?: return result.error("signedOut", null, null)
        files.writeUid(uid)
        files.writeConfig(config)
        files.writeStopReason(null)
        if (LocationService.launch(activity, LocationService.start(activity))) {
            result.success(null)
        } else {
            files.forget()
            result.error("notStarted", null, null)
        }
    }

    private fun stop(result: MethodChannel.Result) {
        if (!LocationService.isRunning(activity)) {
            files.forget()
            return result.success(null)
        }
        files.clearConfig()
        var replied = false
        val reply = {
            if (!replied) {
                replied = true
                result.success(null)
            }
        }
        val receiver = object : ResultReceiver(main) {
            override fun onReceiveResult(resultCode: Int, resultData: Bundle?) = reply()
        }
        try {
            activity.startService(LocationService.stop(activity, receiver))
            main.postDelayed(reply, LocationService.STOP_REPLY_MILLIS)
        } catch (_: IllegalStateException) {
            files.forget()
            reply()
        }
    }

    private fun update(result: MethodChannel.Result, change: (LocationConfig) -> LocationConfig) {
        val current = files.readConfig() ?: return result.success(null)
        val next = try {
            change(current)
        } catch (e: IllegalArgumentException) {
            return result.error("badArguments", e.message, null)
        }
        files.writeConfig(next)
        if (LocationService.isRunning(activity)) {
            runCatching { activity.startService(LocationService.reload(activity)) }
        }
        result.success(null)
    }

    private fun status(): Map<String, Any?> {
        val config = files.readConfig()
        return mapOf(
            "running" to LocationService.isRunning(activity),
            "householdId" to config?.householdId,
            "memberId" to config?.memberId,
            "lastStopReason" to files.readStopReason()?.wire,
        )
    }

    private fun permissions(afterRequest: Boolean): Map<String, String> = mapOf(
        "location" to PermissionNames.location(
            servicesOn = LocationPermissions.locationEnabled(activity),
            anyLocation = LocationPermissions.hasLocation(activity),
            background = LocationPermissions.hasBackground(activity),
            refusedForGood = afterRequest &&
                !activity.shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_FINE_LOCATION),
        ),
        "motion" to PermissionNames.motion(LocationPermissions.motionNeeded(), LocationPermissions.hasMotion(activity)),
    )

    private fun requestAlways(result: MethodChannel.Result) {
        val notifications = if (notificationsMissing()) listOf(Manifest.permission.POST_NOTIFICATIONS) else emptyList()
        val steps = when {
            !LocationPermissions.hasLocation(activity) -> listOf(
                buildList {
                    add(Manifest.permission.ACCESS_FINE_LOCATION)
                    add(Manifest.permission.ACCESS_COARSE_LOCATION)
                    // Android 10 grants "always" from the first prompt; 11 and up refuse it until "while in use" is held.
                    if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) add(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                    addAll(notifications)
                },
            )
            !LocationPermissions.hasBackground(activity) ->
                listOf(listOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION), notifications)
            else -> listOf(notifications)
        }.filter { it.isNotEmpty() }
        if (steps.isEmpty()) return result.success(permissions(afterRequest = false))
        request(steps, result)
    }

    private fun notificationsMissing() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
        activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED

    private fun requestMotion(result: MethodChannel.Result) {
        if (LocationPermissions.hasMotion(activity)) return result.success(permissions(afterRequest = false))
        request(listOf(listOf(Manifest.permission.ACTIVITY_RECOGNITION)), result)
    }

    private fun request(steps: List<List<String>>, result: MethodChannel.Result) {
        if (awaitingPermission != null) return result.error("busy", null, null)
        awaitingPermission = result
        remainingSteps.clear()
        remainingSteps.addAll(steps.drop(1))
        activity.requestPermissions(steps.first().toTypedArray(), PERMISSION_REQUEST)
    }

    private fun openAppSettings() {
        activity.startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", activity.packageName, null))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    private companion object {
        const val METHODS = "io.nullstate.nestprep/location"
        const val EVENTS = "io.nullstate.nestprep/location/events"
        const val PERMISSION_REQUEST = 4107
    }
}
