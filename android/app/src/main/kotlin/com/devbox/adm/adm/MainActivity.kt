package com.devbox.adm.adm

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.regex.Pattern

class MainActivity : FlutterActivity() {
    private val channelName = "com.devbox.adm/intent"
    private var methodChannel: MethodChannel? = null
    private var initialUrl: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            if (call.method == "getInitialUrl") {
                val url = initialUrl
                initialUrl = null
                result.success(url)
            } else {
                result.notImplemented()
            }
        }

        // If an intent was received before Flutter engine was initialized
        initialUrl?.let { url ->
            channel.invokeMethod("onSharedUrl", url)
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action

        var extractedUrl: String? = null

        if (Intent.ACTION_SEND == action) {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                ?: intent.clipData?.let { clip ->
                    if (clip.itemCount > 0) clip.getItemAt(0)?.text?.toString() else null
                }
            if (text != null) {
                extractedUrl = extractUrlFromText(text)
            }
        } else if (Intent.ACTION_VIEW == action) {
            extractedUrl = intent.dataString
        }

        if (!extractedUrl.isNullOrBlank()) {
            initialUrl = extractedUrl
            methodChannel?.invokeMethod("onSharedUrl", extractedUrl)
        }
    }

    private fun extractUrlFromText(text: String): String {
        val trimmed = text.trim()
        if (trimmed.startsWith("http://") || trimmed.startsWith("https://") || 
            trimmed.startsWith("magnet:") || trimmed.startsWith("ftp://")) {
            return trimmed
        }

        val pattern = Pattern.compile(
            "(https?://[^\\s]+|magnet:\\?[^\\s]+|ftp://[^\\s]+)",
            Pattern.CASE_INSENSITIVE
        )
        val matcher = pattern.matcher(trimmed)
        if (matcher.find()) {
            var url = matcher.group(1) ?: trimmed
            while (url.isNotEmpty() && (url.endsWith(".") || url.endsWith(",") || url.endsWith(")") || url.endsWith(">"))) {
                url = url.substring(0, url.length - 1)
            }
            return url
        }

        return trimmed
    }
}
