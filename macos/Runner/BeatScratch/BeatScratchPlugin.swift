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
  
  private var newMelodies: Array<Melody> = []

  func attach(channel: FlutterMethodChannel) {
    let conductor = Conductor.sharedInstance
    self.channel = channel
    channel.setMethodCallHandler { (call, result) in
      print("Call from Swift: " + call.method)
      do {
        switch call.method {
        case "sendMIDI":
          let data = (call.arguments as! FlutterStandardTypedData).data
          let args = [UInt8](data)
          let parsedBytes = conductor.parseMidi(args)
          if parsedBytes > 0 {
            result(nil)
          } else {
            result(FlutterMethodNotImplemented)
          }
          break
        case "createScore", "updateSections":
          let score = try Score(serializedData: (call.arguments as! FlutterStandardTypedData).data)
          BeatScratchScorePlayer.sharedInstance.currentSection = score.sections.first {
            $0.id == BeatScratchScorePlayer.sharedInstance.currentSection.id
            } ?? score.sections.first!
          if call.method == "createScore" {
            self.score = score
          } else if call.method == "updateSections" {
            self.score.sections = score.sections
          }
          result(nil)
          break
        case "createPart", "updatePartConfiguration":
          var part = try Part(serializedData: (call.arguments as! FlutterStandardTypedData).data)
          conductor.setMIDIInstrument(channel: part.instrument.midiChannel, midiInstrument: part.instrument.midiInstrument)
          conductor.setVolume(channel: part.instrument.midiChannel, volume: Double(part.instrument.volume))
          if call.method == "updatePartConfiguration" {
            if let existingPart = self.score.parts.first(where: {$0.id == part.id}) {
              do {
                try part.melodies = existingPart.melodies
                try self.score.parts.removeAll(where: {$0.id == part.id})
                try self.score.parts.append(part)
              } catch {
                print("updatePartConfiguration error: \(error)")
              }
              result(nil)
            } else {
              result(FlutterError(code: "500", message: "Part does not exist", details: "nope"))
            }
          } else {
            self.score.parts.append(part)
            result(nil)
          }
          break
        case "newMelody":
          let melody = try Melody(serializedData: (call.arguments as! FlutterStandardTypedData).data)
          self.newMelodies.append(melody)
          result(nil)
          break
        case "registerMelody":
          let registerMelody = try RegisterMelody(serializedData: (call.arguments as! FlutterStandardTypedData).data)
          if let melody: Melody = self.newMelodies.first(where: { $0.id == registerMelody.melodyID }) {
            if var part: Part = self.score.parts.first(where: { $0.id == registerMelody.partID }) {
              part.melodies.append(melody)
              self.score.parts.removeAll { $0.id == part.id }
              self.score.parts.append(part)
              self.newMelodies.removeAll { $0.id == registerMelody.melodyID }
              result(nil)
            } else {
              result(FlutterError(code: "500", message: "Part must be added first", details: "nope"))
            }
          } else {
            result(FlutterError(code: "500", message: "Melody must be added first", details: "nope"))
          }
          break
        case "updateMelody":
          let melody = try Melody(serializedData: (call.arguments as! FlutterStandardTypedData).data)
          if var part: Part = self.score.parts.first(where:{
            $0.melodies.contains(where: { $0.id == melody.id })
          }) {
            part.melodies.removeAll { $0.id == melody.id }
            part.melodies.append(melody)
          } else {
            result(FlutterError(code: "500", message: "Melody not found in any Part", details: "nope"))
          }
          self.newMelodies.append(melody)
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
          Conductor.sharedInstance.stopPlayingNotes()
          BeatScratchScorePlayer.sharedInstance.currentTick = Int64(beat) * Int64( BeatScratchPlaybackThread.ticksPerBeat)
          result(nil)
          break
        case "countIn":
          let countInBeat = call.arguments as! Int
          BeatScratchPlaybackThread.sharedInstance.sendBeat()
          result(nil)
          break
        case "tickBeat":
          BeatScratchPlaybackThread.sharedInstance.sendBeat()
          result(nil)
          break
        case "setPlaybackMode":
          let playback: Playback = try Playback(serializedData: (call.arguments as! FlutterStandardTypedData).data)
          BeatScratchScorePlayer.sharedInstance.playbackMode = playback.mode
          break
        case "setCurrentSection":
          let sectionId = call.arguments as! String
          if let section = self.score.sections.first(where: { $0.id == sectionId }) {
            BeatScratchScorePlayer.sharedInstance.currentSection = section
          }
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
//      print("swift: sendPressedMidiNotes")
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
  
  func notifyPlayingBeat() {
    let beat: Int = Int(BeatScratchScorePlayer.sharedInstance.currentTick / Int64(BeatScratchPlaybackThread.ticksPerBeat))
    channel?.invokeMethod("notifyPlayingBeat", arguments: beat)
  }
  
  func notifyPaused() {
    channel?.invokeMethod("notifyPaused", arguments: nil)
  }

  func notifyCountInInitiated() {
    channel?.invokeMethod("notifyCountInInitiated", arguments: nil)
  }
  
  func notifyCurrentSection() {
    let section = BeatScratchScorePlayer.sharedInstance.currentSection
    channel?.invokeMethod("setCurrentSection", arguments: section.id)
  }
}
