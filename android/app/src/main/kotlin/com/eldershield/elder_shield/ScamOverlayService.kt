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
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
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
import android.widget.ScrollView
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

        // Dimmed backdrop so the card feels more premium and focused.
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#66000000")) // 60% black
            // Use smaller, responsive side padding so the card is not cramped on small screens.
            val sidePadding = (resources.displayMetrics.density * 24).toInt()
            setPadding(sidePadding, 0, sidePadding, 0)
            gravity = Gravity.CENTER
        }

        // Elevated card container
        val cardBackground = GradientDrawable().apply {
            cornerRadius = 32f
            setColor(Color.parseColor("#FFF9F5"))
        }

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = cardBackground
            val horizontal = (resources.displayMetrics.density * 20).toInt()
            val vertical = (resources.displayMetrics.density * 24).toInt()
            setPadding(horizontal, vertical, horizontal, vertical)
            elevation = 24f
            gravity = Gravity.CENTER_HORIZONTAL
        }

        // Risk accent uses the same red as the in-app warning screens.
        val icon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_dialog_alert)
            setColorFilter(Color.parseColor("#D32F2F"))
        }

        val title = TextView(this).apply {
            text = "Possible scam message"
            // Match high-risk red used in the main app.
            setTextColor(Color.parseColor("#D32F2F"))
            textSize = 24f
            setTypeface(typeface, Typeface.BOLD)
            setPadding(0, 24, 0, 6)
            textAlignment = View.TEXT_ALIGNMENT_CENTER
        }

        val subtitle = TextView(this).apply {
            text = "Take a moment before responding."
            setTextColor(Color.parseColor("#8A000000"))
            textSize = 16f
            setPadding(0, 0, 0, 16)
            textAlignment = View.TEXT_ALIGNMENT_CENTER
        }

        val senderView = TextView(this).apply {
            text = "From: $sender"
            setTextColor(Color.parseColor("#212121"))
            textSize = 18f
            setTypeface(typeface, Typeface.BOLD)
            setPadding(0, 8, 0, 4)
        }

        val bodyView = TextView(this).apply {
            // Show a readable, non-clickable preview. Truncate with an ellipsis if too long.
            val preview = if (body.length > 200) body.take(200) + "…" else body
            text = preview
            setTextColor(Color.parseColor("#424242"))
            textSize = 18f
            setLineSpacing(0f, 1.2f)
            setPadding(0, 0, 0, 32)
            maxLines = 5
            ellipsize = android.text.TextUtils.TruncateAt.END
        }

        val buttonRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            val top = (resources.displayMetrics.density * 8).toInt()
            setPadding(0, top, 0, 0)
        }

        val dismissButton = Button(this).apply {
            text = "Dismiss"
            textSize = 14f
            isAllCaps = false
            // Use brand primary color for text to match the rest of the app.
            setTextColor(Color.parseColor("#1565C0"))
            setBackgroundColor(Color.TRANSPARENT)
            minimumHeight = (resources.displayMetrics.density * 48).toInt()
            setOnClickListener {
                removeOverlay()
                stopSelf()
            }
        }

        // Primary action uses the same blue as the in-app buttons.
        val openButton = Button(this).apply {
            text = "Open warning"
            textSize = 14f
            isAllCaps = false
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#1565C0"))
            minimumHeight = (resources.displayMetrics.density * 48).toInt()
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

        val buttonLp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
            setMargins(0, 0, (resources.displayMetrics.density * 12).toInt(), 0)
        }
        val openButtonLp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)

        buttonRow.addView(dismissButton, buttonLp)
        buttonRow.addView(openButton, openButtonLp)

        val iconLp = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL
        }
        card.addView(icon, iconLp)
        card.addView(title)
        card.addView(subtitle)
        card.addView(senderView)
        card.addView(bodyView)
        card.addView(buttonRow)

        // Wrap card in a ScrollView so larger fonts remain usable.
        val scroll = ScrollView(this).apply {
            isFillViewport = false
        }
        scroll.addView(
            card,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        // Center the scroll/card on screen.
        root.addView(
            scroll,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
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
            gravity = Gravity.CENTER
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
