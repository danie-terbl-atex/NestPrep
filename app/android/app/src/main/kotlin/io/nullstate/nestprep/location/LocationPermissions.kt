package io.nullstate.nestprep.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build

internal object LocationPermissions {
    fun hasLocation(context: Context) =
        context.granted(Manifest.permission.ACCESS_FINE_LOCATION) ||
            context.granted(Manifest.permission.ACCESS_COARSE_LOCATION)

    fun hasFine(context: Context) = context.granted(Manifest.permission.ACCESS_FINE_LOCATION)

    fun hasBackground(context: Context) =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            context.granted(Manifest.permission.ACCESS_BACKGROUND_LOCATION)

    fun motionNeeded() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    fun hasMotion(context: Context) =
        !motionNeeded() || context.granted(Manifest.permission.ACTIVITY_RECOGNITION)

    fun canRunInBackground(context: Context) = hasLocation(context) && hasBackground(context)

    fun locationEnabled(context: Context): Boolean {
        val manager = context.getSystemService(LocationManager::class.java) ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            manager.isLocationEnabled
        } else {
            @Suppress("DEPRECATION")
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    private fun Context.granted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
}
