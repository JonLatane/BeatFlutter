package io.beatscratch.beatscratch_flutter_redux

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import org.beatscratch.models.Music

class BeatScratchPlugin : MethodChannel.MethodCallHandler {
  companion object {
    var currentScore: Music.Score? = null
      set(value) {
        field = value
        MidiDevices.refreshInstruments()
        tickPosition = 0
      }
    var currentSection: Music.Section? = null
      set(value) {
        field = value
//    viewModel?.melodyView?.post {
//      viewModel?.notifySectionChange()
//    }
        //MidiDevices.refreshInstruments()
      }
    var tickPosition: Int = 0
    var keyboardPart: Music.Part? = null
    var colorboardPart: Music.Part? = null

    //TODO probs port to a new Midi-centric proto?
    enum class PlaybackMode { SECTION, PALETTE }
    var playbackMode = PlaybackMode.PALETTE
    @JvmStatic
    fun registerWith(registrar: PluginRegistry.Registrar) {
      val channel = MethodChannel(registrar.messenger(), "BeatScratchPlugin")
      channel.setMethodCallHandler(BeatScratchPlugin())
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      try {
        result.success(null)
      } catch (e: Exception) {
        result.error("Cannot serialize data", null, null)
      }
    } else {
      result.notImplemented()
    }
  }
}
//
//fun getMyPerson(): PersonOuterClass.Person {
//  return PersonOuterClass.Person.newBuilder()
//    .setName("TruongSinh")
//    .addAllSupervisorOf(listOf(
//      PersonOuterClass.Person.newBuilder()
//        .setName("Jane Dane")
//        .addAllAddresses(listOf(
//          PersonOuterClass.UsaAddress.newBuilder()
//            .setStreetNameAndNumber("1 Infinity Loop")
//            .setCity("Cupertino")
//            .setState(PersonOuterClass.UsaState.CA)
//            .setPostCode(95014)
//            .build(),
//          PersonOuterClass.UsaAddress.newBuilder()
//            .setStreetNameAndNumber("1 Microsoft Way")
//            .setCity("Redmond")
//            .setState(PersonOuterClass.UsaState.WA)
//            .setPostCode(98052)
//            .build()
//        ))
//        .build(),
//      PersonOuterClass.Person.newBuilder()
//        .setName("Joe Doe")
//        .addAllAddresses(listOf(
//          PersonOuterClass.UsaAddress.newBuilder()
//            .setStreetNameAndNumber("1 Infinity Loop")
//            .setCity("Cupertino")
//            .setState(PersonOuterClass.UsaState.CA)
//            .setPostCode(95014)
//            .build(),
//          PersonOuterClass.UsaAddress.newBuilder()
//            .setStreetNameAndNumber("1 Microsoft Way")
//            .setCity("Redmond")
//            .setState(PersonOuterClass.UsaState.WA)
//            .setPostCode(98052)
//            .build()
//        ))
//        .build()
//    ))
//    .build()