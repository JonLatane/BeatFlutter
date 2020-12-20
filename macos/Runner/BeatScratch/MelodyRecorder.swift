//
//  MelodyRecorder.swift
//  Runner
//
//  Created by Jon Latane on 5/3/20.
//  Copyright © 2020 The Flutter Authors. All rights reserved.
//

import Foundation
import QuartzCore
import AudioKit

extension Dictionary {
  mutating func processUpdate(_ key: Key, computation: (Value?) -> Value) {
    let oldValue = self[key]
    let newValue: Value = computation(oldValue)
    self[key] = newValue
  }
}

class MelodyRecorder {
  static let sharedInstance = MelodyRecorder()
  private init() {}
  private var recordedSegment = RecordedSegment()
  
  private func cut() -> RecordedSegment {
    let segment = recordedSegment
    clear()
    return segment
  }
  
  func clear() {
    recordedSegment = RecordedSegment()
  }
  var recordingMelodyId: String?
  var recordingMelody: Melody? {
    get {
      if recordingMelodyId == nil {
        return nil
      }
      return BeatScratchPlugin.sharedInstance.score.parts.flatMap { $0.melodies }.first { $0.id == recordingMelodyId }
    }
    set {
      recordingMelodyId = newValue?.id
      if newValue == nil {
        clear()
      }
    }
  }
  
  func notifyNotePlayed(note: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
    if recordingMelodyId != nil {
      var x = RecordedSegment.RecordedData()
      x.timestamp = UInt64(CACurrentMediaTime() * 1000)
      x.midiData = Data([0x90, note, velocity])
      recordedSegment.recordedData.append(x)
    }
  }
  
  func notifyNoteStopped(note: MIDINoteNumber, channel: MIDIChannel) {
    if recordingMelodyId != nil {
      var x = RecordedSegment.RecordedData()
      x.timestamp = UInt64(CACurrentMediaTime() * 1000)
      x.midiData = Data([0x80, note])
      recordedSegment.recordedData.append(x)
    }
  }
  
  func notifyBeatFinished() {
    if recordingMelodyId != nil {
      var beat = Double(BeatScratchScorePlayer.sharedInstance.currentTick) / BeatScratchPlaybackThread.ticksPerBeat
      if beat < 0 {
        let m = recordingMelody!
        beat += Double(m.length / m.subdivisionsPerBeat)
      }
      var rb = RecordedSegment.RecordedBeat()
      rb.beat = UInt32(beat)
      rb.timestamp = UInt64(CACurrentMediaTime() * 1000)
      recordedSegment.beats.append(rb)
      recordToMelody()
    }
  }
  
  private func recordToMelody() {
    if recordingMelodyId != nil {
      // Need at least two beat points to be worth sending data
      if recordedSegment.beats.count > 1 {
        let segment = cut()
        let lastBeat = segment.beats.max { (rb1, rb2) -> Bool in rb1.timestamp < rb2.timestamp }!
        recordedSegment.beats.append(lastBeat)
        BeatScratchPlugin.sharedInstance.notifyRecordedSegment(segment)
      } else {
        print("recordToMelody: Not enough beats")
      }
    }
  }
}
