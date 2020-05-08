package io.beatscratch.beatscratch_flutter_redux.hardware

//import kotlinx.coroutines.experimental.*
import android.media.midi.MidiDevice
import android.media.midi.MidiDeviceInfo
import android.media.midi.MidiOutputPort
import android.media.midi.MidiReceiver
import android.os.Build
import androidx.annotation.RequiresApi
import io.beatscratch.beatscratch_flutter_redux.*
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.keyboardPart
import io.beatscratch.beatscratch_flutter_redux.MidiConstants.leftHalf
import io.beatscratch.beatscratch_flutter_redux.MidiConstants.leftHalfMatchesAny
import io.beatscratch.beatscratch_flutter_redux.MidiConstants.rightHalf

object MidiControllers {
	val pressedNotes: MutableSet<Int> = mutableSetOf()

	@RequiresApi(Build.VERSION_CODES.M)
	internal fun setupController(info: MidiDeviceInfo, device: MidiDevice): MidiOutputPort? = with(MidiConstants) {
		val portNumber = info.ports.find {
			it.type == MidiDeviceInfo.PortInfo.TYPE_OUTPUT
		}!!.portNumber
		device.openOutputPort(portNumber)?.let { outputPort ->
			try {
//				MainApplication.instance.toast("Controller ${info.name} connected!")
			} catch(t: Throwable) {}
			outputPort.connect(Receiver())
			outputPort
		}
	}

	class Receiver : MidiReceiver() {
		private var sustainDown = false
		override fun onSend(msg: ByteArray, offset: Int, count: Int, timestamp: Long) {
			//info("MIDI data: ${msg.hexString(offset, count)}")
			var byteIndex = offset
			do {
				when {
					msg[byteIndex] == MidiConstants.TICK                                             -> {
						//info("Received beatclock tick ${BeatClockPaletteConsumer.tickPosition}")
						if(AndroidMidi.isPlayingFromExternalDevice) {
							//BeatClockPaletteConsumer.tickPosition++
							//doAsync {
							ScorePlayer.tick()
							//}
						}
						byteIndex += 1
					}
					msg[byteIndex] == MidiConstants.PLAY                                             -> {
						//info("Received play")
						ScorePlayer.currentTick = 0
						AndroidMidi.isPlayingFromExternalDevice = true
						byteIndex += 1
					}
					msg[byteIndex] == MidiConstants.STOP                                             -> {
						//info("Received stop")
						AndroidMidi.isPlayingFromExternalDevice = false
						ScorePlayer.currentTick = 0
						byteIndex += 1
					}
					msg[byteIndex] == MidiConstants.SYNC                                             -> {
						//info("Received sync")
						AndroidMidi.lastMidiSyncTime = System.currentTimeMillis()
						byteIndex += 1
					}
					msg[byteIndex].leftHalfMatchesAny(MidiConstants.NOTE_ON, MidiConstants.NOTE_OFF) -> {
						//info("Received note on")
						val noteOnOrOff = msg[byteIndex].leftHalf
						val channel =  msg[byteIndex].rightHalf
						val midiTone = msg[byteIndex + 1]
						val velocity = msg[byteIndex + 2]
						keyboardPart?.instrument?.let { instrument ->
							when(noteOnOrOff) {
								MidiConstants.NOTE_ON  -> {
									instrument.play(midiTone.toInt() - 60, velocity.toInt(), immediately = true, record = true)
									pressedNotes.add(midiTone.toInt())
									BeatScratchPlugin.sendPressedMidiNotes()
								}
								MidiConstants.NOTE_OFF -> {
									instrument.stop(midiTone.toInt() - 60, immediately = true, record = true)
									pressedNotes.remove(midiTone.toInt())
									BeatScratchPlugin.sendPressedMidiNotes()
								}
							}
							byteIndex += 3
						}
					}
          msg[byteIndex].leftHalfMatchesAny(MidiConstants.CONTROL_CHANGE) -> {
						val channel =  msg[byteIndex].rightHalf
						when {
							msg[byteIndex + 1] == 64.toByte() -> {
								//Sustain pedal
								val value = msg[byteIndex + 2]
								if (value >= 64 && !sustainDown) {
									PlaybackThread.sendBeat()
									sustainDown = true
								} else if (value < 64) {
									sustainDown = false
								}
							}
						}
						val midiTone = msg[byteIndex + 1]
						val velocity = msg[byteIndex + 2]
						byteIndex += 3

					}
					else                                                                             -> {
						error("Unable to parse MIDI: ${msg.hexString(offset, count)}@byte ${byteIndex - offset}")
						byteIndex += 1
					}
				}
			} while(byteIndex < offset + count)
		}
	}
}