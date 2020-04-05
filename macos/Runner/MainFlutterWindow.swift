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
            switch call.method {
            case "sendMIDI":
                let data = (call.arguments as! FlutterStandardTypedData).data
                let args = [UInt8](data)
                if((args[0] & 0xF0) == 0x90) {
                    print("noteOn");
                    conductor.playNote(note: args[1], velocity: args[2], channel: args[0] & 0xF)
                } else if((args[0] & 0xF0) == 0x80) {
                    print("noteOff");
                    conductor.stopNote(note: args[1], channel: args[0] & 0xF)
                } else {
                    print("unmatched args:");
                    print(args);
                }
                result(nil)
                break
            default:
                result(FlutterMethodNotImplemented)
                break
            }
        }
        
        super.awakeFromNib()
    }
}
