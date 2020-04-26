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
    BeatScratchPlugin.sharedInstance.attach(channel: channel)
    
    super.awakeFromNib()
  }
}
