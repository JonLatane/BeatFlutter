//
//  BeatScratchPlaybackThread.swift
//  Runner
//
//  Created by Jon Latane on 4/28/20.
//  Copyright © 2020 The Flutter Authors. All rights reserved.
//

import Foundation
import QuartzCore

class BeatScratchPlaybackThread {
  static let sharedInstance = BeatScratchPlaybackThread()
  static let ticksPerBeat: Double = 24 // This is the MIDI beat clock standard

  private init() {
    DispatchQueue.global(qos: .userInteractive).async {
      self.run()
    }
  }

  var playing: Bool {
    set { stopped = !newValue }
    get { return !stopped }
  }
  
  var stopped: Bool = true {
    didSet {
      if(!stopped) {
        semaphore.signal()
      }
    }
  }
  var terminated: Bool = false
  var bpm: Double = 123
  private let semaphore = DispatchSemaphore(value: 0)
  
  func run() {
    while (!terminated) {
      do {
        if (!stopped) {
          let start: Double = CACurrentMediaTime() * 1000
          let tickTime: Double = (60000 / (self.bpm * BeatScratchPlaybackThread.ticksPerBeat))
          print("Tick @\(BeatScratchScorePlayer.sharedInstance.currentTick) (T:\(start)")
          BeatScratchScorePlayer.sharedInstance.tick()
          while(CACurrentMediaTime() * 1000 < start + tickTime) {
//            try sleep(1)
          }
        } else {
        //          BeatClockPaletteConsumer.viewModel?.editModeToolbar?.playButton?.imageResource = R.drawable.icons8_play_100
//          BeatClockScoreConsumer.clearActiveAttacks()
//          AndroidMidi.flushSendStream()
//          synchronized(PlaybackThread) {
//            (PlaybackThread as Object).wait()
//          }
          semaphore.wait()
        //Thread.sleep(10)
        }
      } catch {
       print("Error during background playback: \(error)")
      }
    }
  }
}
