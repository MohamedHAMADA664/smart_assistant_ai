package com.example.smart_assistant_ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager

import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class CallReceiver : BroadcastReceiver() {

    private val CHANNEL = "smart_assistant/call_events"

    override fun onReceive(context: Context, intent: Intent) {

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)

        if (state == TelephonyManager.EXTRA_STATE_RINGING) {

            val incomingNumber =
                intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: "Unknown"

            // 🔥 نجيب Flutter Engine
            val engine = FlutterEngineCache
                .getInstance()
                .get("main_engine")

            if (engine != null) {

                MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    CHANNEL
                ).invokeMethod("incomingCall", incomingNumber)
            }
        }
    }
}