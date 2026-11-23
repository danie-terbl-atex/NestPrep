package io.nullstate.nestprep

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Process
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Opens the app again in a fresh process, so a downloaded Shorebird patch
 * boots (foundation ADR-0026). The relaunch runs in its own `:relaunch`
 * process because the process being replaced cannot start its successor and
 * die at once; the `:location` process is left alone.
 */
object AppRestart {
    private const val CHANNEL = "io.nullstate.nestprep/app_restart"

    fun register(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRelaunch" -> result.success(true)
                "relaunch" -> {
                    RelaunchActivity.start(activity)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

class RelaunchActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Process.killProcess(intent.getIntExtra(MAIN_PID, -1))
        packageManager.getLaunchIntentForPackage(packageName)?.let { launch ->
            startActivity(
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK),
            )
        }
        finish()
        Runtime.getRuntime().exit(0)
    }

    companion object {
        private const val MAIN_PID = "mainPid"

        fun start(activity: Activity) {
            activity.startActivity(
                Intent(activity, RelaunchActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    .putExtra(MAIN_PID, Process.myPid()),
            )
        }
    }
}
