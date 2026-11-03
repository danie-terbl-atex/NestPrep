package io.nullstate.nestprep.location

import java.io.File

fun File.writeAtomically(text: String) {
    parentFile?.mkdirs()
    val staging = File(parentFile, "$name.tmp")
    staging.writeText(text)
    if (!staging.renameTo(this)) {
        delete()
        staging.renameTo(this)
    }
}

fun File.readTextOrNull(): String? = if (exists()) runCatching { readText() }.getOrNull() else null
