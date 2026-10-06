package com.barqsms.barq_sms

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.telephony.SmsManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var smsChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        smsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "barq_sms/sms_sender",
        )
        smsChannel.setMethodCallHandler { call, result ->
            if (call.method != "sendSms") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val logId = call.argument<Int>("logId")
            val phone = call.argument<String>("phoneNumber")
            val message = call.argument<String>("message")
            if (logId == null || phone.isNullOrBlank() || message.isNullOrBlank()) {
                result.error("INVALID_ARGUMENTS", "بيانات الرسالة غير مكتملة", null)
                return@setMethodCallHandler
            }
            try {
                sendSms(logId, phone, message)
                result.success(null)
            } catch (error: Exception) {
                result.error("SEND_ERROR", error.message, null)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun sendSms(logId: Int, phone: String, message: String) {
        val manager = SmsManager.getDefault()
        val parts = manager.divideMessage(message)
        val sentAction = "$packageName.SMS_SENT.$logId"
        val deliveredAction = "$packageName.SMS_DELIVERED.$logId"
        var sentParts = 0
        var deliveredParts = 0
        var sentFinished = false

        lateinit var sentReceiver: BroadcastReceiver
        lateinit var deliveredReceiver: BroadcastReceiver

        fun unregister(receiver: BroadcastReceiver) {
            try {
                unregisterReceiver(receiver)
            } catch (_: IllegalArgumentException) {
                // Already removed.
            }
        }

        sentReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (sentFinished) return
                if (resultCode != Activity.RESULT_OK) {
                    sentFinished = true
                    sendStatus(logId, "failed", sentErrorMessage(resultCode))
                    unregister(this)
                    unregister(deliveredReceiver)
                    return
                }
                sentParts++
                if (sentParts >= parts.size) {
                    sentFinished = true
                    sendStatus(logId, "sent", null)
                    unregister(this)
                }
            }
        }

        deliveredReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (resultCode != Activity.RESULT_OK) {
                    unregister(this)
                    return
                }
                deliveredParts++
                if (deliveredParts >= parts.size) {
                    sendStatus(logId, "delivered", null)
                    unregister(this)
                }
            }
        }

        registerPrivateReceiver(sentReceiver, sentAction)
        registerPrivateReceiver(deliveredReceiver, deliveredAction)

        val sentIntents = arrayListOf<PendingIntent>()
        val deliveredIntents = arrayListOf<PendingIntent>()
        parts.indices.forEach { index ->
            val requestBase = (logId * 100 + index) and 0x7fffffff
            sentIntents.add(pendingIntent(sentAction, requestBase))
            deliveredIntents.add(pendingIntent(deliveredAction, requestBase + 50))
        }

        manager.sendMultipartTextMessage(
            phone,
            null,
            parts,
            sentIntents,
            deliveredIntents,
        )
    }

    private fun pendingIntent(action: String, requestCode: Int): PendingIntent {
        return PendingIntent.getBroadcast(
            this,
            requestCode,
            Intent(action).setPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun registerPrivateReceiver(receiver: BroadcastReceiver, action: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, IntentFilter(action), RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(receiver, IntentFilter(action))
        }
    }

    private fun sendStatus(logId: Int, status: String, error: String?) {
        runOnUiThread {
            smsChannel.invokeMethod(
                "smsStatus",
                mapOf("logId" to logId, "status" to status, "error" to error),
            )
        }
    }

    private fun sentErrorMessage(code: Int): String = when (code) {
        SmsManager.RESULT_ERROR_GENERIC_FAILURE -> "فشل عام في إرسال الرسالة"
        SmsManager.RESULT_ERROR_NO_SERVICE -> "لا توجد خدمة شبكة"
        SmsManager.RESULT_ERROR_NULL_PDU -> "تعذر تجهيز الرسالة للإرسال"
        SmsManager.RESULT_ERROR_RADIO_OFF -> "شبكة الهاتف أو وضع الطيران يمنع الإرسال"
        else -> "رفض Android إرسال الرسالة (رمز $code)"
    }
}
