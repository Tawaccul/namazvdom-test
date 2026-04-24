package com.example.prayday

import android.content.ComponentName
import android.content.pm.PackageManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "prayday/app_icon"
        private const val TAG = "PrayDayIcon"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "setDarkIconEnabled") {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    try {
                        setDarkLauncherIconEnabled(enabled)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to change launcher icon", e)
                        result.error(
                            "icon_change_failed",
                            e.message ?: "Failed to change launcher icon",
                            null
                        )
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun setDarkLauncherIconEnabled(enabled: Boolean) {
        val packageManager = applicationContext.packageManager
        val packageName = applicationContext.packageName
        val lightAlias = ComponentName(packageName, "$packageName.MainActivityLight")
        val darkAlias = ComponentName(packageName, "$packageName.MainActivityDark")
        if (!componentExists(lightAlias) || !componentExists(darkAlias)) {
            return
        }

        packageManager.setComponentEnabledSetting(
            lightAlias,
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            },
            PackageManager.DONT_KILL_APP
        )

        packageManager.setComponentEnabledSetting(
            darkAlias,
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP
        )
    }

    private fun componentExists(componentName: ComponentName): Boolean {
        return try {
            applicationContext.packageManager.getActivityInfo(componentName, 0)
            true
        } catch (_: Exception) {
            false
        }
    }
}
