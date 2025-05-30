package fluidsynth

import android.content.Context
import android.media.AudioManager
import android.media.midi.MidiReceiver
import io.beatscratch.beatscratch_flutter_redux.AndroidMidi
import io.beatscratch.beatscratch_flutter_redux.hardware.MidiDevices
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okio.buffer
import okio.sink
import okio.source
import java.io.File
import java.net.URL
import kotlin.concurrent.thread
import kotlin.coroutines.CoroutineContext


class FluidSynthMidiReceiver(
  val context: Context
) : MidiReceiver() {
  val nativeLibJNI: FluidSynthJNI = FluidSynthJNI()
  val sf2file = File(context.soundfontDir, sf2FileName)
  val sf3file = File(context.soundfontDir, sf3FileName)

  companion object {
    val sf2FileName = "FluidR3_GM.sf2"
    val sf2FileUrl = "https://www.dropbox.com/s/qjo60tvp2vi98md/FluidR3_GM.sf2?dl=1"
    val sf3FileName = "FluidR3Mono_GM (included).sf3"
    val baseSoundfontDir = "soundfonts"
    val Context.soundfontDir: String get() = "$filesDir${File.separator}$baseSoundfontDir"
    internal fun Byte.toUnsigned() = if (this < 0) 256 + this else this.toInt()
  }

  init {
    if (!sf2file.exists() || sf2file.length() == 0L) {
      copySF3IfNecessary()
      setupSoundFont(sf3file)
      // Auto-download the included SoundFont in SF2 format, to improve FluidSynth performance.
//      thread(start = true) {
//        try {
//          URL(sf2FileUrl).openStream().source().use { source ->
//            sf2file.sink().buffer().use { bufferedSink ->
//              bufferedSink.writeAll(source)
//            }
//          }
//          AndroidMidi.resetFluidSynth()
//        } catch(t: Throwable) {}
//      }
    } else {
      setupSoundFont(sf2file)
    }
  }

  private fun setupSoundFont(file: File) {
    val myAudioMgr = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    val sampleRateStr = myAudioMgr.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)
    val sampleRate = Integer.parseInt(sampleRateStr)
    val framesPerBurstStr = myAudioMgr.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER)
    val periodSize = Integer.parseInt(framesPerBurstStr)

    nativeLibJNI.init(sampleRate, periodSize)
    val soundFontId = nativeLibJNI.addSoundFont(file.absolutePath)
    for (channel in 0..15) {
      nativeLibJNI.selectSoundFont(channel, soundFontId)
    }
  }

  private fun copySF3IfNecessary() {
    if (sf3file.exists() && sf3file.length() > 0) return
    File(context.soundfontDir).mkdirs()
    val file = context.assets.open("soundfont/$sf3FileName")
    file.source().use { source ->
      sf3file.sink().buffer().use { bufferedSink ->
        bufferedSink.writeAll(source)
      }
    }
  }

  override fun onSend(msg: ByteArray?, offset: Int, count: Int, timestamp: Long) {
    // FIXME: consider timestamp
    val startTime = System.nanoTime()
    if (msg == null)
      throw IllegalArgumentException("null msg")
    var off = offset
    var c = count
    var runningStatus = 0
    while (c > 0) {
      var stat = msg[off].toUnsigned()
      if (stat < 0x80) {
        stat = runningStatus
      } else {
        off++
        c--
      }
      runningStatus = stat
      val ch = stat and 0x0F
      when (stat and 0xF0) {
        0x80 -> nativeLibJNI.noteOff(ch, msg[off].toUnsigned())
        0x90 -> {
          if (msg[off + 1].toInt() == 0)
            nativeLibJNI.noteOff(ch, msg[off].toUnsigned())
          else
            nativeLibJNI.noteOn(ch, msg[off].toUnsigned(), msg[off + 1].toUnsigned())
        }
        0xA0 -> {
          // No PAf in fluidsynth?
        }
        0xB0 -> nativeLibJNI.controlChange(ch, msg[off].toUnsigned(), msg[off + 1].toUnsigned())
        0xC0 -> nativeLibJNI.programChange(ch, msg[off].toUnsigned())
//                0xD0 -> syn.channelPressure(ch, msg[off].toUnsigned())
//                0xE0 -> syn.pitchBend(ch, msg[off].toUnsigned() + msg[off + 1].toUnsigned() * 0x80)
//                0xF0 -> syn.sysex(msg.copyOfRange(off, off + c - 1), null)
      }
      when (stat and 0xF0) {
        0xC0, 0xD0 -> {
          off++
          c--
        }
        0xF0       -> {
          off += c - 1
          c = 0
        }
        else       -> {
          off += 2
          c -= 2
        }
      }
    }
  }
}
