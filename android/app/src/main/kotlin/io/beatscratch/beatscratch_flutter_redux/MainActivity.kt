package io.beatscratch.beatscratch_flutter_redux

import android.content.res.Configuration
import android.os.Bundle
import android.os.Handler
import android.view.View
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity : FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState);
    BeatScratchPlugin.handler = Handler()
    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
//        val orientation = resources.configuration.orientation
//        println("resources.configuration.orientation=${resources.configuration.orientation}")
    window.decorView.addOnLayoutChangeListener(View.OnLayoutChangeListener { v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
      if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) { // In landscape
//                window.setFlags(android.view.WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, android.view.WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
        val attrs: WindowManager.LayoutParams = window.attributes
        attrs.flags = attrs.flags or WindowManager.LayoutParams.FLAG_FULLSCREEN
        window.attributes = attrs
      } else {
        val attrs: WindowManager.LayoutParams = window.attributes
        attrs.flags = attrs.flags and WindowManager.LayoutParams.FLAG_FULLSCREEN.inv()
        window.attributes = attrs

      }
    })
    val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "BeatScratchPlugin")
    BeatScratchPlugin.channel = channel
  }

  override fun onResume() {
    super.onResume()
    MainApplication.instance.startPlaybackService()
  }

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    window.decorView.apply {
      // Hide both the navigation bar and the status bar.
      // SYSTEM_UI_FLAG_FULLSCREEN is only available on Android 4.1 and higher, but as
      // a general rule, you should design your app to hide the status bar whenever you
      // hide the navigation bar.
    }
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}
