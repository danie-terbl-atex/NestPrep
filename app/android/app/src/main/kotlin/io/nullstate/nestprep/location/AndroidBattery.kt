package io.nullstate.nestprep.location

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager

internal class AndroidBattery(private val context: Context) : BatteryGauge {
    override fun read(): Battery {
        val sticky = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            ?: return Battery(0, false)
        val level = sticky.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = sticky.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val status = sticky.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val plugged = sticky.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        val percent = if (level >= 0 && scale > 0) level * 100 / scale else 0
        val charging = plugged != 0 ||
            status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
        return Battery(percent.coerceIn(0, 100), charging)
    }
}
