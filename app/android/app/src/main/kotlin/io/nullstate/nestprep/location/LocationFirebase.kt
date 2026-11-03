package io.nullstate.nestprep.location

import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.MemoryCacheSettings

internal class LocationFirebase private constructor(val firestore: FirebaseFirestore, val auth: FirebaseAuth) {
    companion object {
        private var connected: LocationFirebase? = null

        fun connect(context: Context, config: LocationConfig): LocationFirebase = connected ?: open(context, config).also {
            connected = it
        }

        private fun open(context: Context, config: LocationConfig): LocationFirebase {
            if (FirebaseApp.getApps(context).isEmpty()) FirebaseApp.initializeApp(context)
            val auth = FirebaseAuth.getInstance()
            val firestore = FirebaseFirestore.getInstance()
            // The main process owns the on-disk cache; persistence here would fight it for the SQLite lock.
            firestore.firestoreSettings = FirebaseFirestoreSettings.Builder()
                .setLocalCacheSettings(MemoryCacheSettings.newBuilder().build())
                .build()
            config.emulatorHost?.let { host ->
                auth.useEmulator(host, config.authPort)
                firestore.useEmulator(host, config.firestorePort)
            }
            return LocationFirebase(firestore, auth)
        }
    }
}
