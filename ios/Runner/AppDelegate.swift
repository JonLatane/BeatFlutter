import UIKit
import Flutter
import Firebase
import AVFoundation
import Foundation
import AudioKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "BeatScratchPlugin",
                                           binaryMessenger: controller.binaryMessenger)
        let conductor = Conductor.sharedInstance
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            // Note: this method is invoked on the UI thread.
            // Handle battery messages.
            print("Call from iOS: " + call.method)
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
        })
        
        GeneratedPluginRegistrant.register(with: self)
        //# FirebaseApp.configure()
        //    flutterView
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
