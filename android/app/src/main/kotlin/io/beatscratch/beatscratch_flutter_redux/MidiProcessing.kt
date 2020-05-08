package io.beatscratch.beatscratch_flutter_redux

import kotlin.experimental.and

interface MidiEvent {
  val eventByteCount: Int
  fun withChannelOverride(newChannel: Byte): MidiEvent
  fun withVelocityMultiplier(velocityMultiplier: Float): MidiEvent
  fun send(immediately: Boolean = false, record: Boolean = false)
}

data class NoteOnEvent(
  val midiNote: Byte,
  val velocity: Byte = 127,
  val channel: Byte = 0
): MidiEvent {
  override val eventByteCount get() = 3
  override fun withChannelOverride(newChannel: Byte) = NoteOnEvent(midiNote, velocity, newChannel)
  override fun withVelocityMultiplier(velocityMultiplier: Float) = NoteOnEvent(midiNote, (velocity * velocityMultiplier).toByte(), channel)
  override fun send(immediately: Boolean, record: Boolean) {
    AndroidMidi.playNote(midiNote, velocity, channel, immediately, record)
  }
}

data class NoteOffEvent(
  val midiNote: Byte,
  val velocity: Byte = 127,
  val channel: Byte = 0
): MidiEvent {
  override val eventByteCount get() = 3
  override fun withChannelOverride(newChannel: Byte) = NoteOffEvent(midiNote, velocity, newChannel)
  override fun withVelocityMultiplier(velocityMultiplier: Float) = NoteOffEvent(midiNote, (velocity * velocityMultiplier).toByte(), channel)
  override fun send(immediately: Boolean, record: Boolean) {
    AndroidMidi.stopNote(midiNote, channel, immediately, record)
  }
}

val ByteArray.midiEvents: Iterable<MidiEvent> get() {
  val result = mutableListOf<MidiEvent>()
  var index = 0
  while (index < size) {
    when {
      this[index] and 0xF0.toByte() == 0x90.toByte() -> { // noteOn
        val noteNumber = this[index + 1]
        val velocity = this[index + 2]
        val channel = this[index] and 0xF.toByte()
        result.add(NoteOnEvent(midiNote = noteNumber, velocity = velocity, channel = channel))
        index += 3
      }
      this[index] and 0xF0.toByte() == 0x80.toByte() -> { // noteOff
        val noteNumber = this[index + 1]
        val velocity = this[index + 2]
        val channel = this[index] and 0xF.toByte()
        result.add(NoteOffEvent(midiNote = noteNumber, velocity = velocity, channel = channel))

        index += 3
      }
      else -> {
        logW("Failed to match MIDI byte: ${this[index]}")
        index += 1
      }
    }
  }
  return result
}

val ByteArray.noteOns: Iterable<NoteOnEvent> get() = midiEvents.mapNotNull {
  it as? NoteOnEvent
}

val ByteArray.noteOffs: Iterable<NoteOffEvent> get() = midiEvents.mapNotNull {
  it as? NoteOffEvent
}