package io.nullstate.nestprep.location

import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth

// Sign-out happens in the main process, whose FirebaseAuth the :location process cannot see,
// so the main process is the one that notices and stops the service.
internal class SignOutWatch(context: Context, private val onSignedOut: () -> Unit) {
    private val files = LocationFiles(context)
    private val auth: FirebaseAuth? =
        if (FirebaseApp.getApps(context).isEmpty()) null else runCatching { FirebaseAuth.getInstance() }.getOrNull()
    private val listener = FirebaseAuth.AuthStateListener { current ->
        val expected = files.readUid() ?: return@AuthStateListener
        if (files.readConfig() != null && current.currentUser?.uid != expected) onSignedOut()
    }

    fun currentUid(): String? = auth?.currentUser?.uid

    fun attach() {
        auth?.addAuthStateListener(listener)
    }

    fun detach() {
        auth?.removeAuthStateListener(listener)
    }
}
