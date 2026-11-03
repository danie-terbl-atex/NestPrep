package io.nullstate.nestprep.location

import org.junit.Assert.assertEquals
import org.junit.Test

class PermissionNamesTest {
    @Test
    fun `any location with background is always, approximate included`() {
        assertEquals("always", PermissionNames.location(servicesOn = true, anyLocation = true, background = true, refusedForGood = false))
        assertEquals("whileInUse", PermissionNames.location(servicesOn = true, anyLocation = true, background = false, refusedForGood = false))
    }

    @Test
    fun `services off wins and a refusal after asking is for good`() {
        assertEquals("off", PermissionNames.location(servicesOn = false, anyLocation = true, background = true, refusedForGood = false))
        assertEquals("denied", PermissionNames.location(servicesOn = true, anyLocation = false, background = false, refusedForGood = false))
        assertEquals("deniedForever", PermissionNames.location(servicesOn = true, anyLocation = false, background = false, refusedForGood = true))
    }

    @Test
    fun `motion is not needed before Android 10`() {
        assertEquals("notNeeded", PermissionNames.motion(needed = false, granted = false))
        assertEquals("granted", PermissionNames.motion(needed = true, granted = true))
        assertEquals("denied", PermissionNames.motion(needed = true, granted = false))
    }
}
