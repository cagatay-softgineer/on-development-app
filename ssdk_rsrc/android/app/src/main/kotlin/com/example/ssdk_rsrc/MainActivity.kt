package com.example.ssdk_rsrc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register the AppleMusicPlugin.
        //flutterEngine.plugins.add(AppleMusicPlugin())
    }
}
