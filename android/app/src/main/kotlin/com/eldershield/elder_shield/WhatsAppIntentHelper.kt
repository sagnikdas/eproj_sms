package com.eldershield.elder_shield

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log

/**
 * Utility to send guardian alert messages via WhatsApp or SMS.
 *
 * Privacy: This helper NEVER includes any message body content.
 * Only sender ID, risk level, timestamp, and protected person name are shared.
 *
 * Used by [SmsReceiver] when the app is killed and a high-risk SMS is detected.
 */
object WhatsAppIntentHelper {

    private const val TAG = "WhatsAppIntentHelper"
    private const val WHATSAPP_PACKAGE = "com.whatsapp"
    private const val PREFS_NAME = "elder_shield_prefs"
    private const val KEY_GUARDIAN_NUMBER = "guardian_number"
    private const val KEY_GUARDIAN_NAME = "guardian_name"
    private const val KEY_PROTECTED_NAME = "protected_person_name"

    // Rate limiting keys in SharedPreferences
    private const val KEY_LAST_ALERT_TIME = "guardian_last_alert_time"
    private const val KEY_LAST_ALERT_SENDER = "guardian_last_alert_sender"
    private const val KEY_LAST_SENDER_ALERT_TIME = "guardian_last_sender_alert_time"
    private const val KEY_DAILY_ALERT_COUNT = "guardian_daily_alert_count"
    private const val KEY_DAILY_ALERT_DATE = "guardian_daily_alert_date"

    private const val MIN_INTERVAL_MS = 10 * 60 * 1000L       // 10 minutes
    private const val SENDER_COOLDOWN_MS = 60 * 60 * 1000L    // 1 hour
    private const val MAX_ALERTS_PER_DAY = 10

    /**
     * Send a guardian alert for a high-risk SMS detected in the background.
     * Reads guardian info from SharedPreferences (synced from Flutter).
     *
     * @return true if an alert intent was fired
     */
    fun sendGuardianAlert(
        context: Context,
        senderID: String,
        timestamp: Long
    ): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val guardianNumber = prefs.getString(KEY_GUARDIAN_NUMBER, null)
        if (guardianNumber.isNullOrBlank()) {
            Log.d(TAG, "No guardian configured — skipping alert")
            return false
        }

        if (!passesRateLimit(prefs, senderID)) {
            Log.d(TAG, "Rate-limited — skipping guardian alert")
            return false
        }

        val protectedName = prefs.getString(KEY_PROTECTED_NAME, "your family member") ?: "your family member"
        val message = composeMessage(protectedName, senderID, timestamp)

        recordAlert(prefs, senderID)

        val sent = trySendWhatsApp(context, guardianNumber, message)
        if (!sent) {
            return trySendSms(context, guardianNumber, message)
        }
        return true
    }

    /**
     * Compose the alert message. Never includes SMS body content.
     */
    private fun composeMessage(protectedName: String, senderID: String, timestamp: Long): String {
        val cal = java.util.Calendar.getInstance().apply { timeInMillis = timestamp }
        val hour = cal.get(java.util.Calendar.HOUR)
        val minute = cal.get(java.util.Calendar.MINUTE)
        val amPm = if (cal.get(java.util.Calendar.AM_PM) == java.util.Calendar.AM) "AM" else "PM"
        val displayHour = if (hour == 0) 12 else hour
        val timeStr = "$displayHour:${minute.toString().padStart(2, '0')} $amPm"

        return "ElderShield Alert\n" +
                "A suspicious message was detected on ${protectedName}'s phone.\n" +
                "Sender: $senderID\n" +
                "Risk: High\n" +
                "Time: $timeStr\n\n" +
                "$protectedName is protected — the message has been flagged."
    }

    /**
     * Try sending via WhatsApp intent.
     */
    private fun trySendWhatsApp(context: Context, phoneNumber: String, message: String): Boolean {
        return try {
            if (!isWhatsAppInstalled(context)) {
                Log.d(TAG, "WhatsApp not installed")
                return false
            }
            val cleanNumber = cleanPhoneNumber(phoneNumber)
            val uri = Uri.parse("https://wa.me/$cleanNumber?text=${Uri.encode(message)}")
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            Log.d(TAG, "WhatsApp alert intent fired")
            true
        } catch (e: Exception) {
            Log.e(TAG, "WhatsApp send failed", e)
            false
        }
    }

    /**
     * Fallback: send via SMS intent.
     */
    private fun trySendSms(context: Context, phoneNumber: String, message: String): Boolean {
        return try {
            val uri = Uri.parse("sms:$phoneNumber")
            val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
                putExtra("sms_body", message)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            Log.d(TAG, "SMS alert intent fired")
            true
        } catch (e: Exception) {
            Log.e(TAG, "SMS send failed", e)
            false
        }
    }

    private fun isWhatsAppInstalled(context: Context): Boolean {
        return try {
            context.packageManager.getPackageInfo(WHATSAPP_PACKAGE, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    /**
     * Strip non-digit chars except leading +. If no country code, assume India (+91).
     * wa.me expects number without leading +.
     */
    private fun cleanPhoneNumber(raw: String): String {
        val digits = raw.replace(Regex("[^\\d+]"), "")
        if (digits.startsWith("+")) return digits.substring(1)
        if (digits.length == 10) return "91$digits"
        return digits
    }

    // ── Rate limiting ──────────────────────────────────────────────

    private fun passesRateLimit(
        prefs: android.content.SharedPreferences,
        senderID: String
    ): Boolean {
        val now = System.currentTimeMillis()

        // 1. Min interval between any alerts
        val lastAlert = prefs.getLong(KEY_LAST_ALERT_TIME, 0L)
        if (now - lastAlert < MIN_INTERVAL_MS) return false

        // 2. Same sender cooldown
        val lastSender = prefs.getString(KEY_LAST_ALERT_SENDER, null)
        val lastSenderTime = prefs.getLong(KEY_LAST_SENDER_ALERT_TIME, 0L)
        if (lastSender == senderID && now - lastSenderTime < SENDER_COOLDOWN_MS) return false

        // 3. Max alerts per day
        val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
            .format(java.util.Date(now))
        val storedDate = prefs.getString(KEY_DAILY_ALERT_DATE, null)
        val dailyCount = if (storedDate == today) {
            prefs.getInt(KEY_DAILY_ALERT_COUNT, 0)
        } else {
            0
        }
        if (dailyCount >= MAX_ALERTS_PER_DAY) return false

        return true
    }

    private fun recordAlert(
        prefs: android.content.SharedPreferences,
        senderID: String
    ) {
        val now = System.currentTimeMillis()
        val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
            .format(java.util.Date(now))
        val storedDate = prefs.getString(KEY_DAILY_ALERT_DATE, null)
        val dailyCount = if (storedDate == today) {
            prefs.getInt(KEY_DAILY_ALERT_COUNT, 0)
        } else {
            0
        }

        prefs.edit()
            .putLong(KEY_LAST_ALERT_TIME, now)
            .putString(KEY_LAST_ALERT_SENDER, senderID)
            .putLong(KEY_LAST_SENDER_ALERT_TIME, now)
            .putString(KEY_DAILY_ALERT_DATE, today)
            .putInt(KEY_DAILY_ALERT_COUNT, dailyCount + 1)
            .apply()
    }
}
