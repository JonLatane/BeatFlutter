package io.beatscratch.beatscratch_flutter_redux;

import android.app.Application
import android.os.Build
import org.beatscratch.models.Music

class MainApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    instance = this
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      MidiDevices.initialize(this)
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
