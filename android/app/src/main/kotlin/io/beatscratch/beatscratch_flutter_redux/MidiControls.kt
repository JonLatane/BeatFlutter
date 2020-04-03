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

fun Music.Instrument.play(tone: Int, velocity: Int) {// Construct a note ON message for the middle C at maximum velocity on channel 1:
  //sendSelectInstrument(instrument)
  byte3[0] = MidiConstants.NOTE_ON or channel  // STATUS byte: note On, 0x00 = channel 1
  byte3[1] = (tone + 60).toByte() // DATA byte: middle C = 60
  byte3[2] = velocity.toByte()  // DATA byte: maximum velocity = 127

  // Send the MIDI byte3 to the synthesizer.
  sendToStream(byte3)
  tones.add(tone)
}

fun Music.Instrument.play(tone: Int) {// Construct a note ON message for the middle C at maximum velocity on channel 1:
  play(tone, MidiConstants.DEFAULT_VELOCITY)
}

fun Music.Instrument.stop() {
  while(tones.isNotEmpty()) {
    val tone = tones.removeAt(0)
    doStop(tone)
  }
}

fun Music.Instrument.stop(tone: Int) {
  doStop(tone)
  tones.remove(tone)
}

private fun Music.Instrument.doStop(tone: Int) {
  // Construct a note OFF message for the middle C at minimum velocity on channel 1:
  byte3[0] = (MidiConstants.NOTE_OFF or channel)  // STATUS byte: 0x80 = note Off, 0x00 = channel 1
  byte3[1] = (tone + 60).toByte()  // 0x3C = middle C
  byte3[2] = 0x00.toByte()  // 0x00 = the minimum velocity (0)

  // Send the MIDI byte3 to the synthesizer.
  sendToStream(byte3)
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