package com.eldershield.elder_shield

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

/**
 * Registers the fraud_guard/events EventChannel and starts the
 * CallStateListener. SmsReceiver fires independently via the manifest.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val EVENT_CHANNEL = "fraud_guard/events"
    }

    private var callStateListener: CallStateListener? = null
    private var eventChannel: EventChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).also { channel ->
            channel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    SmsEventEmitter.sink = events
                    // Start call listener once Flutter is ready to receive events.
                    callStateListener = CallStateListener(applicationContext).also { it.start() }
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
        callStateListener?.stop()
        SmsEventEmitter.sink = null
        eventChannel?.setStreamHandler(null)
        super.onDestroy()
    }
}
