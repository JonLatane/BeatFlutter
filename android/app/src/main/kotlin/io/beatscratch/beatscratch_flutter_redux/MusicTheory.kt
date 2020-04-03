package io.beatscratch.beatscratch_flutter_redux

import android.nfc.FormatException
import org.beatscratch.models.Music
import org.beatscratch.models.Music.*


fun MelodyReference.melodyFrom(score: Music.Score): Music.Melody = score.partsList.first { part ->
  part.melodiesList.any { melody -> melody.id == this.melodyId }
}.melodiesList.first { melody -> melody.id == this.melodyId }


fun Harmony.changeBefore(initialSubdivision: Int): Music.Chord  {
    var subdivision: Int = initialSubdivision
    var result: Music.Chord? = dataMap.getOrDefault(subdivision, null)
    while (result == null) {
      subdivision -= 1
      if (subdivision < 0) {
        subdivision += length
      }
      result = dataMap.getOrDefault(subdivision, null)
    }
    return result;

}

val NoteLetter.tone: Int get() {
  return when (this) {
    NoteLetter.C -> {
      0
    }
    NoteLetter.D -> {
      2
    }
    NoteLetter.E -> {
      4
    }
    NoteLetter.F -> {
      5
    }
    NoteLetter.G -> {
      7
    }
    NoteLetter.A -> {
      9
    }
    NoteLetter.B -> {
      11
    }
    else         -> {
      throw FormatException()
    }
  }
}

val Int.mod12 get() = ((this % 12) + 12) % 12
val Int.mod12Nearest get(): Int = mod12.let {
  when {
    it <= 6 -> it
    else -> it - 12
  }
}

val NoteSign.toneOffset: Int get() {
  return when (this) {
    NoteSign.natural      -> 0
    NoteSign.sharp        -> 1
    NoteSign.flat         -> -1
    NoteSign.double_sharp -> 2
    NoteSign.double_flat  -> -2
    else                  -> throw FormatException()
  }
}


val NoteName.tone: Int get() = noteLetter.tone + noteSign.toneOffset

val NoteName.mod12: Int get() = tone.mod12

fun Melody.offsetUnder(chord: Chord) = when {
  interpretationType != MelodyInterpretationType.fixed_nonadaptive && interpretationType != MelodyInterpretationType.fixed_nonadaptive -> {
    chord.rootNote.mod12.let { root ->
      when {
        root > 6 -> root - 12
        else     -> root
      }
    }
  }
  else                                                                  -> 0
}

fun Int.playbackToneUnder(chord: Chord, melody: Melody): Int {
  return if (melody.interpretationType !== MelodyInterpretationType.fixed_nonadaptive) {
    val transposedTone: Int = this + melody.offsetUnder(chord)
    chord.closestTone(transposedTone)
  } else {
    this
  }
}

fun Chord.containsTone(tone: Int): Boolean {
  var tone = tone
  tone = tone.mod12
  val root: Int = rootNote.tone
  if (root == tone) {
    return true
  }
  val difference = (tone - root).mod12 - 1
  return chroma shr difference and 0x0001 == 1
}

fun Chord.closestTone(tone: Int): Int {
  var result: Int? = null
  (0..11).forEach { i ->
    if (result == null) {
      if (containsTone(tone - i)) {
        result = tone - i
      }
      if (containsTone(tone + i)) {
        result = tone + i
      }
    }
  }
//    print("closest to $tone for ${this.toString().replaceAll("\n", "")} is $result");
  return result ?: rootNote.tone
}
