package io.beatscratch.beatscratch_flutter_redux

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class PlatformChannelPlugin : MethodChannel.MethodCallHandler {

  companion object {
    @JvmStatic
    fun registerWith(registrar: PluginRegistry.Registrar) {
      val channel = MethodChannel(registrar.messenger(), "plugin_with_protobuf")
      channel.setMethodCallHandler(PlatformChannelPlugin())
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