package com.example.gohealth

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Bundle
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationManagerCompat

class MainActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "Flutter engine configured")
        
        // Check notification permission status
        checkNotificationPermission()
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "MainActivity created")
        
        // Handle notification when app is launched
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        Log.d(TAG, "New intent received")
        
        // Handle notification when app is already running
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        
        Log.d(TAG, "MainActivity resumed")
        
        // Check notification permission when app comes to foreground
        checkNotificationPermission()
    }

    private fun handleIntent(intent: Intent?) {
        intent?.let { safeIntent ->
            val extras = safeIntent.extras
            
            if (extras != null) {
                Log.d(TAG, "Intent extras found: ${extras.keySet()}")
                
                // Check if launched from FCM notification
                if (extras.containsKey("google.message_id")) {
                    Log.d(TAG, "App launched/opened from FCM notification")
                    
                    // Log all notification data
                    for (key in extras.keySet()) {
                        val value = extras.get(key)
                        Log.d(TAG, "FCM Extra: $key = $value")
                    }
                    
                    // Flutter side will handle the navigation via getInitialMessage() or onMessageOpenedApp
                } else if (extras.containsKey("payload")) {
                    // Local notification
                    Log.d(TAG, "App launched/opened from local notification")
                    val payload = extras.getString("payload")
                    Log.d(TAG, "Local notification payload: $payload")
                }
            } else {
                Log.d(TAG, "No intent extras found")
            }
        }
    }

    private fun checkNotificationPermission() {
        try {
            val notificationManager = NotificationManagerCompat.from(this)
            val areNotificationsEnabled = notificationManager.areNotificationsEnabled()
            
            Log.d(TAG, "Notifications enabled: $areNotificationsEnabled")
            
            if (!areNotificationsEnabled) {
                Log.w(TAG, "⚠️ Notifications are disabled by user!")
                Log.w(TAG, "💡 User needs to enable notifications in device settings")
            } else {
                Log.d(TAG, "✅ Notifications are enabled")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error checking notification permission: ${e.message}")
        }
    }
}