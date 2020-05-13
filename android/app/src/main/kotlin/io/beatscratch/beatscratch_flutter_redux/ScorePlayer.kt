package io.beatscratch.beatscratch_flutter_redux

import io.beatscratch.beatscratch_flutter_redux.AndroidMidi.playNote
import io.beatscratch.beatscratch_flutter_redux.AndroidMidi.stopNote
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.currentScore
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.currentSection
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.notifyCurrentSection
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.notifyPaused
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.notifyPlayingBeat
import io.beatscratch.beatscratch_flutter_redux.MelodyRecorder.recordBeat
import io.multifunctions.letCheckNull
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.beatscratch.commands.ProtobeatsPlugin.Playback
import org.beatscratch.models.Music.*
import org.beatscratch.models.Music.MelodyReference.PlaybackType
import kotlin.coroutines.CoroutineContext
import kotlin.math.floor

/**
 * A platform-agnostic model for a playback thread that plays back [Section],
 * [Melody] and [Harmony] data as the end-user would expect.
 */
object ScorePlayer : Patterns, CoroutineScope {
  var metronomeEnabled: Boolean = true
  var playbackMode: Playback.Mode = Playback.Mode.score
  private var chord: Chord = Chord.newBuilder()
    .setRootNote(NoteName.newBuilder().setNoteLetter(NoteLetter.C).build())
    .setChroma(2047)
    .build()
  var currentTick = 0
//  private val harmony: Harmony? get() = currentSection?.harmony
//  private val harmonyPosition: Int?
//    get() = harmony?.let { tickPosition.convertSubdivisionPosition(ticksPerBeat, it) }
//  private val harmonyChord: Chord?
//    get() = (harmony to harmonyPosition).letCheckNull { harmony, harmonyPosition ->
//      harmony.changeBefore(harmonyPosition)
//    }
//  var tickPosition: Int = 0 // Always relative to ticksPerBeat
  const val ticksPerBeat = 24 // MIDI standard is pretty clear about this

  fun tick() {
    (currentScore to currentSection).letCheckNull { score: Score, section: Section ->
      val harmony: Harmony = currentSection!!.harmony
      if (currentTick >= (ticksPerBeat * harmony.length / harmony.subdivisionsPerBeat)) {
        val sectionIndex = score.sectionsList.indexOfFirst { it.id == section.id }
        currentTick = 0
        if (playbackMode == Playback.Mode.score) {
          if (sectionIndex + 1 < score.sectionsCount) {
            currentSection = score.sectionsList[sectionIndex + 1]
            notifyCurrentSection()
            launch {
              PlaybackService.instance?.showNotification()
            }
          } else {
            currentSection = score.sectionsList[0]
            notifyPlayingBeat()
            PlaybackThread.playing = false
            notifyCurrentSection()
            launch {
              PlaybackService.instance?.showNotification()
            }
            notifyPaused()
            return
          }
        }
      }
      val beatMod = currentTick % ticksPerBeat
      if (beatMod == 0) {
        playMetronome()
        notifyPlayingBeat()
        recordBeat()
      }
      if (playbackMode == Playback.Mode.score) {
        doPreviousSectionNoteOffs()
      }
      doTick()
      currentTick++
    } ?: logW("Tick called with no Score available")
    AndroidMidi.flushSendStream()
  }

  fun playMetronome(immediately: Boolean = false) {
    if(metronomeEnabled) {
      playNote(75, 127, 9, immediately = immediately)
      stopNote(75, 9, immediately = immediately)
    }
  }

  private fun harmonyPosition(harmony: Harmony): Int
    = harmony.let { currentTick.convertSubdivisionPosition(ticksPerBeat, it) }


  private fun doTick() {
    (currentScore to currentSection).letCheckNull { score: Score, section: Section ->
      score.partsList.forEach { part ->
        section.melodiesList.filter { reference -> reference.playbackType != PlaybackType.disabled
          && part.melodiesList.any { it.id == reference.melodyId } }.forEach { melodyReference ->
          val melody = melodyReference.melodyFrom(score)
          handleCurrentTickPosition(melodyReference, melody, part)
        }
      }
    }
  }
  private fun doPreviousSectionNoteOffs() {
    (currentScore to currentSection).letCheckNull { score: Score, section: Section ->
      val sectionIndex = score.sectionsList.indexOfFirst { it.id == section.id }
      if (sectionIndex >= 1 && currentTick / 24 <= 4) {
        val previousSection = score.sectionsList[sectionIndex - 1]
        score.partsList.forEach { part ->
          previousSection.melodiesList.filter { reference -> reference.playbackType != PlaybackType.disabled
            && part.melodiesList.any { it.id == reference.melodyId } }.forEach { melodyReference ->
            val melody = melodyReference.melodyFrom(score)
            handleCurrentTickPosition(melodyReference, melody, part, playNoteOns = false)
          }
        }
      }
    }
  }

  private fun handleCurrentTickPosition(
    melodyReference: MelodyReference,
    melody: Melody,
    part: Part,
    playNoteOns: Boolean = true
  ) {
    val ticks = Base24ConversionMap[melody.subdivisionsPerBeat]!!
    val correspondingPosition = ticks.indexOfFirst { it == currentTick % ticksPerBeat }
    if(correspondingPosition >= 0) {
      val currentBeat = floor(currentTick.toDouble() / ticksPerBeat)
      val melodyPosition = currentBeat * melody.subdivisionsPerBeat.toDouble() +
        correspondingPosition
      melody.midiData.dataMap[melodyPosition.toInt() % melody.length]?.let {
        midiChange ->
        val bytes = midiChange.data.toByteArray()
        val events = if(playNoteOns) bytes.midiEvents else bytes.noteOffs
        events.forEach {
          it.withChannelOverride(part.instrument.midiChannel.toByte())
            .withVelocityMultiplier(melodyReference.volume)
            .send()
        }
      }
    }
  }

  override val coroutineContext: CoroutineContext
    get() = Dispatchers.Default
}
