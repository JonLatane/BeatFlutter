import UIKit
import Flutter
import AVFoundation
import Foundation
import AudioKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var flutterViewController: FlutterViewController?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UIApplication.shared.isIdleTimerDisabled = true
    self.flutterViewController = FullscreenFlutterViewController()
    self.window = UIWindow.init(frame: UIScreen.main.bounds)
    self.window.rootViewController = self.flutterViewController //MyNavigationController.init(rootViewController: self.flutterViewController!)
    self.window.makeKeyAndVisible()
    
    
    
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
  
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?
    ) -> Void) -> Bool {
    
    // 1
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
      let url = userActivity.webpageURL/*,
      let components = URLComponents(url: url, resolvingAgainstBaseURL: true)*/ else {
        return false
    }
    BeatScratchPlugin.sharedInstance.openScoreFromUrl(url.absoluteString)
    
//    // 2
//    if let computer = ItemHandler.sharedInstance.items
//      .filter({ $0.path == components.path}).first {
//      presentDetailViewController(computer)
//      return true
//    }
//
//    // 3
//    if let webpageUrl = URL(string: "http://rw-universal-links-final.herokuapp.com") {
//      application.open(webpageUrl)
//      return false
//    }
    
    return false
  }
  
//  func presentDetailViewController(_ computer: Computer) {
//    let storyboard = UIStoryboard(name: "Main", bundle: nil)
//
//    guard
//      let detailVC = storyboard
//        .instantiateViewController(withIdentifier: "DetailController")
//        as? ComputerDetailController,
//      let navigationVC = storyboard
//        .instantiateViewController(withIdentifier: "NavigationController")
//        as? UINavigationController
//      else { return }
//
//    detailVC.item = computer
//    navigationVC.modalPresentationStyle = .formSheet
//    navigationVC.pushViewController(detailVC, animated: true)
//  }
}

@objc class FullscreenFlutterViewController: FlutterViewController {
  override var preferredScreenEdgesDeferringSystemGestures : UIRectEdge {
    if #available(iOS 11.0, *) {
      super.preferredScreenEdgesDeferringSystemGestures
    }
    return [UIRectEdge.bottom, UIRectEdge.right]
  }
}
