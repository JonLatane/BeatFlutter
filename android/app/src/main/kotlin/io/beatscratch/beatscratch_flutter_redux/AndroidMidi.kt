package io.beatscratch.beatscratch_flutter_redux

import android.content.pm.PackageManager
import fluidsynth.FluidSynthMidiReceiver
import io.beatscratch.beatscratch_flutter_redux.hardware.MidiDevices
import io.beatscratch.beatscratch_flutter_redux.hardware.MidiSynthesizers
import java.io.ByteArrayOutputStream
import kotlinx.coroutines.*
import kotlin.coroutines.CoroutineContext
import kotlin.experimental.or


/**
 * Singleton interface to both the FluidSynth synthesizer ([FLUIDSYNTH])
 * and native MIDI android devices (via [PackageManager.FEATURE_MIDI]).
 */
object AndroidMidi: CoroutineScope {
	var isMidiReady = false
		private set
	internal var isPlayingFromExternalDevice = false
	internal var lastMidiSyncTime: Long? = null
	init {
		GlobalScope.launch {
			val start = System.currentTimeMillis()
			System.loadLibrary("fluidsynthjni")
			println("it took ${System.currentTimeMillis() - start}ms to load fluidsynthjni")
			resetFluidSynth()
		}
	}
	private var FLUIDSYNTH: FluidSynthMidiReceiver? = null
	fun resetFluidSynth() {
		isMidiReady = false
		BeatScratchPlugin.setSynthesizerAvailable()
		FLUIDSYNTH?.nativeLibJNI?.destroy()
		FLUIDSYNTH = FluidSynthMidiReceiver(MainApplication.instance)
		MidiDevices.refreshInstruments()
		isMidiReady = true
		BeatScratchPlugin.setSynthesizerAvailable()
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

	private val byte3 = ByteArray(3)
	fun playNote(midiNote: Byte, velocity: Byte, channel: Byte, immediately: Boolean = false, record: Boolean = false) {
		byte3[0] = MidiConstants.NOTE_ON or channel  // STATUS byte: note On, 0x00 = channel 1
		byte3[1] = midiNote // DATA byte: middle C = 60
		byte3[2] = velocity  // DATA byte: maximum velocity = 127

		if(immediately) {
			sendImmediately(byte3, record = record)
		} else {
			sendToStream(byte3)
		}
	}

	fun stopNote(midiNote: Byte, channel: Byte, immediately: Boolean = false, record: Boolean = false) {
		byte3[0] = MidiConstants.NOTE_OFF or channel  // STATUS byte: note On, 0x00 = channel 1
		byte3[1] = midiNote // DATA byte: middle C = 60
		byte3[2] = 0

		if(immediately) {
			sendImmediately(byte3, record = record)
		} else {
			sendToStream(byte3)
		}
	}
	
	fun sendImmediately(bytes: ByteArray, record: Boolean = false) {
    if(record) {
      MelodyRecorder.notifyMidiRecorded(bytes)
    }
		if(sendToInternalFluidSynth) {
			FLUIDSYNTH?.send(bytes, 0, bytes.size, System.currentTimeMillis())
		}
		if (
			MainApplication.instance.packageManager.hasSystemFeature(PackageManager.FEATURE_MIDI)
				&& sendToExternalSynth
		) {
			MidiSynthesizers.send(bytes)
		}
	}

	fun sendAllNotesOff(immediately: Boolean = false) {
		(0 until 16).forEach {  channel ->
			val bytes = byteArrayOf(((0b1011 shl 4) + channel).toByte(), 123, 0) // All notes off
			if(immediately) {
				sendImmediately(bytes)
			} else {
				sendToStream(bytes)
			}
		}
	}

	private fun deactivateUnusedDevices() {
		if(!sendToInternalFluidSynth) {
			stopMidiReceiver { FLUIDSYNTH?.send(it, 0, it.size) }
		}
		if (
			MainApplication.instance.packageManager.hasSystemFeature(PackageManager.FEATURE_MIDI)
			&& !sendToExternalSynth
		) {
			stopMidiReceiver { MidiSynthesizers.send(it) }
		}
	}

	private fun stopMidiReceiver(send: (ByteArray) -> Unit) {
		(0 until 16).forEach {  channel ->
			send(byteArrayOf(((0b1011 shl 4) + channel).toByte(), 123, 0)) // All notes off
			send(byteArrayOf(((0b1011 shl 4) + channel).toByte(), 120, 0)) // All sound off
		}
	}

  override val coroutineContext: CoroutineContext
    get() = Dispatchers.Default
}