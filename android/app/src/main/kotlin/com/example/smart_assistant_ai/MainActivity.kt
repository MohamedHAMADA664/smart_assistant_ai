package com.example.smart_assistant_ai

import android.content.Context
import android.os.Build
import android.telecom.TelecomManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val CALL_CONTROL_CHANNEL = "smart_assistant/call_control"
        private const val MAIN_ENGINE_ID = "main_engine"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        cacheMainEngine(flutterEngine)
        setupCallControlChannel(flutterEngine)
    }

    private fun cacheMainEngine(flutterEngine: FlutterEngine) {
        FlutterEngineCache.getInstance().put(MAIN_ENGINE_ID, flutterEngine)
    }

    private fun setupCallControlChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_CONTROL_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "acceptCall" -> {
                    val accepted = answerCall()
                    if (accepted) {
                        result.success(true)
                    } else {
                        result.error(
                            "ACCEPT_CALL_FAILED",
                            "Unable to answer the incoming call.",
                            null
                        )
                    }
                }

                "rejectCall" -> {
                    val rejected = rejectCall()
                    if (rejected) {
                        result.success(true)
                    } else {
                        result.error(
                            "REJECT_CALL_FAILED",
                            "Rejecting calls is not supported with the current implementation.",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun answerCall(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            Log.w(TAG, "acceptRingingCall requires Android O or higher.")
            return false
        }

        return try {
            val telecomManager =
                getSystemService(Context.TELECOM_SERVICE) as? TelecomManager

            if (telecomManager == null) {
                Log.e(TAG, "TelecomManager is unavailable.")
                false
            } else {
                telecomManager.acceptRingingCall()
                Log.i(TAG, "Incoming call answered successfully.")
                true
            }
        } catch (securityException: SecurityException) {
            Log.e(TAG, "Missing permission to answer phone calls.", securityException)
            false
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to answer incoming call.", exception)
            false
        }
    }

    private fun rejectCall(): Boolean {
        Log.w(
            TAG,
            "Reject call is not implemented with a supported public Android API in this activity."
        )
        return false
    }
}
