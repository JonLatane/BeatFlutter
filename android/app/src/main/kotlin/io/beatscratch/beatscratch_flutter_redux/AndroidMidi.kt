package io.beatscratch.beatscratch_flutter_redux

import android.content.pm.PackageManager
import fluidsynth.FluidSynthMidiReceiver
import java.io.ByteArrayOutputStream

/**
 * Singleton interface to both the Sonivox synthesizer ([ONBOARD_DRIVER])
 * and native MIDI android devices (via [PackageManager.FEATURE_MIDI]).
 */
object AndroidMidi {
	internal var isPlayingFromExternalDevice = false
	internal var lastMidiSyncTime: Long? = null
	init {
		System.loadLibrary("fluidsynthjni")
	}
	private var FLUIDSYNTH = FluidSynthMidiReceiver(MainApplication.instance)
	fun resetFluidSynth() {
		FLUIDSYNTH.nativeLibJNI.destroy()
		FLUIDSYNTH = FluidSynthMidiReceiver(MainApplication.instance)
		MidiDevices.refreshInstruments()
	}
	private var sendToInternalFluidSynthSetting by booleanPref("sendToInternalFluidSynth", true)
	private var sendToExternalSynthSetting by booleanPref("sendToExternalSynth", false)

	var sendToExternalSynth = sendToExternalSynthSetting
		set(value) {
			field = value
			sendToExternalSynthSetting = value
			if(!value) deactivateUnusedDevices()
		}
	var sendToInternalFluidSynth = sendToInternalFluidSynthSetting
		set(value) {
			field = value
			sendToInternalFluidSynthSetting = value
			if(!value) deactivateUnusedDevices()
		}

	val sendStream = ByteArrayOutputStream(2048)
	fun flushSendStream() {
		sendImmediately (
			synchronized(sendStream) {
				sendStream.toByteArray().copyOf().also {
					sendStream.reset()
				}
			}
		)
	}
	fun sendToStream(bytes: ByteArray) = sendStream.write(bytes)

	fun sendImmediately(bytes: ByteArray) {
		if(sendToInternalFluidSynth) {
			FLUIDSYNTH.send(bytes, 0, bytes.size, System.currentTimeMillis())
		}
		if (
			MainApplication.instance.packageManager.hasSystemFeature(PackageManager.FEATURE_MIDI)
				&& sendToExternalSynth
		) {
			MidiSynthesizers.send(bytes)
		}
	}

	private fun deactivateUnusedDevices() {
		if(!sendToInternalFluidSynth) {
			stopMidiReceiver { FLUIDSYNTH.send(it, 0, it.size) }

		}
		if (
			MainApplication.instance.packageManager.hasSystemFeature(PackageManager.FEATURE_MIDI)
			&& !sendToExternalSynth
		) {
			stopMidiReceiver { MidiSynthesizers.send(it) }
		}
	}

	fun stopMidiReceiver(send: (ByteArray) -> Unit) {
		(0 until 16).forEach {  channel ->
			send(byteArrayOf(((0b1011 shl 4) + channel).toByte(), 123, 0)) // All notes off
			send(byteArrayOf(((0b1011 shl 4) + channel).toByte(), 120, 0)) // All sound off
		}
	}
}