import Cocoa
import FlutterMacOS
import CoreAudio
import AVFoundation

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController.init()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        RegisterGeneratedPlugins(registry: flutterViewController)
        
        
        
        let channel = FlutterMethodChannel.init(name: "BeatScratchPlugin", binaryMessenger: flutterViewController.engine.binaryMessenger)
        let conductor = Conductor.sharedInstance
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
                case "pushPart":
                    let part = try Part(serializedData: (call.arguments as! FlutterStandardTypedData).data)
                    conductor.setMIDIInstrument(channel: Int(part.instrument.midiChannel), midiInstrument: Int(part.instrument.midiInstrument))
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
        
        super.awakeFromNib()
    }
}
