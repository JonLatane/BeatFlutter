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
    
    let engine = AVAudioEngine()
    let sampler = AVAudioUnitSampler()
    engine.attach(sampler)
    engine.connect(sampler, to:engine.mainMixerNode, format:engine.mainMixerNode.outputFormat(forBus: 0))

    do {
        let url = Bundle.main.url(forResource:"chaos_bank_v1.9", withExtension:"sf2")
        if url != nil {
            try sampler.loadSoundBankInstrument(at: url!, program: 0, bankMSB: 0, bankLSB: 0)
//            try sampler.loadAudioFiles(at:[url])
            try engine.start()
            print("Started audio engine!")
        } else {
            print("Engine: Couldn't find SoundFont")
        }
    } catch {
        print("Couldn't start engine")
    }
    
//    let channel = FlutterMethodChannel.init(name: "BeatScratchPlugin", binaryMessenger: flutterViewController.engine.binaryMessenger)
//    channel.setMethodCallHandler { (call, result) in
//        print(call.method)
//        switch call.method {
//        case "sendMIDI":
//            sampler.startNote(36, withVelocity:90, onChannel:0)
//
//            let args = call.arguments as! FlutterStandardTypedData
//            sampler.sendMIDISysExEvent(args.data)
//            result(nil)
//            break
//        default:
//            result(FlutterMethodNotImplemented)
//            break
//        }
//    }

    super.awakeFromNib()
  }
}
