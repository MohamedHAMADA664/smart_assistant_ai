package com.example.smart_assistant_ai

import android.content.Context
import android.os.Build
import android.telecom.TelecomManager
import android.telephony.TelephonyManager

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "smart_assistant/call_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smart_assistant/call_control")
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "acceptCall" -> {
                    answerCall()
                    result.success(null)
                }

                "rejectCall" -> {
                    rejectCall()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    // ==========================
    // ANSWER CALL
    // ==========================

    private fun answerCall() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val telecomManager =
                    getSystemService(Context.TELECOM_SERVICE) as TelecomManager

                telecomManager.acceptRingingCall()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ==========================
    // REJECT CALL
    // ==========================

    private fun rejectCall() {
        try {
            val telephonyManager =
                getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

            val method = telephonyManager.javaClass.getDeclaredMethod("endCall")
            method.isAccessible = true
            method.invoke(telephonyManager)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}