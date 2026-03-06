package com.eldershield.elder_shield

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

class ScamOverlayService : Service() {

    companion object {
        private const val ACTION_SHOW = "elder_shield.action.SHOW_OVERLAY"
        private const val ACTION_OPEN = "elder_shield.action.OPEN_WARNING"
        private const val ACTION_DISMISS = "elder_shield.action.DISMISS_OVERLAY"
        private const val CHANNEL_ID = "elder_shield_overlay"
        private const val CHANNEL_NAME = "Elder Shield Overlay"
        private const val FOREGROUND_ID = 91234

        fun show(context: Context, sender: String, body: String, timestamp: Long) {
            val intent = Intent(context, ScamOverlayService::class.java).apply {
                action = ACTION_SHOW
                putExtra(SmsReceiver.EXTRA_SMS_SENDER, sender)
                putExtra(SmsReceiver.EXTRA_SMS_BODY, body)
                putExtra(SmsReceiver.EXTRA_SMS_TIMESTAMP, timestamp)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_OPEN -> {
                openWarning(intent)
                removeOverlay()
                stopSelf()
            }

            ACTION_DISMISS -> {
                removeOverlay()
                stopSelf()
            }

            else -> {
                val sender = intent?.getStringExtra(SmsReceiver.EXTRA_SMS_SENDER) ?: return START_NOT_STICKY
                val body = intent.getStringExtra(SmsReceiver.EXTRA_SMS_BODY) ?: return START_NOT_STICKY
                val timestamp = intent.getLongExtra(SmsReceiver.EXTRA_SMS_TIMESTAMP, 0L)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                startForeground(FOREGROUND_ID, buildForegroundNotification(sender, body, timestamp))
                showOverlay(sender, body, timestamp)
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }

    private fun buildForegroundNotification(sender: String, body: String, timestamp: Long): Notification {
        createChannelIfNeeded()
        val openPending = PendingIntent.getService(
            this,
            timestamp.toInt().and(0x7FFFFFFF),
            Intent(this, ScamOverlayService::class.java).apply {
                action = ACTION_OPEN
                putExtra(SmsReceiver.EXTRA_SMS_SENDER, sender)
                putExtra(SmsReceiver.EXTRA_SMS_BODY, body)
                putExtra(SmsReceiver.EXTRA_SMS_TIMESTAMP, timestamp)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle("Elder Shield warning")
            .setContentText("Possible scam from $sender")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(openPending)
            .build()
    }

    private fun showOverlay(sender: String, body: String, timestamp: Long) {
        removeOverlay()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#FCE8E6"))
            setPadding(48, 48, 48, 48)
            elevation = 24f
        }

        val icon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_dialog_alert)
            setColorFilter(Color.parseColor("#B3261E"))
        }

        val title = TextView(this).apply {
            text = "Possible scam message"
            setTextColor(Color.parseColor("#B3261E"))
            textSize = 24f
            setPadding(0, 24, 0, 12)
        }

        val senderView = TextView(this).apply {
            text = "From: $sender"
            setTextColor(Color.BLACK)
            textSize = 18f
            setPadding(0, 0, 0, 12)
        }

        val bodyView = TextView(this).apply {
            val preview = if (body.length > 180) body.take(180) + "…" else body
            text = preview
            setTextColor(Color.DKGRAY)
            textSize = 16f
            setPadding(0, 0, 0, 32)
        }

        val openButton = Button(this).apply {
            text = "Open warning"
            setOnClickListener {
                openWarning(
                    Intent().apply {
                        putExtra(SmsReceiver.EXTRA_SMS_SENDER, sender)
                        putExtra(SmsReceiver.EXTRA_SMS_BODY, body)
                        putExtra(SmsReceiver.EXTRA_SMS_TIMESTAMP, timestamp)
                    }
                )
                removeOverlay()
                stopSelf()
            }
        }

        val dismissButton = Button(this).apply {
            text = "Dismiss"
            setOnClickListener {
                removeOverlay()
                stopSelf()
            }
        }

        root.addView(icon)
        root.addView(title)
        root.addView(senderView)
        root.addView(bodyView)
        root.addView(openButton)
        root.addView(dismissButton)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = 120
        }

        windowManager?.addView(root, params)
        overlayView = root
    }

    private fun openWarning(intent: Intent) {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(SmsReceiver.EXTRA_SMS_SENDER, intent.getStringExtra(SmsReceiver.EXTRA_SMS_SENDER))
            putExtra(SmsReceiver.EXTRA_SMS_BODY, intent.getStringExtra(SmsReceiver.EXTRA_SMS_BODY))
            putExtra(SmsReceiver.EXTRA_SMS_TIMESTAMP, intent.getLongExtra(SmsReceiver.EXTRA_SMS_TIMESTAMP, 0L))
        }
        startActivity(launchIntent)
    }

    private fun removeOverlay() {
        overlayView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (_: Exception) {
            }
        }
        overlayView = null
    }

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        )
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }
}
