package io.nullstate.nestprep.location

import java.io.File

class TrailBuffer(private val file: File, private val capacity: Int = CAPACITY) {
    private val buffered: MutableList<TrailPoint> =
        file.readTextOrNull().orEmpty().lineSequence()
            // A process killed mid-append leaves a torn last line; it is dropped, not fatal.
            .mapNotNull { if (it.isBlank()) null else TrailPoint.ofLine(it) }
            .toMutableList()

    val points: List<TrailPoint> get() = buffered
    val size: Int get() = buffered.size

    fun add(point: TrailPoint) {
        buffered += point
        if (buffered.size > capacity) {
            buffered.subList(0, buffered.size - capacity).clear()
            save()
        } else {
            file.parentFile?.mkdirs()
            file.appendText(point.toLine() + "\n")
        }
    }

    fun remove(sent: List<TrailPoint>) {
        if (sent.isEmpty()) return
        sent.forEach { buffered.remove(it) }
        save()
    }

    fun clear() {
        buffered.clear()
        file.delete()
    }

    private fun save() = file.writeAtomically(buffered.joinToString("") { it.toLine() + "\n" })

    companion object {
        const val CAPACITY = 3_000
    }
}
