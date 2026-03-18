package com.eldershield.elder_shield

import android.content.Context
import android.util.Log
import androidx.work.ListenableWorker
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * WorkManager worker that sends the daily heartbeat / weekly summary WhatsApp
 * (or SMS) message to the configured guardian contact.
 *
 * The Flutter [HeartbeatService] registers two periodic tasks via the
 * workmanager plugin — one for the daily check-in and one for the weekly
 * summary. Both tasks call this worker.
 *
 * Data is synced from Flutter to SharedPreferences by
 * [MainActivity]'s `elder_shield/heartbeat` MethodChannel before this
 * worker executes, so the worker can run independently of the Flutter engine.
 */
class HeartbeatWorker(context: Context, params: WorkerParameters) :
    Worker(context, params) {

    companion object {
        private const val TAG = "HeartbeatWorker"
        private const val PREFS_NAME = "elder_shield_prefs"

        // Keys written by Flutter HeartbeatService via MethodChannel.
        const val KEY_GUARDIAN_NUMBER = "heartbeat_guardian_number"
        const val KEY_PROTECTED_NAME = "heartbeat_protected_name"
        const val KEY_SUSPICIOUS_COUNT = "heartbeat_suspicious_count"
        const val KEY_TOTAL_SCANNED = "heartbeat_total_scanned"
        const val KEY_FLAGGED_COUNT = "heartbeat_flagged_count"
        const val KEY_HIGH_RISK_COUNT = "heartbeat_high_risk_count"
        const val KEY_TOP_THREATS = "heartbeat_top_threats"
        const val KEY_DATA_TYPE = "heartbeat_data_type"
        const val KEY_LAST_SENT_TIME = "heartbeat_last_sent_time"

        const val TYPE_DAILY = "daily"
        const val TYPE_WEEKLY = "weekly"
    }

    override fun doWork(): ListenableWorker.Result {
        val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val guardianNumber = prefs.getString(KEY_GUARDIAN_NUMBER, "") ?: ""
        val protectedName = prefs.getString(KEY_PROTECTED_NAME, "your family member") ?: "your family member"
        val dataType = prefs.getString(KEY_DATA_TYPE, TYPE_DAILY) ?: TYPE_DAILY

        if (guardianNumber.isBlank()) {
            Log.d(TAG, "No guardian number configured — skipping heartbeat")
            return ListenableWorker.Result.success()
        }

        return try {
            val message = when (dataType) {
                TYPE_WEEKLY -> buildWeeklyMessage(prefs, protectedName)
                else -> buildDailyMessage(prefs, protectedName)
            }

            val sent = WhatsAppIntentHelper.sendTextMessage(
                context = applicationContext,
                recipientNumber = guardianNumber,
                message = message,
            )

            if (sent) {
                prefs.edit()
                    .putLong(KEY_LAST_SENT_TIME, System.currentTimeMillis())
                    .apply()
                Log.d(TAG, "Heartbeat sent [$dataType] to $guardianNumber")
            } else {
                Log.w(TAG, "Heartbeat message delivery failed [$dataType]")
            }
            ListenableWorker.Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "HeartbeatWorker error", e)
            ListenableWorker.Result.retry()
        }
    }

    private fun buildDailyMessage(
        prefs: android.content.SharedPreferences,
        protectedName: String,
    ): String {
        val count = prefs.getInt(KEY_SUSPICIOUS_COUNT, 0)
        return if (count == 0) {
            "✅ Daily update: $protectedName received no suspicious messages yesterday. All clear!"
        } else {
            "⚠️ Daily update: $protectedName received $count suspicious message(s) yesterday. " +
                "Please check the Elder Shield app for details."
        }
    }

    private fun buildWeeklyMessage(
        prefs: android.content.SharedPreferences,
        protectedName: String,
    ): String {
        val total = prefs.getInt(KEY_TOTAL_SCANNED, 0)
        val flagged = prefs.getInt(KEY_FLAGGED_COUNT, 0)
        val high = prefs.getInt(KEY_HIGH_RISK_COUNT, 0)
        val threats = prefs.getString(KEY_TOP_THREATS, "") ?: ""

        val threatLine = if (threats.isNotBlank()) "\nTop threats: $threats" else ""
        return "📊 Weekly summary for $protectedName:\n" +
            "• Messages scanned: $total\n" +
            "• Suspicious: $flagged (High-risk: $high)" +
            threatLine
    }
}
