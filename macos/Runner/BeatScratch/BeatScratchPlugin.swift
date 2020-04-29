//
//  BeatScratchPlugin.swift
//  Runner
//
//  Created by Jon Latane on 4/18/20.
//  Copyright © 2020 The Flutter Authors. All rights reserved.
//

import Foundation
#if canImport(FlutterMacOS)
import FlutterMacOS
#elseif canImport(Flutter)
import Flutter
#endif

class BeatScratchPlugin {
  // Globally accessible
  static let sharedInstance = BeatScratchPlugin()
  var score: Score = Score()
  var channel: FlutterMethodChannel?
  
  private init() {}

  func attach(channel: FlutterMethodChannel) {
    let conductor = Conductor.sharedInstance
    self.channel = channel
    channel.setMethodCallHandler { (call, result) in
      print("Call from macOS: " + call.method)
      do {
        switch call.method {
        case "sendMIDI":
          let data = (call.arguments as! FlutterStandardTypedData).data
          let args = [UInt8](data)
          if((args[0] & 0xF0) == 0x90) { // For now the UI can only send noteOn or noteOff events.
            //                    print("noteOn");
            conductor.playNote(note: args[1], velocity: args[2], channel: args[0] & 0xF)
            result(nil)
          } else if((args[0] & 0xF0) == 0x80) {
            //                    print("noteOff");
            conductor.stopNote(note: args[1], channel: args[0] & 0xF)
            result(nil)
          } else {
            print("unmatched MIDI bytes:");
            print(args);
            result(FlutterMethodNotImplemented)
          }
          break
        case "pushScore":
          let score = try Score(serializedData: (call.arguments as! FlutterStandardTypedData).data)
          self.score = score
          result(nil)
          break
        case "pushPart":
          var part = try Part(serializedData: (call.arguments as! FlutterStandardTypedData).data)
          conductor.setMIDIInstrument(channel: Int(part.instrument.midiChannel), midiInstrument: Int(part.instrument.midiInstrument))
          if(part.melodies.isEmpty) {
            if let existingPart = self.score.parts.first(where: {$0.id == part.id}) {
              part.melodies = existingPart.melodies
              self.score.parts.removeAll(where: {$0.id == part.id})
              self.score.parts.append(part)
            }
          }
          result(nil)
          break
        case "setKeyboardPart":
          let partId = call.arguments as! String
          if let part = self.score.parts.first(where: {$0.id == partId}) {
            Conductor.sharedInstance.assignMidiControllersToChannel(channel: Int(part.instrument.midiChannel))
          }
          break
        case "checkSynthesizerStatus":
          result(Conductor.sharedInstance.samplersInitialized)
          break
        case "play":
          BeatScratchPlaybackThread.sharedInstance.playing = true
          result(nil)
          break
        case "pause":
          BeatScratchPlaybackThread.sharedInstance.stopped = true
          result(nil)
          break
        case "stop":
          BeatScratchPlaybackThread.sharedInstance.stopped = true
          BeatScratchScorePlayer.sharedInstance.currentTick = 0
          result(nil)
          break
        case "setBeat":
          let beat = call.arguments as! Int
          BeatScratchScorePlayer.sharedInstance.currentTick = Int64(beat) * Int64( BeatScratchPlaybackThread.ticksPerBeat)
          result(nil)
          break
        case "countIn":
          let countInBeat = call.arguments as! Int
          BeatScratchScorePlayer.sharedInstance.playMetronome()
          result(nil)
          break
        case "tickBeat":
          BeatScratchScorePlayer.sharedInstance.playMetronome()
          result(nil)
          break
        default:
          result(FlutterMethodNotImplemented)
          break
        }
      } catch {
        print("Failed to process Platform Channel call in macOS. Error: " + error.localizedDescription)
        result(FlutterError())
      }
    }
  }
  
  func sendPressedMidiNotes() {
    do {
      print("swift: sendPressedMidiNotes")
      var midiNotes = MidiNotes()
      midiNotes.midiNotes = Conductor.sharedInstance.pressedNotes.map { UInt32($0) }
      channel?.invokeMethod("sendPressedMidiNotes", arguments: try midiNotes.serializedData())
    } catch {
      print("Failed to sendPressedMidiNotes")
    }
  }
  
  func setSynthesizerAvailable() {
    channel?.invokeMethod("setSynthesizerAvailable", arguments: Conductor.sharedInstance.samplersInitialized)
  }
  
  func sendCurrentBeat() {
    channel?.invokeMethod("sendCurrentBeat", arguments: nil)
  }
}
