package io.nullstate.nestprep

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

/**
 * A PDF shared into NestPrep waits here as its content Uri, under a token the
 * share link carries, and is copied only when the app takes it, off the main
 * thread (recipes ADR-0009). The read grant lasts as long as this activity.
 */
class SharedPdfs(private val activity: Activity) {
    private val waiting = mutableMapOf<String, Uri>()
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun hold(intent: Intent): String? {
        if (intent.type?.lowercase() != PDF) return null
        val uri = streamOf(intent) ?: return null
        val token = UUID.randomUUID().toString()
        waiting.clear()
        waiting[token] = uri
        return token
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "take") return@setMethodCallHandler result.notImplemented()
            val uri = call.argument<String>("token")?.let { waiting.remove(it) }
                ?: return@setMethodCallHandler result.success(null)
            worker.execute {
                val taken = runCatching { copy(uri) }.getOrNull()
                main.post { result.success(taken) }
            }
        }
    }

    private fun copy(uri: Uri): Map<String, String>? {
        val resolver = activity.contentResolver
        var name = "PDF.pdf"
        var size = -1L
        resolver.query(uri, null, null, null, null)?.use { row ->
            if (row.moveToFirst()) {
                row.getColumnIndex(OpenableColumns.DISPLAY_NAME).takeIf { it >= 0 }
                    ?.let { row.getString(it) }?.takeIf { it.isNotBlank() }?.let { name = it }
                row.getColumnIndex(OpenableColumns.SIZE).takeIf { it >= 0 && !row.isNull(it) }
                    ?.let { size = row.getLong(it) }
            }
        }
        if (size > MAX_BYTES) return mapOf("name" to name, "tooLarge" to "true")
        val folder = File(activity.cacheDir, "shared_pdfs").apply {
            deleteRecursively()
            mkdirs()
        }
        val file = File(folder, "${UUID.randomUUID()}.pdf")
        val fits = resolver.openInputStream(uri)?.use { input ->
            file.outputStream().use { output ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                var copied = 0L
                while (copied <= MAX_BYTES) {
                    val read = input.read(buffer)
                    if (read < 0) return@use true
                    output.write(buffer, 0, read)
                    copied += read
                }
                false
            }
        } ?: return null
        if (!fits) {
            file.delete()
            return mapOf("name" to name, "tooLarge" to "true")
        }
        return mapOf("path" to file.path, "name" to name)
    }

    @Suppress("DEPRECATION")
    private fun streamOf(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
        }

    private companion object {
        const val CHANNEL = "io.nullstate.nestprep/shared_pdf"
        const val PDF = "application/pdf"
        const val MAX_BYTES = 100L * 1024 * 1024
    }
}
