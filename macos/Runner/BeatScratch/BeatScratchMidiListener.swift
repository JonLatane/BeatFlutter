//
//  MidiListener.swift
//  Runner
//
//  Created by Jon Latane on 4/22/20.
//  Copyright © 2020 The Flutter Authors. All rights reserved.
//

import Foundation
import AudioKit

class BeatScratchMidiListener : AKMIDIListener {
  static let sharedInstance = BeatScratchMidiListener()
  private init(){}
  var conductorChannel: Int = 0
  func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
    print("received midi note on")
    Conductor.sharedInstance.playNote(note: noteNumber, velocity: velocity, channel: UInt8(conductorChannel))
    Conductor.sharedInstance.pressedNotes.append(Int(noteNumber))
    BeatScratchPlugin.sharedInstance.sendPressedMidiNotes()
  }
  
  func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID? = nil, offset: MIDITimeStamp = 0) {
    print("received midi note off")
    Conductor.sharedInstance.stopNote(note: noteNumber, channel: UInt8(conductorChannel))
    if let indexToRemove = Conductor.sharedInstance.pressedNotes.firstIndex(of: Int(noteNumber)) {
      Conductor.sharedInstance.pressedNotes.remove(at: indexToRemove)
    }
    BeatScratchPlugin.sharedInstance.sendPressedMidiNotes()
  }
  
  func receivedMIDIController(controller: MIDIByte, value: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, offset: MIDITimeStamp) {
    if portID != nil {
      AudioKit.midi.openInput(uid: portID!)
    } else {
      AudioKit.midi.openInput(name: "BeatScratch Session")
    }
  }
  
  func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {
    print(propertyChangeInfo)
    
    if propertyChangeInfo.objectType == MIDIObjectType.device {
      print("Device detected, opening input")
      AudioKit.midi.openInput(name: "BeatScratch Session")
    }
  }
  
  var lastPitchWheelValue: MIDIWord = 8192
  func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord,
                              channel: MIDIChannel,
                              portID: MIDIUniqueID?,
                              offset: MIDITimeStamp) {
    print("receivedMIDIPitchWheel: \(pitchWheelValue)")
    if(lastPitchWheelValue == 8192 && pitchWheelValue != 8192) {
      BeatScratchScorePlayer.sharedInstance.playMetronome()
    }
    lastPitchWheelValue = pitchWheelValue
  }
  
  func receivedMIDISystemCommand(_ data: [MIDIByte],
                                 portID: MIDIUniqueID?,
                                 offset: MIDITimeStamp) {
    print("receivedMIDISystemCommand: \(data)")
  }
  
  func receivedMIDISetupChange() {
    print("receivedMIDISetupChange")
  }


}
