package com.eldershield.elder_shield

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

/**
 * BroadcastReceiver for incoming SMS messages.
 * Declared in AndroidManifest.xml with RECEIVE_SMS permission.
 * Forwards each SMS to SmsEventEmitter → Flutter EventChannel.
 *
 * No overlay, no notification listener — Play-policy safe.
 */
class SmsReceiver : BroadcastReceiver() {

    private val tag = "SmsReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return

        // Group multi-part messages by sender; each part has same originatingAddress.
        val grouped = mutableMapOf<String, StringBuilder>()
        var timestamp = System.currentTimeMillis()

        for (msg in messages) {
            val sender = msg.originatingAddress ?: "unknown"
            grouped.getOrPut(sender) { StringBuilder() }.append(msg.messageBody)
            // Use the timestamp from the first part
            if (msg.timestampMillis > 0) timestamp = msg.timestampMillis
        }

        for ((sender, bodyBuilder) in grouped) {
            val body = bodyBuilder.toString()
            Log.d(tag, "Received SMS from $sender (${body.length} chars)")
            SmsEventEmitter.sendSms(
                sender = sender,
                body = body,
                timestamp = timestamp
            )
        }
    }
}
