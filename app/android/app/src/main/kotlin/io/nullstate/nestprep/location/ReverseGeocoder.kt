package io.nullstate.nestprep.location

import android.content.Context
import android.location.Address
import android.location.Geocoder
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.util.Locale
import java.util.concurrent.Executors

internal class ReverseGeocoder(private val context: Context) {
    private val main = Handler(Looper.getMainLooper())

    fun lookup(latitude: Double, longitude: Double, done: (String?) -> Unit) {
        if (!Geocoder.isPresent()) return done(null)
        val geocoder = Geocoder(context, Locale.getDefault())
        val reply = { line: String? -> main.post { done(line) } }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            geocoder.getFromLocation(
                latitude,
                longitude,
                1,
                object : Geocoder.GeocodeListener {
                    override fun onGeocode(addresses: MutableList<Address>) {
                        reply(addresses.firstOrNull()?.line())
                    }

                    override fun onError(errorMessage: String?) {
                        reply(null)
                    }
                },
            )
        } else {
            background.execute {
                @Suppress("DEPRECATION")
                val line = runCatching { geocoder.getFromLocation(latitude, longitude, 1)?.firstOrNull()?.line() }
                    .getOrNull()
                reply(line)
            }
        }
    }

    private fun Address.line(): String? =
        AddressLine.format(subThoroughfare, thoroughfare, subLocality, locality, getAddressLine(0))

    private companion object {
        val background = Executors.newSingleThreadExecutor()
    }
}
