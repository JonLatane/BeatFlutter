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
    DispatchQueue.global(qos: .default).async {
      self.run()
    }
  }

  var playing: Bool = false {
    willSet {
      if(!playing && newValue) {
        MelodyRecorder.sharedInstance.clear()
      }
    }
    didSet {
      if(playing) {
        if(MelodyRecorder.sharedInstance.recordingMelody != nil && !playingFromCountIn) {
          // Run the count-in
          DispatchQueue.global(qos: .userInitiated).async { [self] in
            BeatScratchScorePlayer.sharedInstance.playMetronome()
            BeatScratchPlugin.sharedInstance.notifyCountInInitiated()
            let start: Double = CACurrentMediaTime() * 1000
            while(CACurrentMediaTime() * 1000 < start + tickTime * 24) {}
            BeatScratchScorePlayer.sharedInstance.playMetronome()
            BeatScratchPlugin.sharedInstance.notifyPlayingBeat(minus: 1)
            while(CACurrentMediaTime() * 1000 < start + tickTime * 48) {}
            if(playing) {
              semaphore.signal()
            }
          }
        } else {
          semaphore.signal()
        }
      } else {
        Conductor.sharedInstance.stopPlayingNotes()
      }
    }
  }
  
  var stopped: Bool {
    set { playing = !newValue }
    get { return !playing }
  }
  var terminated: Bool = false
  var unmultipliedBpm: Double = 123 { //
    didSet { // Only ever set by native-platform in the "shared model"
      BeatScratchPlugin.sharedInstance.notifyUnmultipliedBpm()
    }
  }
  // Settable by the UI, auto-notifying of changes could cause loops
  var bpmMultiplier: Double = 1
  private let semaphore = DispatchSemaphore(value: 0)
  var tickTime: Double {
    get {
      return 60000 / (self.unmultipliedBpm * bpmMultiplier * BeatScratchPlaybackThread.ticksPerBeat)
    }
  }
  
  func run() {
    while (!terminated) {
      do {
        if (!stopped) {
          let start: Double = CACurrentMediaTime() * 1000
//          print("BeatScratchPlaybackThread: Tick @\(BeatScratchScorePlayer.sharedInstance.currentTick) (T:\(start)")
          try BeatScratchScorePlayer.sharedInstance.tick()
          while(CACurrentMediaTime() * 1000 < start + tickTime) {
//            sleep(0.005)
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
  
  private var playingFromCountIn: Bool = false
  private var beatMinus2: Double?
  func sendBeat() {
    let time = CACurrentMediaTime() * 1000
    if playing {
      playing = false
//      BeatScratchScorePlayer.sharedInstance.currentTick = 0
      BeatScratchPlugin.sharedInstance.notifyPaused()
    } else if beatMinus2 != nil && (time - beatMinus2!) < 3000 {
      // Start playback
      let periodMs: Double = (time - beatMinus2!)
      let multipliedBpm = 60000 / periodMs
      bpmMultiplier = multipliedBpm / unmultipliedBpm
      BeatScratchPlugin.sharedInstance.notifyBpmMultiplier()
      beatMinus2 = nil
      BeatScratchScorePlayer.sharedInstance.currentTick = 24 * (BeatScratchScorePlayer.sharedInstance.currentTick / 24) - 24
//      BeatScratchScorePlayer.sharedInstance.currentTick = -24
      playingFromCountIn = true
      playing = true
      playingFromCountIn = false
    } else {
      BeatScratchScorePlayer.sharedInstance.playMetronome()
      BeatScratchPlugin.sharedInstance.notifyCountInInitiated()
      beatMinus2 = time
    }
  }
}
