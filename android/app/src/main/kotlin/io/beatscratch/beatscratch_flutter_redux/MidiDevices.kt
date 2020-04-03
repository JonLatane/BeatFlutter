package io.beatscratch.beatscratch_flutter_redux

import android.content.Context
import android.content.pm.PackageManager
import android.media.midi.*
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import androidx.annotation.RequiresApi
import java.io.Closeable

object MidiDevices {
	data class BSMidiDevice(
		val info: MidiDeviceInfo,
		val device: MidiDevice,
		val inputPort: MidiInputPort?,
		val outputPort: MidiOutputPort?
	): Closeable {
		override fun close() {
			device.close()
			inputPort?.close()
			outputPort?.close()
		}
	}
	val devices = mutableListOf<BSMidiDevice>()

	@get:RequiresApi(Build.VERSION_CODES.M)
	internal val manager: MidiManager by lazy {
		MainApplication.instance.getSystemService(Context.MIDI_SERVICE) as MidiManager
	}
	internal val handler: Handler by lazy {
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
		if (MainApplication.instance.packageManager.hasSystemFeature(PackageManager.FEATURE_MIDI)
			&& Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
		) {
			val infos = manager.devices
			for (info in infos) {
				setupDevice(info)
			}
			manager.registerDeviceCallback(object : MidiManager.DeviceCallback() {
				@RequiresApi(Build.VERSION_CODES.M)
				override fun onDeviceAdded(info: MidiDeviceInfo) {
					try {
//						context.toast("Connecting to ${info.properties[MidiDeviceInfo.PROPERTY_NAME]}...")
					} catch(t: Throwable) {}
					setupDevice(info)
				}

				@RequiresApi(Build.VERSION_CODES.M)
				override fun onDeviceRemoved(info: MidiDeviceInfo) {
//					context.toast("Disconnected from ${info.name}.")
					devices.find { it.info == info }?.close()
					devices.removeAll { it.info == info }
				}

				override fun onDeviceStatusChanged(status: MidiDeviceStatus) {}
			}, handler)
		}
	}


	@RequiresApi(Build.VERSION_CODES.M)
	private fun setupDevice(info: MidiDeviceInfo) {
		manager.openDevice(info, { device ->
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