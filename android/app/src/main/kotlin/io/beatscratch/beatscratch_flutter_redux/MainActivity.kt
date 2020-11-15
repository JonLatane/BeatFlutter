package io.beatscratch.beatscratch_flutter_redux

import android.R
import android.app.Activity
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Rect
import android.os.Bundle
import android.os.Handler
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.net.URL
import java.util.concurrent.Future


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
//        val attrs: WindowManager.LayoutParams = window.attributes
//        attrs.flags = attrs.flags or WindowManager.LayoutParams.FLAG_FULLSCREEN
//        window.attributes = attrs
//        AndroidBug5497Workaround.assistActivity(this)
        window.decorView.apply {
          systemUiVisibility = View.SYSTEM_UI_FLAG_FULLSCREEN
        }
      } else {
//        val attrs: WindowManager.LayoutParams = window.attributes
//        attrs.flags = attrs.flags and WindowManager.LayoutParams.FLAG_FULLSCREEN.inv()
//        window.attributes = attrs
//        window.decorView.apply {
//          systemUiVisibility = View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_FULLSCREEN
//        }
      }
    })
    val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "BeatScratchPlugin")
    BeatScratchPlugin.methodChannel = channel
    intent.data?.let { uri ->

      BeatScratchPlugin.notifyScoreUrlOpened(uri.toString())
    }
  }
  override fun onNewIntent(intent: Intent) {
//    getIntent().data = intent.getData()
    intent.data?.let { uri ->
      BeatScratchPlugin.notifyScoreUrlOpened(uri.toString())
    }
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

private var keyboardShown = false
class AndroidBug5497Workaround private constructor(val activity: Activity) {
  private val mChildOfContent: View
  private var usableHeightPrevious = 0
  private fun possiblyResizeChildOfContent() {
    val usableHeightNow = computeUsableHeight()
    if (usableHeightNow != usableHeightPrevious) {
      val usableHeightSansKeyboard = mChildOfContent.rootView.height
      val heightDifference = usableHeightSansKeyboard - usableHeightNow
      if (heightDifference > usableHeightSansKeyboard / 4) {
        // keyboard probably just became visible
        if (!keyboardShown) {
          logI("Keyboard shown")
          activity.window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
          activity.window.decorView.apply {
            systemUiVisibility = View.SYSTEM_UI_FLAG_FULLSCREEN
          }
        }
        keyboardShown = true
      } else {
        // keyboard probably just became hidden
        if (keyboardShown) {
          logI("Keyboard hidden")
          activity.window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
          activity.window.decorView.apply {
            systemUiVisibility = View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_FULLSCREEN
          }
        }
        keyboardShown = false
      }
      mChildOfContent.requestLayout()
      usableHeightPrevious = usableHeightNow
    }
  }

  private fun computeUsableHeight(): Int {
    val r = Rect()
    mChildOfContent.getWindowVisibleDisplayFrame(r)
    return r.bottom - r.top
  }

  companion object {
    // For more information, see https://issuetracker.google.com/issues/36911528
    // To use this class, simply invoke assistActivity() on an Activity that already has its content view set.
    fun assistActivity(activity: Activity) {
      AndroidBug5497Workaround(activity)
    }
  }

  init {
    val content: FrameLayout = activity.findViewById(R.id.content) as FrameLayout
    mChildOfContent = content.getChildAt(0)
    mChildOfContent.viewTreeObserver.addOnGlobalLayoutListener { possiblyResizeChildOfContent() }
//    frameLayoutParams = mChildOfContent.layoutParams as FrameLayout.LayoutParams
  }
}
