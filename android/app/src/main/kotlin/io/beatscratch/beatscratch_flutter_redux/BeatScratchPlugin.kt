package io.beatscratch.beatscratch_flutter_redux

import android.content.Intent
import android.os.Handler
import io.beatscratch.beatscratch_flutter_redux.AndroidMidi.sendAllNotesOff
import io.beatscratch.beatscratch_flutter_redux.MelodyRecorder.recordingMelody
import io.beatscratch.beatscratch_flutter_redux.MelodyRecorder.recordingMelodyId
import io.beatscratch.beatscratch_flutter_redux.ScorePlayer.currentTick
import io.beatscratch.beatscratch_flutter_redux.ScorePlayer.metronomeEnabled
import io.beatscratch.beatscratch_flutter_redux.ScorePlayer.playbackMode
import io.beatscratch.beatscratch_flutter_redux.ScorePlayer.ticksPerBeat
import io.beatscratch.beatscratch_flutter_redux.hardware.MidiControllers
import io.beatscratch.beatscratch_flutter_redux.hardware.MidiDevices
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.multifunctions.letCheckNull
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.beatscratch.commands.ProtobeatsPlugin.*
import org.beatscratch.models.Music.*
import kotlin.coroutines.CoroutineContext

object BeatScratchPlugin : MethodChannel.MethodCallHandler, CoroutineScope {
  var handler: Handler? = null
  var methodChannel: MethodChannel? = null
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
  private var currentSectionId: String? = null
  var currentSection: Section?
    get() = currentScore?.sectionsList?.firstOrNull { it.id == currentSectionId }
    set(value) {
      currentSectionId = value?.id
    }
  var tickPosition: Int = 0
  var keyboardPart: Part? = null
  var colorboardPart: Part? = null

  private var newMelodies = mutableListOf<Melody>()

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "sendMIDI"                              -> {
        AndroidMidi.sendImmediately(call.arguments as ByteArray, record = true)
        result.success(null)
      }
      "createScore", "updateSections"         -> {
        try {
          val score: Score = Score.parseFrom(call.arguments as ByteArray)
          currentSection = score.sectionsList.firstOrNull { it.id == currentSection?.id }
            ?: score.sectionsList[0]
          if (call.method == "createScore") {
            currentScore = score
          } else if (call.method == "updateSections") {
            currentScore = currentScore?.let {
              Score.newBuilder(it)
                .clearSections()
                .addAllSections(score.sectionsList)
                .build()
            }
          }
          result.success(null)
        } catch (e: Throwable) {
          logE("Failed to deserialize score", e)
          result.error("deserialize", "Failed to deserialize score", e)
        }
      }
      "createPart", "updatePartConfiguration" -> {
        try {
          val part: Part = Part.parseFrom(call.arguments as ByteArray)
          part.instrument.sendSelectInstrument()
          AndroidMidi.flushSendStream()
          if (call.method == "updatePartConfiguration") {
            currentScore?.partsList?.firstOrNull { it.id == part.id }?.let { oldPart ->
              val updatedPart = Part.newBuilder(part)
                .addAllMelodies(oldPart.melodiesList)
                .build()
              updatePart(updatedPart)
              if (keyboardPart?.id == part.id) {
                keyboardPart = part
              }
              result.success(null)
            } ?: result.error("500", "Part does not exist", "nope")
          } else {
            currentScore = currentScore?.let {
              Score.newBuilder(it)
                .addParts(part)
                .build()
            }
            result.success(null)
          }
        } catch (e: Throwable) {
          logE("Failed to deserialize part", e)
          result.error("deserialize", "Failed to deserialize part", e)
        }
      }
      "deletePart"                            -> {
        try {
          val partId = call.arguments as String
          currentScore?.let { score: Score ->
            score.partsList.firstOrNull { it.id == partId }?.let { part ->
              val partIndex = score.partsList.indexOfFirst { it.id == part.id }
              currentScore = currentScore?.let {
                Score.newBuilder(it)
                  .removeParts(partIndex)
                  .build()
              }
            }
          }
          result.success(null)
        } catch (e: Exception) {
          result.error("Cannot serialize data", null, e)
        }
      }
      "newMelody"                             -> {
        val melody: Melody = Melody.parseFrom(call.arguments as ByteArray)
        newMelodies.add(melody)
        result.success(null)
      }
      "registerMelody"                        -> {
        val registerMelody = RegisterMelody.parseFrom(call.arguments as ByteArray)
        newMelodies.firstOrNull { it.id == registerMelody.melodyId }?.let { melody ->
          currentScore?.partsList?.firstOrNull { it.id == registerMelody.partId }?.let { part ->
            val updatedPart = Part.newBuilder(part)
              .addMelodies(melody)
              .build()
            updatePart(updatedPart)
            result.success(null)
          } ?: result.error("500", "Part does not exist", "nope")
        } ?: result.error("500", "Melody must be added first", "nope")
      }
      "updateMelody"                          -> {
        val melody: Melody = Melody.parseFrom(call.arguments as ByteArray)
        if (updateMelody(melody)) {
          result.success(null)
        } else {
          result.error("500", "Part does not exist", "nope")
        }
      }
      "deleteMelody"                          -> {
        val melodyId = call.arguments as String
        currentScore?.partFor(melodyId)?.let { part ->
          val melodyIndex = part.melodiesList.indexOfFirst { it.id == melodyId }
          val updatedPart = Part.newBuilder(part)
            .removeMelodies(melodyIndex)
            .build()
          updatePart(updatedPart)
        } ?: result.error("500", "Part does not exist", "nope")
      }
      "setKeyboardPart"                       -> {
        val partId = call.arguments as String
        currentScore?.partsList?.first { it.id == partId }?.let { part ->
          keyboardPart = part
        }
        result.success(null)
      }
      "checkSynthesizerStatus"                -> {
        result.success(AndroidMidi.isMidiReady)
      }
      "resetAudioSystem"                      -> {
        launch {
          AndroidMidi.resetFluidSynth()
        }
        result.success(null)
      }
      "play"                                  -> {
        val intent = Intent(MainApplication.instance, PlaybackService::class.java)
        intent.action = PlaybackService.Companion.Action.PLAY_ACTION
        MainApplication.instance.startService(intent)
        result.success(null)
      }
      "pause"                                 -> {
        val intent = Intent(MainApplication.instance, PlaybackService::class.java)
        intent.action = PlaybackService.Companion.Action.PAUSE_ACTION
        MainApplication.instance.startService(intent)
        result.success(null)
      }
      "stop"                                  -> {
        val intent = Intent(MainApplication.instance, PlaybackService::class.java)
        intent.action = PlaybackService.Companion.Action.PAUSE_ACTION
        MainApplication.instance.startService(intent)
        result.success(null)
        currentTick = 0
      }
      "setBeat"                               -> {
        val beat = call.arguments as Int
        sendAllNotesOff(immediately = true)
        currentTick = beat * ticksPerBeat
        result.success(null)
      }
      "setCurrentSection"                     -> {
        val sectionId = call.arguments as String
        currentScore?.sectionsList?.firstOrNull { it.id == sectionId }?.let { section ->
//          sendAllNotesOff(immediately = true)
          currentSection = section
          result.success(null)
          ScorePlayer.clearNonSectionActiveAttacks()
          launch {
            PlaybackService.instance?.showNotification()
          }
        } ?: result.error("500", "Section not found", "nope")
      }
      "countIn"                               -> {
        val beat = call.arguments as Int
        PlaybackThread.sendBeat()
        result.success(null)
      }
      "tickBeat"                              -> {
        PlaybackThread.sendBeat()
        result.success(null)
      }
      "setPlaybackMode"                       -> {
        val playback: Playback = Playback.parseFrom(call.arguments as ByteArray)
        playbackMode = playback.mode
        result.success(null)
      }
      "setRecordingMelody"                    -> {
        val melodyId = call.arguments as String?
        recordingMelodyId = melodyId
        result.success(null)
      }
      "setMetronomeEnabled"                   -> {
        val enabled = call.arguments as Boolean
        metronomeEnabled = enabled
        result.success(null)
      }
      else                                    -> result.notImplemented()
    }
  }

  fun updatePart(updatedPart: Part): Boolean {
    currentScore?.let { score: Score ->
      score.partsList.firstOrNull { it.id == updatedPart.id }?.let { part ->
        val partIndex = score.partsList.indexOfFirst { it.id == part.id }
        currentScore = currentScore?.let {
          Score.newBuilder(it)
            .removeParts(partIndex)
            .addParts(updatedPart)
            .build()
        }
        return true
      }
    }
    return false
  }

  fun updateMelody(melody: Melody): Boolean {
    currentScore?.let { score: Score ->
      score.partsList.firstOrNull { it.melodiesList.any { it.id == melody.id } }?.let { part ->
        val melodyIndex = part.melodiesList.indexOfFirst { it.id == melody.id }
        val partIndex = score.partsList.indexOfFirst { it.id == part.id }
        currentScore = currentScore?.let {
          val updatedPart = Part.newBuilder(part)
            .removeMelodies(melodyIndex)
            .addMelodies(melody)
          Score.newBuilder(it)
            .removeParts(partIndex)
            .addParts(updatedPart)
            .build()
        }
        return true
      }
    }
    return false
  }

  fun sendPressedMidiNotes() {
    print("kotlin: sendPressedMidiNotes")
    val midiNotes: MidiNotes = MidiNotes.newBuilder()
      .addAllMidiNotes(MidiControllers.pressedNotes).build()
    handler?.post {
      methodChannel?.invokeMethod("sendPressedMidiNotes", midiNotes.toByteArray())
    }
  }

  fun sendRecordedMelody() {
    print("kotlin: sendPressedMidiNotes")
    recordingMelody?.let { recordingMelody ->
      handler?.post {
        methodChannel?.invokeMethod("sendRecordedMelody", recordingMelody.toByteArray())
      }
    }
  }

  fun setSynthesizerAvailable() {
    handler?.post {
      methodChannel?.invokeMethod("setSynthesizerAvailable", AndroidMidi.isMidiReady)
    }
  }

  fun notifyPlayingBeat() {
    handler?.post {
      val beat: Int = currentTick / ticksPerBeat
      methodChannel?.invokeMethod("notifyPlayingBeat", beat)
    }
  }

  fun notifyPaused() {
    handler?.post {
      methodChannel?.invokeMethod("notifyPaused", null)
    }
  }

  fun notifyCountInInitiated() {
    handler?.post {
      methodChannel?.invokeMethod("notifyCountInInitiated", null)
    }
  }

  fun notifyCurrentSection() {
    handler?.post {
      methodChannel?.invokeMethod("notifyCurrentSection", currentSection!!.id)
    }
  }

  override val coroutineContext: CoroutineContext = Dispatchers.Default
}