package io.nullstate.nestprep

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FragmentActivity because the phone's biometric prompt is a fragment: the
// vault opens behind it (documents ADR-0003, `local_auth`).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
    }
}
