package com.example.smart_assistant_ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class CallReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "CallReceiver"
        private const val CHANNEL = "smart_assistant/call_events"
        private const val MAIN_ENGINE_ID = "main_engine"
        private const val METHOD_INCOMING_CALL = "incomingCall"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) {
            return
        }

        try {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)

            if (state != TelephonyManager.EXTRA_STATE_RINGING) {
                return
            }

            val incomingNumber =
                intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                    ?.trim()
                    ?.takeIf { it.isNotEmpty() }
                    ?: "رقم غير معروف"

            val engine = FlutterEngineCache
                .getInstance()
                .get(MAIN_ENGINE_ID)

            if (engine == null) {
                Log.w(
                    TAG,
                    "Flutter engine '$MAIN_ENGINE_ID' was not found in cache. Incoming call event was skipped."
                )
                return
            }

            MethodChannel(
                engine.dartExecutor.binaryMessenger,
                CHANNEL
            ).invokeMethod(METHOD_INCOMING_CALL, incomingNumber)

            Log.i(TAG, "Incoming call event sent to Flutter: $incomingNumber")
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to process incoming call broadcast.", exception)
        }
    }
}