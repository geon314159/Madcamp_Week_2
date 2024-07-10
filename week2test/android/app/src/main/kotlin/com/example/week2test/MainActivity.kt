package com.android.application

import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.kakao.sdk.common.util.Utility

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.yourapp/keyhash"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getKeyHash") {
                val keyHash = Utility.getKeyHash(this)
                if (keyHash != null) {
                    result.success(keyHash)
                } else {
                    result.error("UNAVAILABLE", "KeyHash not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
