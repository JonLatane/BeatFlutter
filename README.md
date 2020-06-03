# BeatScratch for Flutter

BeatScratch is a new type of music app that combines fantastically readable musical notation with 
looping features similar to Boss or Ableton products. [Its grandparent](https://github.com/falrm/beatpad) 
also has some revolutionary means of visualizing and composing chord changes that your loops can 
adapt to, but those haven't yet been ported to the Flutter version.

On the backend, BeatScratch uses Platform Channels to delegate audio generation to FluidSynth
on Android, AudioKit on iOS/macOS, and MIDI.js for the web (web has much more limited support).

## License

* The source code to BeatScratch is licensed under the [GPLv3](LICENSE.md).
* This means you must publish changes to BeatScratch under the GPLv3 if you distribute a modified version of it.
* The logo and the BeatScratch name, while available in this repository, *is not licensed under the GPL*.
* I encourage you not to attempt to release it in the App Store or Play Store, but of course anyone
  is free to do so provided they release the source. The logo and name may only be used by me, however.

## Build/Run

* With Protobuf 3 installed, you can run `./build-protos` to build the Dart and Swift protos. Android JVM proto compilation build is handled by Gradle.
    * Generated Dart/Swift classes are committed to the repo if you don't want to install Protobuf.
* Beyond that, `flutter run`, etc. will work as normal.
