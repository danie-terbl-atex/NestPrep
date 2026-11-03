package io.nullstate.nestprep.location

object PermissionNames {
    fun location(
        servicesOn: Boolean,
        anyLocation: Boolean,
        background: Boolean,
        refusedForGood: Boolean,
    ): String = when {
        !servicesOn -> "off"
        anyLocation -> if (background) "always" else "whileInUse"
        refusedForGood -> "deniedForever"
        else -> "denied"
    }

    fun motion(needed: Boolean, granted: Boolean): String = when {
        !needed -> "notNeeded"
        granted -> "granted"
        else -> "denied"
    }
}
