package io.nullstate.nestprep.location

object AddressLine {
    fun format(number: String?, street: String?, suburb: String?, town: String?, fallback: String?): String? {
        val road = street.clean()?.let { listOfNotNull(number.clean(), it).joinToString(" ") }
        val area = suburb.clean() ?: town.clean()
        return listOfNotNull(road, area).joinToString(", ").ifEmpty { null } ?: fallback.clean()
    }

    private fun String?.clean(): String? = this?.trim()?.takeIf { it.isNotEmpty() }
}
