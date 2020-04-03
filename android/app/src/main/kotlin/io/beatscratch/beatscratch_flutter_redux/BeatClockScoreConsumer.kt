package io.beatscratch.beatscratch_flutter_redux

import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.Companion.currentScore
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.Companion.currentSection
import io.multifunctions.letCheckNull
import kotlinx.io.pool.DefaultPool
import org.beatscratch.models.Music
import java.util.*

/**
 * A platform-agnostic model for a playback thread that plays back [Section],
 * [Melody] and [Harmony] data as the end-user would expect.
 */
object BeatClockScoreConsumer : Patterns {
  enum class PlaybackMode { SECTION, PALETTE }
  var playbackMode = PlaybackMode.PALETTE
  private var chord: Music.Chord? = null
  val harmony: Music.Harmony? get() = currentSection?.harmony
  private val harmonyPosition: Int?
    get() = harmony?.let { tickPosition.convertSubdivisionPosition(ticksPerBeat, it) }
  private val harmonyChord: Music.Chord?
    get() = (harmony to harmonyPosition).letCheckNull { harmony, harmonyPosition ->
      harmony.changeBefore(harmonyPosition)
    }
  var tickPosition: Int = 0 // Always relative to ticksPerBeat
  const val ticksPerBeat = 24 // MIDI standard is pretty clear about this

  private data class Attack(
    var part: Music.Part? = null,
    var instrument: Music.Instrument? = null,
    var melody: Music.Melody? = null,
    var chosenTones: MutableList<Int> = Vector(16),
    var velocity: Float = 1f
  )

  private val attackPool: DefaultPool<Attack> = object : DefaultPool<Attack>(16) {
    override fun produceInstance() = Attack()
    override fun clearInstance(instance: Attack): Attack = instance.apply { chosenTones.clear() }
  }
  private val activeAttacks = Vector<Attack>(16)
  private val outgoingAttacks = Vector<Attack>(16)
  private val upcomingAttacks = Vector<Attack>(16)

  private fun loadUpcomingAttacks(palette: Music.Score, section: Music.Section) {
//    chord = (harmonyChord ?: chord)?.also { chord ->
//      doAsync {
//        viewModel?.apply {
//          if (
//            !harmonyViewModel.isChoosingHarmonyChord && chord != orbifold.chord
//          ) {
//            orbifold.disableNextTransitionAnimation()
//            //viewModel?.orbifold?.prepareAnimationTo(chord)
//            uiThread {
//              orbifold.chord = chord
//            }
//          }
//        }
//      }
//    }
    logV("Harmony index: $harmonyPosition; Chord: $chord")
    palette.partsList.map { part: Music.Part ->
      section.melodiesList.filter { reference: Music.MelodyReference ->
        reference.playbackType != Music.MelodyReference.PlaybackType.disabled
          && part.melodiesList.any { it.id == reference.melodyId }
      }.forEach { melodyReference: Music.MelodyReference ->
        val melody = melodyReference.melodyFrom(palette)
        (melody as? Music.Melody)
          ?.attackForCurrentTickPosition(part, chord, melodyReference.volume)?.let {
            upcomingAttacks += it
          }
      }
    }
  }

  private fun cleanUpExpiredAttacks() {
    activeAttacks.forEach { attack ->
      val attackCameFromRunningMelody = currentSection?.melodiesList
        ?.filter { it.playbackType != Music.MelodyReference.PlaybackType.disabled }
        ?.map { ref -> currentScore?.let { ref.melodyFrom(it) } }
        ?.contains(attack.melody) ?: false
      if (!attackCameFromRunningMelody) {
        //info("stopping active attack $attack")
        outgoingAttacks.add(attack)
      }
    }
    outgoingAttacks.forEach { attack ->
      destroyAttack(attack)
    }
    outgoingAttacks.clear()
  }

  private val _activeAttacksCopy = Vector<Attack>()
  private fun Music.Melody.stopCurrentAttacks() {
    _activeAttacksCopy.clear()
    _activeAttacksCopy.addAll(activeAttacks)
    for (activeAttack in _activeAttacksCopy) {
      if (activeAttack.melody == this) {
        //verbose { "Ending attack $activeAttack" }
        destroyAttack(activeAttack)
        break
      }
    }
  }

  private fun getNextSection(): Music.Section {
    var isNextSection = false
    var nextSection: Music.Section? = null
    loop@ for(candidate in currentScore!!.sectionsList) {
      when {
        candidate === currentSection -> isNextSection = true
        isNextSection                -> { nextSection = candidate; break@loop }
      }
    }
    return nextSection ?: currentScore!!.sectionsList.first()
  }

  fun tick() {
    (currentScore to currentSection).letCheckNull { palette: Music.Score, section: Music.Section ->
      val totalBeats = harmony?.let { it.length.toFloat() / it.subdivisionsPerBeat } ?: 0f
      loadUpcomingAttacks(palette, section)
      cleanUpExpiredAttacks()
      for (attack in upcomingAttacks) {
        val instrument = attack.instrument!!
        attack.melody?.stopCurrentAttacks()

        // And play the new notes

        logI("Executing attack $attack")

        attack.chosenTones.forEach { tone ->
          instrument.play(tone, attack.velocity.to127Int)
        }
        activeAttacks += attack
      }
      if ((tickPosition + 1) / ticksPerBeat >= totalBeats) {
        if(playbackMode == PlaybackMode.PALETTE) {
          val nextSection = getNextSection()
          tickPosition = 0
          currentSection = nextSection
        } else {
          tickPosition = 0
        }
      } else {
        tickPosition += 1
      }
    } ?: logW("Tick called with no Palette available")

    upcomingAttacks.clear()

    AndroidMidi.flushSendStream()
//    viewModel?.harmonyView?.post { viewModel?.playbackTick = tickPosition }
  }

  internal fun clearActiveAttacks() {
    for (activeAttack in listOf(*activeAttacks.toArray(arrayOf<Attack>()))) {
      destroyAttack(activeAttack)
    }
  }

  @Synchronized
  private fun destroyAttack(attack: Attack) {
    attack.chosenTones.forEach { tone ->
      attack.instrument!!.stop(tone)
    }
    attackPool.recycle(attack)
    activeAttacks.remove(attack)
  }

  //private fun Melody<*>.

  /**
   * Based on the current [tickPosition], populates the passed [Attack] object.
   * Returns true if the attack should be played.
   */
  private fun Music.Melody.attackForCurrentTickPosition(
    part: Music.Part,
    chord: Music.Chord?,
    volume: Float
  ): Attack? {
    return Base24ConversionMap[subdivisionsPerBeat]?.indexOf(tickPosition % ticksPerBeat)?.takeIf { it >=0 }?.let { correspondingPosition ->
      val currentBeat = tickPosition / ticksPerBeat
      val melodyPosition = currentBeat * subdivisionsPerBeat + correspondingPosition
      val attack = attackPool.borrow()
      when {
//        isChangeAt(melodyPosition % length) -> {
//          val change = changeBefore(melodyPosition % length)
//          attack.part = part
//          attack.instrument = part.instrument
//          attack.melody = this
//          attack.velocity = change.velocity * volume
//
//          change.tones.forEach { tone ->
//            val playbackTone = chord?.let { chord -> tone.playbackToneUnder(chord, this) } ?: tone
//            attack.chosenTones.add(playbackTone)
//          }
//          logI("creating attack for melody=${this.hashCode()} tick=$tickPosition correspondingPosition=$correspondingPosition subdivision=$melodyPosition/$subdivisionsPerBeat beat=$currentBeat with tones ${attack.chosenTones}")
//          attack
//        }
        else                                       -> null
      }
    }
  }
}
