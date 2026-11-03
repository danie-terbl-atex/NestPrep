package io.nullstate.nestprep.location

enum class StopReason(val wire: String) {
    Refused("refused"),
    PermissionRevoked("permissionRevoked"),
    SignedOut("signedOut"),
    Paused("paused");

    companion object {
        fun ofWire(wire: String?): StopReason? = entries.firstOrNull { it.wire == wire }
    }
}
