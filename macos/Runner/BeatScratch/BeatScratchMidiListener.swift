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
  
  // Return the number of bytes processed
  static func parseFirstMidiCommand(args: [UInt8]) -> Int {
    let conductor = Conductor.sharedInstance
    if((args[0] & 0xF0) == 0x90) { // For now the UI can only send noteOn or noteOff events.
      //                    print("noteOn");
      conductor.playNote(note: args[1], velocity: args[2], channel: args[0] & 0xF)
      return 3
    } else if((args[0] & 0xF0) == 0x80) {
      //                    print("noteOff");
      conductor.stopNote(note: args[1], channel: args[0] & 0xF)
      return 3
    } else {
      print("unmatched MIDI bytes:");
      print(args);
      return 0
    }
  }

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
  
  private var sustainDown = false
  func receivedMIDIController(_ controller: MIDIByte, value: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, offset: MIDITimeStamp) {
    print("receivedMIDIController: controller=\(controller), value=\(value), channel=\(channel), portID=\(String(describing: portID)), offset=\(offset)")
    switch controller {
      // Sustain Pedal
      case AKMIDIControl.damperOnOff.rawValue:
        if value > 0 && !sustainDown {
          BeatScratchPlaybackThread.sharedInstance.sendBeat()
          sustainDown = true
        } else if value == 0 {
          sustainDown = false
        }
      // Mod Wheel
      //      case AKMIDIControl.modulationWheel.rawValue:
      //        DispatchQueue.main.async {
      //          self.modWheelPad.setVerticalValueFrom(midiValue: value)
      //        }
      default:
        break
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
      BeatScratchPlaybackThread.sharedInstance.sendBeat()
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
