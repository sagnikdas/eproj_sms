package com.eldershield.elder_shield

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Registers the fraud_guard/events EventChannel and the elder_shield/launch MethodChannel.
 * When the app is opened from a high-risk SMS notification (app was killed), Flutter
 * calls getLaunchSms to get the message and show the warning sheet.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val EVENT_CHANNEL = "fraud_guard/events"
        private const val LAUNCH_CHANNEL = "elder_shield/launch"
        private const val SYSTEM_CHANNEL = "elder_shield/system"
        private const val WHITELIST_CHANNEL = "elder_shield/whitelist"
        private const val HEARTBEAT_CHANNEL = "elder_shield/heartbeat"
        private const val TAG = "MainActivity"

        @Volatile
        var isAppVisible: Boolean = false
    }

    private var callStateListener: CallStateListener? = null
    private var eventChannel: EventChannel? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        isAppVisible = true
    }

    override fun onPause() {
        isAppVisible = false
        super.onPause()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LAUNCH_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getLaunchSms") {
                val i = intent ?: return@setMethodCallHandler result.success(null)
                val sender = i.getStringExtra(SmsReceiver.EXTRA_SMS_SENDER)
                val body = i.getStringExtra(SmsReceiver.EXTRA_SMS_BODY)
                val timestamp = i.getLongExtra(SmsReceiver.EXTRA_SMS_TIMESTAMP, 0L)
                if (sender != null && body != null && timestamp != 0L) {
                    result.success(mapOf(
                        "sender" to sender,
                        "body" to body,
                        "timestamp" to timestamp
                    ))
                    setIntent(Intent())
                } else {
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SYSTEM_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canDrawOverlays" -> {
                    result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                            Settings.canDrawOverlays(this)
                    )
                }

                "openOverlayPermissionSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("overlay_settings", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WHITELIST_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "setWhitelist") {
                @Suppress("UNCHECKED_CAST")
                val senders = (call.arguments as? List<*>)
                    ?.filterIsInstance<String>()
                    ?.toSet()
                    ?: emptySet()
                getSharedPreferences("elder_shield_prefs", MODE_PRIVATE)
                    .edit()
                    .putStringSet("trusted_senders", senders)
                    .apply()
                Log.d(TAG, "Whitelist updated: ${senders.size} sender(s)")
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HEARTBEAT_CHANNEL
        ).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("elder_shield_prefs", MODE_PRIVATE)
            when (call.method) {
                "syncGuardianInfo" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                    val guardianNumber = args["guardianNumber"] as? String ?: ""
                    val protectedPersonName = args["protectedPersonName"] as? String ?: ""
                    prefs.edit()
                        .putString(HeartbeatWorker.KEY_GUARDIAN_NUMBER, guardianNumber)
                        .putString(HeartbeatWorker.KEY_PROTECTED_NAME, protectedPersonName)
                        .apply()
                    Log.d(TAG, "Heartbeat guardian info synced")
                    result.success(null)
                }
                "syncHeartbeatData" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                    val type = args["type"] as? String ?: HeartbeatWorker.TYPE_DAILY
                    val dataJson = args["data"] as? String ?: "{}"
                    // Parse and persist the key fields for HeartbeatWorker.
                    try {
                        val json = org.json.JSONObject(dataJson)
                        val editor = prefs.edit().putString(HeartbeatWorker.KEY_DATA_TYPE, type)
                        if (type == HeartbeatWorker.TYPE_DAILY) {
                            editor.putInt(HeartbeatWorker.KEY_SUSPICIOUS_COUNT,
                                json.optInt("suspiciousCount", 0))
                        } else {
                            editor.putInt(HeartbeatWorker.KEY_TOTAL_SCANNED,
                                json.optInt("totalScanned", 0))
                            editor.putInt(HeartbeatWorker.KEY_FLAGGED_COUNT,
                                json.optInt("flaggedCount", 0))
                            editor.putInt(HeartbeatWorker.KEY_HIGH_RISK_COUNT,
                                json.optInt("highRiskCount", 0))
                            val threats = json.optJSONArray("topThreatTypes")
                            if (threats != null) {
                                val list = (0 until threats.length()).map { threats.getString(it) }
                                editor.putString(HeartbeatWorker.KEY_TOP_THREATS, list.joinToString(", "))
                            }
                        }
                        editor.apply()
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to parse heartbeat data", e)
                    }
                    result.success(null)
                }
                "getLastHeartbeatTime" -> {
                    val lastTime = prefs.getLong(HeartbeatWorker.KEY_LAST_SENT_TIME, 0L)
                    result.success(lastTime)
                }
                else -> result.notImplemented()
            }
        }

        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).also { channel ->
            channel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    try {
                        SmsEventEmitter.sink = events
                        // Start call listener once Flutter is ready to receive events.
                        callStateListener =
                            CallStateListener(applicationContext).also { it.start() }
                        Log.d(TAG, "EventChannel onListen: native listeners started")
                    } catch (se: SecurityException) {
                        Log.e(TAG, "SecurityException in onListen", se)
                        SmsEventEmitter.sink = null
                        callStateListener?.stop()
                        callStateListener = null
                        events.error(
                            "security",
                            se.message ?: "SecurityException starting native listeners",
                            null
                        )
                    } catch (e: Exception) {
                        Log.e(TAG, "Unexpected error in onListen", e)
                        SmsEventEmitter.sink = null
                        callStateListener?.stop()
                        callStateListener = null
                        events.error(
                            "error",
                            e.message ?: "Unexpected error starting native listeners",
                            null
                        )
                    }
                }

                override fun onCancel(arguments: Any?) {
                    SmsEventEmitter.sink = null
                    callStateListener?.stop()
                    callStateListener = null
                }
            })
        }
    }

    override fun onDestroy() {
        isAppVisible = false
        callStateListener?.stop()
        SmsEventEmitter.sink = null
        eventChannel?.setStreamHandler(null)
        super.onDestroy()
    }
}
