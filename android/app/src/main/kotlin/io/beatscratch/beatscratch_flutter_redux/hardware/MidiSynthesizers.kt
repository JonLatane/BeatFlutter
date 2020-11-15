package io.beatscratch.beatscratch_flutter_redux.hardware

import android.media.midi.MidiDevice
import android.media.midi.MidiDeviceInfo
import android.media.midi.MidiInputPort
import android.os.Build
import androidx.annotation.RequiresApi
import io.beatscratch.beatscratch_flutter_redux.*
import io.beatscratch.beatscratch_flutter_redux.hardware.MidiDevices.name

/**
 * Interface around Android's native MIDI synthesizer support.
 */
@RequiresApi(Build.VERSION_CODES.M)
object MidiSynthesizers {
	internal fun setupSynthesizer(info: MidiDeviceInfo, device: MidiDevice): MidiInputPort? {
		return if (info.inputPortCount > 0) {
			val portNumber = info.ports.find {
				it.type == MidiDeviceInfo.PortInfo.TYPE_INPUT
			}!!.portNumber
			device.openInputPort(portNumber)?.let { inputPort ->
				inputPort.send(byteArrayOf(123.toByte()), 0, 1) //All notes off
				inputPort
			}
		} else null
	}

	/**
	 * Basically, skip everything in the Google guide required to reach the
	 * "Sending Play ON" section. Send away! Your signals will go to all
	 * synthesizers or you can specify the one it should go to.
	 */
	internal fun send(data: ByteArray) {
		logI("Sending ${data.hexString} to synthesizers")
		MidiDevices.synthesizers.forEach {
			if (BeatScratchPlugin.enabledSynthesizersByName.contains(it.info.name)) {
				logI("Sending to ${it.info.name}")
				val port = it.synthPort!!
				try {
					port.send(data, 0, data.size)
					logI("Sent MIDI data")
				} catch (t: Throwable) {
					logE("Failed to send midi data", t)
					port.close()
				}
			}
		}
	}
}