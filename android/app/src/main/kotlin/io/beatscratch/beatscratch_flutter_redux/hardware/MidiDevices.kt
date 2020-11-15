package io.beatscratch.beatscratch_flutter_redux.hardware

import android.content.Context
import android.media.midi.*
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import androidx.annotation.RequiresApi
import io.beatscratch.beatscratch_flutter_redux.*
import java.io.Closeable

object MidiDevices {
	data class BSMidiDevice(
		val info: MidiDeviceInfo,
		val device: MidiDevice,
		val synthPort: MidiInputPort?,
		val controllerPort: MidiOutputPort?
	): Closeable {
		override fun close() {
			device.close()
			synthPort?.close()
			controllerPort?.close()
		}
	}
	val devices = mutableListOf<BSMidiDevice>()
	val controllers get() = devices.filter { it.controllerPort != null }
	val synthesizers get() = devices.filter { it.synthPort != null }

	@get:RequiresApi(Build.VERSION_CODES.M)
	internal val manager: MidiManager by lazy {
		MainApplication.instance.getSystemService(Context.MIDI_SERVICE) as MidiManager
	}
	private val handler: Handler by lazy {
		val handlerThread = HandlerThread("MIDIDeviceHandlerThread")
		handlerThread.start()
		val looper = handlerThread.looper
		Handler(looper)
	}

	fun refreshInstruments(){
		BeatScratchPlugin.currentScore?.partsList
			?.map { it.instrument }
			?.forEach {
				it.sendSelectInstrument()
			} ?: Unit
		AndroidMidi.flushSendStream()
	}

	@RequiresApi(Build.VERSION_CODES.M)
	fun initialize(context: Context) {
		val infos = manager.devices
		for (info in infos) {
			try {
				setupDevice(info)
			} catch(t: Throwable) {
				logE("Failed to initialize device on startup", t)
			}
		}
		manager.registerDeviceCallback(object : MidiManager.DeviceCallback() {
			@RequiresApi(Build.VERSION_CODES.M)
			override fun onDeviceAdded(info: MidiDeviceInfo) {
				try {
					setupDevice(info)
//						context.toast("Connecting to ${info.properties[MidiDeviceInfo.PROPERTY_NAME]}...")
				} catch(t: Throwable) {
					logE("Failed to setup device", t)
				}
				BeatScratchPlugin.notifyMidiDevices()
			}

			@RequiresApi(Build.VERSION_CODES.M)
			override fun onDeviceRemoved(info: MidiDeviceInfo) {
//					context.toast("Disconnected from ${info.name}.")
				devices.find { it.info == info }?.close()
				devices.removeAll { it.info == info }
				BeatScratchPlugin.notifyMidiDevices()
			}

			override fun onDeviceStatusChanged(status: MidiDeviceStatus) {
				BeatScratchPlugin.notifyMidiDevices()
			}
		}, handler)
	}


	@RequiresApi(Build.VERSION_CODES.M)
	private fun setupDevice(info: MidiDeviceInfo) {
		manager.openDevice(info, { device: MidiDevice? ->
			if(device == null) {
				return@openDevice
			}
			// Again, kinda weirdly, we'll be using input ports to set up output devices
			val inputPort = if (info.inputPortCount > 0) {
				MidiSynthesizers.setupSynthesizer(info, device)
			} else null
			val outputPort = if (info.outputPortCount > 0) {
				MidiControllers.setupController(info, device)
			} else null
			devices += BSMidiDevice(info, device, inputPort, outputPort)
			refreshInstruments()
		}, handler)
	}

	@get:RequiresApi(Build.VERSION_CODES.M)
	internal val MidiDeviceInfo.name: String
		get() {
			return properties[MidiDeviceInfo.PROPERTY_NAME]?.toString() ?: "Unnamed MIDI Device"
		}
}