package io.nullstate.nestprep.location

import android.content.Context
import java.io.File

internal class LocationFiles(context: Context) {
    private val dir = File(context.noBackupFilesDir, "location")
    private val config = File(dir, "config.json")
    private val stopReason = File(dir, "stop_reason")
    private val uid = File(dir, "uid")
    val trail = File(dir, "trail.jsonl")
    val ledger = File(dir, "trail_ledger.json")

    fun readConfig(): LocationConfig? =
        config.readTextOrNull()?.let { runCatching { LocationConfig.fromJson(it) }.getOrNull() }

    fun writeConfig(value: LocationConfig) = config.writeAtomically(value.toJson())

    fun clearConfig() {
        config.delete()
    }

    fun readUid(): String? = uid.readTextOrNull()?.trim()?.takeIf { it.isNotEmpty() }

    fun writeUid(value: String) = uid.writeAtomically(value)

    fun forget() {
        config.delete()
        uid.delete()
        clearTrail()
    }

    fun readStopReason(): StopReason? = StopReason.ofWire(stopReason.readTextOrNull()?.trim())

    fun writeStopReason(reason: StopReason?) {
        if (reason == null) stopReason.delete() else stopReason.writeAtomically(reason.wire)
    }

    fun clearTrail() {
        trail.delete()
        ledger.delete()
    }
}
