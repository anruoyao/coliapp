package com.retrytech.chatter.untitled

import com.baseflow.permissionhandler.PermissionHandlerPlugin
import com.retrytech.retrytech_plugin.RetrytechPlugin
import com.tekartik.sqflite.SqflitePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.videoplayer.VideoPlayerPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(SqflitePlugin())
        flutterEngine.plugins.add(VideoPlayerPlugin())
        flutterEngine.plugins.add(PermissionHandlerPlugin())
        flutterEngine.plugins.add(RetrytechPlugin())
    }
}
