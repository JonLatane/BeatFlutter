package io.beatscratch.beatscratch_flutter_redux

import org.beatscratch.models.Music
import kotlin.math.floor

interface Patterns {
  companion object : Patterns

  fun Int.convertPatternIndex(
    fromMelody: Music.Melody,
    toMelody: Music.Melody
  ): Int = convertPatternIndex(
    fromSubdivisionsPerBeat = fromMelody.subdivisionsPerBeat,
    toSubdivisionsPerBeat = toMelody.subdivisionsPerBeat
  )

  fun Int.convertPatternIndex(
    fromMelody: Music.Melody,
    toHarmony: Music.Harmony
  ): Int = convertPatternIndex(
    fromSubdivisionsPerBeat = fromMelody.subdivisionsPerBeat,
    toSubdivisionsPerBeat = toHarmony.subdivisionsPerBeat
  )

  fun Int.convertPatternIndex(
    fromHarmony: Music.Harmony,
    toMelody: Music.Melody
  ): Int = convertPatternIndex(
    fromSubdivisionsPerBeat = fromHarmony.subdivisionsPerBeat,
    toSubdivisionsPerBeat = toMelody.subdivisionsPerBeat
  )

  fun Int.convertPatternIndex(
    fromHarmony: Music.Harmony,
    toHarmony: Music.Harmony
  ): Int = convertPatternIndex(
    fromSubdivisionsPerBeat = fromHarmony.subdivisionsPerBeat,
    toSubdivisionsPerBeat = toHarmony.subdivisionsPerBeat
  )

  fun Int.convertPatternIndex(
    fromSubdivisionsPerBeat: Int,
    toMelody: Music.Melody
  ): Int = convertPatternIndex(
    fromSubdivisionsPerBeat = fromSubdivisionsPerBeat,
    toSubdivisionsPerBeat = toMelody.subdivisionsPerBeat,
    toLength = toMelody.length
  )

  fun Int.convertPatternIndex(
    fromSubdivisionsPerBeat: Int,
    toHarmony: Music.Harmony
  ): Int = convertPatternIndex(
    fromSubdivisionsPerBeat = fromSubdivisionsPerBeat,
    toSubdivisionsPerBeat = toHarmony.subdivisionsPerBeat,
    toLength = toHarmony.length
  )

  fun Int.convertPatternIndex(
    fromSubdivisionsPerBeat: Int,
    toSubdivisionsPerBeat: Int,
    toLength: Int = Int.MAX_VALUE
  ): Int {
    // In the storageContext of the "from" melody, in, say, sixteenth notes (subdivisionsPerBeat=4),
    // if this is 5, then currentBeat is 1.25.
    val fromBeat: Double = this.toDouble() / fromSubdivisionsPerBeat

    val toLengthBeats: Double = toLength.toDouble() / toSubdivisionsPerBeat
    val positionInToPattern: Double = fromBeat % toLengthBeats

    // This candidate for attack is the closest element index to the current tick
    val result = floor(positionInToPattern * toSubdivisionsPerBeat).toInt()
    return result
  }
}