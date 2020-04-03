package io.beatscratch.beatscratch_flutter_redux

import org.beatscratch.models.Music

fun Music.MelodyReference.melodyFrom(score: Music.Score): Music.Melody = score.partsList.first { part ->
  part.melodiesList.any { melody -> melody.id == this.melodyId }
}.melodiesList.first { melody -> melody.id == this.melodyId }