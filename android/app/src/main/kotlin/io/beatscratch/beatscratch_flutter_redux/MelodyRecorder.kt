package io.beatscratch.beatscratch_flutter_redux

import com.google.protobuf.ByteString
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.sendRecordedMelody
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.updateMelody
import io.beatscratch.beatscratch_flutter_redux.ScorePlayer.currentTick
import io.beatscratch.beatscratch_flutter_redux.ScorePlayer.ticksPerBeat
import org.beatscratch.models.Music.*
import java.lang.System.currentTimeMillis
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.round

//TODO
object MelodyRecorder {
  var recordingMelodyId: String? = null
  var recordingMelody: Melody?
    get() = BeatScratchPlugin.currentScore?.partsList
      ?.firstOrNull { part -> part.melodiesList.any { it.id == recordingMelodyId } }
      ?.melodiesList?.firstOrNull { it.id == recordingMelodyId }
    private set(value) {
      if(value != null) {
        updateMelody(value)
      }
    }
  private var recordingBeat: Int? = null
  private var beatStartTime: Long? = null
  private var recordedData = mutableMapOf<Long, MutableList<Byte>>()

  fun notifyMidiRecorded(midiBytes: ByteArray) {
    if (recordingMelody != null) {
      logI("Recording MIDI data: ${midiBytes.toList()}")
      val time = currentTimeMillis()
      val data: MutableList<Byte> = recordedData.getOrPut(time, { mutableListOf() })
      data.addAll(midiBytes.asIterable())
      logI("recordedData=$recordedData")
    }
  }

  fun notifyNotePlayed(note: Byte, velocity: Byte, channel: Byte) {
    if (recordingMelody != null) {
      val time = currentTimeMillis()
      val data: MutableList<Byte> = recordedData.getOrPut(time, { mutableListOf() })
      data.add(0x90.toByte())
      data.add(note)
      data.add(velocity)
    }
  }

  fun notifyNoteStopped(note: Byte, channel: Byte) {
    if (recordingMelody != null) {
      val time = currentTimeMillis()
      val data: MutableList<Byte> = recordedData.getOrPut(time, { mutableListOf() })
      data.add(0x80.toByte())
      data.add(note)
      data.add(127)
    }
  }

  fun recordBeat() {
    if(recordingMelodyId != null) {
      recordToMelody()
      beatStartTime = currentTimeMillis()
      recordingBeat = currentTick / ticksPerBeat
    }

  }

  private fun recordToMelody() {
    val melody = recordingMelody
    val startTime = beatStartTime
    val beat = recordingBeat
    if(melody != null && startTime != null && beat != null) {
      val endTime = currentTimeMillis()
      val updatedMidiData = MidiData.newBuilder(melody.midiData)
      logI("Processing recordedData=$recordedData")
      recordedData.forEach { (time, data) ->
        logI("Processing data recorded at $time")
        val beatSize = endTime - startTime
        val beatProgress = time - startTime
        val normalizedProgress = beatProgress.toDouble() / beatSize
        var subdivision = round(normalizedProgress * melody.subdivisionsPerBeat).toInt()
        subdivision += beat * melody.subdivisionsPerBeat
        subdivision = (subdivision + melody.length) % melody.length
        val oldData: ByteArray = updatedMidiData.dataMap[subdivision]?.data?.toByteArray()
          ?: ByteArray(0)
        val newData: ByteArray = oldData + data
        updatedMidiData.putData(subdivision,
          MidiChange.newBuilder().setData(ByteString.copyFrom(newData)).build())
      }
      val updatedMelody = Melody.newBuilder(melody)
        .setMidiData(updatedMidiData.build())
        .build()
      recordingMelody = updatedMelody
      sendRecordedMelody()
    }
    recordedData.clear()
  }
}