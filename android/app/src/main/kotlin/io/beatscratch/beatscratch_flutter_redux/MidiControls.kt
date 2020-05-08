package io.beatscratch.beatscratch_flutter_redux

import io.beatscratch.beatscratch_flutter_redux.AndroidMidi.sendToStream
import org.beatscratch.models.Music
import kotlin.experimental.or


val Music.Instrument.drumTrack: Boolean get() = type == Music.InstrumentType.drum
val Music.Instrument.channel: Byte get() = midiChannel.toByte()
private val channelToneMap = mutableMapOf<Int, MutableList<Int>>()
val Music.Instrument.tones: MutableList<Int> get() = channelToneMap
  .computeIfAbsent(midiChannel) { mutableListOf() }
val byte2 = ByteArray(2)
val byte3 = ByteArray(3)

fun Music.Instrument.play(tone: Int, velocity: Int = MidiConstants.DEFAULT_VELOCITY, immediately: Boolean = false, record: Boolean = false) {// Construct a note ON message for the middle C at maximum velocity on channel 1:
  //sendSelectInstrument(instrument)
  AndroidMidi.playNote((tone + 60).toByte(), velocity.toByte(), channel, immediately, record)
  tones.add(tone)
}

fun Music.Instrument.stop(tone: Int, immediately: Boolean = false, record: Boolean = false) {
  AndroidMidi.stopNote((tone + 60).toByte(), channel, immediately, record)
  tones.remove(tone)
}

fun Music.Instrument.sendSelectInstrument() {
  // Write Bank MSB Control Change
  val msb = midiGm2Msb.toByte() ?: if (drumTrack) 120.toByte() else null
  if (msb != null) {
    byte3[0] = (MidiConstants.CONTROL_CHANGE or channel)
    byte3[1] = MidiConstants.CONTROL_MSB
    byte3[2] = msb
    sendToStream(byte3)
  }

  // Write Bank LSB Control Change
  val lsb = midiGm2Lsb.toByte() ?: if (drumTrack) 0.toByte() else null
  if (lsb != null) {
    byte3[0] = (MidiConstants.CONTROL_CHANGE or channel)
    byte3[1] = MidiConstants.CONTROL_LSB
    byte3[2] = lsb
    sendToStream(byte3)
  }

  // Then send Program Change
  byte2[0] = (MidiConstants.PROGRAM_CHANGE or channel)  // STATUS byte: Change, 0x00 = channel 1
  byte2[1] = if (drumTrack) 0 else midiInstrument.toByte()
  sendToStream(byte2)

  byte3[0] = (MidiConstants.CONTROL_CHANGE or channel)
  byte3[1] = MidiConstants.CONTROL_VOLUME
  byte3[2] = (volume * 127).toByte()
  sendToStream(byte3)
}