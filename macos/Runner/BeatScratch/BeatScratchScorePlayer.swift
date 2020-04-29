//
//  BeatScratchScorePlayer.swift
//  Runner
//
//  Created by Jon Latane on 4/28/20.
//  Copyright © 2020 The Flutter Authors. All rights reserved.
//

import Foundation
class BeatScratchScorePlayer {
  static let sharedInstance = BeatScratchScorePlayer()
  
  var selectedSection: Section? = nil
  var playing: Bool = false
  var currentTick: Int64 = 0
  
  private init() {
  }
  
  func tick() {
    let beatMod: Int = Int(currentTick % Int64(BeatScratchPlaybackThread.ticksPerBeat))
    if beatMod == 0 {
      playMetronome()
    }
    doTick()
    currentTick += 1
  }
  
  func playMetronome() {
    Conductor.sharedInstance.playNote(note: 75, velocity: 127, channel: 9)
  }
  
  private func doTick() {
    
  }
}
