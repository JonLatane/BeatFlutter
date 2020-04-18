//
//  Conductor
//  ROM Player
//
//  Created by Matthew Fecher on 7/20/17.
//  Copyright © 2017 AudioKit Pro. All rights reserved.

import AudioKit
import FlutterMacOS

class Conductor {
  
  // Globally accessible
  static let sharedInstance = Conductor()
  
  var flutterMethodChannel: FlutterMethodChannel? = nil
  var samplersInitialized = false
  var sampler1 = AKSampler()
  var sampler2 = AKSampler()
  var sampler3 = AKSampler()
  var sampler4 = AKSampler()
  var sampler5 = AKSampler()
  var sampler6 = AKSampler()
  var sampler7 = AKSampler()
  var sampler8 = AKSampler()
  var sampler9 = AKSampler()
  var drumSampler = AKSampler()
  var sampler11 = AKSampler()
  var sampler12 = AKSampler()
  var sampler13 = AKSampler()
  var sampler14 = AKSampler()
  var sampler15 = AKSampler()
  var sampler16 = AKSampler()
  var channelSamplers: [Int: AKSampler] = [:]
  
  //    var decimator: AKDecimator
  //    var tremolo: AKTremolo
  //    var fatten: Fatten
  //    var filterSection: FilterSection
  //
  //    var autoPanMixer: AKDryWetMixer
  //    var autopan: AutoPan
  //
  //    var multiDelay: PingPongDelay
  //    var masterVolume = AKMixer()
  //    var reverb: AKCostelloReverb
  //    var reverbMixer: AKDryWetMixer
  let midi = AudioKit.midi
  
  var pressedNotes = [Int]()
  
  init() {
    
    // MIDI Configure
    midi.createVirtualPorts()
    midi.openInput(name: "BeatScratch Session")
    midi.openOutput()
    
    // Session settings
    //AKAudioFile.cleanTempDirectory()
    AKSettings.bufferLength = .medium
    AKSettings.enableLogging = true
    
    // Set Output & Start AudioKit
    let mix = AKMixer(sampler1, sampler2, sampler3, sampler4, sampler5, drumSampler)
    AudioKit.output = mix
    do {
      try AudioKit.start()
    } catch {
      AKLog("AudioKit did not start")
    }
    
    DispatchQueue.global(qos: .background).async {
      self.setupSamplers()
      self.samplersInitialized = true;
      print("This is run on the background queue")
    }
  }
  
  func assignMidiControllersToChannel(channel: Int) {
    midi.clearListeners()
    let listener = MidiListener()
    listener.conductorChannel = channel
    midi.addListener(listener)
  }
  
  private func setupSamplers() {
    channelSamplers.merge([
      0: sampler1,
      1: sampler2,
      2: sampler3,
      3: sampler4,
      4: sampler5,
      5: sampler6,
      6: sampler7,
      7: sampler8,
      8: sampler9,
      9: drumSampler,
      10: sampler11,
      11: sampler12,
      12: sampler13,
      13: sampler14,
      14: sampler15,
      15: sampler16,
    ], uniquingKeysWith: { (_, last) in last })
    for (channel, sampler) in channelSamplers {
      if channel == 9 {
        setupSampler(sampler: sampler, fluidSample: "000_Standard")
      } else if channel == 0 {
        setupSampler(sampler: sampler, fluidSample: "000_Grand Piano")
      }
    }
  }
  
  private func setupSampler(sampler: AKSampler, fluidSample: String) {
    // Example (below) of loading compressed sample files without a SFZ file
    //loadAndMapCompressedSampleFiles()
    
    // Preferred method: use SFZ file
    loadSFZ(sampler: sampler, sfzFileName: fluidSample + ".sfz")
    
    
    // Set up the main amplitude envelope
    sampler.attackDuration = 0.01
    sampler.decayDuration = 0.1
    sampler.sustainLevel = 0.8
    sampler.releaseDuration = 0.5
    
    // optionally, enable the per-voice filters and set up the filter envelope
    // (Try this with the sawtooth waveform example above)
    //        sampler.filterEnable = true
    //        sampler.filterCutoff = 20.0
    //        sampler.filterAttackDuration = 1.0
    //        sampler.filterDecayDuration = 1.0
    //        sampler.filterSustainLevel = 0.5
    //        sampler.filterReleaseDuration = 10.0
    //        sampler.filterEnvelopeVelocityScaling = 1.0
  }
  
  private func loadSFZ(sampler: AKSampler, sfzFileName: String) {
    let folderPath = Bundle.main.resourcePath! + "/Sounds/sfz/fluid"
    print("Fluid R3 Resources are in " + folderPath)
    let info = ProcessInfo.processInfo
    let begin = info.systemUptime
    
    sampler.loadSfzWithEmbeddedSpacesInSampleNames(folderPath: folderPath,
                                                   sfzFileName: sfzFileName)
    
    let elapsedTime = info.systemUptime - begin
    AKLog("Time to load samples \(elapsedTime) seconds")
  }
  
  func addMidiListener(listener: AKMIDIListener) {
    midi.addListener(listener)
  }
  
  func setMIDIInstrument(channel: Int, midiInstrument: Int) {
    self.samplersInitialized = false;
    DispatchQueue.global(qos: .background).async {
      self.setupSampler(sampler: self.channelSamplers[channel]!, fluidSample: instrumentPatches[midiInstrument])
      self.samplersInitialized = true;
    }
  }
  
  func playNote(note: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
    print("Conductor playNote, note=\(note), velocity=\(velocity), channel=\(channel)")
    do {
      try channelSamplers[Int(channel)]?.play(noteNumber: note, velocity: velocity)
    } catch {
      print("playNote error: " + error.localizedDescription)
    }
  }
  
  func stopNote(note: MIDINoteNumber, channel: MIDIChannel) {
    print("Conductor stopNote, note=\(note), channel=\(channel)")
    do {
      try channelSamplers[Int(channel)]?.stop(noteNumber: note)
    } catch {
      print("stopNote error: " + error.localizedDescription)
    }
  }
  
  func allNotesOff() {
    for note in 0 ... 127 {
      for(channel, _) in channelSamplers {
        stopNote(note: UInt8(note), channel: UInt8(channel))
      }
    }
  }
}

class MidiListener : AKMIDIListener {
  var conductorChannel: Int = 0
  func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
    print("received midi note on")
    Conductor.sharedInstance.playNote(note: noteNumber, velocity: velocity, channel: UInt8(conductorChannel))
    Conductor.sharedInstance.pressedNotes.append(Int(noteNumber))
    sendPressedNotes()
  }
  
  func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
    print("received midi note off")
    Conductor.sharedInstance.stopNote(note: noteNumber, channel: UInt8(conductorChannel))
    if let indexToRemove = Conductor.sharedInstance.pressedNotes.firstIndex(of: Int(noteNumber)) {
      Conductor.sharedInstance.pressedNotes.remove(at: indexToRemove)
    }
    sendPressedNotes()
  }
  
  func sendPressedNotes() {
    do {
      print("swift: sendPressedNotes")
      var midiNotes = MidiNotes.init()
      midiNotes.midiNotes = Conductor.sharedInstance.pressedNotes.map { UInt32($0) }
      Conductor.sharedInstance.flutterMethodChannel?.invokeMethod("sendPressedMidiNotes", arguments: try midiNotes.serializedData())
    } catch {
      print("Failed to send pressed notes")
    }
  }
}

var drumPatch = "000_Standard"
var instrumentPatches = [
  "000_Grand Piano",
  // "000_Mellow Grand Piano",
  // "000_Standard",
  "001_Bright Grand Piano",
  // "001_Standard 1",
  "002_Electric Grand",
  // "002_Standard 2",
  "003_Honky-Tonk Piano",
  // "003_Standard 3",
  // "004_Detuned Tine EP",
  // "004_Standard 4",
  "004_Tine Electric Piano",
  // "005_Detuned FM EP",
  "005_FM Electric Piano",
  // "005_Standard 5",
  // "006_Coupled Harpsichord",
  "006_Harpsichord",
  // "006_Standard 6",
  "007_Clavinet",
  // "007_Standard 7",
  "008_Celesta",
  // "008_Room",
  "009_Glockenspiel",
  // "009_Room 1",
  "010_Music Box",
  // "010_Room 2",
  // "011_Room 3",
  "011_Vibraphone",
  "012_Marimba",
  // "012_Room 4",
  // "013_Room 5",
  "013_Xylophone",
  // "014_Church Bell",
  // "014_Room 6",
  "014_Tubular Bells",
  "015_Dulcimer",
  // "015_Room 7",
  // "016_Detuned Organ 1",
  "016_Drawbar Organ",
  // "016_Power",
  // "017_Detuned Organ 2",
  "017_Percussive Organ",
  // "017_Power 1",
  // "018_Power 2",
  "018_Rock Organ",
  // "019_Church Organ 2",
  "019_Church Organ",
  // "019_Power 3",
  "020_Reed Organ",
  "021_Accordion",
  // "021_Italian Accordion",
  "022_Harmonica",
  "023_Bandoneon",
  // "024_Electronic",
  "024_Nylon String Guitar",
  // "024_Ukulele",
  // "025_12-String Guitar",
  // "025_Mandolin",
  "025_Steel String Guitar",
  // "025_TR-808",
  // "026_Hawaiian Guitar",
  "026_Jazz Guitar",
  "027_Clean Guitar",
  "028_Funk Guitar",
  // "028_Palm Muted Guitar",
  "029_Overdrive Guitar",
  "030_Distortion Guitar",
  // "030_Feedback Guitar",
  // "031_Guitar Feedback",
  "031_Guitar Harmonics",
  "032_Acoustic Bass",
  // "032_Jazz",
  "033_Fingered Bass",
  // "033_Jazz 1",
  // "034_Jazz 2",
  "034_Picked Bass",
  "035_Fretless Bass",
  // "035_Jazz 3",
  // "036_Jazz 4",
  "036_Slap Bass",
  "037_Pop Bass",
  "038_Synth Bass 1",
  // "038_Synth Bass 3",
  "039_Synth Bass 2",
  // "039_Synth Bass 4",
  // "040_Brush",
  // "040_Slow Violin",
  "040_Violin",
  // "041_Brush 1",
  "041_Viola",
  // "042_Brush 2",
  "042_Cello",
  "043_Contrabass",
  "044_Tremolo Strings",
  "045_Pizzicato Strings",
  "046_Harp",
  "047_Timpani",
  // "048_Dry Strings",
  // "048_Orchestra Kit",
  // "048_Orchestral Pad",
  "048_Strings",
  "049_Slow Strings",
  "050_Synth Strings 1",
  // "050_Synth Strings 3",
  "051_Synth Strings 2",
  "052_Choir Aahs",
  "053_Voice Oohs",
  "054_Synth Voice",
  "055_Orchestra Hit",
  // "056_MarchingSnare",
  "056_Trumpet",
  // "057_OldMarchingBass",
  "057_Trombone",
  // "058_Marching Cymbals",
  "058_Tuba",
  "059_Harmon Mute Trumpet",
  // "059_NewMarchingBass",
  "060_French Horns",
  // "061_Brass 2",
  "061_Brass Section",
  "062_Synth Brass 1",
  // "062_Synth Brass 3",
  "063_Synth Brass 2",
  // "063_Synth Brass 4",
  "064_Soprano Sax",
  "065_Alto Sax",
  "066_Tenor Sax",
  "067_Baritone Sax",
  "068_Oboe",
  "069_English Horn",
  "070_Bassoon",
  "071_Clarinet",
  "072_Piccolo",
  "073_Flute",
  "074_Recorder",
  "075_Pan Flute",
  "076_Bottle Chiff",
  "077_Shakuhachi",
  "078_Whistle",
  "079_Ocarina",
  // "080_Sine Wave",
  "080_Square Lead",
  "081_Saw Lead",
  "082_Calliope Lead",
  "083_Chiffer Lead",
  "084_Charang",
  "085_Solo Vox",
  "086_5th Saw Wave",
  "087_Bass & Lead",
  "088_Fantasia",
  "089_Warm Pad",
  "090_Polysynth",
  "091_Space Voice",
  "092_Bowed Glass",
  "093_Metal Pad",
  "094_Halo Pad",
  // "095_OldMarchingTenor",
  "095_Sweep Pad",
  "096_Ice Rain",
  // "096_MarchingTenor",
  "097_Soundtrack",
  "098_Crystal",
  "099_Atmosphere",
  "100_Brightness",
  "101_Goblin",
  "102_Echo Drops",
  "103_Star Theme",
  "104_Sitar",
  "105_Banjo",
  "106_Shamisen",
  "107_Koto",
  // "107_Taisho Koto",
  "108_Kalimba",
  "109_Bagpipe",
  "110_Fiddle",
  "111_Shenai",
  "112_Tinker Bell",
  "113_Agogo",
  "114_Steel Drums",
  // "115_Castanets",
  // "115_Temple Blocks",
  "115_Woodblock",
  // "116_Concert Bass Drum",
  "116_Taiko Drum",
  // "117_Melo Tom 2",
  "117_Melodic Tom",
  // "118_808 Tom",
  "118_Synth Drum",
  "119_Reverse Cymbal",
  "120_Fret Noise",
  "121_Breath Noise",
  "122_Sea Shore",
  "123_Bird Tweet",
  "124_Telephone",
  "125_Helicopter",
  "126_Applause",
  "127_Gun Shot"
]
