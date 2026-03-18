package com.eldershield.elder_shield

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Helper for sending WhatsApp messages or falling back to SMS.
 *
 * For background WorkManager tasks (HeartbeatWorker), we cannot open UI
 * apps directly on Android 10+. Instead, we post a local notification with a
 * deep-link PendingIntent so the user or the OS can tap to send when convenient.
 */
object WhatsAppIntentHelper {

    private const val TAG = "WhatsAppIntentHelper"
    private const val CHANNEL_ID = "heartbeat_channel"
    private const val NOTIFICATION_ID = 2001

    /**
     * Send a text message to [recipientNumber] via WhatsApp (if installed) or SMS.
     *
     * When called from a background context (WorkManager), launches a notification
     * that opens WhatsApp/SMS when tapped. Returns true if the intent/notification
     * was successfully queued.
     */
    fun sendTextMessage(
        context: Context,
        recipientNumber: String,
        message: String,
    ): Boolean {
        if (recipientNumber.isBlank()) return false

        return try {
            val normalizedNumber = recipientNumber.replace(Regex("[^+\\d]"), "")

            // Build a WhatsApp deep-link intent.
            val whatsappUri = Uri.parse(
                "https://wa.me/$normalizedNumber?text=${Uri.encode(message)}"
            )
            val whatsappIntent = Intent(Intent.ACTION_VIEW, whatsappUri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            // Try to open directly if app is visible; otherwise post a notification.
            if (MainActivity.isAppVisible) {
                context.startActivity(whatsappIntent)
                Log.d(TAG, "WhatsApp intent launched directly")
            } else {
                postHeartbeatNotification(context, whatsappIntent, message)
                Log.d(TAG, "Heartbeat notification posted for guardian update")
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "sendTextMessage failed", e)
            false
        }
    }

    private fun postHeartbeatNotification(
        context: Context,
        openIntent: Intent,
        previewText: String,
    ) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Guardian Updates",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Daily heartbeat and weekly summary for guardian"
            }
            nm.createNotificationChannel(channel)
        }

        val pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        val pi = PendingIntent.getActivity(context, NOTIFICATION_ID, openIntent, pendingFlags)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Send guardian update")
            .setContentText(previewText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(previewText))
            .setContentIntent(pi)
            .setAutoCancel(true)
            .build()

        nm.notify(NOTIFICATION_ID, notification)
    }
}
