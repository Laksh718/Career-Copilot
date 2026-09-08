package com.example.career_copilot

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.career_copilot/config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDefaultGeminiApiKey") {
                val resId = resources.getIdentifier("default_gemini_api_key", "string", packageName)
                val key = if (resId != 0) getString(resId) else ""
                result.success(key)
            } else {
                result.notImplemented()
            }
        }
    }
}
