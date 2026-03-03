package com.eldershield.elder_shield

import android.content.Context
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.util.Log

/**
 * Listens for phone call state changes using PhoneStateListener.
 * Reports IDLE / RINGING / OFFHOOK states to SmsEventEmitter.
 *
 * PhoneStateListener is deprecated in API 31+ in favour of TelephonyCallback,
 * but remains functional and is the simplest cross-version solution for Phase 1.
 * Upgrade path: replace with TelephonyCallback when minSdk ≥ 31.
 */
@Suppress("DEPRECATION")
class CallStateListener(private val context: Context) {

    private val tag = "CallStateListener"
    private var telephonyManager: TelephonyManager? = null

    private val listener = object : PhoneStateListener() {
        override fun onCallStateChanged(state: Int, phoneNumber: String?) {
            val stateStr = when (state) {
                TelephonyManager.CALL_STATE_IDLE -> "IDLE"
                TelephonyManager.CALL_STATE_RINGING -> "RINGING"
                TelephonyManager.CALL_STATE_OFFHOOK -> "OFFHOOK"
                else -> "UNKNOWN"
            }
            Log.d(tag, "Call state → $stateStr  number=${phoneNumber ?: ""}")
            SmsEventEmitter.sendCallState(
                state = stateStr,
                number = phoneNumber ?: ""
            )
        }
    }

    fun start() {
        telephonyManager =
            context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        telephonyManager?.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)
        Log.d(tag, "CallStateListener started")
    }

    fun stop() {
        telephonyManager?.listen(listener, PhoneStateListener.LISTEN_NONE)
        telephonyManager = null
        Log.d(tag, "CallStateListener stopped")
    }
}
