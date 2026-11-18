package com.inpand.jaihindrunnerclub

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.inpand.jaihindrunnerclub/street_view",
            StreetViewPlatformViewFactory(
                activity = this,
                lifecycle = this.lifecycle,
                messenger = flutterEngine.dartExecutor.binaryMessenger
            )
        )
    }
}
