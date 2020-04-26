package io.beatscratch.beatscratch_flutter_redux

import android.os.Handler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.beatscratch.commands.ProtobeatsPlugin.MidiNotes
import org.beatscratch.models.Music
import org.beatscratch.models.Music.Part
import org.beatscratch.models.Music.Score
import kotlin.coroutines.CoroutineContext

object BeatScratchPlugin : MethodChannel.MethodCallHandler, CoroutineScope {
  var handler: Handler? = null
  var channel: MethodChannel? = null
  set(value) {
    field = value
    value?.setMethodCallHandler(this)
  }
  var currentScore: Score? = null
    set(value) {
      field = value
      MidiDevices.refreshInstruments()
      tickPosition = 0
    }
  var currentSection: Music.Section? = null
    set(value) {
      field = value
//    viewModel?.melodyView?.post {
//      viewModel?.notifySectionChange()
//    }
      //MidiDevices.refreshInstruments()
    }
  var tickPosition: Int = 0
  var keyboardPart: Part? = null
  var colorboardPart: Part? = null

  //TODO probs port to a new Midi-centric proto?
  enum class PlaybackMode { SECTION, PALETTE }

  var playbackMode = PlaybackMode.PALETTE

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "sendMIDI"               -> {
        logI("sendMIDI: Kotlin BeatScratchPlugin.onMethodCall")
        AndroidMidi.sendImmediately(call.arguments as ByteArray)
      }
      "pushScore"              -> {
        logI("pushScore: Kotlin BeatScratchPlugin.onMethodCall")
        try {
          val score: Score = Score.parseFrom(call.arguments as ByteArray)
          currentScore = score
          currentSection = score.sectionsList[0]
          logI("deserialized score successfully: $score")
        } catch (e: Throwable) {
          logE("Failed to deserialize score", e)
          result.error("deserialize", "Failed to deserialize score", e)
        }
      }
      "pushPart"               -> {
        logI("pushPart: Kotlin BeatScratchPlugin.onMethodCall")
        try {
          var part: Part = Part.parseFrom(call.arguments as ByteArray)
          logI("deserialized part successfully: $part")
          currentScore?.let { score ->
            val oldPartIndex = score.partsList.indexOfFirst { it.id == part.id }.takeIf { it >= 0 }
            val newScore = Score.newBuilder(score)
            if (oldPartIndex != null) {
              logI("updating existing Part at $oldPartIndex")
              val oldPart = score.partsList[oldPartIndex];
              part = Part.newBuilder(part)
                .addAllMelodies(oldPart.melodiesList)
                .build()
              newScore.removeParts(oldPartIndex)
            } else {
              logI("adding new Part")
            }
            newScore.addParts(part)
            currentScore = newScore.build()
            part.instrument.sendSelectInstrument()
            AndroidMidi.flushSendStream()
          }
        } catch (e: Throwable) {
          logE("Failed to deserialize part", e)
          result.error("deserialize", "Failed to deserialize part", e)
        }
      }
      "deletePart"             -> {
        try {
          val partId = call.arguments as String
          currentScore?.partsList?.removeIf { it.id == partId }
          result.success(null)
        } catch (e: Exception) {
          result.error("Cannot serialize data", null, e)
        }
      }
      "playNote"               -> {
        try {
          val args: List<Any> = call.arguments as List<Any>
          val tone = args[0] as Int
          val velocity = args[1] as Int
          val partId = args[2] as String
          val part: Part? = currentScore?.partsList?.first { it.id == partId }
          result.success(null)
        } catch (e: Exception) {
          result.error("Cannot serialize data", null, e)
        }
      }
      "setKeyboardPart"        -> {
        val partId = call.arguments as String
        currentScore?.partsList?.first { it.id == partId }?.let { part ->
          keyboardPart = part
        }
        result.success(null)
      }
      "checkSynthesizerStatus" -> {
        result.success(AndroidMidi.isMidiReady)
      }
      "resetAudioSystem"       -> {
        launch {
          AndroidMidi.resetFluidSynth()
        }
        result.success(null)
      }
      else                     -> result.notImplemented()
    }
  }

  fun sendPressedMidiNotes() {
    print("kotlin: sendPressedMidiNotes")
    val midiNotes: MidiNotes = MidiNotes.newBuilder()
      .addAllMidiNotes(MidiControllers.pressedNotes).build()
    handler?.post {
      channel?.invokeMethod("sendPressedMidiNotes", midiNotes.toByteArray())
    }
  }

  fun setSynthesizerAvailable() {
    handler?.post {
      channel?.invokeMethod("setSynthesizerAvailable", AndroidMidi.isMidiReady)
    }
  }

  override val coroutineContext: CoroutineContext = Dispatchers.Default
}