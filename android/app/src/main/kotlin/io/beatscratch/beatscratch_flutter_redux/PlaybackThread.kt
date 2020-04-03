package io.beatscratch.beatscratch_flutter_redux


internal class PlaybackThread : Thread() {
  companion object {
    private const val subdivisionsPerBeat = 24 // This is the MIDI beat clock standard
  }

  var stopped = true
  var terminated = false
  var bpm: Float = 123f
  
  override fun run() {
    while (!terminated) {
      try {
        if (!stopped) {
          val start = System.currentTimeMillis()
          val tickTime: Long = (60000L / (bpm * subdivisionsPerBeat)).toLong()
          logV("Tick @${BeatClockScoreConsumer.tickPosition} (T:${System.currentTimeMillis()}")
          BeatClockScoreConsumer.tick()
          while(System.currentTimeMillis() < start + tickTime) {
            sleep(1L)
          }
        } else {
//          BeatClockPaletteConsumer.viewModel?.editModeToolbar?.playButton?.imageResource = R.drawable.icons8_play_100
          BeatClockScoreConsumer.clearActiveAttacks()
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