package io.beatscratch.beatscratch_flutter_redux;

import android.content.Intent
import io.beatscratch.beatscratch_flutter_redux.hardware.MidiDevices
import io.flutter.app.FlutterApplication
import org.beatscratch.models.Music

class MainApplication : FlutterApplication() {

  override fun onCreate() {
    super.onCreate()
    instance = this
    MidiDevices.initialize(this)
  }
  
  fun startPlaybackService() {
    try {
      Intent(instance, PlaybackService::class.java).let {
        it.action = PlaybackService.Companion.Action.STARTFOREGROUND_ACTION
        startService(it)
      }
    } catch(t: Throwable) {
      logE("startPlaybackService failed", t)
    }
  }

  companion object {
    var intentMelody: Music.Melody? = null
    var intentHarmony: Music.Harmony? = null
    var intentScore: Music.Score? = null
    lateinit var instance: MainApplication
      private set
  }
}
