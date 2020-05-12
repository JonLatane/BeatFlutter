package io.beatscratch.beatscratch_flutter_redux

import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.notifyCountInInitiated
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.notifyPaused
import io.beatscratch.beatscratch_flutter_redux.ScorePlayer.currentTick
import io.beatscratch.beatscratch_flutter_redux.ScorePlayer.playMetronome
import org.beatscratch.models.Music
import java.lang.System.currentTimeMillis

var PlaybackThread = PlaybackThreadInstance()

class PlaybackThreadInstance : Thread() {
  companion object {
    private const val subdivisionsPerBeat = 24 // This is the MIDI beat clock standard
  }

  var playing: Boolean = false
    set(value) {
      val wasPlaying = field;
      field = value
      if(value) {
        if(!wasPlaying) {
          MelodyRecorder.recordedData.clear()
        }
        try {
          synchronized(PlaybackThread) {
            (PlaybackThread as Object).notify()
          }
        } catch(t: Throwable) {
          logW("notify failed", t)
        }
      } else {
        AndroidMidi.sendAllNotesOff(immediately = true)
      }
    }
  var stopped: Boolean get() = !playing
    set(value) { playing = !value }
  var terminated = false
  var bpm: Float = 123f
  
  override fun run() {
    while (!terminated) {
      try {
        if (!stopped) {
          val start = currentTimeMillis()
          val tickTime: Long = (60000L / (bpm * subdivisionsPerBeat)).toLong()
//          logV("Tick @${ScorePlayer.currentTick} (T:${currentTimeMillis()}")
          ScorePlayer.tick()
          while(currentTimeMillis() < start + tickTime) {
            sleep(1L)
          }
        } else {
//          BeatClockPaletteConsumer.viewModel?.editModeToolbar?.playButton?.imageResource = R.drawable.icons8_play_100
//          ScorePlayer.clearActiveAttacks()
          AndroidMidi.flushSendStream()
          synchronized(PlaybackThread) {
            (PlaybackThread as Object).wait()
          }
          //Thread.sleep(10)
        }
      } catch (t: Throwable) {
        logE( "Error during background playback", t)
      }
    }
  }

  private var beatMinus2: Long? = null
  fun sendBeat() {
    val time = currentTimeMillis()
    if (playing) {
      playing = false
      notifyPaused()
    } else if (beatMinus2 != null && time - beatMinus2!! < 3000) {
      val periodMs = (time - beatMinus2!!).toFloat()
      bpm = 60000/ periodMs
      beatMinus2 = null
      currentTick = -24
      playing = true
    } else {
      playMetronome(immediately = true)
      notifyCountInInitiated()
      beatMinus2 = time
    }
  }

  private inline fun tryWithRetries(maxAttempts: Int = 1, action: () -> Unit) {
    var attempts = 0
    while (attempts++ < maxAttempts) {
      try {
        action()
        return
      } catch (t: Throwable) {
        continue
      }
    }
  }
}