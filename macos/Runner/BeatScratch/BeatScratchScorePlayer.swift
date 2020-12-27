//
//  BeatScratchScorePlayer.swift
//  Runner
//
//  Created by Jon Latane on 4/28/20.
//  Copyright © 2020 The Flutter Authors. All rights reserved.
//

import Foundation
import AudioKit

class BeatScratchScorePlayer {
  static let sharedInstance = BeatScratchScorePlayer()
  var metronomeEnabled: Bool = true
  var score: Score { return BeatScratchPlugin.sharedInstance.score }
  struct Attack {
    var melodyId: String? = nil
    var channel: MIDIChannel
    var tone: MIDINoteNumber
    var velocity: MIDIVelocity
  }
  
  static let cChromatic: Chord = {
    var chord = Chord()
    chord.rootNote = NoteName()
    chord.rootNote.noteLetter = NoteLetter.c
    return chord
  }()
  
  var playbackMode: Playback.Mode = Playback.Mode.score
  private var currentSectionId: String = ""
  var currentSection: Section {
    get {
      return score.sections.first { $0.id == currentSectionId } ?? Section()
    }
    set {
      currentSectionId = newValue.id
      BeatScratchPlaybackThread.sharedInstance.unmultipliedBpm = Double(newValue.tempo.bpm)
      clearNonSectionActiveAttacks()
      BeatScratchPlugin.sharedInstance.notifyUnmultipliedBpm()
    }
  }
  var currentTick: Int64 = 0
  private var chord: Chord = cChromatic
  var activeAttacks: Array<Attack> = []
  var outgoingAttacks: Array<Attack> = []
  var upcomingAttacks: Array<Attack> = []
  
  private init() {}
  
  func tick() {
    let harmony = currentSection.harmony
    if currentTick >= Int(24 * Double(harmony.length) / Double(harmony.subdivisionsPerBeat)) {
//      Conductor.sharedInstance.stopPlayingNotes()
      let sectionIndex = score.sections.firstIndex(of: currentSection) ?? -1
      currentTick = 0
      if playbackMode == Playback.Mode.score {
        if sectionIndex + 1 < score.sections.count {
          currentSection = score.sections[sectionIndex + 1]
          BeatScratchPlugin.sharedInstance.notifyStartedCurrentSection()
        } else {
          currentSection = score.sections[0]
          BeatScratchPlugin.sharedInstance.notifyPlayingBeat()
          BeatScratchPlaybackThread.sharedInstance.playing = false
          BeatScratchPlugin.sharedInstance.notifyStartedCurrentSection()
          BeatScratchPlugin.sharedInstance.notifyPaused()
          return
        }
      }
    }
    let beatMod: Int = Int(currentTick % Int64(BeatScratchPlaybackThread.ticksPerBeat))
    if beatMod == 0 {
      playMetronome()
      if (playbackMode == Playback.Mode.score && currentTick == 0) {
        clearNonSectionActiveAttacks()
      }
      BeatScratchPlugin.sharedInstance.notifyPlayingBeat()
      MelodyRecorder.sharedInstance.notifyBeatFinished()
    }
    if playbackMode == Playback.Mode.score {
      doPreviousSectionTickNoteOffs()
    }
    doTick()
    currentTick += 1
  }
  
  func playMetronome() {
    if metronomeEnabled {
      Conductor.sharedInstance.playNote(note: 75, velocity: 127, channel: 9)
    }
  }
  
  private func harmonyPosition(harmony: Harmony) -> Int {
    return Int(currentTick).convertSubdivisionPosition(
      fromSubdivisionsPerBeat: 24,
      toSubdivisionsPerBeat: Int(harmony.subdivisionsPerBeat)
    )
  }
  
//  private var harmonyChord: Chord {
//    return chord
//  }
  
  private func doTick() {
//    print("BeatScratchScorePlayer: processing tick \(currentTick)")
    let score = BeatScratchPlugin.sharedInstance.score
    let section: Section = currentSection
    //    chord = (harmonyChord ?: chord)?.also { chord ->
    //      doAsync {
    //        viewModel?.apply {
    //          if (
    //            !harmonyViewModel.isChoosingHarmonyChord && chord != orbifold.chord
    //          ) {
    //            orbifold.disableNextTransitionAnimation()
    //            //viewModel?.orbifold?.prepareAnimationTo(chord)
    //            uiThread {
    //              orbifold.chord = chord
    //            }
    //          }
    //        }
    //      }
    //    }
//    print("BeatScratchScorePlayer: harmonyPosition=\(harmonyPosition); chord=\(chord)")
    score.parts.forEach {
      let part = $0
      section.melodies.filter {
        let reference = $0
        return reference.playbackType != MelodyReference.PlaybackType.disabled
        && part.melodies.contains { $0.id == reference.melodyID }
      }.forEach {
        let melodyReference = $0
        if let melody: Melody = melodyReference.melodyFrom(score) {
          handleCurrentTickPosition(melodyReference, melody, part)
        }
      }
    }
  }
  
  private func doPreviousSectionTickNoteOffs() {
    //    print("BeatScratchScorePlayer: processing tick \(currentTick)")
    let score = BeatScratchPlugin.sharedInstance.score
    let sectionIndex = BeatScratchPlugin.sharedInstance.score.sections.firstIndex { $0.id == currentSection.id } ?? 0
    if sectionIndex >= 1 && currentTick / 24 <= 4 {
      let previousSection: Section = BeatScratchPlugin.sharedInstance.score.sections[sectionIndex - 1]
      score.parts.forEach {
        let part = $0
        previousSection.melodies.filter {
          let reference = $0
          return reference.playbackType != MelodyReference.PlaybackType.disabled
            && part.melodies.contains { $0.id == reference.melodyID }
        }.forEach {
          let melodyReference = $0
          if let melody: Melody = melodyReference.melodyFrom(score) {
            handleCurrentTickPosition(melodyReference, melody, part, playNoteOns: false)
          }
        }
      }
    }
  }
  
  private func handleCurrentTickPosition(_ melodyReference: MelodyReference, _ melody: Melody, _ part: Part, playNoteOns: Bool = true) {
    let ticks = Base24Conversion.map[Int(melody.subdivisionsPerBeat)]!
    if let correspondingPosition = ticks.firstIndex(of: Int(currentTick) % Int(BeatScratchPlaybackThread.ticksPerBeat)) {
      let currentBeat = floor(Double(currentTick) / BeatScratchPlaybackThread.ticksPerBeat)
      let melodyPosition = currentBeat * Double(melody.subdivisionsPerBeat) + Double(correspondingPosition)
      if let midiData = melody.midiData.data[Int32(melodyPosition) % Int32(melody.length)] {
        let bytes = [UInt8](midiData.data)
//        print("BeatScratchScorePlayer: CALLING parseMidi. bytes=\(bytes)");
        let processedBytes = Conductor.sharedInstance.parseMidi(bytes, channelOverride: UInt8(part.instrument.midiChannel), velocityMultiplier: melodyReference.volume, playNoteOns: playNoteOns, melodyId: melody.id, attacks: &activeAttacks)
//        print("BeatScratchScorePlayer: processed \(processedBytes) of data")
      }
    }
  }
  
  func clearNonSectionActiveAttacks() {
    activeAttacks.removeAll(where: { (attack) -> Bool in
      let remove: Bool = !currentSection.melodies.contains(where: { $0.melodyID == attack.melodyId })
      if (remove) {
        Conductor.sharedInstance.stopNote(note: attack.tone, channel: attack.channel)
      }
      return remove
    })
  }
}

