package io.nullstate.nestprep.location

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.os.Build
import io.nullstate.nestprep.R

internal object SharingNotification {
    const val CHANNEL_ID = "nestprep_location_sharing"
    private const val NOTIFICATION_ID = 4107

    fun promote(service: Service, config: LocationConfig) {
        val builder = builder(service, config.notificationChannelName, rename = true)
            .setContentTitle(config.notificationTitle)
            .setContentText(config.notificationBody)
        config.notificationPauseLabel?.let { label ->
            builder.addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(service, R.drawable.ic_notification),
                    label,
                    LocationIntents.pause(service),
                ).build(),
            )
        }
        show(service, builder.build())
    }

    // Started without a config to show, the service must still go foreground before it stops.
    fun promoteBare(service: Service) {
        val name = service.applicationInfo.loadLabel(service.packageManager)
        show(service, builder(service, name, rename = false).setContentTitle(name).build())
    }

    private fun builder(service: Service, channelName: CharSequence, rename: Boolean): Notification.Builder {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = service.getSystemService(NotificationManager::class.java)
            val existing = manager?.getNotificationChannel(CHANNEL_ID)
            if (existing == null || (rename && existing.name != channelName)) {
                manager?.createNotificationChannel(
                    NotificationChannel(CHANNEL_ID, channelName, NotificationManager.IMPORTANCE_LOW),
                )
            }
            Notification.Builder(service, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(service).setPriority(Notification.PRIORITY_LOW)
        }
        return builder
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(service.getColor(R.color.notification_accent))
            .setContentIntent(LocationIntents.openApp(service))
            .setOngoing(true)
            .setShowWhen(false)
    }

    private fun show(service: Service, notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            service.startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            service.startForeground(NOTIFICATION_ID, notification)
        }
    }
}
