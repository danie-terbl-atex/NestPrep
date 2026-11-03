package io.nullstate.nestprep

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.nullstate.nestprep.location.LocationChannel

// A FragmentActivity because the phone's biometric prompt is a fragment: the
// vault opens behind it (documents ADR-0003, `local_auth`).
class MainActivity : FlutterFragmentActivity() {
    private var location: LocationChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        if (savedInstanceState == null) shareLink(intent)?.let { setIntent(it) }
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(shareLink(intent) ?: intent)
    }

    private fun shareLink(intent: Intent?): Intent? {
        if (intent?.action != Intent.ACTION_SEND) return null
        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString().orEmpty()
        val link = Uri.Builder().scheme("nestprep").authority("share")
        WEB_LINK.find(text)?.let { link.appendQueryParameter("url", it.value) }
        intent.getCharSequenceExtra(Intent.EXTRA_SUBJECT)?.toString()?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { link.appendQueryParameter("title", it) }
        return Intent(Intent.ACTION_VIEW, link.build()).addFlags(intent.flags)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        location = LocationChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        // The notification channels (`AndroidChannel` in the app) a person can
        // silence one by one in the phone's own settings (notifications
        // ADR-0001). Their names come from the app's copy; this only asks
        // Android to make them.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATIONS)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "createChannels" -> {
                        createChannels(call.arguments as? List<*>)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        location?.dispose()
        location = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        location?.onPermissionsResult(requestCode)
    }

    private fun createChannels(specs: List<*>?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        for (spec in specs.orEmpty()) {
            val fields = spec as? Map<*, *> ?: continue
            val id = fields["id"] as? String ?: continue
            val name = fields["name"] as? String ?: continue
            val importance = if (fields["important"] == true) {
                NotificationManager.IMPORTANCE_HIGH
            } else {
                NotificationManager.IMPORTANCE_DEFAULT
            }
            val channel = NotificationChannel(id, name, importance)
            channel.description = fields["description"] as? String
            manager.createNotificationChannel(channel)
        }
    }

    private companion object {
        const val NOTIFICATIONS = "io.nullstate.nestprep/notifications"
        val WEB_LINK = Regex("https?://\\S+", RegexOption.IGNORE_CASE)
    }
}
