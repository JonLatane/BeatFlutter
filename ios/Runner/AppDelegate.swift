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
        UIApplication.shared.isIdleTimerDisabled = true
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
//      controller.preferredScreenEdgesDeferringSystemGestures = []
        let channel = FlutterMethodChannel(name: "BeatScratchPlugin",
                                           binaryMessenger: controller.binaryMessenger)
        
        do {
          try AKSettings.setSession(category: .playAndRecord, with: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
        } catch {
          AKLog("Could not set session category.")
        }
        BeatScratchPlugin.sharedInstance.attach(channel: channel)

        
        GeneratedPluginRegistrant.register(with: self)
        //# FirebaseApp.configure()
        //    flutterView
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
